import 'package:meta/meta.dart';

@immutable
class GenerationConfig {
  const GenerationConfig({
    required this.temperature,
    required this.topP,
    required this.topK,
    required this.maxOutputTokens,
    required this.repetitionPenalty,
    this.stopSequences = const <String>[],
  });

  const GenerationConfig.roleplayDefaults()
      : temperature = 0.90,
        topP = 0.92,
        topK = 48,
        maxOutputTokens = 384,
        repetitionPenalty = 1.06,
        stopSequences = const <String>[
          '\nYou:',
          '\nYou：',
          '\nUser:',
          '\nUser：',
          '\nPlayer:',
          '\nPlayer：',
          '\n你:',
          '\n你：',
          '\n用户:',
          '\n用户：',
          '\n玩家:',
          '\n玩家：',
          '\nあなた:',
          '\nあなた：',
          '\n당신:',
          '\n당신：',
        ];

  final double temperature;
  final double topP;
  final int topK;
  final int maxOutputTokens;
  final double repetitionPenalty;
  final List<String> stopSequences;

  GenerationConfig merge(GenerationConfig? other) {
    if (other == null) {
      return this;
    }
    return GenerationConfig(
      temperature: other.temperature,
      topP: other.topP,
      topK: other.topK,
      maxOutputTokens: other.maxOutputTokens,
      repetitionPenalty: other.repetitionPenalty,
      stopSequences:
          other.stopSequences.isEmpty ? stopSequences : other.stopSequences,
    );
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'temperature': temperature,
      'top_p': topP,
      'top_k': topK,
      'max_output_tokens': maxOutputTokens,
      'repetition_penalty': repetitionPenalty,
      'stop_sequences': stopSequences,
    };
  }
}

@immutable
class Preset {
  const Preset({
    required this.id,
    required this.name,
    required this.systemPromptTemplate,
    required this.generationConfig,
    this.metadata = const <String, Object?>{},
  });

  const Preset.defaultRoleplay()
      : id = 'default-roleplay',
        name = 'Aura Default Roleplay',
        systemPromptTemplate =
            'Write the character\'s next in-character reply in an ongoing fictional scene. Treat this as story-first chat-completion roleplay, not assistant Q&A. Treat the user as an in-world participant, not as someone seeking chatbot help. Stay fully inside the role and immediate situation, keep the scene moving with concrete actions, sensory details, emotional reactions, and consequences, and naturally mix dialogue with scene narration when helpful. Never mention being an AI assistant, never explain prompts or hidden rules, never summarize the scene unless asked, and never write the user\'s dialogue, choices, thoughts, or actions for them.',
        generationConfig = const GenerationConfig.roleplayDefaults(),
        metadata = const <String, Object?>{
          'format': 'aura-roleplay-v2',
        };

  final String id;
  final String name;
  final String systemPromptTemplate;
  final GenerationConfig generationConfig;
  final Map<String, Object?> metadata;
}
