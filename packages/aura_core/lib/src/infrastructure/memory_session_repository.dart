import '../application/session_repository.dart';
import '../domain/session_models.dart';

class MemorySessionRepository implements SessionRepository {
  final Map<String, ChatSession> _sessions = <String, ChatSession>{};

  @override
  Future<void> delete(String sessionId) async {
    _sessions.remove(sessionId);
  }

  @override
  Future<ChatSession?> getById(String sessionId) async {
    return _sessions[sessionId];
  }

  @override
  Future<List<ChatSession>> list() async {
    final List<ChatSession> sessions = _sessions.values.toList(growable: false);
    sessions.sort((ChatSession a, ChatSession b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  @override
  Future<void> put(ChatSession session) async {
    _sessions[session.id] = session;
  }
}
