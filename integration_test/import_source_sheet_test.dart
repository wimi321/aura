import 'package:aura_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('character import exposes photo and file sources',
      (WidgetTester tester) async {
    app.main();
    await tester.pump();

    final Finder importCharacterButton = _findFirstText(<String>[
      '导入角色',
      'Import Character',
      'キャラクターを追加',
      '캐릭터 가져오기',
    ]);
    await _waitForFinder(
      tester,
      importCharacterButton,
      timeout: const Duration(minutes: 2),
    );
    await tester.ensureVisible(importCharacterButton.first);
    await tester.tap(importCharacterButton.first);
    await tester.pumpAndSettle();

    final Finder chooseImportButton = _findFirstText(<String>[
      '选择图片或文件',
      'Choose Image or File',
      '画像またはファイルを選択',
      '이미지 또는 파일 선택',
    ]);
    await _waitForFinder(
      tester,
      chooseImportButton,
      timeout: const Duration(seconds: 20),
    );
    await tester.ensureVisible(chooseImportButton.first);
    await tester.tap(chooseImportButton.first);
    await tester.pumpAndSettle();

    expect(
      _findFirstText(<String>[
        '选择导入方式',
        'Choose Import Source',
        '取り込み方法を選択',
        '가져오기 방식 선택',
      ]),
      findsOneWidget,
    );
    expect(
      _findFirstText(<String>[
        '从照片导入 PNG',
        'Import From Photos',
        '写真から取り込む',
        '사진에서 가져오기',
      ]),
      findsOneWidget,
    );
    expect(
      _findFirstText(<String>[
        '从文件导入',
        'Import From Files',
        'ファイルから取り込む',
        '파일에서 가져오기',
      ]),
      findsOneWidget,
    );
  }, semanticsEnabled: false);
}

Finder _findFirstText(List<String> candidates) {
  return find.byWidgetPredicate((Widget widget) {
    if (widget is! Text) {
      return false;
    }
    final String? data = widget.data?.trim();
    return data != null && candidates.contains(data);
  });
}

Future<void> _waitForFinder(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
  Duration step = const Duration(milliseconds: 300),
}) async {
  final DateTime deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(step);
  }
  expect(finder, findsOneWidget);
}
