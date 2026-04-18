import '../domain/device_profile.dart';
import '../domain/runtime_options.dart';

class DeviceProfileResolver {
  const DeviceProfileResolver();

  RuntimeOptions resolveRuntimeOptions(DeviceProfile profile) {
    if (profile.supportsCoreMl && profile.platform.toLowerCase() == 'ios') {
      return RuntimeOptions(
        primaryDelegate: HardwareDelegate.coreMl,
        fallbackDelegates: <HardwareDelegate>[HardwareDelegate.cpu],
        maxContextTokensOverride: profile.isLowMemoryDevice ? 2048 : null,
      );
    }
    if (profile.supportsNnapi && profile.platform.toLowerCase() == 'android') {
      return RuntimeOptions(
        primaryDelegate: HardwareDelegate.nnapi,
        fallbackDelegates: profile.supportsGpuDelegate
            ? const <HardwareDelegate>[
                HardwareDelegate.gpu,
                HardwareDelegate.cpu
              ]
            : const <HardwareDelegate>[HardwareDelegate.cpu],
        maxContextTokensOverride: profile.isLowMemoryDevice ? 2048 : null,
      );
    }
    return RuntimeOptions(
      primaryDelegate: profile.supportsGpuDelegate
          ? HardwareDelegate.gpu
          : HardwareDelegate.cpu,
      fallbackDelegates: const <HardwareDelegate>[HardwareDelegate.cpu],
      maxContextTokensOverride: profile.isLowMemoryDevice ? 2048 : null,
    );
  }
}
