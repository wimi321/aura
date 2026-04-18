import 'package:meta/meta.dart';

@immutable
class ExpressionLayer {
  const ExpressionLayer({
    required this.label,
    required this.assetName,
    required this.bytes,
  });

  final String label;
  final String assetName;
  final List<int> bytes;
}

@immutable
class ExpressionPack {
  const ExpressionPack({
    required this.id,
    required this.layers,
    this.coverAssetName,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final List<ExpressionLayer> layers;
  final String? coverAssetName;
  final Map<String, Object?> metadata;
}
