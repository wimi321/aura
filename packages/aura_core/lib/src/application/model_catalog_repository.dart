import '../domain/model_manifest.dart';

abstract interface class ModelCatalogRepository {
  Future<List<ModelManifest>> listModels();
  Future<ModelManifest?> getById(String modelId);
  Future<void> upsert(ModelManifest manifest);
  Future<void> remove(String modelId);
}
