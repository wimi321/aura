import '../domain/download_models.dart';
import '../domain/model_manifest.dart';

abstract interface class ModelDownloader {
  Stream<ModelDownloadSnapshot> download(ModelManifest manifest);
  Future<void> cancel(String modelId);
}
