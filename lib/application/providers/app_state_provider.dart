import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:aura_core/aura_core.dart';
import 'package:flutter/foundation.dart';

import '../../backend/services/app_preferences_store.dart';
import '../../backend/services/character_library_store.dart';
import '../../backend/models/default_assets.dart';
import '../../backend/services/preset_library_store.dart';

enum AppModelState {
  idle,
  initializing,
  loading,
  ready,
  switching,
  error,
}

class AppStateProvider extends ChangeNotifier {
  AppStateProvider(
    this.engine, {
    required FileModelCatalogRepository catalogRepository,
    required ModelDownloadManager downloadManager,
    required List<ModelManifest> curatedModels,
    required AppPreferencesStore preferencesStore,
    required CharacterLibraryStore characterLibraryStore,
    required PresetLibraryStore presetLibraryStore,
  })  : _catalogRepository = catalogRepository,
        _downloadManager = downloadManager,
        _curatedModels = curatedModels,
        _preferencesStore = preferencesStore,
        _characterLibraryStore = characterLibraryStore,
        _presetLibraryStore = presetLibraryStore {
    _stateSub = engine.modelManager.states.listen(_handleState);
    unawaited(refreshModels());
    unawaited(loadPreferences());
    unawaited(refreshCharacters());
    unawaited(refreshPresets());
  }

  final AuraEngine engine;
  final FileModelCatalogRepository _catalogRepository;
  final ModelDownloadManager _downloadManager;
  final List<ModelManifest> _curatedModels;
  final AppPreferencesStore _preferencesStore;
  final CharacterLibraryStore _characterLibraryStore;
  final PresetLibraryStore _presetLibraryStore;
  StreamSubscription<ModelLoadState>? _stateSub;
  Future<void>? _engineInitializationFuture;
  bool _isDisposed = false;

  AppModelState _modelState = AppModelState.idle;
  String? _errorMessage;
  String? _downloadingModelId;
  String? _cancelledDownloadId;
  double _downloadProgress = 0;
  int _downloadReceivedBytes = 0;
  int _downloadTotalBytes = 0;
  InferenceRuntimeStatus? _runtimeStatus;
  List<ModelManifest> _availableModels = const <ModelManifest>[];
  final Map<String, bool> _installedModelIds = <String, bool>{};
  String? _localeCode;
  List<CharacterCard> _availableCharacters = localizedBuiltInCharacterLibrary(
    PlatformDispatcher.instance.locale.toLanguageTag(),
  );
  List<Preset> _availablePresets = const <Preset>[Preset.defaultRoleplay()];
  String _activePresetId = 'default-roleplay';
  bool _isRecoveringModel = false;
  String? _conversationActionCharacterId;
  List<String> _recentCharacterIds = const <String>[];
  int _preferencesMutationToken = 0;
  bool _startupResolved = false;

  AppModelState get modelState => _modelState;
  String? get errorMessage => _errorMessage;
  List<ModelManifest> get availableModels => _availableModels;
  ModelManifest? get activeModel => engine.modelManager.activeModel;
  String? get downloadingModelId => _downloadingModelId;
  double get downloadProgress => _downloadProgress;
  int get downloadReceivedBytes => _downloadReceivedBytes;
  int get downloadTotalBytes => _downloadTotalBytes;
  InferenceRuntimeStatus? get runtimeStatus => _runtimeStatus;
  String? get localeCode => _localeCode;
  Locale? get localeOverride =>
      _localeCode == null ? null : Locale(_localeCode!);
  String get effectiveLocaleTag {
    final String? selected = _localeCode?.trim();
    if (selected != null && selected.isNotEmpty) {
      return selected.replaceAll('_', '-');
    }
    return PlatformDispatcher.instance.locale.toLanguageTag();
  }

  List<CharacterCard> get availableCharacters => _availableCharacters;
  List<Preset> get availablePresets => _availablePresets;
  String get activePresetId => _activePresetId;
  bool get isRecoveringModel => _isRecoveringModel;
  bool get startupResolved => _startupResolved;
  bool get hasInstalledModels =>
      _availableModels.any((ModelManifest manifest) => isInstalled(manifest));
  bool get needsModelDownload => !hasInstalledModels && activeModel == null;
  Preset get activePreset => _availablePresets.firstWhere(
        (Preset preset) => preset.id == _activePresetId,
        orElse: () => const Preset.defaultRoleplay(),
      );

