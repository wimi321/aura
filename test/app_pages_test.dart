import 'dart:convert';
import 'dart:io';

import 'package:aura_app/application/providers/app_state_provider.dart';
import 'package:aura_app/backend/models/default_assets.dart';
import 'package:aura_app/backend/services/app_preferences_store.dart';
import 'package:aura_app/backend/services/character_library_store.dart';
import 'package:aura_app/backend/services/preset_library_store.dart';
import 'package:aura_app/core/theme/app_theme.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';
import 'package:aura_app/presentation/pages/character_list/character_list_page.dart';
import 'package:aura_app/presentation/pages/settings/advanced_settings_page.dart';
import 'package:aura_app/presentation/widgets/session_history_sheet.dart';
import 'package:aura_core/aura_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('Aura pages', () {
    late Directory tempDir;
    late AppStateProvider appState;
    late ModelManifest installedE2bManifest;
    late List<ModelManifest> curatedModels;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('aura_widget_test');
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
    });

    tearDown(() async {
      appState.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('character list shows all built-in characters',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          _buildTestApp(appState: appState, child: const CharacterListPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      for (final CharacterCard card in builtInCharacterLibrary) {
        await tester.scrollUntilVisible(
          find.text(card.name),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(card.name), findsOneWidget);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('character list renders imported PNG artwork on the card',
        (WidgetTester tester) async {
      final File avatarFile = File('${tempDir.path}/imported.png')
        ..writeAsBytesSync(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADElEQVR42mP8/5+hHgAHggJ/P6nxsQAAAABJRU5ErkJggg==',
          ),
        );
      final CharacterCard imported = const CharacterCard(
        id: 'imported-png-role',
        name: 'Imported PNG Role',
        description: 'Has a real PNG avatar.',
        personality: 'Scene-first.',
        scenario: 'A test scene.',
        firstMessage: 'Here is the imported art.',
        exampleDialogues: <String>[],
      ).copyWith(
        avatarPath: avatarFile.path,
        extensions: const <String, Object?>{'imported': true},
      );
      await tester.runAsync(() async {
        await appState.saveCharacter(imported);
      });

      await tester.pumpWidget(
        _buildTestApp(appState: appState, child: const CharacterListPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.scrollUntilVisible(
        find.text('Imported PNG Role'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.byKey(
            const ValueKey<String>('character-art-image-imported-png-role')),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('settings page can change locale preference',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(
          appState: appState, child: const AdvancedSettingsPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(appState.localeCode, isNull);

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('简体中文').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(appState.localeCode, 'zh');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('zh localization exposes translated copy',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...AppLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              final AppLocalizations l10n = AppLocalizations.of(context)!;
              return Column(
                children: <Widget>[
                  Text(l10n.companionsTitle),
                  Text(l10n.appTagline),
                ],
              );
            },
          ),
        ),
      );

      await tester.pump();
      expect(find.text('剧本库'), findsOneWidget);
      expect(find.text('Gemma 4 手机直接跑，不用 API，不花钱。'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('settings prompt preset section localizes for zh users',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          appState: appState,
          child: const AdvancedSettingsPage(),
          forcedLocale: const Locale('zh'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      for (int index = 0;
          index < 4 && find.text('编辑当前准则').evaluate().isEmpty;
          index += 1) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -220));
        await tester.pumpAndSettle();
      }

      expect(
        find.text('导入准则文件'),
        findsOneWidget,
        reason: _visibleTextDump(tester),
      );
      expect(find.text('编辑当前准则'), findsOneWidget);
      expect(find.text('Import JSON'), findsNothing);
      expect(find.textContaining('你将完全沉浸于当前角色设定中'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Aura 默认剧情准则').last, findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets(
        'built-in characters stay localized when stale built-in copies exist',
        (WidgetTester tester) async {
      final CharacterCard staleEnglishBuiltIn =
          builtInCharacterLibrary.first.copyWith(
        description: 'Stale English copy',
      );
      await tester.runAsync(() async {
        await appState.saveCharacter(staleEnglishBuiltIn);
        await appState.setLocaleCode('zh');
      });

      await tester.pumpWidget(
        _buildTestApp(appState: appState, child: const CharacterListPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.scrollUntilVisible(
        find.text(builtInCharacterLibraryZh.first.name),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(builtInCharacterLibraryZh.first.name), findsOneWidget);
      expect(find.text('Stale English copy'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('clear history confirmation dialog requires explicit approval',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          appState: appState,
          child: Builder(
            builder: (BuildContext context) {
              return Center(
                child: FilledButton(
                  onPressed: () {
                    showClearHistoryConfirmation(
                      context,
                      characterName: builtInCharacterLibrary.first.name,
                    );
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Clear all session history?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Clear all session history?'), findsNothing);

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Delete All'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Clear all session history?'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    test('conversation actions create a fresh session and clear history',
        () async {
      final String characterId = builtInCharacterLibrary.first.id;

      final ChatSession first =
          await appState.startNewConversation(characterId);
      final ChatSession second =
          await appState.startNewConversation(characterId);

      expect(second.id, isNot(first.id));

      final ChatSession resolved =
          await appState.resolveChatSession(characterId);
      expect(resolved.id, second.id);

      await appState.clearConversationHistory(characterId);

      final ChatSession? latest =
          await appState.engine.latestSessionForCharacter(characterId);
      expect(latest, isNull);
    });

    test('recoverActiveModel returns false when model reload fails', () async {
      final Directory recoveryDir =
          await Directory.systemTemp.createTemp('aura_recovery_failure');
      addTearDown(() async {
        if (await recoveryDir.exists()) {
          await recoveryDir.delete(recursive: true);
        }
      });

      final File modelFile = File('${recoveryDir.path}/bundled-model.task');
      await modelFile.writeAsBytes(const <int>[1, 2, 3, 4]);
      final ModelManifest manifest =
          downloadableE2bModelManifest.copyWith(localPath: modelFile.path);

      final _ReloadFailureGateway gateway = _ReloadFailureGateway();
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
        initialModel: manifest,
      );

      final AppStateProvider failureState = AppStateProvider(
        engine,
        catalogRepository: FileModelCatalogRepository(
            File('${recoveryDir.path}/catalog.json')),
        downloadManager: ModelDownloadManager(
          downloader: HttpResumableModelDownloader(
            tempDirectory: Directory('${recoveryDir.path}/downloads'),
          ),
          catalogRepository: FileModelCatalogRepository(
              File('${recoveryDir.path}/catalog.json')),
        ),
        curatedModels: <ModelManifest>[manifest],
        preferencesStore:
            AppPreferencesStore(File('${recoveryDir.path}/prefs.json')),
        characterLibraryStore: CharacterLibraryStore(
          catalogFile: File('${recoveryDir.path}/characters.json'),
          assetDirectory: Directory('${recoveryDir.path}/character_assets'),
        ),
        presetLibraryStore:
            PresetLibraryStore(File('${recoveryDir.path}/presets.json')),
      )..markInitialized(
          deviceProfile: const DeviceProfile(
            platform: 'android',
            totalRamGb: 8,
            supportsCoreMl: false,
            supportsNnapi: false,
            supportsGpuDelegate: true,
          ),
        );
      addTearDown(() => failureState.dispose());

      final bool recovered = await failureState.recoverActiveModel();

      expect(recovered, isFalse);
      expect(failureState.isRecoveringModel, isFalse);
      expect(failureState.modelState, AppModelState.error);
      expect(
        failureState.errorMessage,
        'Something went wrong. Please try again.',
      );
      expect(gateway.loadCount, 2);
    });
  });
}

Widget _buildTestApp({
  required AppStateProvider appState,
  required Widget child,
  Locale? forcedLocale,
}) {
  return ChangeNotifierProvider<AppStateProvider>.value(
    value: appState,
    child: Consumer<AppStateProvider>(
      builder: (BuildContext context, AppStateProvider value, _) {
        return MaterialApp(
          theme: AppTheme.darkTheme,
          locale: forcedLocale ?? value.localeOverride,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...AppLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        );
      },
    ),
  );
}

String _visibleTextDump(WidgetTester tester) {
  final Iterable<String> visibleTexts = tester
      .widgetList<Text>(find.byType(Text))
      .map((Text text) => text.data)
      .whereType<String>()
      .map((String value) => value.trim())
      .where((String value) => value.isNotEmpty);
  return 'Visible texts: ${visibleTexts.join(' | ')}';
}

class _ReloadFailureGateway implements InferenceGateway {
  int loadCount = 0;
  RuntimeOptions? options;

  @override
  Future<void> cancelActiveGeneration() async {}

  @override
  Future<InferenceRuntimeStatus> getRuntimeStatus() async =>
      InferenceRuntimeStatus(
        runtime: 'fake',
        primaryBackend: options?.primaryDelegate.name ?? 'cpu',
        audioInputSupported: false,
      );

  @override
  Future<void> initialize({required RuntimeOptions options}) async {
    this.options = options;
  }

  @override
  Future<void> loadModel(ModelManifest manifest) async {
    loadCount += 1;
    if (loadCount > 1) {
      throw StateError('reload failed');
    }
  }

  @override
  Stream<String> streamAudio({
    required PromptEnvelope prompt,
    required List<List<int>> audioFrames,
  }) {
    return const Stream<String>.empty();
  }

  @override
  Stream<String> streamText({required PromptEnvelope prompt}) {
    return const Stream<String>.empty();
  }

  @override
  Future<void> unloadModel() async {}
}
