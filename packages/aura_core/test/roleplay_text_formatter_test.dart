import 'package:aura_core/src/utils/roleplay_text_formatter.dart';
import 'package:test/test.dart';

void main() {
  group('RoleplayTextFormatter', () {
    group('formatCardField', () {
      test('replaces {{char}} with character name', () {
        final String result = RoleplayTextFormatter.formatCardField(
          '{{char}} greets you warmly.',
          characterName: 'Alice',
        );
        expect(result, 'Alice greets you warmly.');
      });

      test('replaces {{user}} with locale-derived alias', () {
        final String result = RoleplayTextFormatter.formatCardField(
          '{{user}} enters the room.',
          characterName: 'Alice',
          localeTag: 'en',
        );
        expect(result, 'you enters the room.');
      });

      test('replaces {{bot}} same as {{char}}', () {
        final String result = RoleplayTextFormatter.formatCardField(
          '{{bot}} smiles.',
          characterName: 'Alice',
        );
        expect(result, 'Alice smiles.');
      });

      test('replaces <BOT> and <USER> tags', () {
        final String result = RoleplayTextFormatter.formatCardField(
          '<BOT> talks to <USER>.',
          characterName: 'Bob',
          localeTag: 'en',
        );
        expect(result, 'Bob talks to you.');
      });

      test('is case-insensitive for macros', () {
        final String result = RoleplayTextFormatter.formatCardField(
          '{{ CHAR }} and {{ User }}',
          characterName: 'Eve',
          localeTag: 'en',
        );
        expect(result, 'Eve and you');
      });

      test('strips hidden blocks', () {
        final String result = RoleplayTextFormatter.formatCardField(
          'Hello<thinking>secret thoughts</thinking> world',
          characterName: 'Alice',
        );
        expect(result, 'Hello world');
      });

      test('strips UpdateVariable blocks', () {
        final String result = RoleplayTextFormatter.formatCardField(
          'Before<UpdateVariable a="1">content</UpdateVariable>After',
          characterName: 'Alice',
        );
        expect(result, 'BeforeAfter');
      });

      test('strips inner_voice blocks', () {
        final String result = RoleplayTextFormatter.formatCardField(
          'Hello<inner_voice>hidden</inner_voice>!',
          characterName: 'Alice',
        );
        expect(result, 'Hello!');
      });

      test('strips wrapper tags like gametxt', () {
        final String result = RoleplayTextFormatter.formatCardField(
          '<gametxt>Story text here</gametxt>',
          characterName: 'Alice',
        );
        expect(result, 'Story text here');
      });

      test('strips scene/chapter tags', () {
        final String result = RoleplayTextFormatter.formatCardField(
          '<scene>Inside<chapter>1</chapter></scene>',
          characterName: 'Alice',
        );
        expect(result, 'Inside1');
      });

      test('preserves {{original}} macro when requested', () {
        final String result = RoleplayTextFormatter.formatCardField(
          '{{original}} then {{char}} says hello',
          characterName: 'Alice',
          preserveOriginalMacro: true,
        );
        expect(result, contains('{{original}}'));
        expect(result, contains('Alice'));
      });

      test('returns empty string for whitespace-only input', () {
        final String result = RoleplayTextFormatter.formatCardField(
          '   ',
          characterName: 'Alice',
        );
        expect(result, '');
      });

      test('normalizes CRLF to LF', () {
        final String result = RoleplayTextFormatter.formatCardField(
          'line1\r\nline2\rline3',
          characterName: 'Alice',
        );
        expect(result, 'line1\nline2\nline3');
      });
    });

    group('sanitizeModelOutput', () {
      test('trims leading character name speaker label', () {
        final String result = RoleplayTextFormatter.sanitizeModelOutput(
          'Alice: Hello there!',
          characterName: 'Alice',
        );
        expect(result, 'Hello there!');
      });

      test('returns empty when output starts with user turn', () {
        final String result = RoleplayTextFormatter.sanitizeModelOutput(
          'you: I said something',
          characterName: 'Alice',
          localeTag: 'en',
        );
        expect(result, '');
      });

      test('cuts leaked user turn after newline', () {
        final String result = RoleplayTextFormatter.sanitizeModelOutput(
          'Alice says hello.\nyou: But then I replied.',
          characterName: 'Alice',
          localeTag: 'en',
        );
        expect(result, 'Alice says hello.');
      });

      test('trims result', () {
        final String result = RoleplayTextFormatter.sanitizeModelOutput(
          '  Hello  ',
          characterName: 'Alice',
        );
        expect(result, 'Hello');
      });

      test('collapses triple newlines', () {
        final String result = RoleplayTextFormatter.sanitizeModelOutput(
          'Hello\n\n\n\nWorld',
          characterName: 'Alice',
        );
        expect(result, 'Hello\n\nWorld');
      });
    });

    group('sanitizeStreamDelta', () {
      test('trims leading character name', () {
        final String result = RoleplayTextFormatter.sanitizeStreamDelta(
          'Alice: Hello',
          characterName: 'Alice',
        );
        expect(result, 'Hello');
      });

      test('does not trim trailing whitespace (preserves stream state)', () {
        final String result = RoleplayTextFormatter.sanitizeStreamDelta(
          'Hello ',
          characterName: 'Alice',
        );
        expect(result, 'Hello ');
      });
    });

    group('defaultUserAlias', () {
      test('returns you for English', () {
        expect(
          RoleplayTextFormatter.defaultUserAlias(localeTag: 'en'),
          'you',
        );
      });

      test('returns 你 for Chinese', () {
        expect(
          RoleplayTextFormatter.defaultUserAlias(localeTag: 'zh'),
          '你',
        );
        expect(
          RoleplayTextFormatter.defaultUserAlias(localeTag: 'zh-CN'),
          '你',
        );
      });

      test('returns あなた for Japanese', () {
        expect(
          RoleplayTextFormatter.defaultUserAlias(localeTag: 'ja'),
          'あなた',
        );
      });

      test('returns 당신 for Korean', () {
        expect(
          RoleplayTextFormatter.defaultUserAlias(localeTag: 'ko'),
          '당신',
        );
      });

      test('detects Japanese from sample text when no locale', () {
        expect(
          RoleplayTextFormatter.defaultUserAlias(sampleText: 'こんにちは'),
          'あなた',
        );
      });

      test('detects Korean from sample text when no locale', () {
        expect(
          RoleplayTextFormatter.defaultUserAlias(sampleText: '안녕하세요'),
          '당신',
        );
      });

      test('detects Chinese from sample text when no locale', () {
        expect(
          RoleplayTextFormatter.defaultUserAlias(sampleText: '你好世界'),
          '你',
        );
      });

      test('defaults to you when no locale and no CJK text', () {
        expect(
          RoleplayTextFormatter.defaultUserAlias(sampleText: 'hello'),
          'you',
        );
        expect(
          RoleplayTextFormatter.defaultUserAlias(),
          'you',
        );
      });
    });

    group('honorific cleanup', () {
      test('strips CJK honorifics after user alias', () {
        final String result = RoleplayTextFormatter.sanitizeModelOutput(
          'Hello you様 and youさん',
          characterName: 'Alice',
          userAlias: 'you',
          localeTag: 'en',
        );
        expect(result, contains('様'));
        expect(result, contains('さん'));
        expect(result, isNot(contains('you様')));
        expect(result, isNot(contains('youさん')));
      });
    });

    group('regex scripts', () {
      test('applies regex script to model output', () {
        final String result = RoleplayTextFormatter.sanitizeModelOutput(
          'Hello *bold* world',
          characterName: 'Alice',
          extensions: <String, Object?>{
            'regex_scripts': <Map<String, Object?>>[
              <String, Object?>{
                'findRegex': r'\*([^*]+)\*',
                'replaceString': r'$1',
                'placement': <int>[2],
                'substituteRegex': 0,
              },
            ],
          },
        );
        expect(result, 'Hello bold world');
      });

      test('skips disabled regex scripts', () {
        final String result = RoleplayTextFormatter.sanitizeModelOutput(
          'Hello *bold* world',
          characterName: 'Alice',
          extensions: <String, Object?>{
            'regex_scripts': <Map<String, Object?>>[
              <String, Object?>{
                'findRegex': r'\*([^*]+)\*',
                'replaceString': r'$1',
                'placement': <int>[2],
                'substituteRegex': 0,
                'disabled': true,
              },
            ],
          },
        );
        expect(result, 'Hello *bold* world');
      });

      test('handles regex literal with flags', () {
        final String result = RoleplayTextFormatter.sanitizeModelOutput(
          'Hello WORLD',
          characterName: 'Alice',
          extensions: <String, Object?>{
            'regex_scripts': <Map<String, Object?>>[
              <String, Object?>{
                'findRegex': '/world/i',
                'replaceString': 'earth',
                'placement': <int>[2],
                'substituteRegex': 0,
              },
            ],
          },
        );
        expect(result, 'Hello earth');
      });
    });
  });
}
