class RoleplayTextFormatter {
  const RoleplayTextFormatter._();

  static const int _regexPlacementAiOutput = 2;
  static const int _regexPlacementWorldInfo = 5;
  static final RegExp _originalMacroPattern =
      RegExp(r'\{\{\s*original\s*\}\}', caseSensitive: false);
  static final List<RegExp> _hiddenBlockPatterns = <RegExp>[
    RegExp(
      r'<UpdateVariable\b[^>]*>.*?</UpdateVariable>',
      caseSensitive: false,
      dotAll: true,
    ),
    RegExp(
      r'<thinking\b[^>]*>.*?</thinking>',
      caseSensitive: false,
      dotAll: true,
    ),
    RegExp(
      r'<inner_voice\b[^>]*>.*?</inner_voice>',
      caseSensitive: false,
      dotAll: true,
    ),
  ];
  static final List<RegExp> _wrapperTagPatterns = <RegExp>[
    RegExp(r'</?gametxt\b[^>]*>', caseSensitive: false),
    RegExp(r'</?options\b[^>]*>', caseSensitive: false),
    RegExp(r'</?option\b[^>]*>', caseSensitive: false),
    RegExp(r'</?choice\b[^>]*>', caseSensitive: false),
    RegExp(r'</?chapter\b[^>]*>', caseSensitive: false),
    RegExp(r'</?scene\b[^>]*>', caseSensitive: false),
  ];
  static final List<RegExp> _hiddenSingleTagPatterns = <RegExp>[
    RegExp(r'<StatusPlaceHolderImpl\s*/>', caseSensitive: false),
  ];

  static String formatCardField(
    String source, {
    required String characterName,
    String? userAlias,
    String? localeTag,
    bool preserveOriginalMacro = false,
    Map<String, Object?>? extensions,
    bool applyPromptRegex = false,
  }) {
    return _sanitize(
      source,
      characterName: characterName,
      userAlias: userAlias,
      localeTag: localeTag,
      preserveOriginalMacro: preserveOriginalMacro,
      isStreamDelta: false,
      trimSpeakerTurns: false,
      extensions: extensions,
      applyPromptRegex: applyPromptRegex,
    );
  }

  static String sanitizeModelOutput(
    String source, {
    required String characterName,
    String? userAlias,
    String? localeTag,
    Map<String, Object?>? extensions,
  }) {
    return _sanitize(
      source,
      characterName: characterName,
      userAlias: userAlias,
      localeTag: localeTag,
      preserveOriginalMacro: false,
      isStreamDelta: false,
      trimSpeakerTurns: true,
      extensions: extensions,
      applyPromptRegex: false,
    );
  }

  static String sanitizeStreamDelta(
    String source, {
    required String characterName,
    String? userAlias,
    String? localeTag,
    Map<String, Object?>? extensions,
  }) {
    return _sanitize(
      source,
      characterName: characterName,
      userAlias: userAlias,
      localeTag: localeTag,
      preserveOriginalMacro: false,
      isStreamDelta: true,
      trimSpeakerTurns: true,
      extensions: extensions,
      applyPromptRegex: false,
    );
  }

  static String defaultUserAlias({
    String? localeTag,
    String sampleText = '',
  }) {
    final String normalizedLocale = (localeTag ?? '').toLowerCase();
    if (normalizedLocale.startsWith('zh')) {
      return '你';
    }
    if (normalizedLocale.startsWith('ja')) {
      return 'あなた';
    }
    if (normalizedLocale.startsWith('ko')) {
      return '당신';
    }
    if (normalizedLocale.startsWith('en')) {
      return 'you';
    }

    if (RegExp(r'[\u3040-\u30ff]').hasMatch(sampleText)) {
      return 'あなた';
    }
    if (RegExp(r'[\uac00-\ud7af]').hasMatch(sampleText)) {
      return '당신';
    }
    if (RegExp(r'[\u3400-\u9fff]').hasMatch(sampleText)) {
      return '你';
    }
    return 'you';
  }

  static String _resolvedUserAlias({
    String? explicitUserAlias,
    String? localeTag,
    required String sampleText,
  }) {
    final String trimmed = explicitUserAlias?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return defaultUserAlias(localeTag: localeTag, sampleText: sampleText);
  }

