import 'dart:convert';

import '../domain/lorebook.dart';

class JsonLorebookParser {
  const JsonLorebookParser();

  Lorebook parseString(String source) {
    final Object? decoded = jsonDecode(source);
    return parseJsonObject(decoded);
  }

  Lorebook parseJsonObject(Object? decoded) {
    final Map<String, Object?> map = _normalizeMap(decoded);
    if (!looksLikeLorebookObject(map)) {
      throw const FormatException(
          'JSON does not look like a standalone lorebook/worldbook.');
    }
    return _parseMap(map);
  }

  bool looksLikeLorebookObject(Object? decoded) {
    if (decoded is! Map) {
      return false;
    }
    final Map<String, Object?> map = decoded.cast<String, Object?>();
    final Object? entries = map['entries'];
    return entries is List || entries is Map;
  }

  Lorebook _parseMap(Map<String, Object?> map) {
    final Object? entriesObject = map['entries'];
    final Iterable<Map<String, Object?>> entryMaps =
        _normalizeEntries(entriesObject);

    final List<LorebookEntry> entries = <LorebookEntry>[];
    int index = 0;
    for (final Map<String, Object?> entry in entryMaps) {
      final Set<String> knownKeys = <String>{
        'uid',
        'id',
        'key',
        'keys',
        'keysecondary',
        'secondary_keys',
        'content',
        'enabled',
        'disable',
        'case_sensitive',
        'caseSensitive',
        'priority',
        'order',
        'insertion_order',
        'comment',
        'constant',
        'selective',
        'matchWholeWords',
        'match_whole_words',
        'name',
        'position',
        '__entry_key',
        'extensions',
      };
      final Map<String, Object?> extensions = <String, Object?>{
        ..._readMap(entry['extensions']),
        for (final MapEntry<String, Object?> item in entry.entries)
          if (!knownKeys.contains(item.key)) item.key: item.value,
      };
      entries.add(
        LorebookEntry(
          id: (entry['uid'] ??
                  entry['id'] ??
                  entry['__entry_key'] ??
                  'entry-$index')
              .toString(),
          content: entry['content']?.toString() ?? '',
          keywords: _readStringList(entry['keys'] ?? entry['key']),
          secondaryKeywords: _readStringList(
            entry['secondary_keys'] ?? entry['keysecondary'],
          ),
          enabled: _readBool(entry['enabled']) ??
              !(_readBool(entry['disable']) ?? false),
          caseSensitive: _readBool(entry['case_sensitive']) ??
              _readBool(entry['caseSensitive']) ??
              false,
          priority:
              _readInt(entry['priority']) ?? _readInt(entry['order']) ?? 0,
          insertionOrder: _readInt(entry['insertion_order']) ??
              _readInt(entry['order']) ??
              index,
          selective: _readBool(entry['selective']) ?? false,
          constant: _readBool(entry['constant']) ?? false,
          matchWholeWords: _readBool(entry['matchWholeWords']) ??
              _readBool(entry['match_whole_words']) ??
              false,
          comment: entry['comment']?.toString(),
          name: entry['name']?.toString(),
          position: _readInt(entry['position']),
          extensions: extensions,
        ),
      );
      index += 1;
    }

    final Set<String> knownRootKeys = <String>{
      'name',
      'description',
      'scan_depth',
      'scanDepth',
      'token_budget',
      'tokenBudget',
      'recursive_scanning',
      'recursiveScanning',
      'entries',
      'extensions',
    };

    return Lorebook(
      name: map['name']?.toString(),
      description: map['description']?.toString(),
      scanDepth: _readInt(map['scan_depth']) ?? _readInt(map['scanDepth']),
      tokenBudget:
          _readInt(map['token_budget']) ?? _readInt(map['tokenBudget']),
      recursiveScanning: _readBool(map['recursive_scanning']) ??
          _readBool(map['recursiveScanning']) ??
          false,
      extensions: <String, Object?>{
        ..._readMap(map['extensions']),
        for (final MapEntry<String, Object?> item in map.entries)
          if (!knownRootKeys.contains(item.key)) item.key: item.value,
      },
      entries: entries,
    );
  }

  Iterable<Map<String, Object?>> _normalizeEntries(Object? entriesObject) {
    if (entriesObject is List) {
      return entriesObject.whereType<Map<Object?, Object?>>().map(
            (Map<Object?, Object?> item) => item.cast<String, Object?>(),
          );
    }
    if (entriesObject is Map<Object?, Object?>) {
      return entriesObject.entries
          .where((MapEntry<Object?, Object?> item) => item.value is Map)
          .map((MapEntry<Object?, Object?> item) {
        final Map<String, Object?> normalized =
            (item.value as Map<Object?, Object?>).cast<String, Object?>();
        if (normalized.containsKey('uid') || normalized.containsKey('id')) {
          return normalized;
        }
        return <String, Object?>{
          '__entry_key': item.key?.toString(),
          ...normalized,
        };
      });
    }
    throw const FormatException('Lorebook entries must be a list or object.');
  }

  Map<String, Object?> _normalizeMap(Object? decoded) {
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, Object?>();
    }
    throw const FormatException('Lorebook JSON must be an object.');
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

  List<String> _readStringList(Object? value) {
    if (value is List) {
      return value
          .map((Object? item) => item?.toString() ?? '')
          .where((String item) => item.trim().isNotEmpty)
          .toList(growable: false);
    }
    if (value is String) {
      return value
          .split(',')
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  bool? _readBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
        case 'yes':
          return true;
        case 'false':
        case '0':
        case 'no':
          return false;
      }
    }
    return null;
  }

  int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }
}
