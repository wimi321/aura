import 'dart:convert';

import '../domain/character_card.dart';
import '../domain/lorebook.dart';
import '../utils/roleplay_text_formatter.dart';
import 'json_lorebook_parser.dart';

class JsonCharacterCardParser {
  const JsonCharacterCardParser({
    JsonLorebookParser lorebookParser = const JsonLorebookParser(),
  }) : _lorebookParser = lorebookParser;

  final JsonLorebookParser _lorebookParser;

  CharacterCard parseString(String source, {String? avatarPath}) {
    final Object? decoded = jsonDecode(source);
    return parseJsonObject(decoded, avatarPath: avatarPath);
  }

  CharacterCard parseJsonObject(Object? decoded, {String? avatarPath}) {
    final Map<String, Object?> map = _normalizeMap(decoded);
    if (!looksLikeCharacterCardObject(map)) {
      throw const FormatException('JSON does not look like a character card.');
    }
    return _mapToCard(map, avatarPath: avatarPath);
  }

  bool looksLikeCharacterCardObject(Object? decoded) {
    if (decoded is! Map) {
      return false;
    }
    final Map<String, Object?> map = decoded.cast<String, Object?>();
    final Object? spec = map['spec'];
    if (spec is String && spec.startsWith('chara_card_v')) {
      return true;
    }

    final Map<String, Object?> data = _readMap(map['data']);
    final Map<String, Object?> candidate = data.isNotEmpty ? data : map;
    final bool hasName =
        (candidate['name']?.toString().trim().isNotEmpty ?? false);
    final bool hasCharacterFields = candidate.containsKey('first_mes') ||
        candidate.containsKey('mes_example') ||
        candidate.containsKey('personality') ||
        candidate.containsKey('scenario') ||
        candidate.containsKey('alternate_greetings') ||
        candidate.containsKey('character_book');
    return hasName && hasCharacterFields;
  }

  CharacterCard _mapToCard(Map<String, Object?> map, {String? avatarPath}) {
    final Map<String, Object?> data = _readMap(map['data']);
    final Map<String, Object?> source = data.isNotEmpty ? data : map;
    final Map<String, Object?> sourceExtensions = _readMap(source['extensions']);
    final String name = source['name']?.toString() ?? 'Unknown Character';

    return CharacterCard(
      id: _normalizeId(source['id']?.toString(), name),
      name: _formatCardField(
        name,
        characterName: name,
        extensions: sourceExtensions,
      ),
      description: _formatCardField(
        source['description'],
        characterName: name,
        extensions: sourceExtensions,
      ),
      personality: _formatCardField(
        source['personality'],
        characterName: name,
        extensions: sourceExtensions,
      ),
      scenario: _formatCardField(
        source['scenario'],
        characterName: name,
        extensions: sourceExtensions,
      ),
      firstMessage: _formatCardField(
        source['first_mes'],
        characterName: name,
        extensions: sourceExtensions,
      ),
      exampleDialogues: _readExamples(
        source['mes_example'],
        characterName: name,
        extensions: sourceExtensions,
      ),
      alternateGreetings: _readStringList(
        source['alternate_greetings'],
        characterName: name,
        extensions: sourceExtensions,
      ),
      creator: _firstNonBlankString(<Object?>[
        _formatCardField(
          source['creator'],
          characterName: name,
          extensions: sourceExtensions,
        ),
        _formatCardField(
          map['creator'],
          characterName: name,
          extensions: sourceExtensions,
        ),
      ]),
      creatorNotes: _firstNonBlankString(<Object?>[
        _formatCardField(
          source['creator_notes'],
          characterName: name,
          extensions: sourceExtensions,
        ),
        _formatCardField(
          source['creatorcomment'],
          characterName: name,
          extensions: sourceExtensions,
        ),
      ]),
      mainPromptOverride: _firstNonBlankString(<Object?>[
        _formatCardField(
          source['system_prompt'],
          characterName: name,
          preserveOriginalMacro: true,
          extensions: sourceExtensions,
          applyPromptRegex: true,
        ),
        _formatCardField(
          source['main_prompt'],
          characterName: name,
          preserveOriginalMacro: true,
          extensions: sourceExtensions,
          applyPromptRegex: true,
        ),
      ]),
      postHistoryInstructions: _formatCardField(
        source['post_history_instructions'],
        characterName: name,
        extensions: sourceExtensions,
        applyPromptRegex: true,
      ),
      avatarPath: avatarPath,
      lorebook: _parseLorebook(source['character_book']),
      extensions: sourceExtensions,
      tags: _readTagsList(source['tags']),
      characterVersion: source['character_version']?.toString(),
      spec: map['spec']?.toString(),
      specVersion: map['spec_version']?.toString(),
    );
  }