  static String _sanitize(
    String source, {
    required String characterName,
    String? userAlias,
    String? localeTag,
    required bool preserveOriginalMacro,
    required bool isStreamDelta,
    required bool trimSpeakerTurns,
    Map<String, Object?>? extensions,
    required bool applyPromptRegex,
  }) {
    if (source.trim().isEmpty) {
      return '';
    }

    final String resolvedUserAlias = _resolvedUserAlias(
      explicitUserAlias: userAlias,
      localeTag: localeTag,
      sampleText: source,
    );

    String result = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    result = _stripHiddenBlocks(result);
    result = _stripWrapperTags(result);

    String? originalToken;
    if (preserveOriginalMacro) {
      originalToken =
          '__AURA_ORIGINAL_MACRO_${source.hashCode}_${characterName.hashCode}__';
      result = result.replaceAll(_originalMacroPattern, originalToken);
    }

    result = _replaceRuntimeMacros(
      result,
      characterName: characterName,
      userAlias: resolvedUserAlias,
    );
    result = _applySafeRegexScripts(
      result,
      extensions: extensions,
      isModelOutput: trimSpeakerTurns,
      applyPromptRegex: applyPromptRegex,
    );
    result = _cleanupHonorificPlaceholders(result, resolvedUserAlias);
    if (trimSpeakerTurns) {
      result = _trimLeakedSpeakerTurns(
        result,
        characterName: characterName,
        userAlias: resolvedUserAlias,
        isStreamDelta: isStreamDelta,
      );
    }
    result = isStreamDelta
        ? _normalizeStreamVisibleText(result)
        : _normalizeVisibleText(result);

    if (originalToken != null) {
      result = result.replaceAll(originalToken, '{{original}}');
    }

    return isStreamDelta ? result : result.trim();
  }

  static String _stripHiddenBlocks(String input) {
    String result = input;
    for (final RegExp pattern in _hiddenBlockPatterns) {
      result = result.replaceAll(pattern, '');
    }
    return result;
  }

  static String _stripWrapperTags(String input) {
    String result = input;
    for (final RegExp pattern in _wrapperTagPatterns) {
      result = result.replaceAll(pattern, '');
    }
    for (final RegExp pattern in _hiddenSingleTagPatterns) {
      result = result.replaceAll(pattern, '');
    }
    return result;
  }

  static String _applySafeRegexScripts(
    String input, {
    Map<String, Object?>? extensions,
    required bool isModelOutput,
    required bool applyPromptRegex,
  }) {
    final List<_SafeRegexScript> scripts = _extractSafeRegexScripts(extensions);
    if (scripts.isEmpty) {
      return input;
    }

    String result = input;
    for (final _SafeRegexScript script in scripts) {
      if (!_shouldApplyRegexScript(
        script,
        isModelOutput: isModelOutput,
        applyPromptRegex: applyPromptRegex,
      )) {
        continue;
      }
      result = result.replaceAllMapped(
        script.pattern,
        (Match match) => _renderRegexReplacement(script.replaceString, match),
      );
    }
    return result;
  }

  static List<_SafeRegexScript> _extractSafeRegexScripts(
    Map<String, Object?>? extensions,
  ) {
    final Object? rawScripts = extensions?['regex_scripts'];
    if (rawScripts is! List) {
      return const <_SafeRegexScript>[];
    }

    final List<_SafeRegexScript> scripts = <_SafeRegexScript>[];
    for (final Object? rawItem in rawScripts) {
      if (rawItem is! Map) {
        continue;
      }
      final Map<String, Object?> item = rawItem.cast<String, Object?>();
      if (_asBool(item['disabled'])) {
        continue;
      }
      final String findRegex = item['findRegex']?.toString().trim() ?? '';
      if (findRegex.isEmpty) {
        continue;
      }
      final RegExp? pattern = _compileSafeRegex(
        findRegex,
        substituteRegex: _asInt(item['substituteRegex']),
      );
      final List<int> placements = _readPlacements(item['placement']);
      if (pattern == null || placements.isEmpty) {
        continue;
      }
      scripts.add(
        _SafeRegexScript(
          pattern: pattern,
          replaceString: item['replaceString']?.toString() ?? '',
          placements: placements,
          markdownOnly: _asBool(item['markdownOnly']),
          promptOnly: _asBool(item['promptOnly']),
        ),
      );
    }
    return scripts;
  }

