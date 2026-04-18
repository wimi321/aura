import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

void main() {
  group('ChatOrchestrator', () {
    final ChatOrchestrator orchestrator = ChatOrchestrator(
      defaultPreset: const Preset.defaultRoleplay(),
      contextWindowProfile: const ContextWindowProfile(
        maxTokens: 2048,
        summaryTriggerRatio: 0.8,
        lowMemoryMaxTokens: 1024,
      ),
    );

    final CharacterCard card = CharacterCard(
      id: 'asuna',
      name: 'Asuna',
      description: 'A sharp-tongued tsundere swordswoman.',
      personality: 'Proud, protective, easily flustered.',
      scenario: 'A late-night rooftop conversation.',
      firstMessage: 'You are late.',
      exampleDialogues: const <String>['[blush] I was not waiting for you.'],
      lorebook: const Lorebook(
        entries: <LorebookEntry>[
          LorebookEntry(
            id: 'academy',
            keywords: <String>['academy', 'student council'],
            content: 'The academy is ruled by a strict student council.',
            priority: 10,
          ),
        ],
      ),
    );

    test('injects lorebook and whisper into prompt envelope', () {
      final PromptEnvelope envelope = orchestrator.prepareTurn(
        card: card,
        input: const ChatTurnInput(
          userMessage: ChatMessage(
            id: 'u1',
            role: ChatRole.user,
            content: 'Did the academy meeting end already?',
          ),
          history: <ChatMessage>[],
          whisperInstruction: 'Act extra tsundere.',
          localeTag: 'en-US',
        ),
      );

      expect(envelope.systemInstruction, contains('student council'));
      expect(envelope.messages.last.content,
          contains('Director Whisper: Act extra tsundere.'));
      expect(envelope.triggeredLore, contains('academy'));
      expect(envelope.assistantLabel, 'Asuna');
      expect(envelope.userLabel, 'You');
      expect(
        envelope.postHistoryInstructions,
        contains('Write only the character\'s next reply'),
      );
    });

    test('adds story-first chat-completion guidance to the system prompt', () {
      final PromptEnvelope envelope = orchestrator.prepareTurn(
        card: card,
        input: const ChatTurnInput(
          userMessage: ChatMessage(
            id: 'u-story',
            role: ChatRole.user,
            content: 'Keep going.',
          ),
          history: <ChatMessage>[],
          localeTag: 'en-US',
        ),
      );

      expect(
        envelope.systemInstruction,
        contains('story-first chat-completion roleplay'),
      );
      expect(
        envelope.systemInstruction,
        contains('blend dialogue, action, sensory detail, and emotional beats'),
      );
    });

    test('strips emotion tags into control signals', () {
      final StreamDelta delta = orchestrator.processModelTextDelta(
        '[joy]Hello there',
        assistantLabel: 'Asuna',
        userLabel: 'You',
        localeTag: 'en-US',
      );

      expect(delta.visibleText, 'Hello there');
      expect(delta.emotions.single.label, 'joy');
    });

    test('sanitizes visible roleplay markup from streamed output', () {
      final StreamDelta delta = orchestrator.processModelTextDelta(
        '<gametxt>Hello, {{user}}.</gametxt><UpdateVariable>x</UpdateVariable>',
        assistantLabel: '顾南栀',
        userLabel: '你',
        localeTag: 'zh-CN',
      );

      expect(delta.visibleText, 'Hello, 你.');
    });

    test('applies safe Tavern regex scripts while cleaning streamed output',
        () {
      final StreamDelta delta = orchestrator.processModelTextDelta(
        '你-好，<thinking>删除</thinking>请继续。',
        assistantLabel: '校园值班生',
        userLabel: '你',
        localeTag: 'zh-CN',
        characterExtensions: <String, Object?>{
          'regex_scripts': <Object?>[
            <String, Object?>{
              'scriptName': '去掉中文破折号',
              'findRegex': r'/(?<=[\u4e00-\u9fa5])-(?=[\u4e00-\u9fa5])/g',
              'replaceString': '',
              'placement': <int>[2],
              'markdownOnly': true,
              'promptOnly': true,
              'substituteRegex': 0,
            },
          ],
        },
      );

      expect(delta.visibleText, '你好，请继续。');
    });

    test('keeps streamed chunk spacing while trimming leaked speaker labels',
        () {
      final StreamDelta first = orchestrator.processModelTextDelta(
        'Asuna: Hello',
        assistantLabel: 'Asuna',
        userLabel: 'You',
        localeTag: 'en-US',
      );
      final StreamDelta second = orchestrator.processModelTextDelta(
        ' there',
        assistantLabel: 'Asuna',
        userLabel: 'You',
        localeTag: 'en-US',
      );

      expect(first.visibleText, 'Hello');
      expect(second.visibleText, ' there');
    });

    test('cuts leaked user turn from streamed output', () {
      final StreamDelta delta = orchestrator.processModelTextDelta(
        'Asuna: Stay close.\nYou: I grab your sleeve.',
        assistantLabel: 'Asuna',
        userLabel: 'You',
        localeTag: 'en-US',
      );

      expect(delta.visibleText, 'Stay close.');
    });

    test('marks summarization when context grows too large', () {
      final ChatOrchestrator summaryOrchestrator = ChatOrchestrator(
        defaultPreset: const Preset.defaultRoleplay(),
        contextWindowProfile: const ContextWindowProfile(
          maxTokens: 100,
          summaryTriggerRatio: 0.8,
          lowMemoryMaxTokens: 48,
        ),
      );
      final List<ChatMessage> history = List<ChatMessage>.generate(
        8,
        (int index) => ChatMessage(
          id: 'm$index',
          role: index.isEven ? ChatRole.user : ChatRole.assistant,
          content:
              'This is a longer message block number $index with enough text to consume tokens.',
        ),
      );

      final PromptEnvelope envelope = summaryOrchestrator.prepareTurn(
        card: card,
        input: ChatTurnInput(
          userMessage: const ChatMessage(
            id: 'u2',
            role: ChatRole.user,
            content: 'Keep going.',
          ),
          history: history,
        ),
      );

      expect(envelope.shouldSummarize, isTrue);
      expect(envelope.summarySourceMessages, isNotEmpty);
    });

    test('keeps CJK lorebook matching working when whole-word mode is enabled',
        () {
      final CharacterCard cjkCard = card.copyWith(
        lorebook: const Lorebook(
          entries: <LorebookEntry>[
            LorebookEntry(
              id: 'liyue',
              keywords: <String>['璃月'],
              content: '璃月相关话题要带出契约与港口秩序。',
              matchWholeWords: true,
            ),
          ],
        ),
      );

      final PromptEnvelope envelope = orchestrator.prepareTurn(
        card: cjkCard,
        input: const ChatTurnInput(
          userMessage: ChatMessage(
            id: 'u3',
            role: ChatRole.user,
            content: '我想聊聊璃月港最近的气氛。',
          ),
          history: <ChatMessage>[],
          localeTag: 'zh-CN',
        ),
      );

      expect(envelope.systemInstruction, contains('契约与港口秩序'));
      expect(envelope.triggeredLore, contains('liyue'));
      expect(envelope.userLabel, '你');
    });

    test('adds continue-scene guidance near the end of the prompt stack', () {
      final PromptEnvelope envelope = orchestrator.prepareTurn(
        card: card,
        input: const ChatTurnInput(
          userMessage: ChatMessage(
            id: 'u4',
            role: ChatRole.user,
            content: 'Continue the scene.',
            metadata: <String, Object?>{
              'hidden_action': 'continue_scene',
            },
          ),
          history: <ChatMessage>[],
          localeTag: 'en-US',
        ),
      );

      expect(
        envelope.postHistoryInstructions,
        contains('This is a continue-scene request.'),
      );
    });

    test(
        'does not summarize short history just because the card prompt is huge',
        () {
      final CharacterCard hugePromptCard = card.copyWith(
        mainPromptOverride:
            '${'A very long scene bible. ' * 400}\n{{original}}',
      );

      final PromptEnvelope envelope = orchestrator.prepareTurn(
        card: hugePromptCard,
        input: const ChatTurnInput(
          userMessage: ChatMessage(
            id: 'u5',
            role: ChatRole.user,
            content: 'Keep the scene moving.',
          ),
          history: <ChatMessage>[
            ChatMessage(
              id: 'm0',
              role: ChatRole.user,
              content: 'Earlier in the hallway.',
            ),
            ChatMessage(
              id: 'm1',
              role: ChatRole.assistant,
              content: 'The bell has already rung.',
            ),
          ],
        ),
      );

      expect(envelope.shouldSummarize, isFalse);
      expect(envelope.summarySourceMessages, isEmpty);
    });

    test('caps lorebook injection to fit the prompt budget', () {
      final ChatOrchestrator constrainedOrchestrator = ChatOrchestrator(
        defaultPreset: const Preset(
          id: 'tight-budget',
          name: 'Tight Budget',
          systemPromptTemplate: 'Stay in scene.',
          generationConfig: GenerationConfig(
            temperature: 0.8,
            topP: 0.9,
            topK: 40,
            maxOutputTokens: 48,
            repetitionPenalty: 1.05,
          ),
        ),
        contextWindowProfile: const ContextWindowProfile(
          maxTokens: 640,
          summaryTriggerRatio: 0.8,
          lowMemoryMaxTokens: 320,
        ),
      );
      final CharacterCard loreHeavyCard = card.copyWith(
        lorebook: const Lorebook(
          tokenBudget: 24,
          entries: <LorebookEntry>[
            LorebookEntry(
              id: 'entry-1',
              keywords: <String>['academy'],
              content:
                  'First lore block. AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
              priority: 10,
            ),
            LorebookEntry(
              id: 'entry-2',
              keywords: <String>['academy'],
              content:
                  'Second lore block. BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
              priority: 9,
            ),
            LorebookEntry(
              id: 'entry-3',
              keywords: <String>['academy'],
              content:
                  'Third lore block. CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC',
              priority: 8,
            ),
          ],
        ),
      );

      final PromptEnvelope envelope = constrainedOrchestrator.prepareTurn(
        card: loreHeavyCard,
        input: const ChatTurnInput(
          userMessage: ChatMessage(
            id: 'u6',
            role: ChatRole.user,
            content: 'Tell me what the academy is hiding.',
          ),
          history: <ChatMessage>[],
          localeTag: 'en-US',
        ),
      );

      expect(envelope.triggeredLore, <String>['entry-1']);
      expect(envelope.systemInstruction, contains('First lore block.'));
      expect(envelope.systemInstruction, isNot(contains('Second lore block.')));
    });

    test('summary slice preserves the latest two turns', () {
      const ContextWindowProfile profile = ContextWindowProfile(
        maxTokens: 100,
        summaryTriggerRatio: 0.8,
        lowMemoryMaxTokens: 48,
      );
      final List<ChatMessage> history = List<ChatMessage>.generate(
        6,
        (int index) => ChatMessage(
          id: 'm$index',
          role: index.isEven ? ChatRole.user : ChatRole.assistant,
          content: 'message $index',
        ),
      );

      final List<ChatMessage> slice = profile.summarySlice(history);
      expect(slice.map((message) => message.id).toList(), <String>['m0', 'm1']);
    });

    test('clamps oversized output budgets when the context window is tiny', () {
      final ChatOrchestrator tinyWindowOrchestrator = ChatOrchestrator(
        defaultPreset: const Preset(
          id: 'tiny-window',
          name: 'Tiny Window',
          systemPromptTemplate: 'Stay in scene.',
          generationConfig: GenerationConfig(
            temperature: 0.9,
            topP: 0.95,
            topK: 40,
            maxOutputTokens: 700,
            repetitionPenalty: 1.03,
          ),
        ),
        contextWindowProfile: const ContextWindowProfile(
          maxTokens: 120,
          summaryTriggerRatio: 0.8,
          lowMemoryMaxTokens: 64,
        ),
      );

      final PromptEnvelope envelope = tinyWindowOrchestrator.prepareTurn(
        card: card.copyWith(
          scenario: 'A compact late-night checkpoint scene.',
        ),
        input: const ChatTurnInput(
          userMessage: ChatMessage(
            id: 'u7',
            role: ChatRole.user,
            content: '继续推进这一幕。',
          ),
          history: <ChatMessage>[],
          localeTag: 'zh-CN',
        ),
      );

      expect(envelope.generationConfig.maxOutputTokens, lessThan(700));
      expect(envelope.generationConfig.maxOutputTokens, greaterThan(0));
    });
  });
}
