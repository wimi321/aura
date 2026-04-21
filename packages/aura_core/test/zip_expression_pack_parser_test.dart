import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

void main() {
  test('parses image layers and metadata from zip bundle', () {
    const ZipExpressionPackParser parser = ZipExpressionPackParser();
    final Archive archive = Archive()
      ..addFile(ArchiveFile(
          'neutral.png', 4, Uint8List.fromList(const <int>[1, 2, 3, 4])))
      ..addFile(ArchiveFile(
          'blush_face.png', 4, Uint8List.fromList(const <int>[5, 6, 7, 8])))
      ..addFile(
        ArchiveFile(
          'manifest.json',
          18,
          utf8.encode('{"author":"Aura"}'),
        ),
      );
    final List<int> zipBytes = ZipEncoder().encode(archive);

    final ExpressionPack pack =
        parser.parseBytes(Uint8List.fromList(zipBytes), packId: 'asuna-pack');

    expect(pack.id, 'asuna-pack');
    expect(pack.layers.map((ExpressionLayer layer) => layer.label),
        containsAll(<String>['neutral', 'blush']));
    expect(pack.metadata['author'], 'Aura');
    expect(pack.coverAssetName, 'neutral.png');
  });
}
