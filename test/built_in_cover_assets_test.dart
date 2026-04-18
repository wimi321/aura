import 'dart:io';

import 'package:aura_core/aura_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:aura_app/backend/models/default_assets.dart';

void main() {
  test('all built-in story cards have local cover assets', () {
    final List<CharacterCard> builtInCharacters = <CharacterCard>[
      ...allBuiltInCharacterLibrary,
      ...allBuiltInCharacterLibraryZh,
    ];
    final List<String> missing = <String>{
      for (final CharacterCard character in builtInCharacters)
        if (!File('assets/images/characters/${character.id}.png').existsSync())
          character.id,
    }.toList()
      ..sort();

    expect(missing, isEmpty, reason: 'Missing built-in cover assets: $missing');
  });

  test('all built-in story cards use the poster cover format', () {
    final List<CharacterCard> builtInCharacters = <CharacterCard>[
      ...allBuiltInCharacterLibrary,
      ...allBuiltInCharacterLibraryZh,
    ];

    final List<String> nonPosterAssets = <String>{}.toList();
    for (final CharacterCard character in builtInCharacters) {
      final File file = File('assets/images/characters/${character.id}.png');
      final img.Image? image = img.decodeImage(file.readAsBytesSync());
      if (image == null || image.width != 1600 || image.height != 2400) {
        nonPosterAssets.add(
          '${character.id}:${image?.width ?? 0}x${image?.height ?? 0}',
        );
      }
    }

    expect(
      nonPosterAssets,
      isEmpty,
      reason: 'Built-in covers must be 1600x2400 posters: $nonPosterAssets',
    );
  });

  test('all visible built-in story cards ship with scene-first roleplay notes',
      () {
    final List<CharacterCard> visibleCharacters = <CharacterCard>[
      ...visibleBuiltInCharacterLibrary,
      ...visibleBuiltInCharacterLibraryZh,
    ];

    for (final CharacterCard character in visibleCharacters) {
      expect(
        character.creatorNotes?.trim(),
        isNotEmpty,
        reason: 'Missing creator notes for ${character.id}',
      );
      expect(
        character.preferredOpeningMessage?.trim(),
        isNotEmpty,
        reason: 'Missing opening message for ${character.id}',
      );
      expect(
        character.lorebook?.entries,
        isNotEmpty,
        reason: 'Missing lorebook entries for ${character.id}',
      );
    }
  });
}