  bool isInstalled(ModelManifest manifest) =>
      _installedModelIds[manifest.id] == true;
  bool isDownloading(ModelManifest manifest) =>
      _downloadingModelId == manifest.id;
  bool isActive(ModelManifest manifest) => activeModel?.id == manifest.id;
  bool isConversationActionInProgressFor(String characterId) =>
      _conversationActionCharacterId == characterId;

  Future<void> loadPreferences() async {
    final int loadToken = _preferencesMutationToken;
    final AppPreferences preferences = await _preferencesStore.load();
    if (loadToken != _preferencesMutationToken) {
      return;
    }
    _localeCode = preferences.localeCode;
    _activePresetId = preferences.activePresetId ?? _activePresetId;
    _recentCharacterIds = preferences.recentCharacterIds;
    await refreshCharacters();
    _notifyListenersSafely();
  }

  Future<void> setLocaleCode(String? code) async {
    _preferencesMutationToken += 1;
    _localeCode = code;
    await refreshCharacters();
    _notifyListenersSafely();
    await _savePreferences();
  }

  Future<void> refreshCharacters() async {
    final List<CharacterCard> imported =
        await _characterLibraryStore.loadImported();
    final List<ChatSession> sessions = await engine.listSessions();
    final List<CharacterCard> builtIns =
        localizedBuiltInCharacterLibrary(effectiveLocaleTag);
    final Map<String, int> builtInOrder = <String, int>{
      for (int index = 0; index < builtIns.length; index += 1)
        builtIns[index].id: index,
    };
    final Map<String, CharacterCard> merged = <String, CharacterCard>{
      for (final CharacterCard card in builtIns) card.id: card,
    };
    for (final CharacterCard card in imported) {
      final bool overridesBuiltIn = !isBuiltInCharacterId(card.id) ||
          card.extensions['imported'] == true ||
          card.extensions['user_modified'] == true;
      if (overridesBuiltIn) {
        merged[card.id] = card;
      }
    }
    final Map<String, DateTime> latestActivity = <String, DateTime>{};
    for (final ChatSession session in sessions) {
      final DateTime? current = latestActivity[session.characterId];
      if (current == null || session.updatedAt.isAfter(current)) {
        latestActivity[session.characterId] = session.updatedAt;
      }
    }
    final Set<String> availableIds = merged.keys.toSet();
    final List<String> cleanedRecentIds = _recentCharacterIds
        .where((String id) => availableIds.contains(id))
        .toList(growable: false);
    if (!_sameStringList(cleanedRecentIds, _recentCharacterIds)) {
      _recentCharacterIds = cleanedRecentIds;
      unawaited(_savePreferences());
    }
    final Map<String, int> recentOrder = <String, int>{
      for (int index = 0; index < _recentCharacterIds.length; index += 1)
        _recentCharacterIds[index]: index,
    };
    final List<CharacterCard> sorted = merged.values.toList(growable: true)
      ..sort((CharacterCard a, CharacterCard b) {
        final int recentCompare =
            _compareRecentOrder(a.id, b.id, recentOrder: recentOrder);
        if (recentCompare != 0) {
          return recentCompare;
        }

        final DateTime? aActivity = latestActivity[a.id];
        final DateTime? bActivity = latestActivity[b.id];
        if (aActivity != null && bActivity != null) {
          final int byActivity = bActivity.compareTo(aActivity);
          if (byActivity != 0) {
            return byActivity;
          }
        } else if (aActivity != null || bActivity != null) {
          return aActivity != null ? -1 : 1;
        }

        final int aBuiltInOrder = builtInOrder[a.id] ?? (1 << 20);
        final int bBuiltInOrder = builtInOrder[b.id] ?? (1 << 20);
        final int byBuiltInOrder = aBuiltInOrder.compareTo(bBuiltInOrder);
        if (byBuiltInOrder != 0) {
          return byBuiltInOrder;
        }

        return a.name.compareTo(b.name);
      });
    _availableCharacters = List<CharacterCard>.unmodifiable(sorted);
    _notifyListenersSafely();
  }

