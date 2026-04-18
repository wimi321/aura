import 'dart:convert';
import 'dart:io';

import 'package:aura_app/backend/services/character_library_store.dart';
import 'package:aura_core/aura_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CharacterLibraryStore', () {
    late Directory tempDir;
    late CharacterLibraryStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('aura_character_store');
      store = CharacterLibraryStore(
        catalogFile: File('${tempDir.path}/characters.json'),
        assetDirectory: Directory('${tempDir.path}/character_assets'),
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('routes standalone worldbook JSON through lorebook preview', () async {
      final File worldbookFile = File('${tempDir.path}/liyue_world.json')
        ..writeAsStringSync('''
        {
          "name": "Liyue Lore",
          "entries": {
            "0": {
              "key": ["璃月", "契约"],
              "content": "Zhongli should sound precise and contractual.",
              "order": 4
            }
          }
        }
        ''');

      await expectLater(
        store.buildPreview(worldbookFile),
        throwsA(
          isA<FormatException>().having(
            (FormatException error) => error.message,
            'message',
            contains('standalone worldbook'),
          ),
        ),
      );

      final LorebookImportPreview preview =
          await store.buildLorebookPreview(worldbookFile);
      expect(preview.fileName, 'liyue_world.json');
      expect(preview.lorebook.name, 'Liyue Lore');
      expect(preview.lorebook.entries, hasLength(1));
      expect(preview.lorebook.entries.first.keywords, <String>['璃月', '契约']);
    });

    test('parses Tavern JSON cards with embedded worldbook in one pass',
        () async {
      final File cardFile = File('${tempDir.path}/story_card.json')
        ..writeAsStringSync('''
        {
          "spec": "chara_card_v2",
          "spec_version": "2.0",
          "data": {
            "name": "Story Lead",
            "description": "A plot-first starter card.",
            "personality": "Direct and scene-aware.",
            "scenario": "A sealed archive after midnight.",
            "first_mes": "You opened the wrong door.",
            "character_book": {
              "name": "Archive Notes",
              "entries": [
                {
                  "uid": "archive",
                  "keys": ["archive", "seal"],
                  "content": "The archive should feel dangerous and active."
                }
              ]
            }
          }
        }
        ''');

      final CharacterImportPreview preview = await store.buildPreview(cardFile);
      expect(preview.hasLorebook, isTrue);
      expect(preview.character.lorebook, isNotNull);
      expect(preview.character.lorebook!.entries, hasLength(1));
      expect(preview.character.preferredOpeningMessage,
          'You opened the wrong door.');
    });

    test('saveCharacter copies external avatar art into the local asset vault',
        () async {
      final File sourceAvatar = File('${tempDir.path}/external_avatar.png')
        ..writeAsBytesSync(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADElEQVR42mP8/5+hHgAHggJ/P6nxsQAAAABJRU5ErkJggg==',
          ),
        );

      const CharacterCard character = CharacterCard(
        id: 'archive-operator',
        name: 'Archive Operator',
        description: 'Keeps the scene coherent.',
        personality: 'Observant and composed.',
        scenario: 'A locked archive corridor.',
        firstMessage: 'State your purpose.',
        exampleDialogues: <String>[],
      );

      final CharacterCard stored = await store.saveCharacter(
        character.copyWith(avatarPath: sourceAvatar.path),
      );

      expect(stored.avatarPath, isNotNull);
      expect(stored.avatarPath, isNot(sourceAvatar.path));
      expect(stored.avatarPath,
          '${tempDir.path}/character_assets/archive-operator.png');
      expect(await File(stored.avatarPath!).exists(), isTrue);
      expect(
        await File(stored.avatarPath!).readAsBytes(),
        sourceAvatar.readAsBytesSync(),
      );

      final List<CharacterCard> reloaded = await store.loadImported();
      expect(reloaded, hasLength(1));
      expect(reloaded.single.avatarPath, stored.avatarPath);
    });
  });
}
