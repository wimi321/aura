import 'package:meta/meta.dart';

@immutable
class InferenceRuntimeStatus {
  const InferenceRuntimeStatus({
    required this.runtime,
    required this.primaryBackend,
    required this.audioInputSupported,
    this.loadedModelId,
    this.loadedModelPath,
  });

  final String runtime;
  final String primaryBackend;
  final bool audioInputSupported;
  final String? loadedModelId;
  final String? loadedModelPath;
}
