import 'dart:io';

import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

void main() {
  test('persists and reads session files', () async {
    final Directory tempDir =
        await Directory.systemTemp.createTemp('aura_session_test');
    addTearDown(() => tempDir.delete(recursive: true));

    final FileSessionRepository repository = FileSessionRepository(tempDir);
    final ChatSession session = ChatSession(
      id: 'session-1',
      characterId: 'asuna',
      messages: const <ChatMessage>[
        ChatMessage(id: 'm1', role: ChatRole.user, content: 'Hello'),
        ChatMessage(id: 'm2', role: ChatRole.assistant, content: 'Hi'),
      ],
      updatedAt: DateTime.now(),
      summary: SessionSummary(
        content: 'user greeted assistant',
        sourceMessageIds: const <String>['m1', 'm2'],
        createdAt: DateTime.now(),
      ),
    );

    await repository.put(session);
    final ChatSession? loaded = await repository.getById('session-1');
    final List<ChatSession> all = await repository.list();

    expect(loaded, isNotNull);
    expect(loaded!.messages.length, 2);
    expect(loaded.summary?.content, contains('greeted'));
    expect(all.single.id, 'session-1');
  });
}
