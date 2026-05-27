import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

void main() {
  const JsonCharacterCardParser jsonParser = JsonCharacterCardParser();
  const PngCharacterCardParser pngParser = PngCharacterCardParser();
  const JsonLorebookParser lorebookParser = JsonLorebookParser();

  group('Tavern fixture compatibility matrix', () {
    test('parses V2 JSON cards with embedded character_book', () async {
      final CharacterCard card = jsonParser.parseString(
        await _fixture('scene_card_v2.json').readAsString(),
      );

      expect(card.id, 'fixture-last-train');
      expect(card.firstMessage, contains('The station clock stops'));
      expect(card.firstMessage, isNot(contains('<gametxt>')));
      expect(card.firstMessage, isNot(contains('{{user}}')));
      expect(card.lorebook?.name, 'Last Train Rules');
      expect(card.lorebook?.entries, hasLength(2));
      expect(card.postHistoryInstructions, contains("user's actions"));
    });

    test('parses V3 JSON cards with embedded character_book', () async {
      final CharacterCard card = jsonParser.parseString(
        await _fixture('scene_card_v3.json').readAsString(),
      );

      expect(card.id, 'fixture-campus-rain');
      expect(card.firstMessage, contains('Rain taps against the windows'));
      expect(card.firstMessage, isNot(contains('<scene>')));
      expect(card.lorebook?.entries.single.id, 'shared-umbrella');
    });

    test('parses PNG tEXt chara metadata', () async {
      final String raw = await _fixture('scene_card_v2.json').readAsString();
      final CharacterCard card = pngParser.parseBytes(
        _pngWithTextChunk(
          keyword: 'chara',
          value: base64.encode(utf8.encode(raw)),
        ),
      );

      expect(card.name, 'Last Train Fixture');
      expect(card.lorebook?.entries.map((LorebookEntry e) => e.id),
          containsAll(<String>['ticket-rule', 'platform-clock']));
    });

    test('parses PNG iTXt ccv3 metadata', () async {
      final String raw = await _fixture('scene_card_v3.json').readAsString();
      final CharacterCard card = pngParser.parseBytes(
        _pngWithInternationalTextChunk(keyword: 'ccv3', value: raw),
      );

      expect(card.name, 'Campus Rain Fixture');
      expect(card.lorebook?.entries.single.keywords, contains('umbrella'));
    });

    test('parses PNG zTXt chara metadata', () async {
      final String raw = await _fixture('scene_card_v2.json').readAsString();
      final CharacterCard card = pngParser.parseBytes(
        _pngWithCompressedTextChunk(
          keyword: 'chara',
          value: base64.encode(utf8.encode(raw)),
        ),
      );

      expect(card.name, 'Last Train Fixture');
      expect(card.lorebook?.entries, hasLength(2));
    });

    test('parses standalone worldbook JSON fixtures', () async {
      final Lorebook lorebook = lorebookParser.parseString(
        await _fixture('standalone_worldbook.json').readAsString(),
      );

      expect(lorebook.name, 'Fixture Worldbook');
      expect(lorebook.entries, hasLength(2));
      expect(lorebook.entries.first.keywords, contains('rain'));
      expect(lorebook.entries.last.constant, isTrue);
    });
  });
}

File _fixture(String name) {
  return File('test/fixtures/tavern_cards/$name');
}

Uint8List _pngWithTextChunk({
  required String keyword,
  required String value,
}) {
  return _pngWithChunk(
    'tEXt',
    Uint8List.fromList(<int>[
      ...latin1.encode(keyword),
      0,
      ...latin1.encode(value),
    ]),
  );
}

Uint8List _pngWithCompressedTextChunk({
  required String keyword,
  required String value,
}) {
  return _pngWithChunk(
    'zTXt',
    Uint8List.fromList(<int>[
      ...latin1.encode(keyword),
      0,
      0,
      ...ZLibEncoder().convert(latin1.encode(value)),
    ]),
  );
}

Uint8List _pngWithInternationalTextChunk({
  required String keyword,
  required String value,
}) {
  return _pngWithChunk(
    'iTXt',
    Uint8List.fromList(<int>[
      ...utf8.encode(keyword),
      0,
      0,
      0,
      0,
      0,
      ...utf8.encode(value),
    ]),
  );
}

Uint8List _pngWithChunk(String type, Uint8List payload) {
  final BytesBuilder builder = BytesBuilder();
  builder.add(const <int>[137, 80, 78, 71, 13, 10, 26, 10]);
  builder.add(
    _chunk(
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
      ]),
    ),
  );
  builder.add(_chunk(type, payload));
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