  bool isDeletableCharacter(CharacterCard card) {
    return card.extensions['imported'] == true ||
        card.extensions['user_created'] == true;
  }

  Future<void> deleteCharacter(String characterId) async {
    final List<CharacterCard> imported =
        await _characterLibraryStore.loadImported();
    await _characterLibraryStore.deleteCharacter(characterId,
        existing: imported);
    await refreshCharacters();
  }

  Future<void> refreshPresets() async {
    final List<Preset> imported = await _presetLibraryStore.loadPresets();
    final Preset? savedDefault = imported
        .where((Preset preset) => preset.id == 'default-roleplay')
        .isEmpty
        ? null
        : imported.firstWhere((Preset preset) => preset.id == 'default-roleplay');
    _availablePresets = <Preset>[
      savedDefault ?? const Preset.defaultRoleplay(),
      ...imported.where((Preset preset) => preset.id != 'default-roleplay'),
    ];
    if (!_availablePresets
        .any((Preset preset) => preset.id == _activePresetId)) {
      _activePresetId = _availablePresets.first.id;
    }
    _notifyListenersSafely();
  }

  Future<void> setActivePresetId(String presetId) async {
    _preferencesMutationToken += 1;
    _activePresetId = presetId;
    _notifyListenersSafely();
    await _savePreferences();
  }

  Future<Preset> importPresetFile(File sourceFile) async {
    final Preset preset = await _presetLibraryStore.importPresetFile(
      sourceFile,
      existing: _availablePresets,
    );
    await refreshPresets();
    await setActivePresetId(preset.id);
    return preset;
  }

  Future<Preset> savePreset(Preset preset) async {
    final Preset saved = await _presetLibraryStore.savePreset(
      preset,
      existing: _availablePresets
          .where((Preset item) => item.id != preset.id)
          .toList(growable: false),
    );
    await refreshPresets();
    return saved;
  }

  CharacterCard characterById(String id) {
    return _availableCharacters.firstWhere(
      (CharacterCard card) => card.id == id,
      orElse: () => builtInCharacterById(id, localeTag: effectiveLocaleTag),
    );
  }

  Future<ChatSession> resolveChatSession(
    String characterId, {
    String? preferredSessionId,
  }) async {
    final CharacterCard character = characterById(characterId);
    final String? requestedSessionId = preferredSessionId?.trim();
    if (requestedSessionId != null && requestedSessionId.isNotEmpty) {
      final ChatSession session = await engine.ensureSession(
        sessionId: requestedSessionId,
        card: character,
        localeTag: effectiveLocaleTag,
      );
      await _recordRecentCharacter(characterId);
      return session;
    }
    final ChatSession? latest =
        await engine.latestSessionForCharacter(characterId);
    if (latest != null) {
      await _recordRecentCharacter(characterId);
      return latest;
    }
    final ChatSession session = await engine.createFreshSession(
      card: character,
      localeTag: effectiveLocaleTag,
    );
    await _recordRecentCharacter(characterId);
    return session;
  }

  Future<ChatSession> startNewConversation(String characterId) async {
    final ChatSession session = await _runConversationAction(
      characterId,
      () => engine.createFreshSession(
        card: characterById(characterId),
        localeTag: effectiveLocaleTag,
      ),
    );
    await _recordRecentCharacter(characterId);
    return session;
  }

  Future<void> clearConversationHistory(String characterId) async {
    await _runConversationAction(
      characterId,
      () => engine.deleteSessionsForCharacter(characterId),
    );
  }

  Future<ChatSession> resetConversation(String characterId) async {
    final ChatSession session =
        await _runConversationAction(characterId, () async {
      await engine.deleteSessionsForCharacter(characterId);
      return engine.createFreshSession(
        card: characterById(characterId),
        localeTag: effectiveLocaleTag,
      );
    });
    await _recordRecentCharacter(characterId);
    return session;
  }

  Future<T> _runConversationAction<T>(
    String characterId,
    Future<T> Function() action,
  ) async {
    _conversationActionCharacterId = characterId;
    _notifyListenersSafely();
    try {
      return await action();
    } finally {
      if (_conversationActionCharacterId == characterId) {
        _conversationActionCharacterId = null;
      }
      _notifyListenersSafely();
    }
  }

