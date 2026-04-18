import 'dart:async';

import '../domain/model_manifest.dart';

abstract interface class InferenceRuntime {
  Future<void> initialize();
  Future<void> loadModel(ModelManifest manifest);
  Future<void> unloadModel();
}

enum ModelLoadState { idle, initializing, loading, ready, switching, error }

class ModelManager {
  ModelManager(this._runtime);

  final InferenceRuntime _runtime;
  final StreamController<ModelLoadState> _stateController = StreamController<ModelLoadState>.broadcast();

  ModelManifest? _activeModel;
  ModelLoadState _state = ModelLoadState.idle;

  Stream<ModelLoadState> get states => _stateController.stream;
  ModelManifest? get activeModel => _activeModel;
  ModelLoadState get state => _state;

  Future<void> bootstrap({ModelManifest? initialModel}) async {
    _emit(ModelLoadState.initializing);
    await _runtime.initialize();
    if (initialModel != null) {
      await switchModel(initialModel);
      return;
    }
    _emit(ModelLoadState.idle);
  }

  Future<void> switchModel(ModelManifest manifest) async {
    _emit(_activeModel == null ? ModelLoadState.loading : ModelLoadState.switching);
    try {
      if (_activeModel != null) {
        await _runtime.unloadModel();
      }
      await _runtime.loadModel(manifest);
      _activeModel = manifest;
      _emit(ModelLoadState.ready);
    } catch (_) {
      _emit(ModelLoadState.error);
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _stateController.close();
  }

  void _emit(ModelLoadState next) {
    _state = next;
    _stateController.add(next);
  }
}
