import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

void main() {
  test('parses base64 payload from PNG tEXt chunk', () {
    const PngCharacterCardParser parser = PngCharacterCardParser();
    final Uint8List pngBytes = _buildPngWithTextChunk(
      keyword: 'chara',
      value: base64.encode(
        utf8.encode('''
        {
          "data": {
            "name": "Mika",
            "description": "A composed strategist.",
            "personality": "Calm and sharp.",
            "scenario": "A war room briefing.",
            "first_mes": "Report in.",
            "mes_example": "<START>Stay focused.",
            "character_book": {
              "entries": [
                {
                  "id": "empire",
                  "keys": ["empire"],
                  "content": "The empire is on the brink of civil war.",
                  "priority": 5
                }
              ]
            }
          }
        }
        '''),
      ),
    );

    final CharacterCard card = parser.parseBytes(pngBytes);

    expect(card.name, 'Mika');
    expect(card.lorebook, isNotNull);
    expect(card.lorebook!.entries.single.keywords, contains('empire'));
  });

  test('normalizes Tavern wrapper tags and user macros from PNG cards', () {
    const PngCharacterCardParser parser = PngCharacterCardParser();
    final Uint8List pngBytes = _buildPngWithTextChunk(
      keyword: 'chara',
      value: base64.encode(
        utf8.encode('''
        {
          "data": {
            "name": "黄昏值日纪要",
            "first_mes": "<gametxt>「你好，{{user}}同学。」</gametxt>\\n<options>【选项A】</options>\\n<chapter>序章</chapter>",
            "mes_example": "<START>{{char}}：别发呆。\\n{{user}}：我在听。",
            "character_book": {
              "entries": [
                {
                  "id": "campus",
                  "keys": ["学园", "社团"],
                  "content": "维持校园恋爱喜剧的推进节奏。",
                  "priority": 8
                }
              ]
            }
          }
        }
        '''),
      ),
    );

    final CharacterCard card = parser.parseBytes(pngBytes);

    expect(card.firstMessage, '「你好，同学。」\n【选项A】\n序章');
    expect(card.exampleDialogues.single, '黄昏值日纪要：别发呆。\n你：我在听。');
    expect(card.lorebook?.entries.single.keywords, contains('学园'));
  });

  test('parses compressed zTXt metadata chunks from PNG cards', () {
    const PngCharacterCardParser parser = PngCharacterCardParser();
    final String payload = jsonEncode(
      const <String, Object?>{
        'spec': 'chara_card_v2',
        'data': <String, Object?>{
          'name': 'Compressed Card',
          'description': 'Saved through a PNG optimizer.',
          'scenario': 'A station after midnight.',
          'first_mes': 'The last train is waiting.',
          'character_book': <String, Object?>{
            'entries': <Object?>[
              <String, Object?>{
                'uid': 7,
                'keys': <String>['last train'],
                'content': 'The platform lights should feel unreliable.',
              },
            ],
          },
        },
      },
    );
    final Uint8List pngBytes = _buildPngWithZtxtChunk(
      keyword: 'chara',
      value: base64.encode(utf8.encode(payload)),
    );

    final CharacterCard card = parser.parseBytes(pngBytes);

    expect(card.name, 'Compressed Card');
    expect(card.lorebook?.entries.single.id, '7');
    expect(card.lorebook?.entries.single.keywords, contains('last train'));
  });
}

Uint8List _buildPngWithTextChunk({
  required String keyword,
  required String value,
}) {
  final BytesBuilder builder = BytesBuilder();
  builder.add(const <int>[137, 80, 78, 71, 13, 10, 26, 10]);
  builder.add(_chunk(
      'IHDR',
      Uint8List.fromList(<int>[
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        1,
        8,
        2,
        0,
        0,
        0,
      ])));
  builder.add(_chunk(
      'tEXt',
      Uint8List.fromList(<int>[
        ...latin1.encode(keyword),
        0,
        ...latin1.encode(value),
      ])));
  builder.add(_chunk('IEND', Uint8List(0)));
  return builder.toBytes();
}

Uint8List _chunk(String type, Uint8List payload) {
  final BytesBuilder builder = BytesBuilder();
  final ByteData length = ByteData(4)..setUint32(0, payload.length);
  builder.add(length.buffer.asUint8List());
  builder.add(latin1.encode(type));
  builder.add(payload);
  builder.add(const <int>[0, 0, 0, 0]);
  return builder.toBytes();
}

Uint8List _buildPngWithZtxtChunk({
  required String keyword,
  required String value,
}) {
  final BytesBuilder builder = BytesBuilder();
  builder.add(const <int>[137, 80, 78, 71, 13, 10, 26, 10]);
  builder.add(_chunk(
      'IHDR',
      Uint8List.fromList(<int>[
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        1,
        8,
        2,
        0,
        0,
        0,
      ])));
  builder.add(_chunk(
    'zTXt',
    Uint8List.fromList(<int>[
      ...latin1.encode(keyword),
      0,
      0,
      ...ZLibEncoder().convert(latin1.encode(value)),
    ]),
  ));
  builder.add(_chunk('IEND', Uint8List(0)));
  return builder.toBytes();
}
