import 'package:meta/meta.dart';

import 'emotion_signal.dart';
import 'preset.dart';

enum ChatRole { system, user, assistant, tool }

enum InputModality { text, audioFrames }

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.createdAt,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime? createdAt;
  final Map<String, Object?> metadata;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'role': role.name,
      'content': content,
      'created_at': createdAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromJson(Map<String, Object?> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      role: ChatRole.values.firstWhere(
        (ChatRole role) => role.name == json['role']?.toString(),
        orElse: () => ChatRole.user,
      ),
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      metadata: (json['metadata'] as Map?)?.cast<String, Object?>() ??
          const <String, Object?>{},
    );
  }

  int get estimatedTokenCount {
    final int visibleLength = content.runes.length;
    return (visibleLength / 4).ceil().clamp(1, 1 << 20);
  }
}

@immutable
class ChatTurnInput {
  const ChatTurnInput({
    required this.userMessage,
    required this.history,
    this.whisperInstruction,
    this.modality = InputModality.text,
    this.audioFrames = const <List<int>>[],
    this.localeTag,
    this.customGenerationConfig,
  });

  final ChatMessage userMessage;
  final List<ChatMessage> history;
  final String? whisperInstruction;
  final InputModality modality;
  final List<List<int>> audioFrames;
  final String? localeTag;
  final GenerationConfig? customGenerationConfig;
}

@immutable
class PromptEnvelope {
  const PromptEnvelope({
    required this.systemInstruction,
    required this.messages,
    required this.generationConfig,
    required this.assistantLabel,
    required this.userLabel,
    this.postHistoryInstructions,
    this.triggeredLore = const <String>[],
    this.depthInsertions = const <DepthInsertion>[],
    this.shouldSummarize = false,
    this.summarySourceMessages = const <ChatMessage>[],
  });

  final String systemInstruction;
  final List<ChatMessage> messages;
  final GenerationConfig generationConfig;
  final String assistantLabel;
  final String userLabel;
  final String? postHistoryInstructions;
  final List<String> triggeredLore;
  final List<DepthInsertion> depthInsertions;
  final bool shouldSummarize;
  final List<ChatMessage> summarySourceMessages;
}

@immutable
class DepthInsertion {
  const DepthInsertion({
    required this.content,
    required this.depth,
  });

  final String content;
  final int depth;
}

@immutable
class StreamDelta {
  const StreamDelta({
    required this.visibleText,
    this.emotions = const <EmotionSignal>[],
    this.isDone = false,
  });

  final String visibleText;
  final List<EmotionSignal> emotions;
  final bool isDone;
}
