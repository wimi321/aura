import Foundation
import FlutterMacOS

final class AuraLiteRTBridge: NSObject, FlutterStreamHandler {
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

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(nil)
      return
    }

    switch call.method {
    case "initialize":
      result(nil)
    case "loadModel":
      result(nil)
    case "unloadModel":
      result(nil)
    case "beginTextInference":
      let prompt = args["prompt"] as? [String: Any] ?? [:]
      let reply = makeTextReply(from: prompt)
      emit(chunks: reply, sink: textSink)
      result(nil)
    case "beginAudioInference":
      emit(chunks: ["[calm]I heard your voice clearly. Let's continue."], sink: audioSink)
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

  private func emit(chunks: [String], sink: FlutterEventSink?) {
    guard let sink else { return }
    for (index, chunk) in chunks.enumerated() {
      DispatchQueue.main.asyncAfter(deadline: .now() + (.milliseconds(120 * index))) {
        sink(chunk)
      }
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
