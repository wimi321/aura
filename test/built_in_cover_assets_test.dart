import 'dart:io';

import 'package:aura_core/aura_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_app/backend/models/default_assets.dart';

void main() {
  test('all visible built-in story cards have local cover assets', () {
    final List<CharacterCard> visibleCharacters = <CharacterCard>[
      ...visibleBuiltInCharacterLibrary,
      ...visibleBuiltInCharacterLibraryZh,
    ];
    final List<String> missing = <String>{
      for (final CharacterCard character in visibleCharacters)
        if (!File('assets/images/characters/${character.id}.png').existsSync())
          character.id,
    }.toList()
      ..sort();

    expect(missing, isEmpty, reason: 'Missing built-in cover assets: $missing');
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