  Lorebook? _parseLorebook(Object? value) {
    if (value is Map<String, Object?> || value is Map) {
      return _lorebookParser.parseJsonObject(value);
    }
    return null;
  }

  Map<String, Object?> _normalizeMap(Object? decoded) {
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, Object?>();
    }
    throw const FormatException('Character card JSON must be an object.');
  }

  Map<String, Object?> _readMap(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, Object?>();
    }
    return const <String, Object?>{};
  }

  List<String> _readExamples(
    Object? value, {
    required String characterName,
    required Map<String, Object?> extensions,
  }) {
    if (value is List) {
      return value
          .map((Object? item) =>
              _formatCardField(
                item,
                characterName: characterName,
                extensions: extensions,
              ))
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
    }
    final String text = value?.toString() ?? '';
    final List<String> rawBlocks =
        RegExp(r'<START>', caseSensitive: false).hasMatch(text)
        ? text
            .split(RegExp(r'<START>', caseSensitive: false))
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty)
            .toList(growable: false)
        : text
            .split(RegExp(r'\n{2,}'))
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty)
            .toList(growable: false);
    return rawBlocks
        .map((String item) => _formatCardField(
              item,
              characterName: characterName,
              extensions: extensions,
            ))
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _readStringList(
    Object? value, {
    required String characterName,
    required Map<String, Object?> extensions,
  }) {
    if (value is List) {
      return value
          .map((Object? item) => _formatCardField(
                item,
                characterName: characterName,
                extensions: extensions,
              ))
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
    }
    if (value is String) {
      return value
          .split(RegExp(r'\n{2,}'))
          .map((String item) =>
              _formatCardField(
                item,
                characterName: characterName,
                extensions: extensions,
              ))
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  String _formatCardField(
    Object? value, {
    required String characterName,
    bool preserveOriginalMacro = false,
    Map<String, Object?>? extensions,
    bool applyPromptRegex = false,
  }) {
    return RoleplayTextFormatter.formatCardField(
      value?.toString() ?? '',
      characterName: characterName,
      preserveOriginalMacro: preserveOriginalMacro,
      extensions: extensions,
      applyPromptRegex: applyPromptRegex,
    );
  }

  List<String> _readTagsList(Object? value) {
    if (value is List) {
      return value
          .map((Object? item) => item?.toString() ?? '')
          .where((String item) => item.trim().isNotEmpty)
          .toList(growable: false);
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  String? _firstNonBlankString(List<Object?> values) {
    for (final Object? value in values) {
      final String text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  String _normalizeId(String? explicitId, String? name) {
    final String source = (explicitId?.trim().isNotEmpty ?? false)
        ? explicitId!.trim()
        : (name?.trim().isNotEmpty ?? false)
            ? name!.trim()
            : 'unknown-character';
    return source
        .toLowerCase()
        .replaceAll(
          RegExp(r'[^a-z0-9\u3400-\u9fff\u3040-\u30ff\uac00-\ud7af]+'),
          '-',
        )
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}