  Future<CharacterImportPreview> previewCharacterImport(File sourceFile) {
    return _characterLibraryStore.buildPreview(sourceFile);
  }

  Future<LorebookImportPreview> previewLorebookImport(File sourceFile) {
    return _characterLibraryStore.buildLorebookPreview(sourceFile);
  }

  Future<CharacterCard> importCharacterPreview(
      CharacterImportPreview preview) async {
    final CharacterCard imported =
        await _characterLibraryStore.importFromPreview(
      preview,
      existing: _availableCharacters,
    );
    await refreshCharacters();
    await _recordRecentCharacter(imported.id);
    return imported;
  }

  Future<CharacterCard> attachLorebookToCharacter({
    required String characterId,
    required LorebookImportPreview preview,
  }) async {
    final CharacterCard current = characterById(characterId);
    final Lorebook mergedLorebook = _mergeLorebooks(
      current.lorebook,
      preview.lorebook,
    );
    final CharacterCard updated = current.copyWith(
      lorebook: mergedLorebook,
      extensions: <String, Object?>{
        ...current.extensions,
        'attached_lorebook_source': preview.fileName,
        'attached_lorebook_mode': 'merge',
        'user_customized': true,
      },
    );
    final CharacterCard stored = await saveCharacter(updated);
    return stored;
  }

  Future<ChatSession> editSessionMessage({
    required String sessionId,
    required String messageId,
    required String newContent,
  }) async {
    final ChatSession? session = await engine.getSession(sessionId);
    if (session == null) {
      throw StateError('Session not found: $sessionId');
    }
    final String normalized = newContent.trim();
    if (normalized.isEmpty) {
      throw StateError('Edited message cannot be empty.');
    }
    final List<ChatMessage> updatedMessages = session.messages
        .map(
          (ChatMessage message) => message.id == messageId
              ? ChatMessage(
                  id: message.id,
                  role: message.role,
                  content: normalized,
                  createdAt: message.createdAt,
                  metadata: message.metadata,
                )
              : message,
        )
        .toList(growable: false);
    return engine.replaceSessionMessages(
      sessionId: sessionId,
      messages: updatedMessages,
    );
  }

  Future<ChatSession> deleteSessionMessage({
    required String sessionId,
    required String messageId,
  }) async {
    final ChatSession? session = await engine.getSession(sessionId);
    if (session == null) {
      throw StateError('Session not found: $sessionId');
    }
    final List<ChatMessage> updatedMessages = session.messages
        .where((ChatMessage message) => message.id != messageId)
        .toList(growable: false);
    if (updatedMessages.length == session.messages.length) {
      throw StateError('Message not found: $messageId');
    }
    return engine.replaceSessionMessages(
      sessionId: sessionId,
      messages: updatedMessages,
    );
  }

