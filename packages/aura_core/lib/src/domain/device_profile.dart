import 'package:meta/meta.dart';

@immutable
class DeviceProfile {
  const DeviceProfile({
    required this.platform,
    required this.totalRamGb,
    required this.supportsCoreMl,
    required this.supportsNnapi,
    required this.supportsGpuDelegate,
  });

  final String platform;
  final int totalRamGb;
  final bool supportsCoreMl;
  final bool supportsNnapi;
  final bool supportsGpuDelegate;

  bool get isLowMemoryDevice => totalRamGb <= 6;
}
