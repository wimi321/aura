import 'dart:io';

import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

void main() {
  group('HttpResumableModelDownloader', () {
    late Directory tempDir;
    late HttpServer server;
    late List<String> requestPaths;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('aura_downloader_test');
      requestPaths = <String>[];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        requestPaths.add(request.uri.path);
        if (request.uri.path == '/primary') {
          request.response.statusCode = HttpStatus.serviceUnavailable;
          await request.response.close();
          return;
        }
        if (request.uri.path == '/mirror') {
          final List<int> bytes = <int>[1, 2, 3, 4, 5];
          request.response.statusCode = HttpStatus.ok;
          request.response.contentLength = bytes.length;
          request.response.add(bytes);
          await request.response.close();
          return;
        }
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Uri serverUri(String path) => Uri(
          scheme: 'http',
          host: InternetAddress.loopbackIPv4.address,
          port: server.port,
          path: path,
        );

    test('falls back to the next URL when the primary download fails',
        () async {
      final File targetFile = File('${tempDir.path}/models/model.bin');
      final HttpResumableModelDownloader downloader =
          HttpResumableModelDownloader(
        tempDirectory: Directory('${tempDir.path}/partials'),
        urlFallbackBuilder: (Uri primary) => <Uri>[
          primary,
          serverUri('/mirror'),
        ],
      );
      final ModelManifest manifest = ModelManifest(
        id: 'model',
        name: 'Model',
        version: '1',
        fileName: 'model.bin',
        localPath: targetFile.path,
        sizeBytes: 5,
        multimodal: false,
        remoteUrl: serverUri('/primary').toString(),
      );

      final List<ModelDownloadSnapshot> snapshots =
          await downloader.download(manifest).toList();

      expect(requestPaths, <String>['/primary', '/mirror']);
      expect(snapshots.first.status, DownloadStatus.queued);
      expect(snapshots.last.status, DownloadStatus.completed);
      expect(await targetFile.readAsBytes(), <int>[1, 2, 3, 4, 5]);
    });
  });
}
