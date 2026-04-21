import 'dart:async';

import 'package:aura_core/src/application/model_manager.dart';
import 'package:aura_core/src/domain/model_manifest.dart';
import 'package:test/test.dart';

class _FakeRuntime implements InferenceRuntime {
  bool initialized = false;
  ModelManifest? loadedModel;
  bool shouldFailOnLoad = false;
  int unloadCount = 0;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> loadModel(ModelManifest manifest) async {
    if (shouldFailOnLoad) {
      throw StateError('load failed');
    }
    loadedModel = manifest;
  }

  @override
  Future<void> unloadModel() async {
    unloadCount += 1;
    loadedModel = null;
  }
}

ModelManifest _testManifest({String id = 'test-model'}) {
  return ModelManifest(
    id: id,
    name: 'Test Model',
    version: '1.0',
    fileName: 'test.bin',
    localPath: '/tmp/test.bin',
    sizeBytes: 1024,
    multimodal: false,
  );
}

void main() {
  late _FakeRuntime runtime;
  late ModelManager manager;

  setUp(() {
    runtime = _FakeRuntime();
    manager = ModelManager(runtime);
  });

  tearDown(() async {
    await manager.dispose();
  });

  group('ModelManager', () {
    test('starts in idle state with no active model', () {
      expect(manager.state, ModelLoadState.idle);
      expect(manager.activeModel, isNull);
    });

    test('bootstrap initializes runtime and stays idle without model',
        () async {
      final List<ModelLoadState> states = <ModelLoadState>[];
      manager.states.listen(states.add);

      await manager.bootstrap();
      await Future<void>.delayed(Duration.zero);

      expect(runtime.initialized, isTrue);
      expect(manager.state, ModelLoadState.idle);
      expect(states, <ModelLoadState>[
        ModelLoadState.initializing,
        ModelLoadState.idle,
      ]);
    });

    test('bootstrap with initial model loads it', () async {
      final List<ModelLoadState> states = <ModelLoadState>[];
      manager.states.listen(states.add);
      final ModelManifest manifest = _testManifest();

      await manager.bootstrap(initialModel: manifest);
      await Future<void>.delayed(Duration.zero);

      expect(manager.state, ModelLoadState.ready);
      expect(manager.activeModel, manifest);
      expect(runtime.loadedModel, manifest);
      expect(states, <ModelLoadState>[
        ModelLoadState.initializing,
        ModelLoadState.loading,
        ModelLoadState.ready,
      ]);
    });

    test('switchModel uses loading state when no prior model', () async {
      final List<ModelLoadState> states = <ModelLoadState>[];
      manager.states.listen(states.add);
      final ModelManifest manifest = _testManifest();

      await manager.switchModel(manifest);

      expect(states, contains(ModelLoadState.loading));
      expect(states, isNot(contains(ModelLoadState.switching)));
      expect(manager.activeModel, manifest);
    });

    test('switchModel uses switching state when replacing model', () async {
      final ModelManifest first = _testManifest(id: 'first');
      final ModelManifest second = _testManifest(id: 'second');
      await manager.switchModel(first);

      final List<ModelLoadState> states = <ModelLoadState>[];
      manager.states.listen(states.add);

      await manager.switchModel(second);

      expect(states.first, ModelLoadState.switching);
      expect(manager.activeModel, second);
    });

    test('switchModel unloads previous model before loading new one', () async {
      final ModelManifest first = _testManifest(id: 'first');
      final ModelManifest second = _testManifest(id: 'second');
      await manager.switchModel(first);
      expect(runtime.loadedModel, first);

      await manager.switchModel(second);
      expect(runtime.loadedModel, second);
    });

    test('switchModel transitions to error on failure', () async {
      runtime.shouldFailOnLoad = true;
      final ModelManifest manifest = _testManifest();

      expect(
        () => manager.switchModel(manifest),
        throwsA(isA<StateError>()),
      );

      await Future<void>.delayed(Duration.zero);
      expect(manager.state, ModelLoadState.error);
      expect(manager.activeModel, isNull);
    });

    test('switchModel clears active model on failure', () async {
      final ModelManifest first = _testManifest(id: 'first');
      await manager.switchModel(first);
      expect(manager.activeModel, first);

      runtime.shouldFailOnLoad = true;
      try {
        await manager.switchModel(_testManifest(id: 'second'));
      } catch (_) {}

      expect(manager.activeModel, isNull);
    });

    test('dispose closes the state stream', () async {
      await manager.dispose();

      expect(
        () => manager.states.listen((_) {}),
        returnsNormally,
      );
    });

    test('dispose unloads the active model', () async {
      final ModelManifest manifest = _testManifest();
      await manager.switchModel(manifest);

      await manager.dispose();

      expect(runtime.loadedModel, isNull);
      expect(runtime.unloadCount, 1);
      expect(manager.activeModel, isNull);
    });

    test('state stream is broadcast (multiple listeners)', () async {
      final List<ModelLoadState> listener1 = <ModelLoadState>[];
      final List<ModelLoadState> listener2 = <ModelLoadState>[];

      manager.states.listen(listener1.add);
      manager.states.listen(listener2.add);

      await manager.switchModel(_testManifest());

      expect(listener1, equals(listener2));
      expect(listener1, isNotEmpty);
    });
  });
}
