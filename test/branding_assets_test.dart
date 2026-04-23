import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('generated brand source and public logo assets are present', () {
    _expectImage('tooling/branding/aura_icon_source_generated.png', 1254, 1254);
    _expectImage('tooling/branding/aura_android_icon_master.png', 1024, 1024);
    _expectImage('docs/readme/aura-icon.png', 1024, 1024, maxBytes: 700 * 1024);
    _expectImage('assets/images/ui/eclipse-core.png', 1024, 1024,
        maxBytes: 850 * 1024);
  });

  test('Android launcher icon assets keep expected platform sizes', () {
    final Map<String, int> densities = <String, int>{
      'mipmap-mdpi': 48,
      'mipmap-hdpi': 72,
      'mipmap-xhdpi': 96,
      'mipmap-xxhdpi': 144,
      'mipmap-xxxhdpi': 192,
    };

    for (final MapEntry<String, int> density in densities.entries) {
      _expectImage(
        'android/app/src/main/res/${density.key}/ic_launcher.png',
        density.value,
        density.value,
      );
    }
    _expectImage(
      'android/app/src/main/res/drawable-nodpi/ic_launcher_foreground_art.png',
      432,
      432,
      maxBytes: 180 * 1024,
    );
  });

  test('Apple icon and launch assets keep expected platform sizes', () {
    final Map<String, Object?> iosContents = jsonDecode(
      File('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json')
          .readAsStringSync(),
    ) as Map<String, Object?>;
    for (final Object? rawItem in iosContents['images']! as List<Object?>) {
      final Map<String, Object?> item = rawItem! as Map<String, Object?>;
      final String filename = item['filename']! as String;
      final int pixels = _scaledPixels(
        item['size']! as String,
        item['scale']! as String,
      );
      _expectImage(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/$filename',
        pixels,
        pixels,
      );
    }

    final Map<String, int> launchImages = <String, int>{
      'LaunchImage.png': 168,
      'LaunchImage@2x.png': 336,
      'LaunchImage@3x.png': 504,
    };
    for (final MapEntry<String, int> entry in launchImages.entries) {
      _expectImage(
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/${entry.key}',
        entry.value,
        entry.value,
      );
    }
  });
}

int _scaledPixels(String pointSize, String scale) {
  final double points = double.parse(pointSize.split('x').first);
  final int multiplier = int.parse(scale.replaceAll('x', ''));
  return (points * multiplier).round();
}

void _expectImage(
  String path,
  int width,
  int height, {
  int? maxBytes,
}) {
  final File file = File(path);
  expect(file.existsSync(), isTrue, reason: 'Missing $path');
  if (maxBytes != null) {
    expect(file.lengthSync(), lessThan(maxBytes), reason: '$path is too large');
  }
  final img.Image? image = img.decodeImage(file.readAsBytesSync());
  expect(image, isNotNull, reason: 'Could not decode $path');
  expect(image!.width, width, reason: 'Unexpected width for $path');
  expect(image.height, height, reason: 'Unexpected height for $path');
}
