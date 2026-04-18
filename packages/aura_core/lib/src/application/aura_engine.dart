import '../domain/character_card.dart';
import '../domain/chat_models.dart';
import '../domain/device_profile.dart';
import '../domain/emotion_signal.dart';
import '../domain/inference_runtime_status.dart';
import '../domain/model_manifest.dart';
import '../domain/preset.dart';
import '../domain/runtime_options.dart';
import '../domain/session_models.dart';
import '../utils/roleplay_text_formatter.dart';
import 'chat_orchestrator.dart';
import 'device_profile_resolver.dart';
import 'inference_gateway.dart';
import 'model_manager.dart';
import 'session_repository.dart';
import 'summarizer.dart';

class AuraEngine {
  AuraEngine({
    required InferenceGateway gateway,
    required SessionRepository sessionRepository,
    required ChatOrchestrator orchestrator,
    required Summarizer summarizer,
    DeviceProfileResolver deviceProfileResolver = const DeviceProfileResolver(),
  })  : _gateway = gateway,
        _sessionRepository = sessionRepository,
        _orchestrator = orchestrator,
        _summarizer = summarizer,
        _deviceProfileResolver = deviceProfileResolver,
        _modelManager = ModelManager(_GatewayRuntimeAdapter(gateway));

  final InferenceGateway _gateway;
  final SessionRepository _sessionRepository;
  final ChatOrchestrator _orchestrator;
  final Summarizer _summarizer;
  final DeviceProfileResolver _deviceProfileResolver;
  final ModelManager _modelManager;
  DeviceProfile? _deviceProfile;

  ModelManager get modelManager => _modelManager;

  Future<InferenceRuntimeStatus> runtimeStatus() {
    return _gateway.getRuntimeStatus();
  }

  Future<void> cancelActiveGeneration() {
    return _gateway.cancelActiveGeneration();
  }

  Future<void> initialize({
    required DeviceProfile deviceProfile,
    ModelManifest? initialModel,
  }) async {
    _deviceProfile = deviceProfile;
    final RuntimeOptions options =
        _deviceProfileResolver.resolveRuntimeOptions(deviceProfile);
    await _gateway.initialize(options: options);
    await _modelManager.bootstrap(initialModel: initialModel);
  }

  Future<ChatSession> createSession({
    required String sessionId,
    required CharacterCard card,
    String? localeTag,
    String? userAlias,
  }) async {
    final String? openingMessage = card.resolveOpeningMessage(
      localeTag: localeTag,
      userAlias: userAlias,
    );
    final ChatSession session = ChatSession(
      id: sessionId,
      characterId: card.id,
      messages: openingMessage == null || openingMessage.isEmpty
          ? const <ChatMessage>[]
          : <ChatMessage>[
              ChatMessage(
                id: 'assistant-bootstrap',
                role: ChatRole.assistant,
                content: openingMessage,
                createdAt: DateTime.now(),
              ),
            ],
      updatedAt: DateTime.now(),
    );
    await _sessionRepository.put(session);
    return session;
  }

  Future<ChatSession?> getSession(String sessionId) {
    return _sessionRepository.getById(sessionId);
  }

  Future<ChatSession> ensureSession({
    required String sessionId,
    required CharacterCard card,
    String? localeTag,
    String? userAlias,
  }) async {
    final ChatSession? existing = await getSession(sessionId);
    if (existing == null) {
      return createSession(
        sessionId: sessionId,
        card: card,
        localeTag: localeTag,
        userAlias: userAlias,
      );
    }
    if (existing.characterId != card.id) {
      throw StateError('Session $sessionId belongs to another character.');
    }
    return existing;
  }

  Future<List<ChatSession>> listSessions() {
    return _sessionRepository.list();
  }

  Future<List<ChatSession>> listSessionsForCharacter(String characterId) async {
    final List<ChatSession> sessions = await listSessions();
    return sessions
        .where((ChatSession session) => session.characterId == characterId)
        .toList(growable: false);
  }

  Future<ChatSession?> latestSessionForCharacter(String characterId) async {
    final List<ChatSession> sessions =
        await listSessionsForCharacter(characterId);
    return sessions.isEmpty ? null : sessions.first;
  }

