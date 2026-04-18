import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

void main() {
  group('AuraEngine', () {
    late FakeInferenceGateway gateway;
    late MemorySessionRepository sessions;
    late AuraEngine engine;
    late CharacterCard card;
    late ModelManifest model;

    setUp(() {
      gateway = FakeInferenceGateway(
        scriptedTextChunks: const <String>['[joy]Hello', ' there'],
        scriptedAudioChunks: const <String>['[calm]I heard you clearly.'],
      );
      sessions = MemorySessionRepository();
      engine = AuraEngine(
        gateway: gateway,
        sessionRepository: sessions,
        orchestrator: ChatOrchestrator(
          defaultPreset: const Preset.defaultRoleplay(),
          contextWindowProfile: const ContextWindowProfile(
            maxTokens: 120,
            summaryTriggerRatio: 0.8,
            lowMemoryMaxTokens: 64,
          ),
        ),
        summarizer: const HeuristicSummarizer(),
      );
      card = const CharacterCard(
        id: 'asuna',
        name: 'Asuna',
        description: 'A sharp swordswoman.',
        personality: 'Proud and warm-hearted.',
        scenario: 'A night walk home.',
        firstMessage: 'You took your time.',
        exampleDialogues: <String>[],
      );
      model = const ModelManifest(
        id: 'gemma-e2b',
        name: 'Gemma 4 E2B',
        version: '1.0.0',
        fileName: 'gemma_e2b.litertlm',
        localPath: '/tmp/gemma_e2b.litertlm',
        sizeBytes: 1024,
        multimodal: true,
      );
    });

    test('initializes runtime with resolved delegate and loads initial model',
        () async {
      await engine.initialize(
        deviceProfile: const DeviceProfile(
          platform: 'android',
          totalRamGb: 12,
          supportsCoreMl: false,
          supportsNnapi: true,
          supportsGpuDelegate: true,
        ),
        initialModel: model,
      );

      expect(gateway.initializedOptions, isNotNull);
      expect(
          gateway.initializedOptions!.primaryDelegate, HardwareDelegate.nnapi);
      expect(gateway.loadedModel?.id, 'gemma-e2b');
      expect(engine.modelManager.activeModel?.id, 'gemma-e2b');
    });

    test('streams text reply and persists session messages', () async {
      await sessions.put(
        ChatSession(
          id: 's1',
          characterId: card.id,
          messages: const <ChatMessage>[],
          updatedAt: DateTime.now(),
        ),
      );

      final List<StreamDelta> deltas = await engine
          .sendTextMessage(
            sessionId: 's1',
            card: card,
            message: 'Hi there',
            whisper: 'Act flirty.',
            localeTag: 'en-US',
          )
          .toList();

      expect(deltas.first.visibleText, 'Hello');
      expect(deltas.first.emotions.single.label, 'joy');
      expect(deltas.last.isDone, isTrue);

      final ChatSession? session = await sessions.getById('s1');
      expect(session, isNotNull);
      expect(session!.messages.length, 2);
      expect(session.messages.first.role, ChatRole.user);
      expect(session.messages.last.content, 'Hello there');
    });

    test('folds emotion-only chunks into the next visible delta', () async {
      gateway = FakeInferenceGateway(
        scriptedTextChunks: const <String>['[joy]', 'Hello there'],
        scriptedAudioChunks: const <String>['[calm]I heard you clearly.'],
      );
      engine = AuraEngine(
        gateway: gateway,
        sessionRepository: sessions,
        orchestrator: ChatOrchestrator(
          defaultPreset: const Preset.defaultRoleplay(),
          contextWindowProfile: const ContextWindowProfile(
            maxTokens: 120,
            summaryTriggerRatio: 0.8,
            lowMemoryMaxTokens: 64,
          ),
        ),
        summarizer: const HeuristicSummarizer(),
      );

      await sessions.put(
        ChatSession(
          id: 's-hidden',
          characterId: card.id,
          messages: const <ChatMessage>[],
          updatedAt: DateTime.now(),
        ),
      );

      final List<StreamDelta> deltas = await engine
          .sendTextMessage(
            sessionId: 's-hidden',
            card: card,
            message: 'Hi there',
          )
          .toList();

      expect(deltas.length, 2);
      expect(deltas.first.visibleText, 'Hello there');
      expect(deltas.first.emotions.single.label, 'joy');
      expect(deltas.last.isDone, isTrue);
    });

    test('streams audio reply path', () async {
      await sessions.put(
        ChatSession(
          id: 's2',
          characterId: card.id,
          messages: const <ChatMessage>[],
          updatedAt: DateTime.now(),
        ),
      );

      final List<StreamDelta> deltas = await engine.sendAudioMessage(
        sessionId: 's2',
        card: card,
        audioFrames: const <List<int>>[
          <int>[1, 2, 3, 4],
        ],
      ).toList();

      expect(deltas.first.visibleText, 'I heard you clearly.');
      expect(deltas.first.emotions.single.label, 'calm');
    });

    test('uses card main prompt and post-history instructions', () async {
      final _CapturingPromptGateway capturingGateway =
          _CapturingPromptGateway();
      final AuraEngine capturingEngine = AuraEngine(
        gateway: capturingGateway,
        sessionRepository: sessions,
        orchestrator: ChatOrchestrator(
          defaultPreset: const Preset.defaultRoleplay(),
          contextWindowProfile: const ContextWindowProfile(
            maxTokens: 120,
            summaryTriggerRatio: 0.8,
            lowMemoryMaxTokens: 64,
          ),
        ),
        summarizer: const HeuristicSummarizer(),
      );
      await capturingEngine.initialize(
        deviceProfile: const DeviceProfile(
          platform: 'android',
          totalRamGb: 12,
          supportsCoreMl: false,
          supportsNnapi: true,
          supportsGpuDelegate: true,
        ),
        initialModel: model,
      );
      await sessions.put(
        ChatSession(
          id: 's-card-prompt',
          characterId: card.id,
          messages: const <ChatMessage>[],
          updatedAt: DateTime.now(),
        ),
      );

      final CharacterCard customCard = card.copyWith(
        mainPromptOverride:
            '{{original}}\nNarrate as a living scene, never as a generic assistant.',
        postHistoryInstructions:
            'Keep the next reply tightly grounded in the current scene.',
      );

      await capturingEngine
          .sendTextMessage(
            sessionId: 's-card-prompt',
            card: customCard,
            message: 'Keep walking with me.',
          )
          .toList();

      expect(capturingGateway.lastPrompt, isNotNull);
      expect(
        capturingGateway.lastPrompt!.systemInstruction,
        contains('living scene'),
      );
      expect(
        capturingGateway.lastPrompt!.systemInstruction,
        contains(const Preset.defaultRoleplay().systemPromptTemplate),
      );
      expect(
        capturingGateway.lastPrompt!.postHistoryInstructions,
        contains('current scene'),
      );
      expect(capturingGateway.lastPrompt!.assistantLabel, 'Asuna');
      expect(capturingGateway.lastPrompt!.userLabel, 'You');
    });

    test('does not persist hidden continue-scene user turns', () async {
      await sessions.put(
        ChatSession(
          id: 's-continue',
          characterId: card.id,
          messages: const <ChatMessage>[
            ChatMessage(
              id: 'assistant-bootstrap',
              role: ChatRole.assistant,
              content: 'You took your time.',
            ),
          ],
          updatedAt: DateTime.now(),
        ),
      );

      await engine.sendTextMessage(
        sessionId: 's-continue',
        card: card,
        message: 'Continue the current scene.',
        userMetadata: const <String, Object?>{
          'hidden_action': 'continue_scene',
        },
      ).toList();

      final ChatSession? session = await sessions.getById('s-continue');
      expect(session, isNotNull);
      expect(session!.messages.length, 2);
      expect(
        session.messages
            .where((ChatMessage message) => message.role == ChatRole.user),
        isEmpty,
      );
      expect(session.messages.last.role, ChatRole.assistant);
    });

    test('keeps recent user turns when a card has a very large prompt',
        () async {
      final AuraEngine largePromptEngine = AuraEngine(
        gateway: gateway,
        sessionRepository: sessions,
        orchestrator: ChatOrchestrator(
          defaultPreset: const Preset.defaultRoleplay(),
          contextWindowProfile: const ContextWindowProfile(
            maxTokens: 64,
            summaryTriggerRatio: 0.5,
            lowMemoryMaxTokens: 32,
          ),
        ),
        summarizer: const HeuristicSummarizer(),
      );
      final CharacterCard hugePromptCard = card.copyWith(
        mainPromptOverride:
            '${'A very long scene bible. ' * 400}\n{{original}}',
      );

      await sessions.put(
        ChatSession(
          id: 's-large-prompt',
          characterId: card.id,
          messages: const <ChatMessage>[],
          updatedAt: DateTime.now(),
        ),
      );

      await largePromptEngine
          .sendTextMessage(
            sessionId: 's-large-prompt',
            card: hugePromptCard,
            message: 'First move.',
          )
          .toList();
      await largePromptEngine
          .sendTextMessage(
            sessionId: 's-large-prompt',
            card: hugePromptCard,
            message: 'Second move.',
          )
          .toList();

      final ChatSession? session = await sessions.getById('s-large-prompt');
      expect(session, isNotNull);
      expect(
        session!.messages
            .where((ChatMessage message) => message.role == ChatRole.user)
            .map((ChatMessage message) => message.content)
            .toList(),
        containsAll(<String>['First move.', 'Second move.']),
      );
    });
  });
}

class _CapturingPromptGateway extends FakeInferenceGateway {
  PromptEnvelope? lastPrompt;

  @override
  Stream<String> streamText({required PromptEnvelope prompt}) async* {
    lastPrompt = prompt;
    yield 'Scene acknowledged.';
  }
}
