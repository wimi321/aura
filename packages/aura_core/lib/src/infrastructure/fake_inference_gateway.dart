import '../application/inference_gateway.dart';
import '../domain/chat_models.dart';
import '../domain/inference_runtime_status.dart';
import '../domain/model_manifest.dart';
import '../domain/runtime_options.dart';

class FakeInferenceGateway implements InferenceGateway {
  FakeInferenceGateway({
    List<String> scriptedTextChunks = const <String>['[joy]Hello', ' there'],
    List<String> scriptedAudioChunks = const <String>[
      '[calm]I heard you clearly.'
    ],
  })  : _scriptedTextChunks = scriptedTextChunks,
        _scriptedAudioChunks = scriptedAudioChunks;

  final List<String> _scriptedTextChunks;
  final List<String> _scriptedAudioChunks;

  RuntimeOptions? initializedOptions;
  ModelManifest? loadedModel;

  @override
  Future<void> initialize({required RuntimeOptions options}) async {
    initializedOptions = options;
  }

  @override
  Future<void> loadModel(ModelManifest manifest) async {
    loadedModel = manifest;
  }

  @override
  Future<InferenceRuntimeStatus> getRuntimeStatus() async {
    return InferenceRuntimeStatus(
      runtime: 'fake',
      primaryBackend: initializedOptions?.primaryDelegate.name ?? 'cpu',
      audioInputSupported: false,
      loadedModelId: loadedModel?.id,
      loadedModelPath: loadedModel?.localPath,
    );
  }

  @override
  Future<void> cancelActiveGeneration() async {}

  @override
  Stream<String> streamAudio(
      {required PromptEnvelope prompt,
      required List<List<int>> audioFrames}) async* {
    for (final String chunk in _scriptedAudioChunks) {
      yield chunk;
    }
  }

  @override
  Stream<String> streamText({required PromptEnvelope prompt}) async* {
    for (final String chunk in _scriptedTextChunks) {
      yield chunk;
    }
  }

  @override
  Future<void> unloadModel() async {
    loadedModel = null;
  }
}
