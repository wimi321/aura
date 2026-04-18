import 'dart:ui' as ui;

import 'package:aura_app/backend/models/default_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:aura_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real device chat flow covers send, stop, and resend',
      (WidgetTester tester) async {
    tester.binding.platformDispatcher.semanticsEnabledTestValue = false;
    addTearDown(
        tester.binding.platformDispatcher.clearSemanticsEnabledTestValue);

    app.main();
    await _pumpFor(tester, const Duration(seconds: 1));

    final String characterId = localizedBuiltInCharacterLibrary(
      ui.PlatformDispatcher.instance.locale.toLanguageTag(),
    ).first.id;
    final Finder newConversationButton = find.byKey(
      ValueKey<String>('character-new-conversation-$characterId'),
    );
    await _waitForFinder(
      tester,
      newConversationButton,
      timeout: const Duration(seconds: 20),
    );
    await _waitForEnabledButton(
      tester,
      newConversationButton,
      timeout: const Duration(minutes: 3),
    );
    await tester.tap(newConversationButton);
    await _pumpFor(tester, const Duration(seconds: 1));

    final Finder chatInput = find.byKey(
      const ValueKey<String>('chat-input-field'),
    );
    final Finder actionButton = find.byKey(
      const ValueKey<String>('chat-action-button'),
    );
    await _waitForFinder(
      tester,
      chatInput,
      timeout: const Duration(seconds: 20),
    );
    await _waitForEnabledTextField(
      tester,
      chatInput,
      timeout: const Duration(seconds: 20),
    );

    const String firstPrompt = '请保持当前角色口吻，连续写出至少12句对白和动作描写来开启这段剧情，每句单独一行，不要总结。';
    await tester.enterText(chatInput, firstPrompt);
    await tester.pump(const Duration(milliseconds: 300));
    await _waitForEnabledButton(
      tester,
      actionButton,
      timeout: const Duration(seconds: 20),
    );
    await tester.tap(actionButton);
    await tester.pump(const Duration(milliseconds: 150));
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey<String>('chat-stop-icon')),
      timeout: const Duration(seconds: 20),
      step: const Duration(milliseconds: 100),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.tap(actionButton);
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey<String>('chat-send-icon')),
      timeout: const Duration(seconds: 20),
    );
    expect(find.text(firstPrompt), findsOneWidget);

    const String secondPrompt = '请以“【回执】”开头，继续当前剧情一句。';
    await tester.enterText(chatInput, secondPrompt);
    await tester.pump(const Duration(milliseconds: 300));
    await _waitForEnabledButton(
      tester,
      actionButton,
      timeout: const Duration(seconds: 20),
    );
    await tester.tap(actionButton);
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey<String>('chat-stop-icon')),
      timeout: const Duration(seconds: 20),
      step: const Duration(milliseconds: 100),
    );

    await _waitForFinder(
      tester,
      find.byKey(const ValueKey<String>('chat-send-icon')),
      timeout: const Duration(minutes: 2),
    );

    expect(find.text(secondPrompt), findsOneWidget);
    expect(find.textContaining('【回执】'), findsWidgets);
  }, semanticsEnabled: false);
}

Future<void> _waitForFinder(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
  Duration step = const Duration(milliseconds: 500),
}) async {
  final DateTime deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(step);
  }
  fail('Timed out waiting for finder: $finder');
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
    await tester.pump(const Duration(milliseconds: 500));
  }
  fail('Timed out waiting for enabled button: $finder');
}

Future<void> _waitForEnabledTextField(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
}) async {
  final DateTime deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (finder.evaluate().isNotEmpty) {
      final Widget widget = tester.widget(finder.first);
      if (widget is TextField && widget.enabled != false) {
        return;
      }
    }
    await tester.pump(const Duration(milliseconds: 500));
  }
  fail('Timed out waiting for enabled text field: $finder');
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final int steps = (duration.inMilliseconds / 100).ceil().clamp(1, 600);
  for (int index = 0; index < steps; index += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
