import 'dart:io';

import 'package:aura_app/application/providers/app_state_provider.dart';
import 'package:aura_app/backend/models/default_assets.dart';
import 'package:aura_app/backend/services/app_preferences_store.dart';
import 'package:aura_app/backend/services/character_library_store.dart';
import 'package:aura_app/backend/services/preset_library_store.dart';
import 'package:aura_core/aura_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppStateProvider', () {
    late Directory tempDir;
    late AppStateProvider appState;
    late ModelManifest installedE2bManifest;
    late List<ModelManifest> curatedModels;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('aura_app_state');
      installedE2bManifest = downloadableE2bModelManifest.copyWith(
        localPath: '${tempDir.path}/models/gemma-4-E2B-it.litertlm',
      );
      curatedModels = <ModelManifest>[
        installedE2bManifest,
        downloadableE4bModelManifest.copyWith(
          localPath: '${tempDir.path}/models/gemma-4-E4B-it.litertlm',
        ),
      ];
      final File installedModelFile = File(installedE2bManifest.localPath);
      await installedModelFile.parent.create(recursive: true);
      await installedModelFile.writeAsBytes(const <int>[1, 2, 3, 4]);
      final FakeInferenceGateway gateway = FakeInferenceGateway();
      final AuraEngine engine = AuraEngine(
        gateway: gateway,
        sessionRepository: MemorySessionRepository(),
        orchestrator: ChatOrchestrator(
          defaultPreset: const Preset.defaultRoleplay(),
          contextWindowProfile: const ContextWindowProfile(
            maxTokens: 2048,
            summaryTriggerRatio: 0.55,
            lowMemoryMaxTokens: 1024,
          ),
        ),
        summarizer: const HeuristicSummarizer(),
      );
      await engine.initialize(
        deviceProfile: const DeviceProfile(
          platform: 'android',
          totalRamGb: 8,
          supportsCoreMl: false,
          supportsNnapi: false,
          supportsGpuDelegate: true,
        ),
        initialModel: installedE2bManifest,
      );

      appState = AppStateProvider(
        engine,
        catalogRepository:
            FileModelCatalogRepository(File('${tempDir.path}/catalog.json')),
        downloadManager: ModelDownloadManager(
          downloader: HttpResumableModelDownloader(
            tempDirectory: Directory('${tempDir.path}/downloads'),
          ),
          catalogRepository:
              FileModelCatalogRepository(File('${tempDir.path}/catalog.json')),
        ),
        curatedModels: curatedModels,
        preferencesStore:
            AppPreferencesStore(File('${tempDir.path}/prefs.json')),
        characterLibraryStore: CharacterLibraryStore(
          catalogFile: File('${tempDir.path}/characters.json'),
          assetDirectory: Directory('${tempDir.path}/character_assets'),
        ),
        presetLibraryStore:
            PresetLibraryStore(File('${tempDir.path}/presets.json')),
      )..markInitialized(
          deviceProfile: const DeviceProfile(
            platform: 'android',
            totalRamGb: 8,
            supportsCoreMl: false,
            supportsNnapi: false,
            supportsGpuDelegate: true,
          ),
        );
      await appState.setLocaleCode('en');
      await appState.refreshCharacters();
    });

    tearDown(() async {
      appState.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('attaches a lorebook to the selected role card and persists it',
        () async {
      final String characterId = appState.availableCharacters.first.id;
      final int existingLoreCount =
          appState.characterById(characterId).lorebook?.entries.length ?? 0;
      const LorebookImportPreview preview = LorebookImportPreview(
        fileName: 'liyue_world.json',
        lorebook: Lorebook(
          name: 'Liyue Lore',
          entries: <LorebookEntry>[
            LorebookEntry(
              id: '0',
              content: 'Zhongli should sound precise and contractual.',
              keywords: <String>['璃月', '契约'],
            ),
          ],
        ),
      );

      final CharacterCard updated = await appState.attachLorebookToCharacter(
        characterId: characterId,
        preview: preview,
      );

      expect(updated.lorebook, isNotNull);
      expect(
        updated.lorebook!.entries,
        hasLength(existingLoreCount + 1),
      );
      expect(
          updated.extensions['attached_lorebook_source'], 'liyue_world.json');
      expect(updated.extensions['attached_lorebook_mode'], 'merge');

      final CharacterCard refreshed = appState.characterById(characterId);
      expect(refreshed.lorebook, isNotNull);
      expect(refreshed.lorebook!.entries, hasLength(existingLoreCount + 1));
      expect(refreshed.extensions['user_customized'], true);
    });

    test('edits and deletes session messages while clearing summary', () async {
      final String characterId = appState.availableCharacters.first.id;
      final CharacterCard character = appState.characterById(characterId);
      await appState.engine
          .createSession(sessionId: 'edit-session', card: character);
      await appState.engine.replaceSessionMessages(
        sessionId: 'edit-session',
        messages: <ChatMessage>[
          const ChatMessage(
            id: 'user-1',
            role: ChatRole.user,
            content: 'old prompt',
          ),
          const ChatMessage(
            id: 'assistant-1',
            role: ChatRole.assistant,
            content: 'old answer',
          ),
        ],
        clearSummary: false,
      );

      final ChatSession edited = await appState.editSessionMessage(
        sessionId: 'edit-session',
        messageId: 'user-1',
        newContent: 'new prompt',
      );
      expect(edited.messages.first.content, 'new prompt');
      expect(edited.summary, isNull);

      final ChatSession deleted = await appState.deleteSessionMessage(
        sessionId: 'edit-session',
        messageId: 'assistant-1',
      );
      expect(deleted.messages, hasLength(1));
      expect(deleted.messages.single.id, 'user-1');
    });

    test('imported character is pinned to the front of the story library',
        () async {
      final CharacterCard imported = const CharacterCard(
        id: 'recent-import-card',
        name: 'Recent Import',
        description: 'Imported for ordering.',
        personality: 'Quiet.',
        scenario: 'A new scene.',
        firstMessage: 'You found me.',
        exampleDialogues: <String>[],
      ).copyWith(
        extensions: const <String, Object?>{'imported': true},
      );

      await appState.saveCharacter(imported);

      expect(appState.availableCharacters.first.id, 'recent-import-card');
    });

    test('recently opened character moves to the front of the story library',
        () async {
      final List<CharacterCard> before = appState.availableCharacters;
      expect(before.length, greaterThan(1));
      final String targetCharacterId = before[1].id;

      await appState.resolveChatSession(targetCharacterId);

      expect(appState.availableCharacters.first.id, targetCharacterId);
    });
  });
}
