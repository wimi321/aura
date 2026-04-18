import 'dart:convert';
import 'dart:io';

import '../application/model_catalog_repository.dart';
import '../domain/model_manifest.dart';

class FileModelCatalogRepository implements ModelCatalogRepository {
  FileModelCatalogRepository(this._file);

  final File _file;

  @override
  Future<ModelManifest?> getById(String modelId) async {
    final List<ModelManifest> models = await listModels();
    for (final ModelManifest model in models) {
      if (model.id == modelId) {
        return model;
      }
    }
    return null;
  }

  @override
  Future<List<ModelManifest>> listModels() async {
    if (!await _file.exists()) {
      return const <ModelManifest>[];
    }
    final Object? decoded = jsonDecode(await _file.readAsString());
    final List<Object?> list = decoded is List<Object?> ? decoded : const <Object?>[];
    return list
        .whereType<Map<Object?, Object?>>()
        .map((Map<Object?, Object?> item) => _fromJson(item.cast<String, Object?>()))
        .toList(growable: false);
  }

  @override
  Future<void> remove(String modelId) async {
    final List<ModelManifest> models = await listModels();
    final List<ModelManifest> retained = models.where((ModelManifest item) => item.id != modelId).toList(growable: false);
    await _write(retained);
  }

  @override
  Future<void> upsert(ModelManifest manifest) async {
    final List<ModelManifest> models = (await listModels()).toList(growable: true);
    final int index = models.indexWhere((ModelManifest item) => item.id == manifest.id);
    if (index >= 0) {
      models[index] = manifest;
    } else {
      models.add(manifest);
    }
    await _write(models);
  }

  Future<void> _write(List<ModelManifest> manifests) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        manifests.map((ModelManifest manifest) => _toJson(manifest)).toList(growable: false),
      ),
    );
  }

  ModelManifest _fromJson(Map<String, Object?> json) {
    return ModelManifest(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      localPath: json['local_path']?.toString() ?? '',
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      multimodal: json['multimodal'] as bool? ?? false,
      remoteUrl: json['remote_url']?.toString(),
      sha256: json['sha256']?.toString(),
      recommendedMinRamGb: (json['recommended_min_ram_gb'] as num?)?.toInt(),
      metadata: (json['metadata'] as Map?)?.cast<String, Object?>() ?? const <String, Object?>{},
    );
  }

  Map<String, Object?> _toJson(ModelManifest manifest) {
    return <String, Object?>{
      'id': manifest.id,
      'name': manifest.name,
      'version': manifest.version,
      'file_name': manifest.fileName,
      'local_path': manifest.localPath,
      'size_bytes': manifest.sizeBytes,
      'multimodal': manifest.multimodal,
      'remote_url': manifest.remoteUrl,
      'sha256': manifest.sha256,
      'recommended_min_ram_gb': manifest.recommendedMinRamGb,
      'metadata': manifest.metadata,
    };
  }
}
