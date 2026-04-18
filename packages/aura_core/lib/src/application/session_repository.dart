import '../domain/session_models.dart';

abstract interface class SessionRepository {
  Future<ChatSession?> getById(String sessionId);
  Future<void> put(ChatSession session);
  Future<List<ChatSession>> list();
  Future<void> delete(String sessionId);
}
