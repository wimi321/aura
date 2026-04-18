import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../domain/character_card.dart';
import 'json_character_card_parser.dart';

class PngCharacterCardParser {
  const PngCharacterCardParser();

  static const List<int> _pngSignature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
  static const JsonCharacterCardParser _jsonParser = JsonCharacterCardParser();

  CharacterCard parseBytes(Uint8List bytes, {String? avatarPath}) {
    if (bytes.length < 8 || !_matchesSignature(bytes)) {
      throw const FormatException('Input is not a PNG file.');
    }

    final Map<String, String> textChunks = _extractTextChunks(bytes);
    final String? rawPayload =
        textChunks['chara'] ?? textChunks['ccv3'] ?? textChunks['aura_card'];
    if (rawPayload == null || rawPayload.isEmpty) {
      throw const FormatException('PNG does not contain character metadata.');
    }

    final String normalizedJson = _decodeCharacterPayload(rawPayload);
    final Object? decoded = jsonDecode(normalizedJson);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Character metadata must be a JSON object.');
    }

    return _jsonParser.parseJsonObject(decoded, avatarPath: avatarPath);
  }

  bool _matchesSignature(Uint8List bytes) {
    for (int index = 0; index < _pngSignature.length; index++) {
      if (bytes[index] != _pngSignature[index]) {
        return false;
      }
    }
    return true;
  }

  Map<String, String> _extractTextChunks(Uint8List bytes) {
    final ByteData data = ByteData.sublistView(bytes);
    final Map<String, String> chunks = <String, String>{};
    int offset = 8;

    while (offset + 8 <= bytes.length) {
      final int chunkLength = data.getUint32(offset);
      final int chunkStart = offset + 4;
      final String chunkType =
          ascii.decode(bytes.sublist(chunkStart, chunkStart + 4));
      final int dataStart = chunkStart + 4;
      final int dataEnd = dataStart + chunkLength;
      if (dataEnd + 4 > bytes.length) {
        break;
      }

      final Uint8List payload =
          Uint8List.sublistView(bytes, dataStart, dataEnd);
      if (chunkType == 'tEXt') {
        final int separator = payload.indexOf(0);
        if (separator > 0) {
          final String key = latin1.decode(payload.sublist(0, separator));
          final String value = latin1.decode(payload.sublist(separator + 1));
          chunks[key] = value;
        }
      } else if (chunkType == 'iTXt') {
        final _IntlTextChunk parsed = _parseInternationalText(payload);
        chunks[parsed.keyword] = parsed.text;
      }

      offset = dataEnd + 4;
      if (chunkType == 'IEND') {
        break;
      }
    }

    return chunks;
  }

  _IntlTextChunk _parseInternationalText(Uint8List payload) {
    final int keywordEnd = payload.indexOf(0);
    if (keywordEnd < 0) {
      throw const FormatException('Malformed iTXt chunk: missing keyword null separator.');
    }
    final String keyword = utf8.decode(payload.sublist(0, keywordEnd));
    final int compressionFlag = payload[keywordEnd + 1];
    // Skip compression flag and compression method bytes.
    int index = keywordEnd + 3;
    // Skip language tag (null-terminated).
    final int langEnd = payload.indexOf(0, index);
    if (langEnd < 0) {
      throw const FormatException('Malformed iTXt chunk: missing language tag null separator.');
    }
    index = langEnd + 1;
    // Skip translated keyword (null-terminated).
    final int translatedEnd = payload.indexOf(0, index);
    if (translatedEnd < 0) {
      throw const FormatException('Malformed iTXt chunk: missing translated keyword null separator.');
    }
    index = translatedEnd + 1;
    final Uint8List textBytes = payload.sublist(index);
    if (compressionFlag != 0) {
      final List<int> decompressed = ZLibDecoder().convert(textBytes);
      return _IntlTextChunk(keyword: keyword, text: utf8.decode(decompressed));
    }
    return _IntlTextChunk(keyword: keyword, text: utf8.decode(textBytes));
  }

  String _decodeCharacterPayload(String rawPayload) {
    final String trimmed = rawPayload.trim();
    if (trimmed.startsWith('{')) {
      return trimmed;
    }

    final Uint8List bytes = base64.decode(trimmed);
    return utf8.decode(bytes);
  }
}

class _IntlTextChunk {
  const _IntlTextChunk({
    required this.keyword,
    required this.text,
  });

  final String keyword;
  final String text;
}
