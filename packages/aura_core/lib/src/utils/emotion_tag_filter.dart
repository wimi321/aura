import '../domain/emotion_signal.dart';

final RegExp _emotionTagPattern = RegExp(r'\[([a-zA-Z0-9_-]{2,24})\]');

class EmotionTagFilterResult {
  const EmotionTagFilterResult({
    required this.visibleText,
    required this.emotions,
  });

  final String visibleText;
  final List<EmotionSignal> emotions;
}

class EmotionTagFilter {
  const EmotionTagFilter();

  EmotionTagFilterResult parse(String rawText) {
    final List<EmotionSignal> emotions = <EmotionSignal>[];
    final String visible = rawText.replaceAllMapped(_emotionTagPattern, (Match match) {
      final String? label = match.group(1);
      if (label != null) {
        emotions.add(
          EmotionSignal(
            label: label,
            rawTag: match.group(0)!,
            offset: match.start,
          ),
        );
      }
      return '';
    });

    return EmotionTagFilterResult(
      visibleText: visible,
      emotions: emotions,
    );
  }
}