  static bool _shouldApplyRegexScript(
    _SafeRegexScript script, {
    required bool isModelOutput,
    required bool applyPromptRegex,
  }) {
    final bool placementMatches = isModelOutput
        ? script.placements.contains(_regexPlacementAiOutput)
        : script.placements.any(
            (int placement) =>
                placement == _regexPlacementAiOutput ||
                placement == _regexPlacementWorldInfo,
          );
    if (!placementMatches) {
      return false;
    }

    final bool markdownOnly = script.markdownOnly;
    final bool promptOnly = script.promptOnly;
    if (isModelOutput) {
      return markdownOnly || (!markdownOnly && !promptOnly);
    }
    if (applyPromptRegex) {
      return promptOnly || (!markdownOnly && !promptOnly);
    }
    return markdownOnly || promptOnly || (!markdownOnly && !promptOnly);
  }

  static RegExp? _compileSafeRegex(
    String source, {
    required int substituteRegex,
  }) {
    if (substituteRegex != 0) {
      return null;
    }

    final _RegexLiteral? literal = _parseRegexLiteral(source);
    if (literal != null) {
      try {
        return RegExp(
          literal.pattern,
          caseSensitive: !literal.flags.contains('i'),
          multiLine: literal.flags.contains('m'),
          unicode: literal.flags.contains('u'),
          dotAll: literal.flags.contains('s'),
        );
      } catch (_) {
        return null;
      }
    }

    try {
      return RegExp(source);
    } catch (_) {
      try {
        return RegExp(RegExp.escape(source));
      } catch (_) {
        return null;
      }
    }
  }

  static _RegexLiteral? _parseRegexLiteral(String source) {
    final String trimmed = source.trim();
    if (!trimmed.startsWith('/')) {
      return null;
    }
    final int closingSlash = _findRegexLiteralClosingSlash(trimmed);
    if (closingSlash <= 0) {
      return null;
    }
    final String flags = trimmed.substring(closingSlash + 1);
    if (!RegExp(r'^[gimsuy]*$').hasMatch(flags)) {
      return null;
    }
    return _RegexLiteral(
      pattern: trimmed.substring(1, closingSlash),
      flags: flags,
    );
  }

  static int _findRegexLiteralClosingSlash(String source) {
    for (int index = source.length - 1; index > 0; index -= 1) {
      if (source.codeUnitAt(index) != 0x2F) {
        continue;
      }
      int slashCount = 0;
      for (int cursor = index - 1;
          cursor >= 0 && source.codeUnitAt(cursor) == 0x5C;
          cursor -= 1) {
        slashCount += 1;
      }
      if (slashCount.isEven) {
        return index;
      }
    }
    return -1;
  }

  static String _renderRegexReplacement(String template, Match match) {
    final String normalized = template.replaceAll(
      RegExp(r'\{\{\s*match\s*\}\}', caseSensitive: false),
      r'$0',
    );
    return normalized.replaceAllMapped(
      RegExp(r'\$0|\$(\d+)|\$<([^>]+)>'),
      (Match token) {
        if (token.group(0) == r'$0') {
          return match.group(0) ?? '';
        }
        final String? numbered = token.group(1);
        if (numbered != null) {
          final int? groupIndex = int.tryParse(numbered);
          if (groupIndex == null) {
            return '';
          }
          return match.group(groupIndex) ?? '';
        }
        final String? named = token.group(2);
        if (named == null || named.isEmpty) {
          return '';
        }
        return '';
      },
    );
  }

  static List<int> _readPlacements(Object? value) {
    if (value is List) {
      return value
          .map(_asInt)
          .where((int item) => item >= 0)
          .toList(growable: false);
    }
    final int single = _asInt(value);
    return single >= 0 ? <int>[single] : const <int>[];
  }

