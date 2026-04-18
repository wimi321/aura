import 'package:meta/meta.dart';

@immutable
class EmotionSignal {
  const EmotionSignal({
    required this.label,
    required this.rawTag,
    required this.offset,
  });

  final String label;
  final String rawTag;
  final int offset;
}
