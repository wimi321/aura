import 'chat_models.dart';

class ContextWindowProfile {
  const ContextWindowProfile({
    required this.maxTokens,
    required this.summaryTriggerRatio,
    required this.lowMemoryMaxTokens,
  });

  final int maxTokens;
  final double summaryTriggerRatio;
  final int lowMemoryMaxTokens;

  int resolveWindow({required bool isLowMemoryDevice}) {
    return isLowMemoryDevice ? lowMemoryMaxTokens : maxTokens;
  }

  bool shouldSummarize({
    required List<ChatMessage> messages,
    required bool isLowMemoryDevice,
  }) {
    final int usedTokens = messages.fold<int>(
        0, (int sum, ChatMessage message) => sum + message.estimatedTokenCount);
    final int window = resolveWindow(isLowMemoryDevice: isLowMemoryDevice);
    return usedTokens >= (window * summaryTriggerRatio).floor();
  }

  List<ChatMessage> summarySlice(List<ChatMessage> messages) {
    if (messages.length <= 4) {
      return const <ChatMessage>[];
    }
    final int preservedTail = messages.length > 12 ? 6 : 4;
    final int cutoff = messages.length - preservedTail;
    if (cutoff <= 0) {
      return const <ChatMessage>[];
    }
    return messages.take(cutoff).toList(growable: false);
  }
}