  static bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final String normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'true' || normalized == '1';
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? -1;
  }

  static String _replaceRuntimeMacros(
    String input, {
    required String characterName,
    required String userAlias,
  }) {
    String result = input;
    final List<MapEntry<RegExp, String>> replacements =
        <MapEntry<RegExp, String>>[
      MapEntry<RegExp, String>(
        RegExp(r'\{\{\s*char\s*\}\}', caseSensitive: false),
        characterName,
      ),
      MapEntry<RegExp, String>(
        RegExp(r'\{\{\s*bot\s*\}\}', caseSensitive: false),
        characterName,
      ),
      MapEntry<RegExp, String>(
        RegExp(r'\{\{\s*user\s*\}\}', caseSensitive: false),
        userAlias,
      ),
      MapEntry<RegExp, String>(
        RegExp(r'<BOT>', caseSensitive: false),
        characterName,
      ),
      MapEntry<RegExp, String>(
        RegExp(r'<USER>', caseSensitive: false),
        userAlias,
      ),
    ];

    for (final MapEntry<RegExp, String> item in replacements) {
      result = result.replaceAll(item.key, item.value);
    }
    return result;
  }

  static String _cleanupHonorificPlaceholders(String input, String userAlias) {
    if (userAlias.trim().isEmpty) {
      return input;
    }

    String result = input;
    final String escapedAlias = RegExp.escape(userAlias);
    final List<String> suffixes = <String>[
      '同学',
      '先生',
      '小姐',
      '学长',
      '学姐',
      '前辈',
      '前輩',
      '大人',
      '君',
      'くん',
      'さん',
      '様',
      '씨',
      '님',
    ];
    final String suffixPattern = suffixes.map(RegExp.escape).join('|');
    if (suffixPattern.isNotEmpty) {
      result = result.replaceAllMapped(
        RegExp('$escapedAlias($suffixPattern)'),
        (Match match) => match.group(1) ?? '',
      );
    }

    result = result.replaceAll(
      RegExp(r"\byou's\b"),
      'your',
    );
    result = result.replaceAll(
      RegExp(r"\bYou's\b"),
      'Your',
    );
    result = result.replaceAll(RegExp(r'([,，])\s*([.。!！?？])'), r'$2');
    result = result.replaceAll(RegExp(r'\(\s+\)'), '');
    return result;
  }

  static String _normalizeVisibleText(String input) {
    String result = input.replaceAll(
      RegExp(r'^[ \t]*-{3,}[ \t]*$', multiLine: true),
      '',
    );
    result = result.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    result = result.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    return result.trim();
  }

  static String _normalizeStreamVisibleText(String input) {
    String result = input.replaceAll(
      RegExp(r'^[ \t]*-{3,}[ \t]*$', multiLine: true),
      '',
    );
    result = result.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return result;
  }

  static String _trimLeakedSpeakerTurns(
    String input, {
    required String characterName,
    required String userAlias,
    required bool isStreamDelta,
  }) {
    String result = input;
    final String trimmedCharacterName = characterName.trim();
    final String trimmedUserAlias = userAlias.trim();
    final List<String> escapedSpeakerNames = <String>[
      if (trimmedCharacterName.isNotEmpty) RegExp.escape(trimmedCharacterName),
      if (trimmedUserAlias.isNotEmpty) RegExp.escape(trimmedUserAlias),
    ];

    if (trimmedCharacterName.isNotEmpty) {
      result = result.replaceFirst(
        RegExp('^${RegExp.escape(trimmedCharacterName)}\\s*[:：]\\s*'),
        '',
      );
    }

    if (trimmedUserAlias.isNotEmpty &&
        RegExp('^${RegExp.escape(trimmedUserAlias)}\\s*[:：]')
            .hasMatch(result)) {
      return '';
    }

    if (trimmedUserAlias.isNotEmpty) {
      final RegExp userTurnBoundary = RegExp(
        '(\\n+)${RegExp.escape(trimmedUserAlias)}\\s*[:：][\\s\\S]*\$',
      );
      result = result.replaceFirst(userTurnBoundary, '');
    }

    if (!isStreamDelta && trimmedCharacterName.isNotEmpty) {
      final RegExp repeatedAssistantBoundary = RegExp(
        '(\\n+)${RegExp.escape(trimmedCharacterName)}\\s*[:：][\\s\\S]*\$',
      );
      result = result.replaceFirst(repeatedAssistantBoundary, '');
    }

    for (final String speaker in escapedSpeakerNames) {
      result = result.replaceAllMapped(
        RegExp('(^|\\n)$speaker\\s*[:：]\\s*'),
        (Match match) => match.group(1) ?? '',
      );
    }

    return result;
  }
}

class _SafeRegexScript {
  const _SafeRegexScript({
    required this.pattern,
    required this.replaceString,
    required this.placements,
    required this.markdownOnly,
    required this.promptOnly,
  });

  final RegExp pattern;
  final String replaceString;
  final List<int> placements;
  final bool markdownOnly;
  final bool promptOnly;
}

class _RegexLiteral {
  const _RegexLiteral({
    required this.pattern,
    required this.flags,
  });

  final String pattern;
  final String flags;
}
