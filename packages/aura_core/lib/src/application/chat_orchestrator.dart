import '../domain/character_card.dart';
import '../domain/chat_models.dart';
import '../domain/context_policy.dart';
import '../domain/lorebook.dart';
import '../domain/preset.dart';
import '../utils/emotion_tag_filter.dart';
import '../utils/roleplay_text_formatter.dart';

class ChatOrchestrator {
  ChatOrchestrator({
    required Preset defaultPreset,
    required ContextWindowProfile contextWindowProfile,
    EmotionTagFilter emotionTagFilter = const EmotionTagFilter(),
  })  : _defaultPreset = defaultPreset,
        _contextWindowProfile = contextWindowProfile,
        _emotionTagFilter = emotionTagFilter;

  final Preset _defaultPreset;
  final ContextWindowProfile _contextWindowProfile;
  final EmotionTagFilter _emotionTagFilter;

  PromptEnvelope prepareTurn({
    required CharacterCard card,
    required ChatTurnInput input,
    Preset? preset,
    bool isLowMemoryDevice = false,
  }) {
    final bool continueScene = _isContinueSceneTurn(input.userMessage);
    final Preset resolvedPreset = preset ?? _defaultPreset;
    final GenerationConfig requestedGenerationConfig =
        resolvedPreset.generationConfig.merge(input.customGenerationConfig);
    final bool compactRolePacket = _shouldUseCompactRolePacket(
      isLowMemoryDevice: isLowMemoryDevice,
    );
    final String assistantLabel = _assistantLabel(card, input.localeTag);
    final String userLabel = _userLabel(input.localeTag);
    final List<LorebookEntry> candidateLore = card.lorebook?.resolveMatches(
          _buildScanText(input, card.lorebook?.scanDepth),
          localeTag: input.localeTag,
        ) ??
        const <LorebookEntry>[];
    final String baseSystemInstruction = _resolveSystemInstruction(
      basePrompt: resolvedPreset.systemPromptTemplate,
      card: card,
      localeTag: input.localeTag,
      beforeCharLore: const <LorebookEntry>[],
      afterCharLore: const <LorebookEntry>[],
      assistantLabel: assistantLabel,
      userLabel: userLabel,
      compactRolePacket: compactRolePacket,
    );
    final GenerationConfig clampedConfig = _clampGenerationConfig(
      generationConfig: requestedGenerationConfig,
      baseSystemInstruction: baseSystemInstruction,
      history: input.history,
      userMessage: input.userMessage,
      isLowMemoryDevice: isLowMemoryDevice,
    );
    final GenerationConfig generationConfig = _withDynamicStopSequences(
      config: clampedConfig,
      userLabel: userLabel,
      characterName: assistantLabel,
    );
    final List<LorebookEntry> matchedLore = _fitLorebookEntries(
      candidates: candidateLore,
      lorebook: card.lorebook,
      localeTag: input.localeTag,
      assistantLabel: assistantLabel,
      userLabel: userLabel,
      cardExtensions: card.extensions,
      baseSystemInstruction: baseSystemInstruction,
      generationConfig: generationConfig,
      history: input.history,
      userMessage: input.userMessage,
      isLowMemoryDevice: isLowMemoryDevice,
    );
    final List<LorebookEntry> beforeCharLore = matchedLore
        .where((LorebookEntry e) => e.position == 0)
        .toList(growable: false);
    final List<LorebookEntry> afterCharLore = matchedLore
        .where((LorebookEntry e) => e.position == null || e.position == 1)
        .toList(growable: false);
    final List<LorebookEntry> depthLore = matchedLore
        .where((LorebookEntry e) => e.position == 4)
        .toList(growable: false);
    final String systemInstruction = _resolveSystemInstruction(
      basePrompt: resolvedPreset.systemPromptTemplate,
      card: card,
      localeTag: input.localeTag,
      beforeCharLore: beforeCharLore,
      afterCharLore: afterCharLore,
      assistantLabel: assistantLabel,
      userLabel: userLabel,
      compactRolePacket: compactRolePacket,
    );
    final List<DepthInsertion> depthInsertions = depthLore
        .map((LorebookEntry entry) {
          final String content = RoleplayTextFormatter.formatCardField(
            entry.content,
            characterName: assistantLabel,
            userAlias: userLabel,
            localeTag: input.localeTag,
            extensions: card.extensions,
            applyPromptRegex: true,
          );
          return content.isEmpty ? null : DepthInsertion(content: content, depth: 0);
        })
        .whereType<DepthInsertion>()
        .toList(growable: false);
    final String? postHistoryInstructions = _resolvePostHistoryInstructions(
      card.postHistoryInstructions,
      localeTag: input.localeTag,
      continueScene: continueScene,
      assistantLabel: assistantLabel,
      userLabel: userLabel,
      cardExtensions: card.extensions,
    );

    final List<ChatMessage> truncatedHistory = _truncateHistory(
      history: input.history,
      systemInstruction: systemInstruction,
      userMessage: input.userMessage,
      generationConfig: generationConfig,
      isLowMemoryDevice: isLowMemoryDevice,
    );

    final List<ChatMessage> messages = <ChatMessage>[
      ChatMessage(
        id: 'system',
        role: ChatRole.system,
        content: systemInstruction,
      ),
      ...truncatedHistory,
      _injectWhisper(input.userMessage, input.whisperInstruction),
    ];

    final List<ChatMessage> summaryBudgetMessages = <ChatMessage>[
      ...input.history,
      input.userMessage,
    ];
    final bool shouldSummarize = _contextWindowProfile.shouldSummarize(
      messages: summaryBudgetMessages,
      isLowMemoryDevice: isLowMemoryDevice,
    );

    return PromptEnvelope(
      systemInstruction: systemInstruction,
      messages: messages,
      generationConfig: generationConfig,
      assistantLabel: assistantLabel,
      userLabel: userLabel,
      postHistoryInstructions: postHistoryInstructions,
      triggeredLore: matchedLore
          .map((LorebookEntry entry) => entry.id)
          .where((String id) => id.isNotEmpty)
          .toList(growable: false),
      depthInsertions: depthInsertions,
      shouldSummarize: shouldSummarize,
      summarySourceMessages: shouldSummarize
          ? _contextWindowProfile.summarySlice(input.history)
          : const <ChatMessage>[],
    );
  }

