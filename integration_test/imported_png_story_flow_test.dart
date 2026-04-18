import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aura_app/application/providers/app_state_provider.dart';
import 'package:aura_app/backend/services/character_library_store.dart';
import 'package:aura_app/presentation/pages/character_list/character_list_page.dart';
import 'package:aura_core/aura_core.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:aura_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'imports a Tavern-style PNG card, pins it to the front, shows artwork, and sanitizes the opening scene',
    (WidgetTester tester) async {
      tester.binding.platformDispatcher.semanticsEnabledTestValue = false;
      addTearDown(
        tester.binding.platformDispatcher.clearSemanticsEnabledTestValue,
      );

      app.main();
      await _pumpFor(tester, const Duration(seconds: 1));

      await _waitForFinder(
        tester,
        find.byType(CharacterListPage),
        timeout: const Duration(seconds: 20),
      );

      final AppStateProvider appState = Provider.of<AppStateProvider>(
        tester.element(find.byType(CharacterListPage).first),
        listen: false,
      );

      final XFile sourceFile = (await tester.runAsync(() async {
        final Directory tempDir =
            await Directory.systemTemp.createTemp('aura_imported_png_story');
        final File file = File('${tempDir.path}/school_story_card.png');
        await file.writeAsBytes(_buildTavernPngFixture());
        return XFile(file.path);
      }))!;

      final CharacterImportPreview preview = (await tester.runAsync(
        () => appState.previewCharacterImport(File(sourceFile.path)),
      ))!;
      expect(preview.character.name, '黄昏值日纪要');
      expect(preview.hasLorebook, isTrue);

      final CharacterCard imported = (await tester.runAsync(
        () => appState.importCharacterPreview(preview),
      ))!;
      await _pumpFor(tester, const Duration(seconds: 1));

      expect(appState.availableCharacters.first.id, imported.id);

      await _waitForFinder(
        tester,
        find.text('黄昏值日纪要'),
        timeout: const Duration(seconds: 20),
      );
      expect(
        find.byKey(ValueKey<String>('character-art-image-${imported.id}')),
        findsOneWidget,
      );

      final Finder newConversationButton = find.byKey(
        ValueKey<String>('character-new-conversation-${imported.id}'),
      );
      await _waitForEnabledButton(
        tester,
        newConversationButton,
        timeout: const Duration(minutes: 3),
      );

      await tester.tap(newConversationButton);
      await _pumpFor(tester, const Duration(seconds: 1));

      await _waitForFinder(
        tester,
        find.byKey(const ValueKey<String>('chat-input-field')),
        timeout: const Duration(seconds: 20),
      );
      await _waitForFinder(
        tester,
        find.textContaining('栖川学园'),
        timeout: const Duration(seconds: 20),
      );

      expect(find.textContaining('<gametxt>'), findsNothing);
      expect(find.textContaining('<options>'), findsNothing);
      expect(find.textContaining('<chapter>'), findsNothing);
      expect(find.textContaining('{{user}}'), findsNothing);
      expect(find.textContaining('晚课观测程序'), findsOneWidget);
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

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final int steps = (duration.inMilliseconds / 100).ceil().clamp(1, 600);
  for (int index = 0; index < steps; index += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Uint8List _buildTavernPngFixture() {
  const Map<String, Object?> payload = <String, Object?>{
    'spec': 'chara_card_v3',
    'spec_version': '3.0',
    'data': <String, Object?>{
      'name': '黄昏值日纪要',
      'description': '',
      'personality': '',
      'scenario': '',
      'first_mes':
          '<gametxt>*四月的晚风擦过旧窗，玻璃上映着快要熄掉的夕照。*\\n\\n这里是栖川学园，旧实验楼三层尽头的文学影像社活动室。\\n\\n「你好，{{user}}同学。」\\n\\n【晚课观测程序，已接管今晚的值日名单。】</gametxt>\\n<options>【选项A：装作只是路过。】</options>\\n<chapter>序章</chapter>',
      'mes_example': '<START>{{char}}：别走神。\\n{{user}}：我在听。\\n<START>【系统提示】请选择。',
      'character_book': <String, Object?>{
        'name': '黄昏值日纪要',
        'entries': <Object?>[
          <String, Object?>{
            'id': 'school-club',
            'keys': <String>['栖川学园', '文学影像社', '值周会'],
            'content': '当剧情提到社团整编、值周检查或放学后的活动室时，要保持校园暧昧与青春悬念交织的节奏。',
            'priority': 10,
          },
        ],
      },
    },
  };

  return _injectTextChunkIntoValidPng(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+nmX8AAAAASUVORK5CYII=',
    ),
    keyword: 'chara',
    value: base64.encode(utf8.encode(jsonEncode(payload))),
  );
}

Uint8List _injectTextChunkIntoValidPng(
  Uint8List source, {
  required String keyword,
  required String value,
}) {
  final int iendOffset = _findIendChunkOffset(source);
  final BytesBuilder builder = BytesBuilder();
  builder.add(source.sublist(0, iendOffset));
  builder.add(
    _chunk(
      'tEXt',
      Uint8List.fromList(
        <int>[
          ...latin1.encode(keyword),
          0,
          ...latin1.encode(value),
        ],
      ),
    ),
  );
  builder.add(source.sublist(iendOffset));
  return builder.toBytes();
}

Uint8List _chunk(String type, Uint8List payload) {
  final BytesBuilder builder = BytesBuilder();
  final ByteData length = ByteData(4)..setUint32(0, payload.length);
  final Uint8List typeBytes = Uint8List.fromList(latin1.encode(type));
  final Uint8List crcInput = Uint8List.fromList(<int>[
    ...typeBytes,
    ...payload,
  ]);
  final ByteData crc = ByteData(4)..setUint32(0, _crc32(crcInput));
  builder.add(length.buffer.asUint8List());
  builder.add(typeBytes);
  builder.add(payload);
  builder.add(crc.buffer.asUint8List());
  return builder.toBytes();
}

int _crc32(Uint8List bytes) {
  int crc = 0xffffffff;
  for (final int value in bytes) {
    crc ^= value;
    for (int bit = 0; bit < 8; bit += 1) {
      final bool carry = (crc & 1) != 0;
      crc = crc >> 1;
      if (carry) {
        crc ^= 0xedb88320;
      }
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}

int _findIendChunkOffset(Uint8List bytes) {
  final ByteData data = ByteData.sublistView(bytes);
  int offset = 8;
  while (offset + 8 <= bytes.length) {
    final int chunkLength = data.getUint32(offset);
    final int typeStart = offset + 4;
    final String chunkType =
        ascii.decode(bytes.sublist(typeStart, typeStart + 4));
    if (chunkType == 'IEND') {
      return offset;
    }
    offset += 12 + chunkLength;
  }
  throw const FormatException('PNG does not contain an IEND chunk.');
}
