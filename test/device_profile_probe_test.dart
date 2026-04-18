import 'package:aura_app/backend/services/device_profile_probe.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel methodChannel = MethodChannel('aura/litert');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
  });

  test('reads physical memory for iOS devices from the native bridge',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      methodChannel,
      (MethodCall call) async {
        if (call.method == 'getDeviceProfile') {
          return <String, Object?>{
            'physicalMemoryBytes': 4 * 1024 * 1024 * 1024,
          };
        }
        return null;
      },
    );

    const DeviceProfileProbe probe = DeviceProfileProbe(
      methodChannel: methodChannel,
      platformOverride: 'ios',
    );

    final profile = await probe.probe();

    expect(profile.platform, 'ios');
    expect(profile.totalRamGb, 4);
    expect(profile.supportsCoreMl, isTrue);
    expect(profile.isLowMemoryDevice, isTrue);
  });
}
