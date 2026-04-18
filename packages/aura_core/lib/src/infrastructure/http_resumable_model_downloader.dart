import 'dart:io';

import 'package:crypto/crypto.dart';

import '../application/model_downloader.dart';
import '../domain/download_models.dart';
import '../domain/model_manifest.dart';

class HttpResumableModelDownloader implements ModelDownloader {
  HttpResumableModelDownloader({
    HttpClient? client,
    Directory? tempDirectory,
  })  : _client = client ?? HttpClient(),
        _tempDirectory = tempDirectory ?? Directory.systemTemp;

  final HttpClient _client;
  final Directory _tempDirectory;
  final Map<String, HttpClientRequest> _activeRequests = <String, HttpClientRequest>{};

  @override
  Future<void> cancel(String modelId) async {
    final HttpClientRequest? request = _activeRequests.remove(modelId);
    request?.abort();
  }

  @override
  Stream<ModelDownloadSnapshot> download(ModelManifest manifest) async* {
    final Uri uri = Uri.parse(manifest.remoteUrl ?? '');
    if (uri.host.isEmpty) {
      throw StateError('Model ${manifest.id} does not define a remoteUrl.');
    }

    await _tempDirectory.create(recursive: true);
    final File partialFile = File('${_tempDirectory.path}/${manifest.fileName}.part');
    final int existingBytes = await partialFile.exists() ? await partialFile.length() : 0;

    yield ModelDownloadSnapshot(
      model: manifest,
      status: DownloadStatus.queued,
      receivedBytes: existingBytes,
      totalBytes: manifest.sizeBytes,
    );

    final HttpClientRequest request = await _client.getUrl(uri);
    _activeRequests[manifest.id] = request;
    if (existingBytes > 0) {
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=$existingBytes-');
    }

    final HttpClientResponse response = await request.close();
    if (response.statusCode != HttpStatus.ok && response.statusCode != HttpStatus.partialContent) {
      throw HttpException('Unexpected status ${response.statusCode} for ${manifest.remoteUrl}', uri: uri);
    }

    final IOSink sink = partialFile.openWrite(mode: existingBytes > 0 ? FileMode.append : FileMode.writeOnly);
    int receivedBytes = existingBytes;
    final int totalBytes = _resolveTotalBytes(response, fallback: manifest.sizeBytes, existingBytes: existingBytes);

    yield ModelDownloadSnapshot(
      model: manifest,
      status: DownloadStatus.downloading,
      receivedBytes: receivedBytes,
      totalBytes: totalBytes,
    );

    try {
      await for (final List<int> chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        yield ModelDownloadSnapshot(
          model: manifest,
          status: DownloadStatus.downloading,
          receivedBytes: receivedBytes,
          totalBytes: totalBytes,
        );
      }
      await sink.flush();
      await sink.close();
      _activeRequests.remove(manifest.id);

      final File finalFile = File(manifest.localPath);
      await finalFile.parent.create(recursive: true);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await partialFile.rename(finalFile.path);
      await _verifyChecksumIfPresent(finalFile, manifest);

      yield ModelDownloadSnapshot(
        model: manifest,
        status: DownloadStatus.completed,
        receivedBytes: receivedBytes,
        totalBytes: totalBytes,
      );
    } catch (error) {
      await sink.close();
      _activeRequests.remove(manifest.id);
      yield ModelDownloadSnapshot(
        model: manifest,
        status: DownloadStatus.failed,
        receivedBytes: receivedBytes,
        totalBytes: totalBytes,
        errorMessage: error.toString(),
      );
      rethrow;
    }
  }

  int _resolveTotalBytes(
    HttpClientResponse response, {
    required int fallback,
    required int existingBytes,
  }) {
    final String? contentRange = response.headers.value(HttpHeaders.contentRangeHeader);
    if (contentRange != null) {
      final RegExpMatch? match = RegExp(r'bytes\s+\d+-\d+/(\d+)').firstMatch(contentRange);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '') ?? fallback;
      }
    }
    final int length = response.contentLength;
    if (length > 0) {
      return response.statusCode == HttpStatus.partialContent ? existingBytes + length : length;
    }
    return fallback;
  }

  Future<void> _verifyChecksumIfPresent(File file, ModelManifest manifest) async {
    final String? expectedSha256 = manifest.sha256;
    if (expectedSha256 == null || expectedSha256.isEmpty) {
      return;
    }

    final Digest digest = await sha256.bind(file.openRead()).first;
    final String actual = digest.toString();
    if (actual != expectedSha256.toLowerCase()) {
      await file.delete();
      throw StateError(
        'SHA-256 mismatch for ${manifest.fileName}. Expected $expectedSha256, got $actual.',
      );
    }
  }
}
