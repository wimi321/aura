import 'dart:async';

import 'package:aura_core/aura_core.dart';
import 'package:flutter/services.dart';

class LiteRtMethodChannelGateway implements InferenceGateway {
  static const String _cancellationError = 'AURA_GENERATION_CANCELLED';

  LiteRtMethodChannelGateway({
    MethodChannel? methodChannel,
    EventChannel? textStreamChannel,
    EventChannel? audioStreamChannel,
  })  : _methodChannel = methodChannel ?? const MethodChannel('aura/litert'),
        _textStreamChannel =
            textStreamChannel ?? const EventChannel('aura/litert/text_stream'),
        _audioStreamChannel = audioStreamChannel ??
            const EventChannel('aura/litert/audio_stream') {
    _textRouter = _EventStreamRouter(
      channel: _textStreamChannel,
      cancellationError: _cancellationError,
    );
    _audioRouter = _EventStreamRouter(
      channel: _audioStreamChannel,
      cancellationError: _cancellationError,
    );
  }

  final MethodChannel _methodChannel;
  final EventChannel _textStreamChannel;
  final EventChannel _audioStreamChannel;
  late final _EventStreamRouter _textRouter;
  late final _EventStreamRouter _audioRouter;

  @override
  Future<void> initialize({required RuntimeOptions options}) {
    return _methodChannel.invokeMethod<void>('initialize', <String, Object?>{
      'primaryDelegate': options.primaryDelegate.name,
      'fallbackDelegates': options.fallbackDelegates
          .map((HardwareDelegate item) => item.name)
          .toList(growable: false),
      'maxContextTokensOverride': options.maxContextTokensOverride,
      'enableAudioUnderstanding': options.enableAudioUnderstanding,
    });
  }

  @override
  Future<void> loadModel(ModelManifest manifest) {
    return _methodChannel.invokeMethod<void>('loadModel', <String, Object?>{
      'id': manifest.id,
      'name': manifest.name,
      'version': manifest.version,
      'fileName': manifest.fileName,
      'localPath': manifest.localPath,
      'sizeBytes': manifest.sizeBytes,
      'multimodal': manifest.multimodal,
      'remoteUrl': manifest.remoteUrl,
      'sha256': manifest.sha256,
      'recommendedMinRamGb': manifest.recommendedMinRamGb,
      'metadata': manifest.metadata,
    });
  }

  @override
  Stream<String> streamAudio(
      {required PromptEnvelope prompt, required List<List<int>> audioFrames}) {
    return _audioRouter.openRequest(
      invoke: (String requestId) => _methodChannel.invokeMethod<void>(
        'beginAudioInference',
        <String, Object?>{
          'requestId': requestId,
          'prompt': _promptToMap(prompt),
          'audioFrames': audioFrames,
        },
      ),
    );
  }

  @override
  Stream<String> streamText({required PromptEnvelope prompt}) {
    return _textRouter.openRequest(
      invoke: (String requestId) => _methodChannel.invokeMethod<void>(
        'beginTextInference',
        <String, Object?>{
          'requestId': requestId,
          'prompt': _promptToMap(prompt),
        },
      ),
    );
  }

  @override
  Future<void> unloadModel() {
    return _methodChannel.invokeMethod<void>('unloadModel');
  }

  @override
  Future<InferenceRuntimeStatus> getRuntimeStatus() async {
    final Map<Object?, Object?> payload = (await _methodChannel
            .invokeMethod<Map<Object?, Object?>>('getRuntimeStatus')) ??
        const <Object?, Object?>{};
    return InferenceRuntimeStatus(
      runtime: payload['runtime']?.toString() ?? 'litert-lm',
      primaryBackend: payload['primaryBackend']?.toString() ?? 'unknown',
      audioInputSupported: payload['audioInputSupported'] == true,
      loadedModelId: payload['loadedModelId']?.toString(),
      loadedModelPath: payload['loadedModelPath']?.toString(),
    );
  }

  @override
  Future<void> cancelActiveGeneration() {
    return _methodChannel.invokeMethod<void>('cancelActiveInference');
  }

  Map<String, Object?> _promptToMap(PromptEnvelope prompt) {
    return <String, Object?>{
      'systemInstruction': prompt.systemInstruction,
      'postHistoryInstructions': prompt.postHistoryInstructions,
      'generationConfig': prompt.generationConfig.toJson(),
      'assistantLabel': prompt.assistantLabel,
      'userLabel': prompt.userLabel,
      'triggeredLore': prompt.triggeredLore,
      'messages': prompt.messages
          .map((ChatMessage message) => message.toJson())
          .toList(growable: false),
    };
  }
}

class _EventStreamRouter {
  _EventStreamRouter({
    required EventChannel channel,
    required String cancellationError,
  })  : _channel = channel,
        _cancellationError = cancellationError;

  final EventChannel _channel;
  final String _cancellationError;
  final Map<String, StreamController<String>> _requests =
      <String, StreamController<String>>{};
  StreamSubscription<dynamic>? _subscription;

  Stream<String> openRequest({
    required Future<void> Function(String requestId) invoke,
  }) {
    _ensureListening();
    final String requestId = DateTime.now().microsecondsSinceEpoch.toString();
    final StreamController<String> controller = StreamController<String>();
    _requests[requestId] = controller;

    controller.onCancel = () async {
      _requests.remove(requestId);
      if (!controller.isClosed) {
        await controller.close();
      }
    };

    Future<void>(() async {
      try {
        await invoke(requestId);
      } catch (error, stackTrace) {
        await _terminateRequest(
          requestId,
          error: error,
          stackTrace: stackTrace,
        );
      }
    });

    return controller.stream;
  }

  void _ensureListening() {
    _subscription ??= _channel.receiveBroadcastStream().listen(
      _handleEvent,
      onError: (Object error, StackTrace stackTrace) {
        unawaited(_terminateAll(error: error, stackTrace: stackTrace));
      },
    );
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) {
      return;
    }
    final Map<Object?, Object?> payload = event.cast<Object?, Object?>();
    final String requestId = payload['requestId']?.toString() ?? '';
    if (requestId.isEmpty) {
      return;
    }
    final StreamController<String>? controller = _requests[requestId];
    if (controller == null) {
      return;
    }

    final bool isDone = payload['done'] == true;
    final String? error = payload['error']?.toString();
    final String? chunk = payload['chunk']?.toString();

    if (error != null && error.isNotEmpty) {
      unawaited(
        _terminateRequest(
          requestId,
          error: error.contains(_cancellationError) ? null : StateError(error),
        ),
      );
      return;
    }

    if (chunk != null && chunk.isNotEmpty && !controller.isClosed) {
      controller.add(chunk);
    }

    if (isDone) {
      unawaited(_terminateRequest(requestId));
    }
  }

  Future<void> _terminateAll({
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final List<String> requestIds = _requests.keys.toList(growable: false);
    for (final String requestId in requestIds) {
      await _terminateRequest(
        requestId,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _terminateRequest(
    String requestId, {
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final StreamController<String>? controller = _requests.remove(requestId);
    if (controller == null) {
      return;
    }
    if (error != null && controller.hasListener && !controller.isClosed) {
      controller.addError(error, stackTrace);
    }
    if (!controller.isClosed) {
      await controller.close();
    }
  }
}