  String newSessionIdForCharacter(String characterId) {
    return 'session-$characterId-${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<ChatSession> createFreshSession({
    required CharacterCard card,
    String? localeTag,
    String? userAlias,
  }) {
    return createSession(
      sessionId: newSessionIdForCharacter(card.id),
      card: card,
      localeTag: localeTag,
      userAlias: userAlias,
    );
  }

  Future<void> deleteSession(String sessionId) {
    return _sessionRepository.delete(sessionId);
  }

  Future<void> deleteSessionsForCharacter(String characterId) async {
    final List<ChatSession> sessions =
        await listSessionsForCharacter(characterId);
    for (final ChatSession session in sessions) {
      await _sessionRepository.delete(session.id);
    }
  }

  Future<ChatSession> replaceSessionMessages({
    required String sessionId,
    required List<ChatMessage> messages,
    bool clearSummary = true,
  }) async {
    final ChatSession session = await _requireSession(sessionId);
    final ChatSession updated = session.copyWith(
      messages: List<ChatMessage>.unmodifiable(messages),
      updatedAt: DateTime.now(),
      clearSummary: clearSummary,
    );
    await _sessionRepository.put(updated);
    return updated;
  }

  Stream<StreamDelta> sendTextMessage({
    required String sessionId,
    required CharacterCard card,
    required String message,
    Map<String, Object?> userMetadata = const <String, Object?>{},
    String? whisper,
    String? localeTag,
    Preset? preset,
  }) async* {
    final ChatSession session = await _requireSession(sessionId);
    final ChatMessage userMessage = ChatMessage(
      id: _messageId('user'),
      role: ChatRole.user,
      content: message,
      createdAt: DateTime.now(),
      metadata: userMetadata,
    );

    final ChatTurnInput turnInput = ChatTurnInput(
      userMessage: userMessage,
      history: _historyWithSummary(session),
      whisperInstruction: whisper,
      localeTag: localeTag,
    );

    final PromptEnvelope envelope = _orchestrator.prepareTurn(
      card: card,
      input: turnInput,
      preset: preset,
      isLowMemoryDevice: _deviceProfile?.isLowMemoryDevice ?? false,
    );

    final ChatSession preparedSession =
        await _persistUserTurn(session, userMessage, envelope);
    yield* _streamAssistantReply(
      session: preparedSession,
      card: card,
      envelope: envelope,
      localeTag: localeTag,
      useAudio: false,
      audioFrames: const <List<int>>[],
    );
  }

  Stream<StreamDelta> sendAudioMessage({
    required String sessionId,
    required CharacterCard card,
    required List<List<int>> audioFrames,
    String? whisper,
    String? localeTag,
    Preset? preset,
  }) async* {
    final ChatSession session = await _requireSession(sessionId);
    final ChatMessage userMessage = ChatMessage(
      id: _messageId('audio-user'),
      role: ChatRole.user,
      content: '[audio_input]',
      createdAt: DateTime.now(),
      metadata: const <String, Object?>{'modality': 'audioFrames'},
    );

    final ChatTurnInput turnInput = ChatTurnInput(
      userMessage: userMessage,
      history: _historyWithSummary(session),
      whisperInstruction: whisper,
      localeTag: localeTag,
      modality: InputModality.audioFrames,
      audioFrames: audioFrames,
    );

    final PromptEnvelope envelope = _orchestrator.prepareTurn(
      card: card,
      input: turnInput,
      preset: preset,
      isLowMemoryDevice: _deviceProfile?.isLowMemoryDevice ?? false,
    );

    final ChatSession preparedSession =
        await _persistUserTurn(session, userMessage, envelope);
    yield* _streamAssistantReply(
      session: preparedSession,
      card: card,
      envelope: envelope,
      localeTag: localeTag,
      useAudio: true,
      audioFrames: audioFrames,
    );
  }

  List<ChatMessage> _historyWithSummary(ChatSession session) {
    if (session.summary == null || session.summary!.content.isEmpty) {
      return session.messages;
    }
    return <ChatMessage>[
      ChatMessage(
        id: 'session-summary',
        role: ChatRole.system,
        content: 'Story so far:\n${session.summary!.content}',
        createdAt: session.summary!.createdAt,
      ),
      ...session.messages,
    ];
  }

  Future<ChatSession> _persistUserTurn(
    ChatSession session,
    ChatMessage userMessage,
    PromptEnvelope envelope,
  ) async {
    final bool persistUserMessage = _shouldPersistUserMessage(userMessage);
    ChatSession next = session.copyWith(
      messages: persistUserMessage
          ? <ChatMessage>[...session.messages, userMessage]
          : session.messages,
      updatedAt: DateTime.now(),
    );
    if (envelope.shouldSummarize) {
      final SessionSummary summary =
          await _summarizer.summarize(envelope.summarySourceMessages);
      final Set<String> trimmedIds = summary.sourceMessageIds.toSet();
      final List<ChatMessage> retained = next.messages
          .where((ChatMessage message) => !trimmedIds.contains(message.id))
          .toList(growable: false);
      next = next.copyWith(
        messages: retained,
        summary: summary,
        updatedAt: DateTime.now(),
      );
    }
    await _sessionRepository.put(next);
    return next;
  }

  Stream<StreamDelta> _streamAssistantReply({
    required ChatSession session,
    required CharacterCard card,
    required PromptEnvelope envelope,
    required String? localeTag,
    required bool useAudio,
    required List<List<int>> audioFrames,
  }) async* {
    final StringBuffer assembled = StringBuffer();
    final List<EmotionSignal> detectedEmotions = <EmotionSignal>[];
    final List<EmotionSignal> pendingEmotions = <EmotionSignal>[];
    final Stream<String> rawStream = useAudio
        ? _gateway.streamAudio(prompt: envelope, audioFrames: audioFrames)
        : _gateway.streamText(prompt: envelope);

    try {
      await for (final String chunk in rawStream) {
        final StreamDelta delta = _orchestrator.processModelTextDelta(
          chunk,
          assistantLabel: envelope.assistantLabel,
          userLabel: envelope.userLabel,
          localeTag: localeTag,
          characterExtensions: card.extensions,
        );
        if (delta.emotions.isNotEmpty) {
          detectedEmotions.addAll(delta.emotions);
          pendingEmotions.addAll(delta.emotions);
        }
        if (delta.visibleText.isEmpty) {
          continue;
        }
        assembled.write(delta.visibleText);
        yield StreamDelta(
          visibleText: delta.visibleText,
          emotions: List<EmotionSignal>.unmodifiable(pendingEmotions),
        );
        pendingEmotions.clear();
      }
    } catch (e) {
      final String partial = assembled.toString().trim();
      final String content = partial.isNotEmpty
          ? partial
          : '[Generation failed: $e]';
      final ChatMessage errorMessage = ChatMessage(
        id: _messageId('assistant'),
        role: ChatRole.assistant,
        content: content,
        createdAt: DateTime.now(),
        metadata: <String, Object?>{
          'character_id': card.id,
          'generation_error': true,
        },
      );
      await _sessionRepository.put(
        session.copyWith(
          messages: <ChatMessage>[...session.messages, errorMessage],
          updatedAt: DateTime.now(),
        ),
      );
      // Persist partial/error message so the session is not left inconsistent,
      // then re-throw so callers (e.g. chat page) can trigger recovery flows.
      rethrow;
    }

    final String finalVisibleText = RoleplayTextFormatter.sanitizeModelOutput(
      assembled.toString(),
      characterName: envelope.assistantLabel,
      userAlias: envelope.userLabel,
      localeTag: localeTag,
      extensions: card.extensions,
    );

    final ChatMessage assistantMessage = ChatMessage(
      id: _messageId('assistant'),
      role: ChatRole.assistant,
      content: finalVisibleText,
      createdAt: DateTime.now(),
      metadata: <String, Object?>{
        'character_id': card.id,
        if (detectedEmotions.isNotEmpty)
          'emotions': detectedEmotions
              .map(
                (EmotionSignal signal) => <String, Object?>{
                  'label': signal.label,
                  'raw_tag': signal.rawTag,
                  'offset': signal.offset,
                },
              )
              .toList(growable: false),
      },
    );

    await _sessionRepository.put(
      session.copyWith(
        messages: <ChatMessage>[...session.messages, assistantMessage],
        updatedAt: DateTime.now(),
      ),
    );

    yield const StreamDelta(visibleText: '', isDone: true);
  }

  Future<ChatSession> _requireSession(String sessionId) async {
    final ChatSession? session = await _sessionRepository.getById(sessionId);
    if (session == null) {
      throw StateError('Session not found: $sessionId');
    }
    return session;
  }

  String _messageId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  bool _shouldPersistUserMessage(ChatMessage userMessage) {
    return userMessage.metadata['hidden_action']?.toString() !=
        'continue_scene';
  }
}

class _GatewayRuntimeAdapter implements InferenceRuntime {
  _GatewayRuntimeAdapter(this._gateway);

  final InferenceGateway _gateway;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> loadModel(ModelManifest manifest) {
    return _gateway.loadModel(manifest);
  }

  @override
  Future<void> unloadModel() {
    return _gateway.unloadModel();
  }
}
