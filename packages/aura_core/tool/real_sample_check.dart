import 'dart:io';
import 'package:aura_core/aura_core.dart';

void main() async {
  const JsonLorebookParser lorebookParser = JsonLorebookParser();
  const PngCharacterCardParser pngParser = PngCharacterCardParser();

  final File worldbookFile = File('/tmp/SillyTavern/default/content/Eldoria.json');
  final worldbook = lorebookParser.parseString(await worldbookFile.readAsString());
  print('worldbook:${worldbook.name}|entries:${worldbook.entries.length}|first:${worldbook.entries.first.id}');

  final File cardFile = File('/tmp/SillyTavern/default/content/default_Seraphina.png');
  try {
    final card = pngParser.parseBytes(await cardFile.readAsBytes(), avatarPath: cardFile.path);
    print('card:${card.name}|lore:${card.lorebook?.entries.length ?? 0}');
  } catch (error) {
    print('card_error:$error');
  }
}
