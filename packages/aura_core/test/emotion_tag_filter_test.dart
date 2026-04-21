import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

void main() {
  const EmotionTagFilter filter = EmotionTagFilter();

  group('EmotionTagFilter', () {
    test('returns empty result for empty string', () {
      final EmotionTagFilterResult result = filter.parse('');
      expect(result.visibleText, '');
      expect(result.emotions, isEmpty);
    });

    test('returns text unchanged when no tags present', () {
      final EmotionTagFilterResult result = filter.parse('Hello world');
      expect(result.visibleText, 'Hello world');
      expect(result.emotions, isEmpty);
    });

    test('extracts single tag at start', () {
      final EmotionTagFilterResult result = filter.parse('[joy]Hello');
      expect(result.visibleText, 'Hello');
      expect(result.emotions, hasLength(1));
      expect(result.emotions[0].label, 'joy');
      expect(result.emotions[0].rawTag, '[joy]');
      expect(result.emotions[0].offset, 0);
    });

    test('extracts single tag at end', () {
      final EmotionTagFilterResult result = filter.parse('Hello[sad]');
      expect(result.visibleText, 'Hello');
      expect(result.emotions, hasLength(1));
      expect(result.emotions[0].label, 'sad');
    });

    test('extracts multiple tags', () {
      final EmotionTagFilterResult result =
          filter.parse('[joy]Hello [blush]world[angry]');
      expect(result.visibleText, 'Hello world');
      expect(result.emotions, hasLength(3));
      expect(result.emotions.map((EmotionSignal e) => e.label).toList(),
          <String>['joy', 'blush', 'angry']);
    });

    test('respects minimum label length of 2', () {
      final EmotionTagFilterResult result = filter.parse('[a]Hello');
      expect(result.visibleText, '[a]Hello');
      expect(result.emotions, isEmpty);
    });

    test('respects maximum label length of 24', () {
      final String longLabel = 'a' * 25;
      final EmotionTagFilterResult result = filter.parse('[$longLabel]Hello');
      expect(result.visibleText, '[$longLabel]Hello');
      expect(result.emotions, isEmpty);
    });

    test('accepts labels with underscores and hyphens', () {
      final EmotionTagFilterResult result =
          filter.parse('[happy_face]text[oh-no]');
      expect(result.emotions, hasLength(2));
      expect(result.emotions[0].label, 'happy_face');
      expect(result.emotions[1].label, 'oh-no');
    });

    test('accepts labels with digits', () {
      final EmotionTagFilterResult result = filter.parse('[emotion01]text');
      expect(result.emotions, hasLength(1));
      expect(result.emotions[0].label, 'emotion01');
    });

    test('rejects labels with spaces', () {
      final EmotionTagFilterResult result = filter.parse('[not valid]text');
      expect(result.visibleText, '[not valid]text');
      expect(result.emotions, isEmpty);
    });

    test('rejects labels with special characters', () {
      final EmotionTagFilterResult result = filter.parse('[no!way]text');
      expect(result.visibleText, '[no!way]text');
      expect(result.emotions, isEmpty);
    });

    test('handles tag as only content', () {
      final EmotionTagFilterResult result = filter.parse('[neutral]');
      expect(result.visibleText, '');
      expect(result.emotions, hasLength(1));
      expect(result.emotions[0].label, 'neutral');
    });

    test('exactly 2-char label works', () {
      final EmotionTagFilterResult result = filter.parse('[ok]text');
      expect(result.emotions, hasLength(1));
      expect(result.emotions[0].label, 'ok');
    });

    test('exactly 24-char label works', () {
      final String label24 = 'a' * 24;
      final EmotionTagFilterResult result = filter.parse('[$label24]text');
      expect(result.emotions, hasLength(1));
      expect(result.emotions[0].label, label24);
    });
  });
}
