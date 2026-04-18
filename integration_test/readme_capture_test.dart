import 'dart:io';

import 'package:aura_app/application/providers/app_state_provider.dart';
import 'package:aura_app/main.dart' as app;
import 'package:aura_app/presentation/pages/character_list/character_list_page.dart';
import 'package:aura_app/presentation/pages/model_setup/model_setup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'captures README media screenshots',
    (WidgetTester tester) async {
      tester.binding.platformDispatcher.semanticsEnabledTestValue = false;
      addTearDown(
        tester.binding.platformDispatcher.clearSemanticsEnabledTestValue,
      );

      app.main();
      await _pumpFor(tester, const Duration(seconds: 2));

      await _waitForFinder(
        tester,
        find.byType(ModelSetupPage),
        timeout: const Duration(seconds: 30),
      );

      final AppStateProvider appState = Provider.of<AppStateProvider>(
        tester.element(find.byType(ModelSetupPage).first),
        listen: false,
      );

      await tester.runAsync(() async {
        await appState.refreshModels();
        await appState.setLocaleCode('en');
      });
      await _pumpFor(tester, const Duration(seconds: 2));

      await binding.takeScreenshot('model-setup-raw');

      final manifest = appState.availableModels.first;
      await tester.runAsync(() async {
        final File file = File(manifest.localPath);
        await file.parent.create(recursive: true);
        if (!await file.exists()) {
          await file.writeAsBytes(const <int>[]);
        }
        await appState.refreshModels();
        await appState.switchModel(manifest);
      });
      await _pumpFor(tester, const Duration(seconds: 2));

      GoRouter.of(tester.element(find.byType(ModelSetupPage).first))
          .go('/characters');
      await _pumpFor(tester, const Duration(seconds: 2));

      await _waitForFinder(
        tester,
        find.byType(CharacterListPage),
        timeout: const Duration(seconds: 20),
      );
      await _pumpFor(tester, const Duration(seconds: 2));
      await binding.takeScreenshot('story-library-raw');

      final Finder importCharacterButton =
          find.byKey(const ValueKey<String>('character-import-button'));
      await _waitForFinder(
        tester,
        importCharacterButton,
        timeout: const Duration(seconds: 20),
      );
      await tester.ensureVisible(importCharacterButton.first);
      await tester.tap(importCharacterButton.first);
      await _pumpFor(tester, const Duration(seconds: 1));

      final Finder chooseImportButton = find.byKey(
        const ValueKey<String>('import-dialog-open-picker-button'),
      );
      await _waitForFinder(
        tester,
        chooseImportButton,
        timeout: const Duration(seconds: 20),
      );
      await tester.ensureVisible(chooseImportButton.first);
      await _pumpFor(tester, const Duration(milliseconds: 300));
      await tester.tap(chooseImportButton.first);
      await _pumpFor(tester, const Duration(seconds: 1));

      final Finder importSourceSheetTitle =
          find.byKey(const ValueKey<String>('import-source-sheet-title'));
      await _waitForFinder(
        tester,
        importSourceSheetTitle,
        timeout: const Duration(seconds: 20),
      );
      await binding.takeScreenshot('import-flow-raw');
      Navigator.of(tester.element(importSourceSheetTitle.first)).pop();
      await _pumpFor(tester, const Duration(milliseconds: 600));
      Navigator.of(tester.element(find.byType(Dialog).first)).pop();
      await _pumpFor(tester, const Duration(seconds: 1));

      final String characterId = appState.availableCharacters.first.id;
      final Finder newConversationButton = find.byKey(
        ValueKey<String>('character-new-conversation-$characterId'),
      );
      await _waitForEnabledButton(
        tester,
        newConversationButton,
        timeout: const Duration(seconds: 20),
      );
      await tester.ensureVisible(newConversationButton);
      await tester.tap(newConversationButton);
      await _pumpFor(tester, const Duration(seconds: 1));

      final Finder chatInputField =
          find.byKey(const ValueKey<String>('chat-input-field'));

      await _waitForFinder(
        tester,
        chatInputField,
        timeout: const Duration(seconds: 20),
      );
      await _pumpFor(tester, const Duration(seconds: 2));
      await binding.takeScreenshot('chat-scene-raw');
    },
    semanticsEnabled: false,
  );
}

Future<void> _waitForFinder(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
  Duration step = const Duration(milliseconds: 250),
}) async {
  final DateTime deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  expect(finder, findsOneWidget);
}

Future<void> _waitForEnabledButton(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
}) async {
  final DateTime deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (finder.evaluate().isNotEmpty) {
      final Widget widget = tester.widget(finder.first);
      if (widget is ButtonStyleButton && widget.onPressed != null) {
        return;
      }
      if (widget is IconButton && widget.onPressed != null) {
        return;
      }
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('Timed out waiting for enabled button: $finder');
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final int steps = (duration.inMilliseconds / 100).ceil().clamp(1, 600);
  for (int index = 0; index < steps; index += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
