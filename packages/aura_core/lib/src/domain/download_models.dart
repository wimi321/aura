import 'package:meta/meta.dart';

import 'model_manifest.dart';

enum DownloadStatus {
  idle,
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled
}

@immutable
class ModelDownloadSnapshot {
  const ModelDownloadSnapshot({
    required this.model,
    required this.status,
    required this.receivedBytes,
    required this.totalBytes,
    this.errorMessage,
  });

  final ModelManifest model;
  final DownloadStatus status;
  final int receivedBytes;
  final int totalBytes;
  final String? errorMessage;

  double get progress {
    if (totalBytes <= 0) {
      return 0;
    }
    return receivedBytes / totalBytes;
  }
}