  StreamDelta processModelTextDelta(
    String rawText, {
    required String assistantLabel,
    required String userLabel,
    String? localeTag,
    Map<String, Object?>? characterExtensions,
    bool isDone = false,
  }) {
    final EmotionTagFilterResult result = _emotionTagFilter.parse(rawText);
    final String visibleText = RoleplayTextFormatter.sanitizeStreamDelta(
      result.visibleText,
      characterName: assistantLabel,
      userAlias: userLabel,
      localeTag: localeTag,
      extensions: characterExtensions,
    );
    return StreamDelta(
      visibleText: visibleText,
      emotions: result.emotions,
      isDone: isDone,
    );
  }

  ChatMessage _injectWhisper(
      ChatMessage userMessage, String? whisperInstruction) {
    final String whisper = whisperInstruction?.trim() ?? '';
    if (whisper.isEmpty) {
      return userMessage;
    }

    return ChatMessage(
      id: userMessage.id,
      role: userMessage.role,
      content: '${userMessage.content}\n\n[Director Whisper: $whisper]',
      createdAt: userMessage.createdAt,
      metadata: <String, Object?>{
        ...userMessage.metadata,
        'whisper_injected': true,
      },
    );
  }

  String _resolveSystemInstruction({
    required String basePrompt,
    required CharacterCard card,
    required String? localeTag,
    required List<LorebookEntry> beforeCharLore,
    required List<LorebookEntry> afterCharLore,
    required String assistantLabel,
    required String userLabel,
    required bool compactRolePacket,
  }) {
    final String mergedBasePrompt = _mergeCardPromptOverride(
      basePrompt: basePrompt,
      cardOverride: card.mainPromptOverride,
      assistantLabel: assistantLabel,
      userLabel: userLabel,
      localeTag: localeTag,
      cardExtensions: card.extensions,
    );
    final StringBuffer system = StringBuffer()
      ..writeln(mergedBasePrompt);

    if (beforeCharLore.isNotEmpty) {
      system.writeln();
      for (final LorebookEntry entry in beforeCharLore) {
        final String entryContent = RoleplayTextFormatter.formatCardField(
          entry.content,
          characterName: assistantLabel,
          userAlias: userLabel,
          localeTag: localeTag,
          extensions: card.extensions,
          applyPromptRegex: true,
        );
        if (entryContent.isNotEmpty) {
          system.writeln(entryContent);
        }
      }
    }

    system
      ..writeln()
      ..writeln(
        card.buildSystemRole(
          userAlias: userLabel,
          localeTag: localeTag,
          includeExamples: !compactRolePacket,
        ),
      )
      ..writeln()
      ..writeln(_roleplayContract(localeTag))
      ..writeln()
      ..writeln(_languageGuardrail(localeTag));

    if (afterCharLore.isNotEmpty) {
      system.writeln();
      system.writeln('Triggered Lorebook Entries:');
      for (final LorebookEntry entry in afterCharLore) {
        final String entryContent = RoleplayTextFormatter.formatCardField(
          entry.content,
          characterName: assistantLabel,
          userAlias: userLabel,
          localeTag: localeTag,
          extensions: card.extensions,
          applyPromptRegex: true,
        );
        if (entryContent.isEmpty) {
          continue;
        }
        system.writeln('- $entryContent');
      }
    }

    return system.toString().trimRight();
  }

