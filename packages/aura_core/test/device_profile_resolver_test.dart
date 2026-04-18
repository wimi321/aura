import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

void main() {
  test('prefers CoreML on iOS', () {
    const DeviceProfileResolver resolver = DeviceProfileResolver();
    final RuntimeOptions options = resolver.resolveRuntimeOptions(
      const DeviceProfile(
        platform: 'ios',
        totalRamGb: 8,
        supportsCoreMl: true,
        supportsNnapi: false,
        supportsGpuDelegate: true,
      ),
    );

    expect(options.primaryDelegate, HardwareDelegate.coreMl);
  });

  test('reduces context on low memory iOS devices', () {
    const DeviceProfileResolver resolver = DeviceProfileResolver();
    final RuntimeOptions options = resolver.resolveRuntimeOptions(
      const DeviceProfile(
        platform: 'ios',
        totalRamGb: 4,
        supportsCoreMl: true,
        supportsNnapi: false,
        supportsGpuDelegate: true,
      ),
    );

    expect(options.primaryDelegate, HardwareDelegate.coreMl);
    expect(options.maxContextTokensOverride, 2048);
  });

  test('reduces context on low memory devices', () {
    const DeviceProfileResolver resolver = DeviceProfileResolver();
    final RuntimeOptions options = resolver.resolveRuntimeOptions(
      const DeviceProfile(
        platform: 'android',
        totalRamGb: 4,
        supportsCoreMl: false,
        supportsNnapi: false,
        supportsGpuDelegate: false,
      ),
    );

    expect(options.primaryDelegate, HardwareDelegate.cpu);
    expect(options.maxContextTokensOverride, 2048);
  });
}
