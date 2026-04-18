import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

void main() {
  test('parses imported preset json', () {
    const JsonPresetParser parser = JsonPresetParser();
    final Preset preset = parser.parse('''
    {
      "id": "cinematic",
      "name": "Cinematic RP",
      "system_prompt": "Stay immersive.",
      "generation": {
        "temperature": 0.92,
        "top_p": 0.95,
        "top_k": 64,
        "max_output_tokens": 700,
        "repetition_penalty": 1.03,
        "stop_sequences": ["<END>"]
      }
    }
    ''');

    expect(preset.id, 'cinematic');
    expect(preset.generationConfig.topK, 64);
    expect(preset.generationConfig.stopSequences, contains('<END>'));
  });
}
