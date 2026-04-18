import Foundation
import Flutter
import AuraLiteRTNative
import Photos
import PhotosUI
import UniformTypeIdentifiers

final class AuraLiteRTBridge: NSObject {
  private let methodChannelName = "aura/litert"
  private let textStreamChannelName = "aura/litert/text_stream"
  private let audioStreamChannelName = "aura/litert/audio_stream"

  private let nativeEngine = AURLiteRTNativeEngine()
  private var textSink: FlutterEventSink?
  private var audioSink: FlutterEventSink?
  private var activeTextRequestId: String?
  private var activeTextGeneration: UInt64 = 0
  private var activeTextState: TextStreamState?
  private var streamTimeoutTimer: DispatchWorkItem?
  private var pendingPhotoPickerResult: FlutterResult?
  private var photoPickerCoordinator: NSObject?

  func register(with messenger: FlutterBinaryMessenger) {
    let methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: messenger)
    methodChannel.setMethodCallHandler(handle)

    let textStream = FlutterEventChannel(name: textStreamChannelName, binaryMessenger: messenger)
    textStream.setStreamHandler(TextStreamProxy(owner: self))

    let audioStream = FlutterEventChannel(name: audioStreamChannelName, binaryMessenger: messenger)
    audioStream.setStreamHandler(AudioStreamProxy(owner: self))
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]

    switch call.method {
    case "initialize":
      nativeEngine.configure(
        withPrimaryDelegate: args["primaryDelegate"] as? String ?? "cpu",
        fallbackDelegates: args["fallbackDelegates"] as? [String] ?? ["cpu"],
        maxContextTokensOverride: args["maxContextTokensOverride"] as? NSNumber,
      )
      result(nil)
    case "getDeviceProfile":
      result([
        "physicalMemoryBytes": NSNumber(value: ProcessInfo.processInfo.physicalMemory),
        "systemVersion": UIDevice.current.systemVersion,
        "model": UIDevice.current.model,
      ])
    case "getRuntimeStatus":
      result(nativeEngine.runtimeStatus())
    case "loadModel":
      handleLoadModel(args: args, result: result)
    case "unloadModel":
      nativeEngine.cancelActiveGeneration()
      clearActiveText(notify: true)
      nativeEngine.unloadModel { error in
        if let error {
          result(FlutterError(code: "ENGINE_UNLOAD_FAILED", message: error.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }
    case "cancelActiveInference":
      nativeEngine.cancelActiveGeneration()
      clearActiveText(notify: true)
      result(nil)
    case "beginTextInference":
      handleBeginTextInference(args: args, result: result)
    case "beginAudioInference":
      let requestId = args["requestId"] as? String ?? ""
      emitError(audioSink, requestId: requestId, error: "Audio input is not supported on iOS yet.")
      result(nil)
    case "pickCharacterCardPhoto":
      handlePickCharacterCardPhoto(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handlePickCharacterCardPhoto(result: @escaping FlutterResult) {
    guard #available(iOS 14.0, *) else {
      result(
        FlutterError(
          code: "PHOTO_PICKER_UNAVAILABLE",
          message: "Photo import from the library requires iOS 14 or newer.",
          details: nil
        )
      )
      return
    }

    handlePickCharacterCardPhotoAvailable(result: result)
  }

  @available(iOS 14.0, *)
  private func handlePickCharacterCardPhotoAvailable(result: @escaping FlutterResult) {
    guard pendingPhotoPickerResult == nil else {
      result(
        FlutterError(
          code: "PHOTO_PICKER_BUSY",
          message: "A photo import is already in progress.",
          details: nil
        )
      )
      return
    }

    guard let presenter = topViewController() else {
      result(
        FlutterError(
          code: "PHOTO_PICKER_UNAVAILABLE",
          message: "Aura could not open the photo picker right now.",
          details: nil
        )
      )
      return
    }

    var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
    configuration.filter = .images
    configuration.selectionLimit = 1
    configuration.preferredAssetRepresentationMode = .current

    let picker = PHPickerViewController(configuration: configuration)
    pendingPhotoPickerResult = result
    let coordinator = PhotoPickerCoordinator(
      owner: self,
      clearRetainedPicker: { [weak self] in
        self?.photoPickerCoordinator = nil
      }
    )
    photoPickerCoordinator = coordinator
    picker.delegate = coordinator

    DispatchQueue.main.async {
      presenter.present(picker, animated: true)
    }
  }

  private func handleLoadModel(args: [String: Any], result: @escaping FlutterResult) {
    let modelPath = args["localPath"] as? String ?? ""
    if modelPath.isEmpty {
      result(FlutterError(code: "MODEL_PATH_MISSING", message: "Model localPath is required.", details: nil))
      return
    }

    nativeEngine.loadModel(withId: args["id"] as? String, path: modelPath) { error, _ in
      if let error {
        result(FlutterError(code: "ENGINE_LOAD_FAILED", message: error.localizedDescription, details: nil))
      } else {
        result(nil)
      }
    }
  }

  private func handleBeginTextInference(args: [String: Any], result: @escaping FlutterResult) {
    let requestId = args["requestId"] as? String ?? ""
    let promptMap = args["prompt"] as? [String: Any] ?? [:]
    let promptData = PromptData.from(prompt: promptMap)

    nativeEngine.cancelActiveGeneration()
    clearActiveText(notify: false)

    let generation = activeTextGeneration + 1
    activeTextGeneration = generation
    activeTextRequestId = requestId
    activeTextState = TextStreamState(
      requestId: requestId,
      maxOutputTokens: promptData.maxOutputTokens,
      stopSequences: promptData.stopSequences,
    )

    nativeEngine.generateText(
      withPrompt: promptData.promptText,
      maxOutputTokens: promptData.maxOutputTokens,
      onChunk: { [weak self] chunk in
        self?.handleTextChunk(chunk: chunk, requestId: requestId, generation: generation)
      },
      completion: { [weak self] error in
        self?.handleTextCompletion(error: error, requestId: requestId, generation: generation)
      },
    )

    scheduleStreamTimeout(requestId: requestId, generation: generation)

    result(nil)
  }

  private func handleTextChunk(chunk: String, requestId: String, generation: UInt64) {
    guard isCurrentTextRequest(requestId: requestId, generation: generation),
          let state = activeTextState
    else {
      return
    }

    state.rawText += chunk
    let boundedRaw = applyStopSequences(state.rawText, stopSequences: state.stopSequences)
    let visibleCurrent = sanitizeVisibleText(boundedRaw)
    let progress = computeVisibleProgress(
      previousEffectiveVisible: state.emittedVisible,
      currentVisible: visibleCurrent,
    )

    if progress.madeProgress {
      scheduleStreamTimeout(requestId: requestId, generation: generation)
      state.emittedVisible = progress.effectiveVisible
      if !progress.delta.isEmpty {
        emitChunk(textSink, requestId: requestId, chunk: progress.delta)
      }
    }

    let hitStopSequence = boundedRaw != state.rawText
    let reachedOutputLimit = estimateTokens(progress.effectiveVisible) >= state.maxOutputTokens
    if hitStopSequence || reachedOutputLimit {
      state.completedLocally = true
      nativeEngine.cancelActiveGeneration()
      clearTextIfCurrent(requestId: requestId, generation: generation)
      emitDone(textSink, requestId: requestId)
    }
  }

  private func handleTextCompletion(error: Error?, requestId: String, generation: UInt64) {
    guard isCurrentTextRequest(requestId: requestId, generation: generation) else {
      return
    }

    if let error {
      if error.localizedDescription.contains(cancellationError), activeTextState?.completedLocally == true {
        clearTextIfCurrent(requestId: requestId, generation: generation)
        return
      }
      clearTextIfCurrent(requestId: requestId, generation: generation)
      emitError(textSink, requestId: requestId, error: error.localizedDescription)
      return
    }

    clearTextIfCurrent(requestId: requestId, generation: generation)
    emitDone(textSink, requestId: requestId)
  }

  private func clearActiveText(notify: Bool) {
    let requestId = activeTextRequestId
    activeTextRequestId = nil
    activeTextState = nil
    activeTextGeneration += 1
    cancelStreamTimeout()
    if notify, let requestId, !requestId.isEmpty {
      emitError(textSink, requestId: requestId, error: cancellationError)
    }
  }

  private func clearTextIfCurrent(requestId: String, generation: UInt64) {
    guard isCurrentTextRequest(requestId: requestId, generation: generation) else {
      return
    }
    activeTextRequestId = nil
    activeTextState = nil
    activeTextGeneration += 1
    cancelStreamTimeout()
  }

  private func isCurrentTextRequest(requestId: String, generation: UInt64) -> Bool {
    activeTextRequestId == requestId && activeTextGeneration == generation
  }

  private func scheduleStreamTimeout(requestId: String, generation: UInt64) {
    cancelStreamTimeout()
    let work = DispatchWorkItem { [weak self] in
      guard let self, self.isCurrentTextRequest(requestId: requestId, generation: generation) else {
        return
      }
      self.nativeEngine.cancelActiveGeneration()
      self.clearTextIfCurrent(requestId: requestId, generation: generation)
      self.emitDone(self.textSink, requestId: requestId)
    }
    streamTimeoutTimer = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 60, execute: work)
  }

  private func cancelStreamTimeout() {
    streamTimeoutTimer?.cancel()
    streamTimeoutTimer = nil
  }

  fileprivate func setTextSink(_ sink: FlutterEventSink?) {
    textSink = sink
  }

  fileprivate func setAudioSink(_ sink: FlutterEventSink?) {
    audioSink = sink
  }

  private func emitChunk(_ sink: FlutterEventSink?, requestId: String, chunk: String) {
    guard let sink, !chunk.isEmpty else { return }
    sink([
      "requestId": requestId,
      "chunk": chunk,
      "done": false,
    ])
  }

  private func emitDone(_ sink: FlutterEventSink?, requestId: String) {
    guard let sink else { return }
    sink([
      "requestId": requestId,
      "done": true,
    ])
  }

  private func emitError(_ sink: FlutterEventSink?, requestId: String, error: String) {
    guard let sink else { return }
    sink([
      "requestId": requestId,
      "done": true,
      "error": error,
    ])
  }

  fileprivate func makeImportedPhotoDestination(suggestedName: String) throws -> URL {
    let importsDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("AuraImportedCards", isDirectory: true)
    try FileManager.default.createDirectory(
      at: importsDirectory,
      withIntermediateDirectories: true
    )

    let rawName = suggestedName.trimmingCharacters(in: .whitespacesAndNewlines)
    let fallbackName = rawName.isEmpty ? "character-card.png" : rawName
    let stem = ((fallbackName as NSString).deletingPathExtension)
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let safeStem = stem.isEmpty ? "character-card" : stem
    let targetName = "\(safeStem)-\(UUID().uuidString).png"
    return importsDirectory.appendingPathComponent(targetName, isDirectory: false)
  }

  fileprivate func completePhotoPicker(with value: Any?) {
    DispatchQueue.main.async {
      let result = self.pendingPhotoPickerResult
      self.pendingPhotoPickerResult = nil
      result?(value)
    }
  }

  fileprivate func completePhotoPicker(errorCode: String, message: String) {
    DispatchQueue.main.async {
      let result = self.pendingPhotoPickerResult
      self.pendingPhotoPickerResult = nil
      result?(
        FlutterError(
          code: errorCode,
          message: message,
          details: nil
        )
      )
    }
  }

  private func topViewController() -> UIViewController? {
    let rootController = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }
      .flatMap { $0.windows }
      .first(where: \.isKeyWindow)?
      .rootViewController

    return topViewController(from: rootController)
  }

  private func topViewController(from controller: UIViewController?) -> UIViewController? {
    if let navigation = controller as? UINavigationController {
      return topViewController(from: navigation.visibleViewController)
    }
    if let tabBar = controller as? UITabBarController {
      return topViewController(from: tabBar.selectedViewController)
    }
    if let presented = controller?.presentedViewController {
      return topViewController(from: presented)
    }
    return controller
  }
}

@available(iOS 14.0, *)
private final class PhotoPickerCoordinator: NSObject, PHPickerViewControllerDelegate {
  init(owner: AuraLiteRTBridge, clearRetainedPicker: @escaping () -> Void) {
    self.owner = owner
    self.clearRetainedPicker = clearRetainedPicker
  }

  private weak var owner: AuraLiteRTBridge?
  private let clearRetainedPicker: () -> Void

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)

    guard let owner else {
      clearRetainedPicker()
      return
    }

    guard let selection = results.first else {
      clearRetainedPicker()
      owner.completePhotoPicker(with: nil)
      return
    }

    exportCharacterCardPhoto(from: selection, owner: owner)
  }

  private func exportCharacterCardPhoto(from selection: PHPickerResult, owner: AuraLiteRTBridge) {
    if let assetIdentifier = selection.assetIdentifier,
       exportCharacterCardPhotoFromAsset(assetIdentifier: assetIdentifier, owner: owner) {
      return
    }
    exportCharacterCardPhotoFromProvider(selection.itemProvider, owner: owner)
  }

  @discardableResult
  private func exportCharacterCardPhotoFromAsset(
    assetIdentifier: String,
    owner: AuraLiteRTBridge
  ) -> Bool {
    let fetchResult = PHAsset.fetchAssets(
      withLocalIdentifiers: [assetIdentifier],
      options: nil
    )
    guard let asset = fetchResult.firstObject else {
      return false
    }

    let resources = PHAssetResource.assetResources(for: asset)
    guard let resource = resources.first(where: { resource in
      let pathExtension = (resource.originalFilename as NSString)
        .pathExtension
        .lowercased()
      return resource.uniformTypeIdentifier == UTType.png.identifier || pathExtension == "png"
    }) else {
      clearRetainedPicker()
      owner.completePhotoPicker(
        errorCode: "PHOTO_PICKER_PNG_ONLY",
        message: "photo import expects png"
      )
      return true
    }

    do {
      let destination = try owner.makeImportedPhotoDestination(
        suggestedName: resource.originalFilename
      )
      PHAssetResourceManager.default().writeData(
        for: resource,
        toFile: destination,
        options: nil
      ) { [weak self] error in
        self?.clearRetainedPicker()
        if let error {
          owner.completePhotoPicker(
            errorCode: "PHOTO_PICKER_EXPORT_FAILED",
            message: error.localizedDescription
          )
        } else {
          owner.completePhotoPicker(with: destination.path)
        }
      }
    } catch {
      clearRetainedPicker()
      owner.completePhotoPicker(
        errorCode: "PHOTO_PICKER_EXPORT_FAILED",
        message: error.localizedDescription
      )
    }

    return true
  }

  private func exportCharacterCardPhotoFromProvider(
    _ itemProvider: NSItemProvider,
    owner: AuraLiteRTBridge
  ) {
    guard itemProvider.hasItemConformingToTypeIdentifier(UTType.png.identifier) else {
      clearRetainedPicker()
      owner.completePhotoPicker(
        errorCode: "PHOTO_PICKER_PNG_ONLY",
        message: "photo import expects png"
      )
      return
    }

    itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.png.identifier) { [weak self] url, error in
      guard let self else { return }
      if let error {
        self.clearRetainedPicker()
        owner.completePhotoPicker(
          errorCode: "PHOTO_PICKER_EXPORT_FAILED",
          message: error.localizedDescription
        )
        return
      }
      guard let url else {
        self.clearRetainedPicker()
        owner.completePhotoPicker(
          errorCode: "PHOTO_PICKER_EXPORT_FAILED",
          message: "Aura could not read the selected PNG."
        )
        return
      }

      do {
        let destination = try owner.makeImportedPhotoDestination(
          suggestedName: url.lastPathComponent
        )
        try FileManager.default.copyItem(at: url, to: destination)
        self.clearRetainedPicker()
        owner.completePhotoPicker(with: destination.path)
      } catch {
        self.clearRetainedPicker()
        owner.completePhotoPicker(
          errorCode: "PHOTO_PICKER_EXPORT_FAILED",
          message: error.localizedDescription
        )
      }
    }
  }
}