  String _mergeCardPromptOverride({
    required String basePrompt,
    required String? cardOverride,
    required String assistantLabel,
    required String userLabel,
    required String? localeTag,
    required Map<String, Object?> cardExtensions,
  }) {
    final String override = RoleplayTextFormatter.formatCardField(
      cardOverride?.trim() ?? '',
      characterName: assistantLabel,
      userAlias: userLabel,
      localeTag: localeTag,
      preserveOriginalMacro: true,
      extensions: cardExtensions,
      applyPromptRegex: true,
    );
    if (override.isEmpty) {
      return basePrompt;
    }
    if (override.contains('{{original}}')) {
      return override.replaceAll('{{original}}', basePrompt);
    }
    return override;
  }

  String? _resolvePostHistoryInstructions(
    String? rawInstructions, {
    required String? localeTag,
    required bool continueScene,
    required String assistantLabel,
    required String userLabel,
    required Map<String, Object?> cardExtensions,
  }) {
    final StringBuffer buffer = StringBuffer();
    final String instructions = RoleplayTextFormatter.formatCardField(
      rawInstructions?.trim() ?? '',
      characterName: assistantLabel,
      userAlias: userLabel,
      localeTag: localeTag,
      extensions: cardExtensions,
      applyPromptRegex: true,
    );
    if (instructions.isNotEmpty) {
      buffer.writeln(instructions);
    } else {
      buffer.writeln(_defaultPostHistory(localeTag));
    }
    if (continueScene) {
      buffer.writeln(_continueSceneDirective(localeTag));
    }
    final String result = buffer.toString().trim();
    return result.isEmpty ? null : result;
  }

  List<LorebookEntry> _fitLorebookEntries({
    required List<LorebookEntry> candidates,
    required Lorebook? lorebook,
    required String? localeTag,
    required String assistantLabel,
    required String userLabel,
    required Map<String, Object?> cardExtensions,
    required String baseSystemInstruction,
    required GenerationConfig generationConfig,
    required List<ChatMessage> history,
    required ChatMessage userMessage,
    required bool isLowMemoryDevice,
  }) {
    if (candidates.isEmpty) {
      return const <LorebookEntry>[];
    }

    final int budget = _resolveLoreBudget(
      lorebook: lorebook,
      baseSystemInstruction: baseSystemInstruction,
      generationConfig: generationConfig,
      history: history,
      userMessage: userMessage,
      isLowMemoryDevice: isLowMemoryDevice,
    );
    if (budget <= 0) {
      return const <LorebookEntry>[];
    }

    int usedTokens = 0;
    final List<LorebookEntry> selected = <LorebookEntry>[];
    for (final LorebookEntry entry in candidates) {
      final String content = RoleplayTextFormatter.formatCardField(
        entry.content,
        characterName: assistantLabel,
        userAlias: userLabel,
        localeTag: localeTag,
        extensions: cardExtensions,
        applyPromptRegex: true,
      );
      if (content.isEmpty) {
        continue;
      }
      final int entryTokens = _estimateTokens(content) + 8;
      if (entryTokens > budget) {
        continue;
      }
      if (usedTokens + entryTokens > budget) {
        continue;
      }
      selected.add(entry);
      usedTokens += entryTokens;
    }
    return selected;
  }

