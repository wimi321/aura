import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:aura_app/application/providers/app_state_provider.dart';
import 'package:aura_app/backend/models/default_assets.dart';
import 'package:aura_app/backend/services/app_preferences_store.dart';
import 'package:aura_app/backend/services/character_library_store.dart';
import 'package:aura_app/backend/services/preset_library_store.dart';
import 'package:aura_app/core/theme/app_theme.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';
import 'package:aura_app/presentation/widgets/import_preview_dialog.dart';
import 'package:aura_core/aura_core.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('ImportPreviewDialog', () {
    late Directory tempDir;
    late AppStateProvider appState;
    late ModelManifest installedE2bManifest;
    late List<ModelManifest> curatedModels;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('aura_import_dialog');
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
    });

    tearDown(() async {
      appState.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('starts with a calm guidance state and waits for user action',
        (WidgetTester tester) async {
      int pickCount = 0;

      await tester.pumpWidget(
        _buildHarness(
          appState: appState,
          child: ImportPreviewDialog(
            pickFile: () async {
              pickCount += 1;
              return null;
            },
          ),
        ),
      );
      await tester.pump();

      expect(pickCount, 0);
      expect(find.text('Import Story Card'), findsOneWidget);
      expect(find.text('Choose Image or File'), findsOneWidget);

      final Finder chooseCardButton =
          find.widgetWithText(FilledButton, 'Choose Image or File');
      await tester.ensureVisible(chooseCardButton);
      await tester.tap(chooseCardButton);
      await tester.pump();

      expect(pickCount, 1);
    });

    testWidgets('shows photo and file source options before picking',
        (WidgetTester tester) async {
      final File galleryCard = File('${tempDir.path}/gallery-card.png')
        ..writeAsBytesSync(
          Uint8List.fromList(
            const <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
          ),
        );
      int filePickCount = 0;
      int photoPickCount = 0;

      await tester.pumpWidget(
        _buildHarness(
          appState: appState,
          child: ImportPreviewDialog(
            pickFile: () async {
              filePickCount += 1;
              return null;
            },
            pickPhotoFile: () async {
              photoPickCount += 1;
              return galleryCard;
            },
            previewLoader: (_) async => const CharacterImportPreview(
              fileName: 'gallery-card.png',
              character: CharacterCard(
                id: 'gallery-card',
                name: 'Gallery Card',
                description: 'Imported from the photo library.',
                personality: 'Observant.',
                scenario: 'A quiet after-school corridor.',
                firstMessage: 'You kept the picture after all.',
                exampleDialogues: <String>[],
              ),
              hasLorebook: false,
            ),
          ),
        ),
      );
      await tester.pump();

      final Finder chooseCardButton =
          find.widgetWithText(FilledButton, 'Choose Image or File');
      await tester.ensureVisible(chooseCardButton);
      await tester.tap(chooseCardButton);
      await tester.pumpAndSettle();

      expect(find.text('Choose Import Source'), findsOneWidget);
      expect(find.text('Import From Photos'), findsOneWidget);
      expect(find.text('Import From Files'), findsOneWidget);

      await tester.tap(find.text('Import From Photos'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(photoPickCount, 1);
      expect(filePickCount, 0);
    });

    testWidgets('waits for the file choice before showing parsing state',
        (WidgetTester tester) async {
      final Completer<XFile?> pickCompleter = Completer<XFile?>();
      final Completer<CharacterImportPreview> previewCompleter =
          Completer<CharacterImportPreview>();
      int previewCallCount = 0;
      CharacterCard? importedCharacter;
      const CharacterCard previewCard = CharacterCard(
        id: 'delayed-firefly',
        name: 'Delayed Firefly',
        description: 'A patient rooftop encounter.',
        personality: 'Gentle and brave.',
        scenario: 'A quiet rooftop conversation.',
        firstMessage: 'You finally found me.',
        exampleDialogues: <String>[],
      );

      await tester.pumpWidget(
        _buildDialogLauncher(
          appState: appState,
          dialogBuilder: () => ImportPreviewDialog(
            pickFile: () => pickCompleter.future,
            previewLoader: (_) {
              previewCallCount += 1;
              return previewCompleter.future;
            },
            importAction: (CharacterImportPreview preview) async =>
                preview.character,
          ),
          onResult: (CharacterCard? value) {
            importedCharacter = value;
          },
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open Import'));
      await tester.pump();
      await tester.pumpAndSettle();

      final Finder chooseCardButton =
          find.widgetWithText(FilledButton, 'Choose Image or File');
      await tester.ensureVisible(chooseCardButton);
      await tester.tap(chooseCardButton);
      await tester.pump();

      expect(previewCallCount, 0);
      expect(find.text('Parsing character card...'), findsNothing);

      pickCompleter.complete(XFile('${tempDir.path}/delayed-firefly.json'));
      await tester.pump();

      expect(previewCallCount, 1);
      expect(find.text('Parsing character card...'), findsOneWidget);

      previewCompleter.complete(
        const CharacterImportPreview(
          fileName: 'delayed-firefly.json',
          character: previewCard,
          hasLorebook: false,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Preview is now shown; confirm the import.
      final Finder confirmButton =
          find.widgetWithText(FilledButton, 'Confirm Import');
      expect(confirmButton, findsOneWidget);
      await tester.ensureVisible(confirmButton);
      await tester.tap(confirmButton);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(importedCharacter, isNotNull);
      expect(importedCharacter!.name, 'Delayed Firefly');
    });

    testWidgets('offers a manual create action and returns the created card',
        (WidgetTester tester) async {
      const CharacterCard createdCard = CharacterCard(
        id: 'custom-created-role',
        name: 'Custom Role',
        description: 'Built from scratch.',
        personality: 'Story-first.',
        scenario: 'A fresh opening scene.',
        firstMessage: 'This one started in the editor.',
        exampleDialogues: <String>[],
      );

      CharacterCard? returnedCharacter;

      await tester.pumpWidget(
        _buildDialogLauncher(
          appState: appState,
          dialogBuilder: () => ImportPreviewDialog(
            createCharacterAction: (_) async => createdCard,
          ),
          onResult: (CharacterCard? value) {
            returnedCharacter = value;
          },
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open Import'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Create Character'), findsOneWidget);

      final Finder createCharacterButton =
          find.widgetWithText(OutlinedButton, 'Create Character');
      await tester.ensureVisible(createCharacterButton);
      await tester.tap(createCharacterButton);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(returnedCharacter, isNotNull);
      expect(returnedCharacter!.id, createdCard.id);
      expect(returnedCharacter!.name, 'Custom Role');
    });

    testWidgets('imports a JSON card immediately after selection',
        (WidgetTester tester) async {
      const CharacterCard previewCard = CharacterCard(
        id: 'firefly-import-dialog',
        name: 'Firefly',
        description: 'A bright and sincere companion.',
        personality: 'Gentle and brave.',
        scenario: 'A quiet rooftop conversation.',
        firstMessage: 'You came.',
        exampleDialogues: <String>[],
        creator: 'Dialog Test',
      );
      const CharacterImportPreview preview = CharacterImportPreview(
        fileName: 'firefly.json',
        character: previewCard,
        hasLorebook: false,
      );

      CharacterCard? importedCharacter;

      await tester.pumpWidget(
        _buildDialogLauncher(
          appState: appState,
          dialogBuilder: () => ImportPreviewDialog(
            pickFile: () async => XFile('${tempDir.path}/firefly.json'),
            previewLoader: (_) async => preview,
            importAction: (CharacterImportPreview selectedPreview) async =>
                selectedPreview.character,
          ),
          onResult: (CharacterCard? value) {
            importedCharacter = value;
          },
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open Import'));
      await tester.pump();
      await tester.pumpAndSettle();

      final Finder chooseCardButton =
          find.widgetWithText(FilledButton, 'Choose Image or File');
      await tester.ensureVisible(chooseCardButton);
      await tester.tap(chooseCardButton);
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Preview is now shown; confirm the import.
      expect(find.text('Confirm Import'), findsOneWidget);
      final Finder confirmButton =
          find.widgetWithText(FilledButton, 'Confirm Import');
      await tester.ensureVisible(confirmButton);
      await tester.tap(confirmButton);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(importedCharacter, isNotNull, reason: _visibleTextDump(tester));
      expect(importedCharacter!.name, 'Firefly');
    });

    testWidgets('recognizes a standalone worldbook and offers an attach action',
        (WidgetTester tester) async {
      final File worldbookFile = File('${tempDir.path}/liyue_world.json')
        ..writeAsStringSync('{}');
      const LorebookImportPreview lorebookPreview = LorebookImportPreview(
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

      await tester.pumpWidget(
        _buildDialogLauncher(
          appState: appState,
          dialogBuilder: () => ImportPreviewDialog(
            pickFile: () async => XFile(worldbookFile.path),
            previewLoader: (_) async => throw const FormatException(
              'This JSON looks like a standalone worldbook.',
            ),
            lorebookPreviewLoader: (_) async => lorebookPreview,
          ),
          onResult: (_) {},
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open Import'));
      await tester.pump();
      await tester.pumpAndSettle();

      final Finder chooseCardButton =
          find.widgetWithText(FilledButton, 'Choose Image or File');
      await tester.ensureVisible(chooseCardButton);
      await tester.tap(chooseCardButton);
      await tester.pump();
      await _pumpUntilVisible(tester, find.text('Liyue Lore'));

      expect(
        find.text('Liyue Lore'),
        findsOneWidget,
        reason: _visibleTextDump(tester),
      );
      expect(find.text('Attach Worldbook'), findsOneWidget);
      expect(find.text('Merge Result'), findsOneWidget);
    });
  });
}

Future<void> _pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 80),
  int maxSteps = 12,
}) async {
  await _pumpUntil(
    tester,
    () => finder.evaluate().isNotEmpty,
    step: step,
    maxSteps: maxSteps,
  );
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration step = const Duration(milliseconds: 80),
  int maxSteps = 12,
}) async {
  for (int index = 0; index < maxSteps; index += 1) {
    if (condition()) {
      return;
    }
    await tester.pump(step);
  }
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

Widget _buildHarness({
  required AppStateProvider appState,
  required Widget child,
}) {
  return ChangeNotifierProvider<AppStateProvider>.value(
    value: appState,
    child: Consumer<AppStateProvider>(
      builder: (BuildContext context, AppStateProvider value, _) {
        return MaterialApp(
          theme: AppTheme.darkTheme,
          locale: value.localeOverride,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...AppLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Center(child: child)),
        );
      },
    ),
  );
}

Widget _buildDialogLauncher({
  required AppStateProvider appState,
  required Widget Function() dialogBuilder,
  required ValueChanged<CharacterCard?> onResult,
}) {
  return ChangeNotifierProvider<AppStateProvider>.value(
    value: appState,
    child: Consumer<AppStateProvider>(
      builder: (BuildContext context, AppStateProvider value, _) {
        return MaterialApp(
          theme: AppTheme.darkTheme,
          locale: value.localeOverride,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...AppLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return Center(
                  child: TextButton(
                    onPressed: () async {
                      final CharacterCard? result =
                          await showDialog<CharacterCard>(
                        context: context,
                        builder: (_) => dialogBuilder(),
                      );
                      onResult(result);
                    },
                    child: const Text('Open Import'),
                  ),
                );
              },
            ),
          ),
        );
      },
    ),
  );
}
