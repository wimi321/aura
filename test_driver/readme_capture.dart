import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final Directory outputDirectory = Directory('docs/readme/raw')
    ..createSync(recursive: true);
  await integrationDriver(
    onScreenshot: (String screenshotName, List<int> screenshotBytes,
        [Map<String, Object?>? args]) async {
      final File image = File('${outputDirectory.path}/$screenshotName.png');
      image.writeAsBytesSync(screenshotBytes);
      return true;
    },
    writeResponseOnFailure: true,
  );
}
