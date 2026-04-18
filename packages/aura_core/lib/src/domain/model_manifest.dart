import 'package:meta/meta.dart';

@immutable
class ModelManifest {
  const ModelManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.fileName,
    required this.localPath,
    required this.sizeBytes,
    required this.multimodal,
    this.remoteUrl,
    this.sha256,
    this.recommendedMinRamGb,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String name;
  final String version;
  final String fileName;
  final String localPath;
  final int sizeBytes;
  final bool multimodal;
  final String? remoteUrl;
  final String? sha256;
  final int? recommendedMinRamGb;
  final Map<String, Object?> metadata;

  ModelManifest copyWith({
    String? id,
    String? name,
    String? version,
    String? fileName,
    String? localPath,
    int? sizeBytes,
    bool? multimodal,
    String? remoteUrl,
    String? sha256,
    int? recommendedMinRamGb,
    Map<String, Object?>? metadata,
  }) {
    return ModelManifest(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      multimodal: multimodal ?? this.multimodal,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      sha256: sha256 ?? this.sha256,
      recommendedMinRamGb: recommendedMinRamGb ?? this.recommendedMinRamGb,
      metadata: metadata ?? this.metadata,
    );
  }
}
