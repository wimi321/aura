import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../domain/expression_pack.dart';

class ZipExpressionPackParser {
  const ZipExpressionPackParser();

  ExpressionPack parseBytes(Uint8List bytes, {String packId = 'expression-pack'}) {
    final Archive archive = ZipDecoder().decodeBytes(bytes);
    final List<ExpressionLayer> layers = <ExpressionLayer>[];
    String? coverAssetName;
    Map<String, Object?> metadata = const <String, Object?>{};

    for (final ArchiveFile file in archive.files) {
      if (!file.isFile) {
        continue;
      }
      final String normalizedName = file.name.toLowerCase();
      if (_isImageAsset(normalizedName)) {
        final List<int> content = _asBytes(file.content);
        final String label = _deriveLabel(file.name);
        layers.add(
          ExpressionLayer(
            label: label,
            assetName: file.name,
            bytes: content,
          ),
        );
        if (coverAssetName == null && (label == 'neutral' || label == 'default')) {
          coverAssetName = file.name;
        }
      } else if (normalizedName.endsWith('manifest.json') || normalizedName.endsWith('metadata.json')) {
        final String raw = utf8.decode(_asBytes(file.content));
        final Object? decoded = jsonDecode(raw);
        if (decoded is Map<String, Object?>) {
          metadata = decoded;
        } else if (decoded is Map) {
          metadata = decoded.cast<String, Object?>();
        }
      }
    }

    layers.sort((ExpressionLayer a, ExpressionLayer b) => a.label.compareTo(b.label));

    return ExpressionPack(
      id: packId,
      layers: layers,
      coverAssetName: coverAssetName ?? (layers.isEmpty ? null : layers.first.assetName),
      metadata: metadata,
    );
  }

  bool _isImageAsset(String fileName) {
    return fileName.endsWith('.png') ||
        fileName.endsWith('.webp') ||
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg');
  }

  String _deriveLabel(String fileName) {
    final String baseName = fileName.split('/').last.split('.').first.trim().toLowerCase();
    if (baseName.isEmpty) {
      return 'default';
    }
    if (baseName.contains('neutral') || baseName.contains('default')) {
      return 'neutral';
    }
    if (baseName.contains('joy') || baseName.contains('happy') || baseName.contains('smile')) {
      return 'joy';
    }
    if (baseName.contains('blush') || baseName.contains('shy')) {
      return 'blush';
    }
    if (baseName.contains('angry') || baseName.contains('mad')) {
      return 'angry';
    }
    if (baseName.contains('sad') || baseName.contains('cry')) {
      return 'sad';
    }
    return baseName.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
  }

  List<int> _asBytes(Object content) {
    if (content is Uint8List) {
      return content.toList(growable: false);
    }
    if (content is List<int>) {
      return List<int>.from(content);
    }
    throw FormatException('Unsupported ZIP entry content type: ${content.runtimeType}');
  }
}
