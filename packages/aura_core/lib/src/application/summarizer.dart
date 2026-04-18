import '../domain/chat_models.dart';
import '../domain/session_models.dart';

abstract interface class Summarizer {
  Future<SessionSummary> summarize(List<ChatMessage> messages);
}

class HeuristicSummarizer implements Summarizer {
  const HeuristicSummarizer();

  @override
  Future<SessionSummary> summarize(List<ChatMessage> messages) async {
    final Iterable<ChatMessage> visible = messages
        .where((ChatMessage message) => message.role != ChatRole.system);
    final List<String> snippets = visible
        .take(8)
        .map(
          (ChatMessage message) =>
              '${_summaryRole(message.role)}: ${_compact(message.content)}',
        )
        .toList(growable: false);

    return SessionSummary(
      content: snippets.join('\n'),
      sourceMessageIds: messages
          .map((ChatMessage message) => message.id)
          .toList(growable: false),
      createdAt: DateTime.now(),
    );
  }

  String _compact(String raw) {
    final String singleLine = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (singleLine.length <= 120) {
      return singleLine;
    }
    return '${singleLine.substring(0, 117)}...';
  }

  String _summaryRole(ChatRole role) {
    return switch (role) {
      ChatRole.user => 'player',
      ChatRole.assistant => 'character',
      ChatRole.system => 'context',
      ChatRole.tool => 'tool',
    };
  }
}