  int _resolveLoreBudget({
    required Lorebook? lorebook,
    required String baseSystemInstruction,
    required GenerationConfig generationConfig,
    required List<ChatMessage> history,
    required ChatMessage userMessage,
    required bool isLowMemoryDevice,
  }) {
    final int window = _contextWindowProfile.resolveWindow(
      isLowMemoryDevice: isLowMemoryDevice,
    );
    final int baseSystemTokens = _estimateTokens(baseSystemInstruction);
    final int historyTokens = history.fold<int>(
            0, (int sum, ChatMessage item) => sum + item.estimatedTokenCount) +
        userMessage.estimatedTokenCount;
    final int availableAfterPrompt = window - baseSystemTokens - historyTokens;
    final int reserveTokens = _responseReserveTokens(
      window: window,
      availableAfterPrompt: availableAfterPrompt,
      requestedOutputTokens: generationConfig.maxOutputTokens,
    );
    final int available = availableAfterPrompt - reserveTokens;
    if (available <= 0) {
      return 0;
    }

    final int preferredBudget =
        lorebook?.tokenBudget ?? (window / 4).floor().clamp(256, 640);
    return available < preferredBudget ? available : preferredBudget;
  }

  GenerationConfig _clampGenerationConfig({
    required GenerationConfig generationConfig,
    required String baseSystemInstruction,
    required List<ChatMessage> history,
    required ChatMessage userMessage,
    required bool isLowMemoryDevice,
  }) {
    final int window = _contextWindowProfile.resolveWindow(
      isLowMemoryDevice: isLowMemoryDevice,
    );
    final int baseSystemTokens = _estimateTokens(baseSystemInstruction);
    final int historyTokens = history.fold<int>(
            0, (int sum, ChatMessage item) => sum + item.estimatedTokenCount) +
        userMessage.estimatedTokenCount;
    final int availableAfterPrompt = window - baseSystemTokens - historyTokens;
    if (availableAfterPrompt <= 0) {
      return generationConfig;
    }

    final int safetyMargin = _responseSafetyMargin(
      window: window,
      availableAfterPrompt: availableAfterPrompt,
    );
    final int minOutputTokens = _minOutputTokensForWindow(window);
    final int maxOutputBudget =
        (((availableAfterPrompt * 0.6).floor()) - safetyMargin)
            .clamp(minOutputTokens, generationConfig.maxOutputTokens);
    if (maxOutputBudget >= generationConfig.maxOutputTokens) {
      return generationConfig;
    }

    return GenerationConfig(
      temperature: generationConfig.temperature,
      topP: generationConfig.topP,
      topK: generationConfig.topK,
      maxOutputTokens: maxOutputBudget,
      repetitionPenalty: generationConfig.repetitionPenalty,
      stopSequences: generationConfig.stopSequences,
    );
  }

  int _responseReserveTokens({
    required int window,
    required int availableAfterPrompt,
    required int requestedOutputTokens,
  }) {
    final int safetyMargin = _responseSafetyMargin(
      window: window,
      availableAfterPrompt: availableAfterPrompt,
    );
    final int minOutputTokens = _minOutputTokensForWindow(window);
    final int outputTokens = requestedOutputTokens.clamp(
      minOutputTokens,
      (availableAfterPrompt - safetyMargin)
          .clamp(minOutputTokens, requestedOutputTokens),
    );
    return outputTokens + safetyMargin;
  }

  int _responseSafetyMargin({
    required int window,
    required int availableAfterPrompt,
  }) {
    final int scaled = (window / 32).floor().clamp(4, 64);
    final int headroom =
        availableAfterPrompt - _minOutputTokensForWindow(window);
    if (headroom <= 0) {
      return 0;
    }
    return scaled > headroom ? headroom : scaled;
  }