private final class TextStreamProxy: NSObject, FlutterStreamHandler {
  init(owner: AuraLiteRTBridge) {
    self.owner = owner
  }

  private weak var owner: AuraLiteRTBridge?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    owner?.setTextSink(events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    owner?.setTextSink(nil)
    return nil
  }
}

private final class AudioStreamProxy: NSObject, FlutterStreamHandler {
  init(owner: AuraLiteRTBridge) {
    self.owner = owner
  }

  private weak var owner: AuraLiteRTBridge?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    owner?.setAudioSink(events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    owner?.setAudioSink(nil)
    return nil
  }
}

private final class TextStreamState {
  init(requestId: String, maxOutputTokens: Int, stopSequences: [String]) {
    self.requestId = requestId
    self.maxOutputTokens = max(1, maxOutputTokens)
    self.stopSequences = stopSequences
  }

  let requestId: String
  let maxOutputTokens: Int
  let stopSequences: [String]
  var rawText = ""
  var emittedVisible = ""
  var completedLocally = false
}

private struct PromptData {
  let promptText: String
  let maxOutputTokens: Int
  let stopSequences: [String]

  static func from(prompt: [String: Any]) -> PromptData {
    let systemInstruction = (prompt["systemInstruction"] as? String)?.trimmedNilIfEmpty
    let postHistoryInstructions = (prompt["postHistoryInstructions"] as? String)?.trimmedNilIfEmpty
    let assistantLabel = (prompt["assistantLabel"] as? String)?.trimmedNilIfEmpty ?? "Character"
    let userLabel = (prompt["userLabel"] as? String)?.trimmedNilIfEmpty ?? "You"
    let generation = prompt["generationConfig"] as? [String: Any] ?? [:]
    let messages = ((prompt["messages"] as? [[String: Any]]) ?? [])
      .compactMap { PromptSeed(map: $0) }
      .droppingLeadingDuplicateSystem(systemInstruction)

    return PromptData(
      promptText: buildPromptText(
        systemInstruction: systemInstruction,
        messages: messages,
        postHistoryInstructions: postHistoryInstructions,
        assistantLabel: assistantLabel,
        userLabel: userLabel,
      ),
      maxOutputTokens: (generation["max_output_tokens"] as? NSNumber)?.intValue ?? 512,
      stopSequences: ((generation["stop_sequences"] as? [Any]) ?? [])
        .compactMap { ($0 as? String)?.trimmedNilIfEmpty },
    )
  }

