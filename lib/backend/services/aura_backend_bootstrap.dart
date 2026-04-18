import 'dart:io';

import 'package:aura_core/aura_core.dart';
import 'package:path_provider/path_provider.dart';

import '../models/default_assets.dart';
import 'app_preferences_store.dart';
import 'character_library_store.dart';
import 'device_profile_probe.dart';
import 'litert_method_channel_gateway.dart';
import 'preset_library_store.dart';

class AuraBackendContext {
  AuraBackendContext({
    required this.engine,
    required this.deviceProfile,
    required this.catalogRepository,
    required this.downloadManager,
    required this.curatedModels,
    required this.preferencesStore,
    required this.characterLibraryStore,
    required this.presetLibraryStore,
  });

  final AuraEngine engine;
  final DeviceProfile deviceProfile;
  final FileModelCatalogRepository catalogRepository;
  final ModelDownloadManager downloadManager;
  final List<ModelManifest> curatedModels;
  final AppPreferencesStore preferencesStore;
  final CharacterLibraryStore characterLibraryStore;
  final PresetLibraryStore presetLibraryStore;
}

class AuraBackendBootstrap {
  AuraBackendBootstrap({
    DeviceProfileProbe deviceProfileProbe = const DeviceProfileProbe(),
  }) : _deviceProfileProbe = deviceProfileProbe;

  final DeviceProfileProbe _deviceProfileProbe;

  Future<AuraBackendContext> createContext() async {
    final Directory supportDirectory = await getApplicationSupportDirectory();
    final Directory sessionsDirectory =
        Directory('${supportDirectory.path}/sessions');
    final Directory downloadTempDirectory =
        Directory('${supportDirectory.path}/downloads');
    final File catalogFile =
        File('${supportDirectory.path}/model_catalog.json');
    final File preferencesFile =
        File('${supportDirectory.path}/app_preferences.json');
    final File charactersFile =
        File('${supportDirectory.path}/characters.json');
    final File presetsFile = File('${supportDirectory.path}/presets.json');
    final Directory characterAssetDirectory =
        Directory('${supportDirectory.path}/character_assets');
    final FileModelCatalogRepository catalogRepository =
        FileModelCatalogRepository(catalogFile);
    final AppPreferencesStore preferencesStore =
        AppPreferencesStore(preferencesFile);
    final CharacterLibraryStore characterLibraryStore = CharacterLibraryStore(
      catalogFile: charactersFile,
      assetDirectory: characterAssetDirectory,
    );
    final PresetLibraryStore presetLibraryStore =
        PresetLibraryStore(presetsFile);

    final List<ModelManifest> curatedModels = curatedModelLibrary
        .map(
          (ModelManifest manifest) => manifest.copyWith(
            localPath: '${supportDirectory.path}/${manifest.fileName}',
          ),
        )
        .toList(growable: false);

    for (final ModelManifest manifest in curatedModels) {
      await catalogRepository.upsert(manifest);
    }

    final InferenceGateway gateway = _buildGateway();
    final AuraEngine engine = AuraEngine(
      gateway: gateway,
      sessionRepository: FileSessionRepository(sessionsDirectory),
      orchestrator: ChatOrchestrator(
        defaultPreset: const Preset.defaultRoleplay(),
        contextWindowProfile: const ContextWindowProfile(
          maxTokens: 2048,
          summaryTriggerRatio: 0.55,
          lowMemoryMaxTokens: 1024,
        ),
      ),
      summarizer: const HeuristicSummarizer(),
    );

    final DeviceProfile profile = await _deviceProfileProbe.probe();
    final ModelDownloadManager downloadManager = ModelDownloadManager(
      downloader:
          HttpResumableModelDownloader(tempDirectory: downloadTempDirectory),
      catalogRepository: catalogRepository,
    );

    return AuraBackendContext(
      engine: engine,
      deviceProfile: profile,
      catalogRepository: catalogRepository,
      downloadManager: downloadManager,
      curatedModels: curatedModels,
      preferencesStore: preferencesStore,
      characterLibraryStore: characterLibraryStore,
      presetLibraryStore: presetLibraryStore,
    );
  }

  Future<AuraEngine> createEngine() async {
    return (await createContext()).engine;
  }

  InferenceGateway _buildGateway() {
    if (const bool.fromEnvironment('AURA_USE_FAKE_GATEWAY',
        defaultValue: false)) {
      return FakeInferenceGateway();
    }
    if (!Platform.isAndroid && !Platform.isIOS) {
      return FakeInferenceGateway();
    }
    return LiteRtMethodChannelGateway();
  }
}
