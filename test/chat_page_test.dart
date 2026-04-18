import 'dart:async';
import 'dart:io';

import 'package:aura_app/application/providers/app_state_provider.dart';
import 'package:aura_app/backend/models/default_assets.dart';
import 'package:aura_app/backend/services/app_preferences_store.dart';
import 'package:aura_app/backend/services/character_library_store.dart';
import 'package:aura_app/backend/services/preset_library_store.dart';
import 'package:aura_app/core/theme/app_theme.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';
import 'package:aura_app/presentation/pages/chat/chat_page.dart';
import 'package:aura_core/aura_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('Aura chat page', () {
    late Directory tempDir;
    late AppStateProvider appState;
    late _ControllableInferenceGateway gateway;
    late ModelManifest installedE2bManifest;
    late List<ModelManifest> curatedModels;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('aura_chat_widget_test');
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
      gateway = _ControllableInferenceGateway();
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
      await gateway.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('send button returns to send state after stream completion',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          appState: appState,
          child: ChatPage(characterId: builtInCharacterLibrary.first.id),
        ),
      );
      await tester.pump();
      await _waitForChatReady(tester);

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();
      await tester.tap(_findComposerActionButton());
      await tester.pump();

      expect(_composerActionIcon(tester), Icons.stop_rounded);

      gateway.latestController.add('Reply received.');
      await gateway.latestController.close();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const ValueKey<String>('chat-stop-icon')),
        findsNothing,
      );
      expect(_composerActionIcon(tester), Icons.arrow_upward_rounded);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('stop button cancels generation and allows sending again',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          appState: appState,
          child: ChatPage(characterId: builtInCharacterLibrary.first.id),
        ),
      );
      await tester.pump();
      await _waitForChatReady(tester);

      await tester.enterText(find.byType(TextField), 'first');
      await tester.pump();
      await tester.tap(_findComposerActionButton());
      await tester.pump();

      expect(_composerActionIcon(tester), Icons.stop_rounded);

      await tester.tap(_findComposerActionButton());
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(gateway.cancelCount, 1);
      expect(_composerActionIcon(tester), Icons.arrow_upward_rounded);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    test('preferred session id restores an older branch', () async {
      final String characterId = builtInCharacterLibrary.first.id;
      final ChatSession first =
          await appState.startNewConversation(characterId);
      await appState.engine.replaceSessionMessages(
        sessionId: first.id,
        messages: <ChatMessage>[
          ChatMessage(
            id: 'first-branch',
            role: ChatRole.assistant,
            content: 'first branch preview',
            createdAt: DateTime.now(),
          ),
        ],
      );
      final ChatSession second =
          await appState.startNewConversation(characterId);
      await appState.engine.replaceSessionMessages(
        sessionId: second.id,
        messages: <ChatMessage>[
          ChatMessage(
            id: 'second-branch',
            role: ChatRole.assistant,
            content: 'second branch preview',
            createdAt: DateTime.now(),
          ),
        ],
      );

      final ChatSession resolved = await appState.resolveChatSession(
        characterId,
        preferredSessionId: first.id,
      );

      expect(resolved.id, first.id);
      expect(
        resolved.messages.where((ChatMessage message) {
          return message.role == ChatRole.assistant &&
              message.content == 'first branch preview';
        }),
        isNotEmpty,
      );
    });

    testWidgets(
        'chat overflow can start a new conversation and clear history after confirmation',
        (WidgetTester tester) async {
      final String characterId = builtInCharacterLibrary.first.id;

      await tester.pumpWidget(
        _buildTestApp(
          appState: appState,
          child: ChatPage(characterId: characterId),
        ),
      );
      await tester.pump();
      await _waitForChatReady(tester);

      expect(
        await appState.engine.listSessionsForCharacter(characterId),
        hasLength(1),
      );

      await tester
          .tap(find.byKey(const ValueKey<String>('chat-overflow-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(
        find.byKey(const ValueKey<String>('chat-menu-new-conversation')).last,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        await appState.engine.listSessionsForCharacter(characterId),
        hasLength(2),
      );

      await tester
          .tap(find.byKey(const ValueKey<String>('chat-overflow-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(
        find.byKey(const ValueKey<String>('chat-menu-clear-history')).last,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Clear all session history?'), findsOneWidget);
      await tester.tap(find.text('Delete All'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        await appState.engine.listSessionsForCharacter(characterId),
        hasLength(1),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('runtime failure auto-recovers and unlocks sending',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          appState: appState,
          child: ChatPage(characterId: builtInCharacterLibrary.first.id),
        ),
      );
      await tester.pump();
      await _waitForChatReady(tester);

      expect(gateway.loadCount, 1);
      gateway.nextTextError = StateError('native stream failed');

      await tester.enterText(find.byType(TextField), 'please recover');
      await tester.pump();
      await tester.tap(_findComposerActionButton());
      await tester.pump();

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(gateway.unloadCount, 1);
      expect(gateway.loadCount, 2);
      expect(_composerActionIcon(tester), Icons.arrow_upward_rounded);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets(
        'continue button advances the scene without adding a visible user bubble',
        (WidgetTester tester) async {
      final String characterId = builtInCharacterLibrary.first.id;

      await tester.pumpWidget(
        _buildTestApp(
          appState: appState,
          child: ChatPage(characterId: characterId),
        ),
      );
      await tester.pump();
      await _waitForChatReady(tester);

      await tester
          .tap(find.byKey(const ValueKey<String>('chat-continue-button')));
      await tester.pump();

      gateway.latestController.add('The scene pushes forward.');
      await gateway.latestController.close();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Continue the current scene'), findsNothing);

      final ChatSession? session =
          await appState.engine.latestSessionForCharacter(characterId);
      expect(session, isNotNull);
      final ChatSession persistedSession = session!;
      expect(
        persistedSession.messages
            .where((ChatMessage message) => message.role == ChatRole.assistant)
            .last
            .content,
        'The scene pushes forward.',
      );
      expect(
        persistedSession.messages.where(
          (ChatMessage message) =>
              message.metadata['hidden_action'] == 'continue_scene',
        ),
        isEmpty,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('assistant messages can be edited from long press actions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          appState: appState,
          child: ChatPage(characterId: builtInCharacterLibrary.first.id),
        ),
      );
      await tester.pump();
      await _waitForChatReady(tester);

      await tester.longPress(
        find.byKey(const ValueKey<String>('chat-message-assistant-bootstrap')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Edit this message'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(
          find.byType(TextField).last, 'The story begins here.');
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('The story begins here.'), findsOneWidget);
      expect(find.text('Message updated.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}

Widget _buildTestApp({
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
          home: child,
        );
      },
    ),
  );
}

Finder _findComposerActionButton() {
  return find.byKey(const ValueKey<String>('chat-action-button'));
}

IconData? _composerActionIcon(WidgetTester tester) {
  final IconButton button =
      tester.widget<IconButton>(_findComposerActionButton());
  final Widget icon = button.icon;
  if (icon is! Icon) {
    return null;
  }
  return icon.icon;
}

Future<void> _waitForChatReady(WidgetTester tester) async {
  for (int attempt = 0; attempt < 40; attempt += 1) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump(const Duration(milliseconds: 100));
    final Iterable<Element> fields = find.byType(TextField).evaluate();
    if (fields.isEmpty) {
      continue;
    }
    final TextField textField =
        tester.widget<TextField>(find.byType(TextField).first);
    if (textField.enabled ?? true) {
      return;
    }
  }
  fail('Chat page did not finish bootstrapping in time.');
}

class _ControllableInferenceGateway implements InferenceGateway {
  RuntimeOptions? options;
  int cancelCount = 0;
  int loadCount = 0;
  int unloadCount = 0;
  Object? nextTextError;
  final List<StreamController<String>> _controllers =
      <StreamController<String>>[];

  StreamController<String> get latestController => _controllers.last;

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
  Future<void> cancelActiveGeneration() async {
    cancelCount += 1;
    if (_controllers.isNotEmpty && !_controllers.last.isClosed) {
      await _controllers.last.close();
    }
  }

  @override
  Future<void> loadModel(ModelManifest manifest) async {
    loadCount += 1;
  }

  @override
  Stream<String> streamAudio(
      {required PromptEnvelope prompt, required List<List<int>> audioFrames}) {
    return const Stream<String>.empty();
  }

  @override
  Stream<String> streamText({required PromptEnvelope prompt}) {
    final StreamController<String> controller = StreamController<String>();
    _controllers.add(controller);
    final Object? pendingError = nextTextError;
    nextTextError = null;
    if (pendingError != null) {
      Future<void>.microtask(() async {
        controller.addError(pendingError);
        await controller.close();
      });
    }
    return controller.stream;
  }

  @override
  Future<void> unloadModel() async {
    unloadCount += 1;
  }

  Future<void> dispose() async {
    for (final StreamController<String> controller in _controllers) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
  }
}