  private static func buildPromptText(
    systemInstruction: String?,
    messages: [PromptSeed],
    postHistoryInstructions: String?,
    assistantLabel: String,
    userLabel: String,
  ) -> String {
    guard !messages.isEmpty else {
      return systemInstruction ?? ""
    }

    let lastMessage = messages.last!
    let history = messages.dropLast()
    var sections: [String] = []

    if let systemInstruction {
      sections.append("Scene rules:\n\(systemInstruction)")
    }

    if !history.isEmpty {
      let transcript = history
        .compactMap { seed -> String? in
          let content = seed.content.trimmingCharacters(in: .whitespacesAndNewlines)
          guard !content.isEmpty else { return nil }
          return "\(seed.displayRole(assistantLabel: assistantLabel, userLabel: userLabel)): \(content)"
        }
        .joined(separator: "\n\n")
      if !transcript.isEmpty {
        sections.append("Roleplay transcript so far:\n\(transcript)")
      }
    }

    if let postHistoryInstructions {
      sections.append("Scene guidance for the next reply:\n\(postHistoryInstructions)")
    }

    if lastMessage.role == "user" && lastMessage.content.trimmingCharacters(in: .whitespacesAndNewlines) == audioInputPlaceholder {
      sections.append(
        "Latest \(userLabel) input arrived as attached audio.\n\n" +
          "Write only \(assistantLabel)'s next in-character reply to that audio while staying consistent with the scene above. " +
          "Do not write \(userLabel)'s dialogue, decisions, thoughts, or actions.")
    } else if lastMessage.role == "user" {
      sections.append(
        "Latest \(userLabel) input:\n\(lastMessage.content.trimmingCharacters(in: .whitespacesAndNewlines))\n\n" +
          "Write only \(assistantLabel)'s next in-character reply. Continue the same scene, stay inside the role, and do not write \(userLabel)'s dialogue, thoughts, choices, or actions.")
    } else {
      sections.append(
        "Write only \(assistantLabel)'s next in-character reply and continue the current scene from the latest context above.")
    }

    return sections.filter { !$0.isEmpty }.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

private struct PromptSeed {
  let role: String
  let content: String

  init?(map: [String: Any]) {
    guard let role = map["role"] as? String else { return nil }
    self.role = role
    self.content = map["content"] as? String ?? ""
  }

  func displayRole(assistantLabel: String, userLabel: String) -> String {
    switch role {
    case "assistant":
      return assistantLabel
    case "system":
      return "Context"
    case "tool":
      return "Tool"
    default:
      return userLabel
    }
  }
}

private struct VisibleProgress {
  let effectiveVisible: String
  let delta: String
  let madeProgress: Bool
}

private func computeVisibleProgress(previousEffectiveVisible: String, currentVisible: String) -> VisibleProgress {
  let effectiveVisible = currentVisible.trimmingTrailingWhitespaceAndNewlines()
  let delta: String
  if effectiveVisible.hasPrefix(previousEffectiveVisible) {
    delta = String(effectiveVisible.dropFirst(previousEffectiveVisible.count))
  } else {
    delta = effectiveVisible
  }
  return VisibleProgress(
    effectiveVisible: effectiveVisible,
    delta: delta,
    madeProgress: effectiveVisible != previousEffectiveVisible,
  )
}

private func applyStopSequences(_ text: String, stopSequences: [String]) -> String {
  guard !stopSequences.isEmpty else { return text }
  var cutIndex = text.endIndex
  for sequence in stopSequences where !sequence.isEmpty {
    if let range = text.range(of: sequence), range.lowerBound < cutIndex {
      cutIndex = range.lowerBound
    }
  }
  return String(text[..<cutIndex])
}

private func sanitizeVisibleText(_ text: String) -> String {
  text.replacingOccurrences(
    of: #"\[[a-zA-Z0-9_-]{2,24}\]"#,
    with: "",
    options: .regularExpression,
  )
}

private func estimateTokens(_ text: String) -> Int {
  max(1, (text.count + 3) / 4)
}

private extension Array where Element == PromptSeed {
  func droppingLeadingDuplicateSystem(_ systemInstruction: String?) -> [PromptSeed] {
    guard let first, first.role == "system", first.content.trimmingCharacters(in: .whitespacesAndNewlines) == systemInstruction?.trimmingCharacters(in: .whitespacesAndNewlines) else {
      return self
    }
    return Array(dropFirst())
  }
}

private extension String {
  var trimmedNilIfEmpty: String? {
    let value = trimmingCharacters(in: .whitespacesAndNewlines)
    return value.isEmpty ? nil : value
  }

  func trimmingTrailingWhitespaceAndNewlines() -> String {
    var value = self
    while let lastScalar = value.unicodeScalars.last,
          CharacterSet.whitespacesAndNewlines.contains(lastScalar) {
      value.removeLast()
    }
    return value
  }
}

private let cancellationError = "AURA_GENERATION_CANCELLED"
private let audioInputPlaceholder = "[audio_input]"
