import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aura_core/aura_core.dart';

class CharacterImportPreview {
  const CharacterImportPreview({
    required this.fileName,
    required this.character,
    required this.hasLorebook,
  });

  final String fileName;
  final CharacterCard character;
  final bool hasLorebook;
}

class LorebookImportPreview {
  const LorebookImportPreview({
    required this.fileName,
    required this.lorebook,
  });

  final String fileName;
  final Lorebook lorebook;
}

class CharacterLibraryStore {
  CharacterLibraryStore({
    required File catalogFile,
    required Directory assetDirectory,
  })  : _catalogFile = catalogFile,
        _assetDirectory = assetDirectory;

  final File _catalogFile;
  final Directory _assetDirectory;
  static const PngCharacterCardParser _pngParser = PngCharacterCardParser();
  static const JsonCharacterCardParser _jsonParser = JsonCharacterCardParser();
  static const JsonLorebookParser _lorebookParser = JsonLorebookParser();

  Future<List<CharacterCard>> loadImported() async {
    if (!await _catalogFile.exists()) {
      return const <CharacterCard>[];
    }

    final Object? decoded = jsonDecode(await _catalogFile.readAsString());
    final List<Object?> items = decoded is List ? decoded : const <Object?>[];
    return items
        .whereType<Map>()
        .map((Map item) => CharacterCard.fromJson(item.cast<String, Object?>()))
        .toList(growable: false);
  }

  Future<CharacterImportPreview> buildPreview(File sourceFile) async {
    final CharacterCard parsed = await _parseCharacterFile(sourceFile);
    return CharacterImportPreview(
      fileName: _displayName(sourceFile),
      character: parsed,
      hasLorebook: (parsed.lorebook?.entries.isNotEmpty ?? false),
    );
  }

  Future<LorebookImportPreview> buildLorebookPreview(File sourceFile) async {
    final Object? decoded = jsonDecode(await sourceFile.readAsString());
    final Lorebook lorebook = _lorebookParser.parseJsonObject(decoded);
    return LorebookImportPreview(
      fileName: _displayName(sourceFile),
      lorebook: lorebook,
    );
  }

  Future<CharacterCard> importFromPreview(CharacterImportPreview preview,
      {List<CharacterCard> existing = const <CharacterCard>[]}) async {
    await _assetDirectory.create(recursive: true);
    final String safeId = _uniqueId(preview.character.id, existing);
    String? avatarPath;
    final String? sourceAvatarPath = preview.character.avatarPath;

    if (sourceAvatarPath != null && _isImageFile(sourceAvatarPath)) {
      final String extension = _fileExtension(sourceAvatarPath);
      avatarPath = '${_assetDirectory.path}/$safeId$extension';
      await File(sourceAvatarPath).copy(avatarPath);
    }

    final CharacterCard stored = preview.character.copyWith(
      id: safeId,
      avatarPath: avatarPath,
      extensions: <String, Object?>{
        ...preview.character.extensions,
        'imported': true,
        'source_file': preview.fileName,
      },
    );

    final List<CharacterCard> next = <CharacterCard>[
      ...existing.where((CharacterCard card) => card.id != stored.id),
      stored,
    ];
    await _save(next);
    return stored;
  }

  Future<CharacterCard> saveCharacter(CharacterCard character,
      {List<CharacterCard> existing = const <CharacterCard>[]}) async {
    await _assetDirectory.create(recursive: true);
    final String? normalizedAvatarPath =
        await _normalizeAvatarPath(character.id, character.avatarPath);
    final CharacterCard stored = character.copyWith(
      avatarPath: normalizedAvatarPath,
    );
    final List<CharacterCard> next = <CharacterCard>[
      ...existing.where((CharacterCard card) => card.id != stored.id),
      stored,
    ];
    await _save(next);
    return stored;
  }

  Future<void> deleteCharacter(String characterId,
      {List<CharacterCard> existing = const <CharacterCard>[]}) async {
    final List<CharacterCard> next = <CharacterCard>[
      ...existing.where((CharacterCard card) => card.id != characterId),
    ];
    await _save(next);
    final String avatarGlob = '${_assetDirectory.path}/$characterId';
    for (final String ext in const <String>['.png', '.jpg', '.jpeg', '.webp']) {
      final File avatarFile = File('$avatarGlob$ext');
      if (await avatarFile.exists()) {
        await avatarFile.delete();
      }
    }
  }

  Future<void> _save(List<CharacterCard> cards) async {
    await _catalogFile.parent.create(recursive: true);
    await _catalogFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        cards
            .map((CharacterCard card) => card.toJson())
            .toList(growable: false),
      ),
    );
  }

  String _uniqueId(String base, List<CharacterCard> existing) {
    final Set<String> ids =
        existing.map((CharacterCard card) => card.id).toSet();
    if (!ids.contains(base)) {
      return base;
    }
    int suffix = 2;
    while (ids.contains('$base-$suffix')) {
      suffix++;
    }
    return '$base-$suffix';
  }

  String _fileExtension(String path) {
    final int dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1) {
      return '.png';
    }
    return path.substring(dotIndex);
  }

  Future<CharacterCard> _parseCharacterFile(File sourceFile) async {
    final String extension = _fileExtension(sourceFile.path).toLowerCase();
    if (extension == '.png') {
      final Uint8List bytes = await sourceFile.readAsBytes();
      return _pngParser.parseBytes(bytes, avatarPath: sourceFile.path);
    }
    if (extension == '.json') {
      final String source = await sourceFile.readAsString();
      final Object? decoded = jsonDecode(source);
      if (_jsonParser.looksLikeCharacterCardObject(decoded)) {
        return _jsonParser.parseJsonObject(decoded);
      }
      if (_lorebookParser.looksLikeLorebookObject(decoded)) {
        throw const FormatException(
          'This JSON looks like a standalone worldbook. Open Edit Character and import it into the lorebook section.',
        );
      }
      throw const FormatException(
        'JSON import currently supports character cards or standalone worldbooks only.',
      );
    }
    throw FormatException('Unsupported file type: $extension');
  }

  bool _isImageFile(String path) {
    final String extension = _fileExtension(path).toLowerCase();
    return extension == '.png' ||
        extension == '.jpg' ||
        extension == '.jpeg' ||
        extension == '.webp';
  }

  Future<String?> _normalizeAvatarPath(
    String characterId,
    String? avatarPath,
  ) async {
    final String sourcePath = (avatarPath ?? '').trim();
    if (sourcePath.isEmpty) {
      return null;
    }
    if (sourcePath.startsWith('assets/')) {
      return sourcePath;
    }
    if (!_isImageFile(sourcePath)) {
      return sourcePath;
    }
    final File sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      return sourcePath;
    }
    final String destinationPath =
        '${_assetDirectory.path}/$characterId${_fileExtension(sourcePath)}';
    if (sourceFile.path == destinationPath) {
      return destinationPath;
    }
    await sourceFile.copy(destinationPath);
    return destinationPath;
  }

  String _displayName(File sourceFile) {
    return sourceFile.uri.pathSegments.isEmpty
        ? sourceFile.path
        : sourceFile.uri.pathSegments.last;
  }
}
