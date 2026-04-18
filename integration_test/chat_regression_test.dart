import 'package:aura_app/backend/models/default_assets.dart';
import 'package:aura_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'dart:ui' as ui;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'new conversation supports resend, stop, resend, and clear history',
      (WidgetTester tester) async {
    final semantics = tester.ensureSemantics();
    try {
      app.main();
      await tester.pump();

      final String characterId = localizedBuiltInCharacterLibrary(
        ui.PlatformDispatcher.instance.locale.toLanguageTag(),
      ).first.id;
      final Finder newConversationButton = find.byKey(
        ValueKey<String>('character-new-conversation-$characterId'),
      );
      final Finder clearHistoryButton = find.byKey(
        ValueKey<String>('character-clear-history-$characterId'),
      );
      final Finder chatInputField =
          find.byKey(const ValueKey<String>('chat-input-field'));
      final Finder chatActionButton =
          find.byKey(const ValueKey<String>('chat-action-button'));
      final Finder sendIcon =
          find.byKey(const ValueKey<String>('chat-send-icon'));
      final Finder stopIcon =
          find.byKey(const ValueKey<String>('chat-stop-icon'));

      await _pumpUntilVisible(
        tester,
        newConversationButton,
        timeout: const Duration(minutes: 2),
      );
      await _pumpUntilEnabled(
        tester,
        newConversationButton,
        timeout: const Duration(minutes: 2),
      );

      await tester.tap(newConversationButton);
      await tester.pump(const Duration(milliseconds: 600));

      await _pumpUntilVisible(
        tester,
        chatInputField,
        timeout: const Duration(minutes: 2),
      );

      Future<void> sendAndWaitForFinish(String text) async {
        await tester.enterText(chatInputField, text);
        await tester.pump(const Duration(milliseconds: 150));
        await _pumpUntilEnabled(
          tester,
          chatActionButton,
          timeout: const Duration(minutes: 2),
        );

        final IconButton actionButton =
            tester.widget<IconButton>(chatActionButton);
        expect(actionButton.onPressed, isNotNull);

        await tester.tap(chatActionButton);
        await tester.pump();

        await _pumpUntilVisible(
          tester,
          stopIcon,
          timeout: const Duration(seconds: 20),
        );
        await _pumpUntilGone(
          tester,
          stopIcon,
          timeout: const Duration(minutes: 2),
        );
        expect(sendIcon, findsOneWidget);
      }

      await sendAndWaitForFinish('hello');
      await sendAndWaitForFinish('tell me more');

      await tester.enterText(chatInputField, 'pause midway');
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(chatActionButton);
      await tester.pump();

      await _pumpUntilVisible(
        tester,
        stopIcon,
        timeout: const Duration(seconds: 20),
      );
      await tester.tap(chatActionButton);
      await tester.pump();

      await _pumpUntilGone(
        tester,
        stopIcon,
        timeout: const Duration(seconds: 20),
      );
      expect(sendIcon, findsOneWidget);

      await sendAndWaitForFinish('after stop we continue');

      await _leaveChatPage(tester);

      await _pumpUntilVisible(
        tester,
        clearHistoryButton,
        timeout: const Duration(minutes: 2),
      );
      await tester.tap(clearHistoryButton);
      await tester.pump();
      await _confirmClearHistory(tester);

      await _pumpUntilVisible(
        tester,
        find.byType(SnackBar),
        timeout: const Duration(seconds: 10),
      );
    } finally {
      semantics.dispose();
    }
  });
}

Future<void> _pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
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

Future<void> _pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final DateTime deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (finder.evaluate().isEmpty) {
      return;
    }
  }
  expect(finder, findsNothing);
}

Future<void> _pumpUntilEnabled(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final DateTime deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (finder.evaluate().isEmpty) {
      continue;
    }
    final Widget widget = tester.widget(finder);
    if (widget is ButtonStyleButton && widget.onPressed != null) {
      return;
    }
    if (widget is IconButton && widget.onPressed != null) {
      return;
    }
  }
  final Widget widget = tester.widget(finder);
  if (widget is ButtonStyleButton) {
    expect(widget.onPressed, isNotNull);
    return;
  }
  if (widget is IconButton) {
    expect(widget.onPressed, isNotNull);
    return;
  }
  fail('Widget found by $finder is not a supported button type.');
}

Future<void> _leaveChatPage(WidgetTester tester) async {
  final List<Finder> candidates = <Finder>[
    find.byTooltip('返回'),
    find.byTooltip('Back'),
    find.byIcon(Icons.arrow_back_ios_new_rounded),
  ];

  for (final Finder finder in candidates) {
    if (finder.evaluate().isNotEmpty) {
      await tester.tap(finder.first);
      await tester.pump(const Duration(milliseconds: 600));
      return;
    }
  }

  fail('No supported back control found on chat page.');
}

Future<void> _confirmClearHistory(WidgetTester tester) async {
  final List<Finder> candidates = <Finder>[
    find.text('确认清空'),
    find.text('Delete All'),
  ];

  for (final Finder finder in candidates) {
    if (finder.evaluate().isNotEmpty) {
      await tester.tap(finder.first);
      await tester.pump(const Duration(milliseconds: 600));
      return;
    }
  }

  fail('No clear-history confirmation action found.');
}
