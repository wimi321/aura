import 'dart:convert';
import 'dart:io';

import 'package:aura_core/aura_core.dart';

class PresetLibraryStore {
  PresetLibraryStore(this._file);

  final File _file;
  static const JsonPresetParser _parser = JsonPresetParser();

  Future<List<Preset>> loadPresets() async {
    if (!await _file.exists()) {
      return const <Preset>[];
    }
    final Object? decoded = jsonDecode(await _file.readAsString());
    final List<Object?> items = decoded is List ? decoded : const <Object?>[];
    return items
        .whereType<Map>()
        .map((Map item) => _presetFromJson(item.cast<String, Object?>()))
        .toList(growable: false);
  }

  Future<Preset> importPresetFile(File sourceFile, {List<Preset> existing = const <Preset>[]}) async {
    final Preset parsed = _parser.parse(await sourceFile.readAsString());
    final String id = _uniqueId(parsed.id, existing);
    final Preset normalized = Preset(
      id: id,
      name: parsed.name,
      systemPromptTemplate: parsed.systemPromptTemplate,
      generationConfig: parsed.generationConfig,
      metadata: <String, Object?>{
        ...parsed.metadata,
        'imported': true,
        'source_file': sourceFile.uri.pathSegments.isEmpty ? sourceFile.path : sourceFile.uri.pathSegments.last,
      },
    );
    final List<Preset> next = <Preset>[
      ...existing.where((Preset preset) => preset.id != normalized.id),
      normalized,
    ];
    await _save(next);
    return normalized;
  }

  Future<Preset> savePreset(Preset preset, {List<Preset> existing = const <Preset>[]}) async {
    final List<Preset> next = <Preset>[
      ...existing.where((Preset item) => item.id != preset.id),
      preset,
    ];
    await _save(next);
    return preset;
  }

  Future<void> _save(List<Preset> presets) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        presets.map((Preset preset) => _presetToJson(preset)).toList(growable: false),
      ),
    );
  }

  String _uniqueId(String base, List<Preset> existing) {
    final Set<String> ids = existing.map((Preset preset) => preset.id).toSet();
    if (!ids.contains(base)) {
      return base;
    }
    int suffix = 2;
    while (ids.contains('$base-$suffix')) {
      suffix++;
    }
    return '$base-$suffix';
  }

  Map<String, Object?> _presetToJson(Preset preset) {
    return <String, Object?>{
      'id': preset.id,
      'name': preset.name,
      'system_prompt': preset.systemPromptTemplate,
      'generation': preset.generationConfig.toJson(),
      'metadata': preset.metadata,
    };
  }

  Preset _presetFromJson(Map<String, Object?> json) {
    final Map<String, Object?> generation = (json['generation'] as Map?)?.cast<String, Object?>() ?? const <String, Object?>{};
    return Preset(
      id: json['id']?.toString() ?? 'imported-preset',
      name: json['name']?.toString() ?? 'Imported Preset',
      systemPromptTemplate: json['system_prompt']?.toString() ?? const Preset.defaultRoleplay().systemPromptTemplate,
      generationConfig: GenerationConfig(
        temperature: (generation['temperature'] as num?)?.toDouble() ?? 0.85,
        topP: (generation['top_p'] as num?)?.toDouble() ?? 0.9,
        topK: (generation['top_k'] as num?)?.toInt() ?? 40,
        maxOutputTokens: (generation['max_output_tokens'] as num?)?.toInt() ?? 512,
        repetitionPenalty: (generation['repetition_penalty'] as num?)?.toDouble() ?? 1.08,
        stopSequences: ((generation['stop_sequences'] as List?) ?? const <Object>[])
            .map((Object? item) => item.toString())
            .toList(growable: false),
      ),
      metadata: (json['metadata'] as Map?)?.cast<String, Object?>() ?? const <String, Object?>{},
    );
  }
}