  /// Removes the last assistant message and returns the session along with
  /// the preceding user message text so the caller can re-send.
  Future<({ChatSession session, String? lastUserText})> rerollLastMessage(
    String sessionId,
  ) async {
    final ChatSession? session = await engine.getSession(sessionId);
    if (session == null) {
      throw StateError('Session not found: $sessionId');
    }
    final List<ChatMessage> messages =
        List<ChatMessage>.from(session.messages);
    // Remove trailing assistant message
    if (messages.isNotEmpty &&
        messages.last.role == ChatRole.assistant) {
      messages.removeLast();
    }
    // Find last user message text
    String? lastUserText;
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == ChatRole.user) {
        lastUserText = messages[i].content;
        break;
      }
    }
    final ChatSession updated = await engine.replaceSessionMessages(
      sessionId: sessionId,
      messages: messages,
    );
    return (session: updated, lastUserText: lastUserText);
  }

  Future<CharacterCard> saveCharacter(CharacterCard character) async {
    final bool explicitBuiltInCustomization =
        character.extensions['user_customized'] == true;
    final CharacterCard persistedCharacter =
        isBuiltInCharacterId(character.id) && explicitBuiltInCustomization
            ? character.copyWith(
                extensions: <String, Object?>{
                  ...character.extensions,
                  'user_modified': true,
                },
              )
            : character;
    final CharacterCard stored = await _characterLibraryStore.saveCharacter(
      persistedCharacter,
      existing: _availableCharacters,
    );
    await refreshCharacters();
    await _recordRecentCharacter(stored.id);
    return stored;
  }

  Future<void> _recordRecentCharacter(String characterId) async {
    final String normalized = characterId.trim();
    if (normalized.isEmpty) {
      return;
    }
    _preferencesMutationToken += 1;
    final List<String> next = <String>[
      normalized,
      ..._recentCharacterIds.where((String id) => id != normalized),
    ];
    _recentCharacterIds = next.take(24).toList(growable: false);
    _availableCharacters = List<CharacterCard>.unmodifiable(
      _sortCharacters(_availableCharacters),
    );
    _notifyListenersSafely();
    await _savePreferences();
  }

  List<CharacterCard> _sortCharacters(Iterable<CharacterCard> source) {
    final List<CharacterCard> builtIns =
        localizedBuiltInCharacterLibrary(effectiveLocaleTag);
    final Map<String, int> builtInOrder = <String, int>{
      for (int index = 0; index < builtIns.length; index += 1)
        builtIns[index].id: index,
    };
    final Map<String, int> recentOrder = <String, int>{
      for (int index = 0; index < _recentCharacterIds.length; index += 1)
        _recentCharacterIds[index]: index,
    };
    final List<CharacterCard> sorted = source.toList(growable: true)
      ..sort((CharacterCard a, CharacterCard b) {
        final int recentCompare =
            _compareRecentOrder(a.id, b.id, recentOrder: recentOrder);
        if (recentCompare != 0) {
          return recentCompare;
        }
        final int aBuiltInOrder = builtInOrder[a.id] ?? (1 << 20);
        final int bBuiltInOrder = builtInOrder[b.id] ?? (1 << 20);
        final int byBuiltInOrder = aBuiltInOrder.compareTo(bBuiltInOrder);
        if (byBuiltInOrder != 0) {
          return byBuiltInOrder;
        }
        return a.name.compareTo(b.name);
      });
    return sorted;
  }

  int _compareRecentOrder(
    String aId,
    String bId, {
    required Map<String, int> recentOrder,
  }) {
    final int? aRecent = recentOrder[aId];
    final int? bRecent = recentOrder[bId];
    if (aRecent != null && bRecent != null) {
      return aRecent.compareTo(bRecent);
    }
    if (aRecent != null || bRecent != null) {
      return aRecent != null ? -1 : 1;
    }
    return 0;
  }

  bool _sameStringList(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (int index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  Future<void> _savePreferences() {
    return _preferencesStore.save(
      AppPreferences(
        localeCode: _localeCode,
        activePresetId: _activePresetId,
        recentCharacterIds: _recentCharacterIds,
      ),
    );
  }

  void markInitialized({
    required DeviceProfile deviceProfile,
  }) {
    _handleState(engine.modelManager.state);
    _startupResolved = false;
    _notifyListenersSafely();
    if (activeModel != null ||
        engine.modelManager.state != ModelLoadState.idle) {
      _engineInitializationFuture ??= _finalizeStartup();
    } else {
      _engineInitializationFuture ??= _initializeEngine(deviceProfile);
    }
  }

  Future<void> _initializeEngine(DeviceProfile deviceProfile) async {
    try {
      await engine.initialize(deviceProfile: deviceProfile);
      await refreshModels();
      await refreshRuntimeStatus();
      // Auto-load the first installed model so the app is ready to chat.
      if (activeModel == null && hasInstalledModels) {
        final ModelManifest firstInstalled = _availableModels.firstWhere(
          (ModelManifest m) => _installedModelIds[m.id] == true,
        );
        await _attemptModelSwitch(firstInstalled);
      }
    } catch (error) {
      _errorMessage = _presentableError(error);
      _modelState = AppModelState.error;
      _notifyListenersSafely();
    } finally {
      _startupResolved = true;
      _notifyListenersSafely();
    }
  }

  Future<void> _finalizeStartup() async {
    try {
      await refreshModels();
      await refreshRuntimeStatus();
    } catch (error) {
      _errorMessage = _presentableError(error);
      _modelState = AppModelState.error;
      _notifyListenersSafely();
    } finally {
      _startupResolved = true;
      _notifyListenersSafely();
    }
  }

  Future<void> refreshModels() async {
    final List<ModelManifest> storedModels =
        await _catalogRepository.listModels();
    final Map<String, ModelManifest> merged = <String, ModelManifest>{
      for (final ModelManifest manifest in _curatedModels)
        manifest.id: manifest,
      for (final ModelManifest manifest in storedModels) manifest.id: manifest,
    };

    final Set<String> curatedIds =
        _curatedModels.map((ModelManifest m) => m.id).toSet();

    final List<ModelManifest> ordered = <ModelManifest>[
      for (final ModelManifest manifest in _curatedModels) merged[manifest.id]!,
      for (final ModelManifest manifest in storedModels)
        if (!curatedIds.contains(manifest.id)) manifest,
    ];

    for (final ModelManifest manifest in ordered) {
      _installedModelIds[manifest.id] = await File(manifest.localPath).exists();
    }

    _availableModels = ordered;
    _notifyListenersSafely();
  }

  Lorebook _mergeLorebooks(Lorebook? current, Lorebook incoming) {
    final List<LorebookEntry> existingEntries =
        current?.entries ?? const <LorebookEntry>[];
    final Map<String, LorebookEntry> merged = <String, LorebookEntry>{
      for (final LorebookEntry entry in existingEntries)
        _lorebookEntryKey(entry): entry,
    };
    for (final LorebookEntry entry in incoming.entries) {
      merged.putIfAbsent(_lorebookEntryKey(entry), () => entry);
    }
    return Lorebook(
      name: (current?.name?.trim().isNotEmpty ?? false)
          ? current!.name
          : incoming.name,
      description: (current?.description?.trim().isNotEmpty ?? false)
          ? current!.description
          : incoming.description,
      scanDepth: current?.scanDepth ?? incoming.scanDepth,
      tokenBudget: current?.tokenBudget ?? incoming.tokenBudget,
      recursiveScanning:
          (current?.recursiveScanning ?? false) || incoming.recursiveScanning,
      extensions: <String, Object?>{
        ...?current?.extensions,
        ...incoming.extensions,
      },
      entries: merged.values.toList(growable: false),
    );
  }

  String _lorebookEntryKey(LorebookEntry entry) {
    final List<String> normalizedKeywords = <String>[
      ...entry.keywords.map(_normalizeLorebookValue),
      ...entry.secondaryKeywords.map(_normalizeLorebookValue),
    ]..sort();
    final String entryId = _normalizeLorebookValue(entry.id);
    final String content = _normalizeLorebookValue(entry.content);
    return '$entryId|${normalizedKeywords.join(",")}|$content';
  }

  String _normalizeLorebookValue(String value) {
    return value.trim().toLowerCase();
  }

  Future<void> refreshRuntimeStatus() async {
    try {
      _runtimeStatus = await engine.runtimeStatus();
      _notifyListenersSafely();
    } catch (error) {
      _errorMessage ??= _presentableError(error);
      _notifyListenersSafely();
    }
  }

  Future<void> switchModel(ModelManifest manifest) async {
    await _attemptModelSwitch(manifest);
  }

  Future<bool> _attemptModelSwitch(ModelManifest manifest) async {
    if (!await File(manifest.localPath).exists()) {
      _errorMessage = '${manifest.name} is not ready yet. Download it first.';
      _notifyListenersSafely();
      return false;
    }

    try {
      _errorMessage = null;
      _notifyListenersSafely();
      await engine.modelManager.switchModel(manifest);
      await _catalogRepository.upsert(manifest);
      await refreshModels();
      await refreshRuntimeStatus();
      return true;
    } catch (error) {
      _errorMessage = _presentableError(error);
      _modelState = AppModelState.error;
      _notifyListenersSafely();
      return false;
    }
  }

  Future<bool> recoverActiveModel() async {
    final ModelManifest? manifest = activeModel;
    if (manifest == null || _isRecoveringModel) {
      return false;
    }
    _isRecoveringModel = true;
    _notifyListenersSafely();
    try {
      return await _attemptModelSwitch(manifest);
    } finally {
      _isRecoveringModel = false;
      _notifyListenersSafely();
    }
  }

  Future<void> downloadModel(ModelManifest manifest) async {
    if (_downloadingModelId != null) {
      return;
    }

    _errorMessage = null;
    _cancelledDownloadId = null;
    _downloadingModelId = manifest.id;
    _downloadProgress = 0;
    _downloadReceivedBytes = 0;
    _downloadTotalBytes = manifest.sizeBytes;
    _notifyListenersSafely();

    try {
      await for (final ModelDownloadSnapshot snapshot
          in _downloadManager.downloadAndRegister(manifest)) {
        _downloadProgress = snapshot.progress.clamp(0.0, 1.0).toDouble();
        _downloadReceivedBytes = snapshot.receivedBytes;
        _downloadTotalBytes = snapshot.totalBytes;
        if (snapshot.status == DownloadStatus.failed &&
            snapshot.errorMessage != null &&
            _cancelledDownloadId != manifest.id) {
          _errorMessage = _presentableError(snapshot.errorMessage!);
        }
        _notifyListenersSafely();
      }

      await refreshModels();
      await _attemptModelSwitch(manifest);
    } catch (error) {
      if (_cancelledDownloadId != manifest.id) {
        _errorMessage = _presentableError(error);
      }
      _notifyListenersSafely();
    } finally {
      if (_cancelledDownloadId == manifest.id) {
        _errorMessage = null;
      }
      _cancelledDownloadId = null;
      _downloadingModelId = null;
      _downloadProgress = 0;
      _downloadReceivedBytes = 0;
      _downloadTotalBytes = 0;
      _notifyListenersSafely();
    }
  }

  Future<void> cancelModelDownload() async {
    final String? modelId = _downloadingModelId;
    if (modelId == null) {
      return;
    }
    _cancelledDownloadId = modelId;
    try {
      await _downloadManager.cancel(modelId);
    } catch (_) {}
    _notifyListenersSafely();
  }

  Future<bool> deleteInstalledModel(ModelManifest manifest) async {
    if (activeModel?.id == manifest.id) {
      return false;
    }
    if (_downloadingModelId == manifest.id) {
      return false;
    }
    final File modelFile = File(manifest.localPath);
    if (await modelFile.exists()) {
      await modelFile.delete();
    }
    _installedModelIds[manifest.id] = false;
    _notifyListenersSafely();
    return true;
  }

  void _handleState(ModelLoadState state) {
    switch (state) {
      case ModelLoadState.idle:
        _modelState = AppModelState.idle;
        break;
      case ModelLoadState.initializing:
        _modelState = AppModelState.initializing;
        break;
      case ModelLoadState.loading:
        _modelState = AppModelState.loading;
        break;
      case ModelLoadState.ready:
        _modelState = AppModelState.ready;
        break;
      case ModelLoadState.switching:
        _modelState = AppModelState.switching;
        break;
      case ModelLoadState.error:
        _modelState = AppModelState.error;
        break;
    }
    _notifyListenersSafely();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stateSub?.cancel();
    super.dispose();
  }

  void _notifyListenersSafely() {
    if (_isDisposed) {
      return;
    }
    notifyListeners();
  }

  String _presentableError(Object error) {
    final String raw = error.toString().trim();
    final String normalized = raw.toLowerCase();
    if (normalized.isEmpty) {
      return 'Something went wrong. Please try again.';
    }
    if (normalized.contains('enospc') ||
        normalized.contains('no space left on device') ||
        normalized.contains('not enough space')) {
      return 'Not enough storage space. Free up some space and try again.';
    }
    if (normalized.contains('sha-256 mismatch') ||
        normalized.contains('size mismatch') ||
        normalized.contains('integrity')) {
      return 'The downloaded file was incomplete. Please try again.';
    }
    if (normalized.contains('socketexception') ||
        normalized.contains('handshakeexception') ||
        normalized.contains('connection') ||
        normalized.contains('network') ||
        normalized.contains('timed out') ||
        normalized.contains('unexpected status')) {
      return 'Download interrupted. Check your connection and try again.';
    }
    if (normalized.contains('is not ready yet')) {
      return raw;
    }
    return 'Something went wrong. Please try again.';
  }
}
