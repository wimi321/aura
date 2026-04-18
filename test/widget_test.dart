import 'package:aura_app/core/theme/app_theme.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';
import 'package:aura_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bootstrap loading view localizes copy for zh users',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        locale: const Locale('zh'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BootstrapLoadingView(),
      ),
    );

    await tester.pump();

    expect(find.text('AURA'), findsOneWidget);
    expect(find.text('正在开启你的本地剧情空间...'), findsOneWidget);
  });

  testWidgets('bootstrap error view shows localized heading and raw message',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BootstrapErrorView(message: 'native runtime unavailable'),
      ),
    );

    await tester.pump();

    expect(find.text('Aura failed to launch'), findsOneWidget);
    expect(
      find.text('Aura could not finish startup. Check the details below.'),
      findsOneWidget,
    );
    expect(find.text('native runtime unavailable'), findsOneWidget);
  });
}
