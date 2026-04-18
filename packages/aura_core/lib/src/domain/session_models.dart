import 'package:meta/meta.dart';

import 'chat_models.dart';

@immutable
class SessionSummary {
  const SessionSummary({
    required this.content,
    required this.sourceMessageIds,
    required this.createdAt,
  });

  final String content;
  final List<String> sourceMessageIds;
  final DateTime createdAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'content': content,
      'source_message_ids': sourceMessageIds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SessionSummary.fromJson(Map<String, Object?> json) {
    return SessionSummary(
      content: json['content']?.toString() ?? '',
      sourceMessageIds: ((json['source_message_ids'] as List?) ?? const <Object>[])
          .map((Object? item) => item.toString())
          .toList(growable: false),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

@immutable
class ChatSession {
  const ChatSession({
    required this.id,
    required this.characterId,
    required this.messages,
    required this.updatedAt,
    this.summary,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String characterId;
  final List<ChatMessage> messages;
  final DateTime updatedAt;
  final SessionSummary? summary;
  final Map<String, Object?> metadata;

  ChatSession copyWith({
    List<ChatMessage>? messages,
    DateTime? updatedAt,
    SessionSummary? summary,
    bool clearSummary = false,
    Map<String, Object?>? metadata,
  }) {
    return ChatSession(
      id: id,
      characterId: characterId,
      messages: messages ?? this.messages,
      updatedAt: updatedAt ?? this.updatedAt,
      summary: clearSummary ? null : (summary ?? this.summary),
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'character_id': characterId,
      'updated_at': updatedAt.toIso8601String(),
      'summary': summary?.toJson(),
      'metadata': metadata,
      'messages': messages.map((ChatMessage message) => message.toJson()).toList(growable: false),
    };
  }

  factory ChatSession.fromJson(Map<String, Object?> json) {
    return ChatSession(
      id: json['id']?.toString() ?? '',
      characterId: json['character_id']?.toString() ?? '',
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      summary: json['summary'] is Map<String, Object?>
          ? SessionSummary.fromJson(json['summary']! as Map<String, Object?>)
          : json['summary'] is Map<Object?, Object?>
              ? SessionSummary.fromJson((json['summary']! as Map<Object?, Object?>).cast<String, Object?>())
              : null,
      metadata: (json['metadata'] as Map?)?.cast<String, Object?>() ?? const <String, Object?>{},
      messages: ((json['messages'] as List?) ?? const <Object>[])
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> item) => ChatMessage.fromJson(item.cast<String, Object?>()))
          .toList(growable: false),
    );
  }
}
