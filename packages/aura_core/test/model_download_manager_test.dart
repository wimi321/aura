import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

void main() {
  test('registers model while download progresses', () async {
    final MemoryModelCatalogRepository catalog = MemoryModelCatalogRepository();
    final _FakeDownloader downloader = _FakeDownloader();
    final ModelDownloadManager manager = ModelDownloadManager(
      downloader: downloader,
      catalogRepository: catalog,
    );

    const ModelManifest manifest = ModelManifest(
      id: 'gemma-e2b',
      name: 'Gemma 4 E2B',
      version: '1.0.0',
      fileName: 'gemma.litertlm',
      localPath: '/models/gemma.litertlm',
      sizeBytes: 100,
      multimodal: true,
    );

    final List<ModelDownloadSnapshot> snapshots =
        await manager.downloadAndRegister(manifest).toList();
    final ModelManifest? stored = await catalog.getById('gemma-e2b');

    expect(snapshots.last.status, DownloadStatus.completed);
    expect(stored?.id, 'gemma-e2b');
  });
}

class _FakeDownloader implements ModelDownloader {
  @override
  Future<void> cancel(String modelId) async {}

  @override
  Stream<ModelDownloadSnapshot> download(ModelManifest manifest) async* {
    yield ModelDownloadSnapshot(
      model: manifest,
      status: DownloadStatus.downloading,
      receivedBytes: 20,
      totalBytes: 100,
    );
    yield ModelDownloadSnapshot(
      model: manifest,
      status: DownloadStatus.completed,
      receivedBytes: 100,
      totalBytes: 100,
    );
  }
}
