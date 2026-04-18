import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart' as image_picker;

class CharacterCardPhotoPicker {
  const CharacterCardPhotoPicker({MethodChannel? methodChannel})
      : _methodChannel = methodChannel ?? const MethodChannel('aura/litert');

  final MethodChannel _methodChannel;

  Future<File?> pick() async {
    if (Platform.isIOS) {
      try {
        final String? path =
            await _methodChannel.invokeMethod<String>('pickCharacterCardPhoto');
        if (path == null || path.isEmpty) {
          return null;
        }
        return File(path);
      } on MissingPluginException {
        // Fall back to the cross-platform picker if the native bridge is
        // unavailable in tests or on an older install.
      }
    }

    final image_picker.XFile? picked =
        await image_picker.ImagePicker().pickImage(
      source: image_picker.ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (picked == null) {
      return null;
    }
    return File(picked.path);
  }
}