  int _minOutputTokensForWindow(int window) {
    if (window <= 128) {
      return 8;
    }
    if (window <= 256) {
      return 16;
    }
    return 24;
  }

  bool _shouldUseCompactRolePacket({
    required bool isLowMemoryDevice,
  }) {
    return _contextWindowProfile.resolveWindow(
          isLowMemoryDevice: isLowMemoryDevice,
        ) <=
        256;
  }

  int _estimateTokens(String text) {
    return (text.runes.length / 4).ceil().clamp(1, 1 << 20);
  }

  String _languageGuardrail(String? localeTag) {
    final String normalized = (localeTag ?? '').toLowerCase();
    if (normalized.startsWith('zh')) {
      return 'Always reply in Simplified Chinese unless the user explicitly switches language.';
    }
    if (normalized.startsWith('ja')) {
      return 'Always reply in Japanese unless the user explicitly switches language.';
    }
    if (normalized.startsWith('ko')) {
      return 'Always reply in Korean unless the user explicitly switches language.';
    }
    if (normalized.startsWith('en')) {
      return 'Always reply in English unless the user explicitly switches language.';
    }
    return 'Match the user\'s language and preserve multilingual roleplay fidelity.';
  }

  String _roleplayContract(String? localeTag) {
    final String normalized = (localeTag ?? '').toLowerCase();
    if (normalized.startsWith('zh')) {
      return '把用户视为剧情中的“你”，而不是来咨询助手的人。把输出写成更像酒馆剧情补全的下一拍，可自然混合对白、动作、环境与情绪描写，但绝不要代写用户的台词、心理、决定或动作。';
    }
    if (normalized.startsWith('ja')) {
      return 'ユーザーは相談相手ではなく、物語の中にいる「あなた」です。出力は物語の次の一拍として書き、台詞・所作・空気感を自然に混ぜて構いませんが、ユーザーの台詞・思考・行動を代筆しないでください。';
    }
    if (normalized.startsWith('ko')) {
      return '사용자는 상담 상대가 아니라 이야기 속의 "당신"입니다. 출력은 이야기의 다음 박자처럼 작성하고, 대사·행동·장면 묘사를 자연스럽게 섞어도 되지만 사용자의 대사·생각·행동을 대신 쓰지 마세요.';
    }
    return 'Treat the user as the in-scene "you", not as someone consulting an assistant. Write the next beat of story-first chat-completion roleplay and feel free to blend dialogue, action, sensory detail, and emotional beats, but never author the user\'s dialogue, thoughts, decisions, or actions.';
  }

  String _defaultPostHistory(String? localeTag) {
    final String normalized = (localeTag ?? '').toLowerCase();
    if (normalized.startsWith('zh')) {
      return '只写角色下一轮回复。延续当前场景，主动推进眼前冲突、线索、情绪或后果。优先写成剧情镜头里的对白、动作和即时反应，而不是解释说明。不要总结剧情，不要跳出角色。';
    }
    if (normalized.startsWith('ja')) {
      return 'キャラクターの次の返答だけを書いてください。現在の場面を継続し、目の前の衝突・手掛かり・感情・結果を前に進めてください。説明文よりも台詞・所作・即時反応を優先し、要約やメタ発言は禁止です。';
    }
    if (normalized.startsWith('ko')) {
      return '캐릭터의 다음 응답만 작성하세요. 현재 장면을 이어가며 눈앞의 갈등, 단서, 감정, 결과를 앞으로 밀어 주세요. 설명보다 대사·행동·즉각적인 반응을 우선하고, 요약하거나 메타로 벗어나지 마세요.';
    }
    return 'Write only the character\'s next reply. Continue the current scene and actively move the immediate conflict, clues, emotions, or consequences forward. Prefer scene prose, spoken lines, and immediate reactions over explanations. Do not summarize the story or break character.';
  }

