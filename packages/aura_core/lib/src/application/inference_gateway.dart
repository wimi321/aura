import '../domain/chat_models.dart';
import '../domain/inference_runtime_status.dart';
import '../domain/model_manifest.dart';
import '../domain/runtime_options.dart';

abstract interface class InferenceGateway {
  Future<void> initialize({
    required RuntimeOptions options,
  });

  Future<void> loadModel(ModelManifest manifest);

  Future<void> unloadModel();

  Future<InferenceRuntimeStatus> getRuntimeStatus();

  Future<void> cancelActiveGeneration();

  Stream<String> streamText({
    required PromptEnvelope prompt,
  });

  Stream<String> streamAudio({
    required PromptEnvelope prompt,
    required List<List<int>> audioFrames,
  });
}
