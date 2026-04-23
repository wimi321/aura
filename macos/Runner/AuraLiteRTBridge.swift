import Foundation
import FlutterMacOS

final class AuraLiteRTBridge: NSObject {
  private let methodChannelName = "aura/litert"
  private let textStreamChannelName = "aura/litert/text_stream"
  private let audioStreamChannelName = "aura/litert/audio_stream"

  private var textSink: FlutterEventSink?
  private var audioSink: FlutterEventSink?

  func register(with messenger: FlutterBinaryMessenger) {
    let methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: messenger)
    methodChannel.setMethodCallHandler(handle)

    let textStream = FlutterEventChannel(name: textStreamChannelName, binaryMessenger: messenger)
    textStream.setStreamHandler(TextStreamProxy(owner: self))

    let audioStream = FlutterEventChannel(name: audioStreamChannelName, binaryMessenger: messenger)
    audioStream.setStreamHandler(AudioStreamProxy(owner: self))
  }

  private var isLoaded = false
  private var activeTextRequestId: String?

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]

    switch call.method {
    case "initialize":
      result(nil)
    case "loadModel":
      isLoaded = true
      result(nil)
    case "unloadModel":
      isLoaded = false
      activeTextRequestId = nil
      result(nil)
    case "getRuntimeStatus":
      result([
        "engineLoaded": isLoaded,
        "audioInputSupported": false,
      ])
    case "cancelActiveInference":
      activeTextRequestId = nil
      result(nil)
    case "beginTextInference":
      let requestId = args["requestId"] as? String ?? ""
      let prompt = args["prompt"] as? [String: Any] ?? [:]
      let reply = makeTextReply(from: prompt)
      activeTextRequestId = requestId
      emit(chunks: reply, sink: textSink, requestId: requestId)
      result(nil)
    case "beginAudioInference":
      let requestId = args["requestId"] as? String ?? ""
      emit(chunks: ["[calm]I heard your voice clearly. Let's continue."], sink: audioSink, requestId: requestId)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func makeTextReply(from prompt: [String: Any]) -> [String] {
    let messages = prompt["messages"] as? [[String: Any]] ?? []
    let lastUser = messages.reversed().first(where: { ($0["role"] as? String) == "user" })
    let raw = (lastUser?["content"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let visible = raw.isEmpty ? "Hello. I'm ready." : raw
    return ["[joy]", "You said: ", visible]
  }

  private func emit(chunks: [String], sink: FlutterEventSink?, requestId: String) {
    guard let sink else { return }
    for (index, chunk) in chunks.enumerated() {
      DispatchQueue.main.asyncAfter(deadline: .now() + (.milliseconds(120 * index))) { [weak self] in
        guard self?.activeTextRequestId == requestId else { return }
        sink([
          "requestId": requestId,
          "chunk": chunk,
          "done": false,
        ])
      }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + (.milliseconds(120 * chunks.count))) { [weak self] in
      guard self?.activeTextRequestId == requestId else { return }
      self?.activeTextRequestId = nil
      sink([
        "requestId": requestId,
        "done": true,
      ])
    }
  }

  fileprivate func setTextSink(_ sink: FlutterEventSink?) {
    textSink = sink
  }

  fileprivate func setAudioSink(_ sink: FlutterEventSink?) {
    audioSink = sink
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
