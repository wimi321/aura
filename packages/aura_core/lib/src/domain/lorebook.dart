import 'package:meta/meta.dart';

@immutable
class LorebookEntry {
  const LorebookEntry({
    required this.id,
    required this.content,
    required this.keywords,
    this.secondaryKeywords = const <String>[],
    this.enabled = true,
    this.caseSensitive = false,
    this.priority = 0,
    this.insertionOrder = 0,
    this.selective = false,
    this.constant = false,
    this.matchWholeWords = false,
    this.comment,
    this.name,
    this.position,
    this.extensions = const <String, Object?>{},
  });

  final String id;
  final String content;
  final List<String> keywords;
  final List<String> secondaryKeywords;
  final bool enabled;
  final bool caseSensitive;
  final int priority;
  final int insertionOrder;
  final bool selective;
  final bool constant;
  final bool matchWholeWords;
  final String? comment;
  final String? name;
  final int? position;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'content': content,
      'keywords': keywords,
      'secondaryKeywords': secondaryKeywords,
      'enabled': enabled,
      'caseSensitive': caseSensitive,
      'priority': priority,
      'insertionOrder': insertionOrder,
      'selective': selective,
      'constant': constant,
      'matchWholeWords': matchWholeWords,
      'comment': comment,
      'name': name,
      'position': position,
      'extensions': extensions,
    };
  }

  factory LorebookEntry.fromJson(Map<String, Object?> json) {
    return LorebookEntry(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      keywords: ((json['keywords'] as List?) ?? const <Object>[])
          .map((Object? item) => item.toString())
          .toList(growable: false),
      secondaryKeywords:
          ((json['secondaryKeywords'] as List?) ?? const <Object>[])
              .map((Object? item) => item.toString())
              .toList(growable: false),
      enabled: json['enabled'] as bool? ?? true,
      caseSensitive: json['caseSensitive'] as bool? ?? false,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      insertionOrder: (json['insertionOrder'] as num?)?.toInt() ?? 0,
      selective: json['selective'] as bool? ?? false,
      constant: json['constant'] as bool? ?? false,
      matchWholeWords: json['matchWholeWords'] as bool? ?? false,
      comment: json['comment']?.toString(),
      name: json['name']?.toString(),
      position: (json['position'] as num?)?.toInt(),
      extensions: json['extensions'] is Map<String, Object?>
          ? json['extensions']! as Map<String, Object?>
          : json['extensions'] is Map
              ? (json['extensions']! as Map).cast<String, Object?>()
              : const <String, Object?>{},
    );
  }

  bool matches(String text, {String? localeTag}) {
    if (!enabled || text.trim().isEmpty) {
      return false;
    }
    if (constant) {
      return true;
    }

    final bool primaryMatches =
        _matchesKeywordList(keywords, text, localeTag: localeTag);
    if (!primaryMatches) {
      return false;
    }
    if (!selective || secondaryKeywords.isEmpty) {
      return true;
    }
    return _matchesKeywordList(
      secondaryKeywords,
      text,
      localeTag: localeTag,
    );
  }

  bool _matchesKeywordList(
    List<String> candidates,
    String text, {
    String? localeTag,
  }) {
    if (candidates.isEmpty) {
      return false;
    }
    final String haystack = caseSensitive ? text : text.toLowerCase();
    for (final String keyword in candidates) {
      final String needle = caseSensitive ? keyword : keyword.toLowerCase();
      if (needle.isEmpty) {
        continue;
      }
      if (_useWholeWordMatch(needle, localeTag: localeTag)) {
        final RegExp pattern = RegExp(
          '(?<![A-Za-z0-9_])${RegExp.escape(needle)}(?![A-Za-z0-9_])',
          caseSensitive: caseSensitive,
        );
        if (pattern.hasMatch(text)) {
          return true;
        }
        continue;
      }
      if (haystack.contains(needle)) {
        return true;
      }
    }
    return false;
  }

  bool _useWholeWordMatch(String keyword, {String? localeTag}) {
    if (!matchWholeWords) {
      return false;
    }
    if (_isCjkLocale(localeTag) || _containsCjk(keyword)) {
      return false;
    }
    return true;
  }
}

@immutable
class Lorebook {
  const Lorebook({
    required this.entries,
    this.name,
    this.description,
    this.scanDepth,
    this.tokenBudget,
    this.recursiveScanning = false,
    this.extensions = const <String, Object?>{},
  });

  final List<LorebookEntry> entries;
  final String? name;
  final String? description;
  final int? scanDepth;
  final int? tokenBudget;
  final bool recursiveScanning;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'description': description,
      'scanDepth': scanDepth,
      'tokenBudget': tokenBudget,
      'recursiveScanning': recursiveScanning,
      'extensions': extensions,
      'entries': entries
          .map((LorebookEntry entry) => entry.toJson())
          .toList(growable: false),
    };
  }

  factory Lorebook.fromJson(Map<String, Object?> json) {
    return Lorebook(
      entries: ((json['entries'] as List?) ?? const <Object>[])
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> item) =>
              LorebookEntry.fromJson(item.cast<String, Object?>()))
          .toList(growable: false),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      scanDepth: (json['scanDepth'] as num?)?.toInt(),
      tokenBudget: (json['tokenBudget'] as num?)?.toInt(),
      recursiveScanning: json['recursiveScanning'] as bool? ?? false,
      extensions: json['extensions'] is Map<String, Object?>
          ? json['extensions']! as Map<String, Object?>
          : json['extensions'] is Map
              ? (json['extensions']! as Map).cast<String, Object?>()
              : const <String, Object?>{},
    );
  }

  List<LorebookEntry> resolveMatches(
    String input, {
    int limit = 8,
    String? localeTag,
  }) {
    final List<LorebookEntry> matches = entries
        .where(
          (LorebookEntry entry) => entry.matches(
            input,
            localeTag: localeTag,
          ),
        )
        .toList()
      ..sort((LorebookEntry a, LorebookEntry b) {
        final int constantOrder =
            (b.constant ? 1 : 0).compareTo(a.constant ? 1 : 0);
        if (constantOrder != 0) {
          return constantOrder;
        }
        final int priorityOrder = b.priority.compareTo(a.priority);
        if (priorityOrder != 0) {
          return priorityOrder;
        }
        return a.insertionOrder.compareTo(b.insertionOrder);
      });
    if (matches.length <= limit) {
      return matches;
    }
    return matches.take(limit).toList(growable: false);
  }
}

bool _isCjkLocale(String? localeTag) {
  final String normalized = (localeTag ?? '').toLowerCase();
  return normalized.startsWith('zh') ||
      normalized.startsWith('ja') ||
      normalized.startsWith('ko');
}

bool _containsCjk(String value) {
  return RegExp(r'[\u3400-\u9FFF\u3040-\u30FF\uAC00-\uD7AF]').hasMatch(value);
}