  String _continueSceneDirective(String? localeTag) {
    final String normalized = (localeTag ?? '').toLowerCase();
    if (normalized.startsWith('zh')) {
      return '这是一次“自动继续剧情”。把它当作剧情模式里的自动续写，不要等用户重新下指令，直接顺着当前局势自然推进出新的事件、反应或后果。';
    }
    if (normalized.startsWith('ja')) {
      return 'これは「シーンを続ける」入力です。物語モードの自動続行として扱い、ユーザーの追加指示を待たず、現在の流れのまま新しい出来事・反応・結果を自然に進めてください。';
    }
    if (normalized.startsWith('ko')) {
      return '이 입력은 "장면 계속"입니다. 스토리 모드의 자동 이어쓰기로 보고, 추가 지시를 기다리지 말고 현재 흐름에서 새로운 사건·반응·결과를 자연스럽게 전개하세요.';
    }
    return 'This is a continue-scene request. Treat it like auto-continue in story mode. Do not wait for another player command; naturally push the same situation forward with a fresh beat, reaction, or consequence.';
  }

  String _assistantLabel(CharacterCard card, String? localeTag) {
    final String name = card.name.trim();
    if (name.isNotEmpty) {
      return name;
    }
    final String normalized = (localeTag ?? '').toLowerCase();
    if (normalized.startsWith('zh')) {
      return '角色';
    }
    if (normalized.startsWith('ja')) {
      return 'キャラクター';
    }
    if (normalized.startsWith('ko')) {
      return '캐릭터';
    }
    return 'Character';
  }

  String _userLabel(String? localeTag) {
    final String normalized = (localeTag ?? '').toLowerCase();
    if (normalized.startsWith('zh')) {
      return '你';
    }
    if (normalized.startsWith('ja')) {
      return 'あなた';
    }
    if (normalized.startsWith('ko')) {
      return '당신';
    }
    return 'You';
  }

  GenerationConfig _withDynamicStopSequences({
    required GenerationConfig config,
    required String userLabel,
    required String characterName,
  }) {
    final Set<String> sequences = <String>{...config.stopSequences};
    for (final String separator in const <String>[':', '：']) {
      sequences.add('\n$userLabel$separator');
      sequences.add('\n$characterName$separator');
    }
    final List<String> deduplicated = sequences.toList(growable: false);
    return GenerationConfig(
      temperature: config.temperature,
      topP: config.topP,
      topK: config.topK,
      maxOutputTokens: config.maxOutputTokens,
      repetitionPenalty: config.repetitionPenalty,
      stopSequences: deduplicated,
    );
  }

  List<ChatMessage> _truncateHistory({
    required List<ChatMessage> history,
    required String systemInstruction,
    required ChatMessage userMessage,
    required GenerationConfig generationConfig,
    required bool isLowMemoryDevice,
  }) {
    if (history.isEmpty) {
      return history;
    }
    final int window = _contextWindowProfile.resolveWindow(
      isLowMemoryDevice: isLowMemoryDevice,
    );
    final int systemTokens = _estimateTokens(systemInstruction);
    final int userTokens = userMessage.estimatedTokenCount;
    final int reserveForOutput = generationConfig.maxOutputTokens;
    final int budget = window - systemTokens - userTokens - reserveForOutput;
    if (budget <= 0) {
      // Keep at least last 2 messages.
      final int keep = history.length < 2 ? history.length : 2;
      return history.sublist(history.length - keep);
    }

    int totalTokens = 0;
    for (final ChatMessage message in history) {
      totalTokens += message.estimatedTokenCount;
    }
    if (totalTokens <= budget) {
      return history;
    }

    // Remove oldest messages until we fit, keeping at least 2.
    int startIndex = 0;
    final int minKeep = history.length < 2 ? history.length : 2;
    final int maxRemovable = history.length - minKeep;
    while (totalTokens > budget && startIndex < maxRemovable) {
      totalTokens -= history[startIndex].estimatedTokenCount;
      startIndex++;
    }
    return history.sublist(startIndex);
  }

  String _buildScanText(ChatTurnInput input, int? scanDepth) {
    final int depth = scanDepth ?? 2;
    final StringBuffer buffer = StringBuffer();
    final int start = input.history.length > depth
        ? input.history.length - depth
        : 0;
    for (int i = start; i < input.history.length; i++) {
      buffer.writeln(input.history[i].content);
    }
    buffer.write(input.userMessage.content);
    return buffer.toString();
  }

  bool _isContinueSceneTurn(ChatMessage message) {
    return message.metadata['hidden_action']?.toString() == 'continue_scene';
  }
}
