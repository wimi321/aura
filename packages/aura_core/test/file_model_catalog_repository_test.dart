import 'dart:io';

import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

void main() {
  test('upserts and reads model manifests', () async {
    final Directory tempDir =
        await Directory.systemTemp.createTemp('aura_model_catalog');
    addTearDown(() => tempDir.delete(recursive: true));

    final FileModelCatalogRepository repository = FileModelCatalogRepository(
      File('${tempDir.path}/models.json'),
    );

    const ModelManifest manifest = ModelManifest(
      id: 'gemma-e4b',
      name: 'Gemma 4 E4B',
      version: '1.0.0',
      fileName: 'gemma_e4b.litertlm',
      localPath: '/models/gemma_e4b.litertlm',
      sizeBytes: 2048,
      multimodal: true,
      remoteUrl: 'https://example.com/gemma_e4b.litertlm',
    );

    await repository.upsert(manifest);
    final List<ModelManifest> models = await repository.listModels();
    final ModelManifest? loaded = await repository.getById('gemma-e4b');

    expect(models.single.id, 'gemma-e4b');
    expect(loaded?.remoteUrl, contains('example.com'));
  });
}
