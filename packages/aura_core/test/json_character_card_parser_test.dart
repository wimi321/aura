import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

void main() {
  test('parses V2 JSON character cards with embedded character_book', () {
    const JsonCharacterCardParser parser = JsonCharacterCardParser();

    final CharacterCard card = parser.parseJsonObject(<String, Object?>{
      'spec': 'chara_card_v2',
      'spec_version': '2.0',
      'data': <String, Object?>{
        'id': 'firefly-test',
        'name': 'Firefly',
        'description': 'A sincere girl carrying hidden weight.',
        'personality': 'Gentle and earnest.',
        'scenario': 'A quiet rooftop after the dream collapsed.',
        'first_mes': 'Did you come to see me?',
        'mes_example': '<START>Hello.\n\n<START>Stay with me a little longer.',
        'creator': 'Test Fixture',
        'system_prompt':
            '{{original}}\nLean into immersive roleplay and scenic narration.',
        'post_history_instructions':
            'For the next reply, keep the tone intimate and scene-aware.',
        'creator_notes': 'Imported from a SillyTavern-style fixture.',
        'alternate_greetings': <String>[
          'It is quieter when you are here.',
        ],
        'character_book': <String, Object?>{
          'name': 'Firefly Lore',
          'entries': <Object?>[
            <String, Object?>{
              'uid': 'dreamscape',
              'keys': <String>['dreamscape', '匹诺康尼'],
              'secondary_keys': <String>['自由'],
              'content':
                  'Dreamscape topics should surface her longing for freedom.',
              'selective': true,
              'match_whole_words': true,
            },
          ],
        },
      },
    });

    expect(card.id, 'firefly-test');
    expect(card.name, 'Firefly');
    expect(card.exampleDialogues, hasLength(2));
    expect(
        card.alternateGreetings, contains('It is quieter when you are here.'));
    expect(card.creator, 'Test Fixture');
    expect(card.creatorNotes, contains('SillyTavern-style'));
    expect(card.mainPromptOverride, contains('immersive roleplay'));
    expect(
      card.postHistoryInstructions,
      contains('scene-aware'),
    );
    expect(card.lorebook, isNotNull);
    expect(card.lorebook!.name, 'Firefly Lore');
    expect(card.lorebook!.entries.single.secondaryKeywords, contains('自由'));
    expect(card.lorebook!.entries.single.selective, isTrue);
  });

  test('normalizes Tavern markup and user macros in imported cards', () {
    const JsonCharacterCardParser parser = JsonCharacterCardParser();

    final CharacterCard card = parser.parseJsonObject(<String, Object?>{
      'spec': 'chara_card_v2',
      'spec_version': '2.0',
      'data': <String, Object?>{
        'name': '黄昏值日纪要',
        'first_mes':
            '<gametxt>「你好，{{user}}同学。」</gametxt>\n<chapter>序章</chapter>\n---',
        'mes_example': '<START>{{char}}：别发呆。\n{{user}}：我在听。',
        'system_prompt':
            '{{original}}\n<UpdateVariable>debug</UpdateVariable>\n让{{char}}主动推进剧情。',
      },
    });

    expect(card.firstMessage, '「你好，同学。」\n序章');
    expect(card.exampleDialogues.single, '黄昏值日纪要：别发呆。\n你：我在听。');
    expect(card.mainPromptOverride, '{{original}}\n\n让黄昏值日纪要主动推进剧情。');
  });

  test('applies safe Tavern regex scripts to imported fields', () {
    const JsonCharacterCardParser parser = JsonCharacterCardParser();

    final CharacterCard card = parser.parseJsonObject(<String, Object?>{
      'spec': 'chara_card_v2',
      'spec_version': '2.0',
      'data': <String, Object?>{
        'name': '校园恋爱值班生',
        'first_mes': '你-好，{{user}}。',
        'system_prompt': '{{original}}\n系统噪音：删掉我\n继续推进剧情。',
        'extensions': <String, Object?>{
          'regex_scripts': <Object?>[
            <String, Object?>{
              'scriptName': '去掉中文破折号',
              'findRegex': r'/(?<=[\u4e00-\u9fa5])-(?=[\u4e00-\u9fa5])/g',
              'replaceString': '',
              'placement': <int>[2],
              'markdownOnly': true,
              'promptOnly': true,
              'substituteRegex': 0,
            },
            <String, Object?>{
              'scriptName': '去掉系统噪音',
              'findRegex': r'/系统噪音：.*$/gm',
              'replaceString': '',
              'placement': <int>[2],
              'promptOnly': true,
              'substituteRegex': 0,
            },
          ],
        },
      },
    });

    expect(card.firstMessage, '你好，你。');
    expect(card.mainPromptOverride, '{{original}}\n\n继续推进剧情。');
  });

  test('normalizes English possessive macros when no explicit user name exists',
      () {
    const JsonCharacterCardParser parser = JsonCharacterCardParser();

    final CharacterCard card = parser.parseJsonObject(<String, Object?>{
      'spec': 'chara_card_v2',
      'spec_version': '2.0',
      'data': <String, Object?>{
        'name': 'Lynn',
        'first_mes': "{{user}}'s notebook is still open on the table.",
      },
    });

    expect(card.firstMessage, 'your notebook is still open on the table.');
  });
}
