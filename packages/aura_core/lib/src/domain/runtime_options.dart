import 'package:meta/meta.dart';

enum HardwareDelegate { cpu, coreMl, nnapi, gpu }

@immutable
class RuntimeOptions {
  const RuntimeOptions({
    required this.primaryDelegate,
    this.fallbackDelegates = const <HardwareDelegate>[HardwareDelegate.cpu],
    this.maxContextTokensOverride,
    this.enableAudioUnderstanding = true,
  });

  final HardwareDelegate primaryDelegate;
  final List<HardwareDelegate> fallbackDelegates;
  final int? maxContextTokensOverride;
  final bool enableAudioUnderstanding;
}
