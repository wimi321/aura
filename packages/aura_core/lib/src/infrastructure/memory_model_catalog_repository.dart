import '../application/model_catalog_repository.dart';
import '../domain/model_manifest.dart';

class MemoryModelCatalogRepository implements ModelCatalogRepository {
  final Map<String, ModelManifest> _models = <String, ModelManifest>{};

  @override
  Future<ModelManifest?> getById(String modelId) async {
    return _models[modelId];
  }

  @override
  Future<List<ModelManifest>> listModels() async {
    return _models.values.toList(growable: false);
  }

  @override
  Future<void> remove(String modelId) async {
    _models.remove(modelId);
  }

  @override
  Future<void> upsert(ModelManifest manifest) async {
    _models[manifest.id] = manifest;
  }
}
