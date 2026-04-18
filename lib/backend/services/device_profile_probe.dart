import 'dart:io';

import 'package:aura_core/aura_core.dart';
import 'package:flutter/services.dart';

class DeviceProfileProbe {
  const DeviceProfileProbe({
    MethodChannel? methodChannel,
    String? platformOverride,
  })  : _methodChannel = methodChannel ?? const MethodChannel('aura/litert'),
        _platformOverride = platformOverride;

  final MethodChannel _methodChannel;
  final String? _platformOverride;

  Future<DeviceProfile> probe() async {
    final String platform;
    if (_platformOverride != null && _platformOverride!.isNotEmpty) {
      platform = _platformOverride!;
    } else if (Platform.isIOS) {
      platform = 'ios';
    } else if (Platform.isAndroid) {
      platform = 'android';
    } else if (Platform.isMacOS) {
      platform = 'macos';
    } else {
      platform = Platform.operatingSystem;
    }

    return DeviceProfile(
      platform: platform,
      totalRamGb: await _estimateTotalRamGb(platform),
      supportsCoreMl: Platform.isIOS || Platform.isMacOS,
      // Prefer stable GPU/CPU startup until we have a verified native NNAPI
      // capability probe instead of assuming every Android device supports it.
      supportsNnapi: false,
      supportsGpuDelegate: true,
    );
  }

  Future<int> _estimateTotalRamGb(String platform) async {
    if (platform == 'ios') {
      final int? physicalMemoryBytes = await _probePhysicalMemoryBytes();
      if (physicalMemoryBytes != null && physicalMemoryBytes > 0) {
        const int gib = 1024 * 1024 * 1024;
        return (physicalMemoryBytes / gib).ceil();
      }
      return 8;
    }
    if (platform == 'android') {
      return 8;
    }
    return 16;
  }

  Future<int?> _probePhysicalMemoryBytes() async {
    try {
      final Map<Object?, Object?>? response = await _methodChannel
          .invokeMethod<Map<Object?, Object?>>('getDeviceProfile');
      final Object? physicalMemoryBytes = response?['physicalMemoryBytes'];
      if (physicalMemoryBytes is int) {
        return physicalMemoryBytes;
      }
      if (physicalMemoryBytes is num) {
        return physicalMemoryBytes.toInt();
      }
      return int.tryParse(physicalMemoryBytes?.toString() ?? '');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
