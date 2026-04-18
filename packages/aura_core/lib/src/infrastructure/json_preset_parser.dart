import 'dart:convert';

import '../domain/preset.dart';

class JsonPresetParser {
  const JsonPresetParser();

  Preset parse(String rawJson) {
    final Object? decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Preset JSON must be an object.');
    }

    final Map<String, Object?> map = decoded;
    final Map<String, Object?> generation = (map['generation'] as Map?)?.cast<String, Object?>() ?? <String, Object?>{};

    return Preset(
      id: (map['id'] as String?) ?? 'imported-preset',
      name: (map['name'] as String?) ?? 'Imported Preset',
      systemPromptTemplate: (map['system_prompt'] as String?) ?? const Preset.defaultRoleplay().systemPromptTemplate,
      generationConfig: GenerationConfig(
        temperature: (generation['temperature'] as num?)?.toDouble() ?? 0.85,
        topP: (generation['top_p'] as num?)?.toDouble() ?? 0.9,
        topK: (generation['top_k'] as num?)?.toInt() ?? 40,
        maxOutputTokens: (generation['max_output_tokens'] as num?)?.toInt() ?? 512,
        repetitionPenalty: (generation['repetition_penalty'] as num?)?.toDouble() ?? 1.08,
        stopSequences: ((generation['stop_sequences'] as List?) ?? const <Object?>[])
            .map<String>((Object? item) => item.toString())
            .toList(growable: false),
      ),
      metadata: map,
    );
  }
}
