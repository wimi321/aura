import '../domain/download_models.dart';
import '../domain/model_manifest.dart';
import 'model_catalog_repository.dart';
import 'model_downloader.dart';

class ModelDownloadManager {
  ModelDownloadManager({
    required ModelDownloader downloader,
    required ModelCatalogRepository catalogRepository,
  })  : _downloader = downloader,
        _catalogRepository = catalogRepository;

  final ModelDownloader _downloader;
  final ModelCatalogRepository _catalogRepository;

  Stream<ModelDownloadSnapshot> downloadAndRegister(ModelManifest manifest) async* {
    await _catalogRepository.upsert(manifest);
    await for (final ModelDownloadSnapshot snapshot in _downloader.download(manifest)) {
      if (snapshot.status == DownloadStatus.completed) {
        await _catalogRepository.upsert(snapshot.model);
      }
      yield snapshot;
    }
  }

  Future<void> cancel(String modelId) {
    return _downloader.cancel(modelId);
  }
}
