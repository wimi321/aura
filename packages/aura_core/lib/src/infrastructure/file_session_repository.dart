import 'dart:convert';
import 'dart:io';

import '../application/session_repository.dart';
import '../domain/session_models.dart';

class FileSessionRepository implements SessionRepository {
  FileSessionRepository(this._rootDirectory);

  final Directory _rootDirectory;

  @override
  Future<void> delete(String sessionId) async {
    final File file = _fileFor(sessionId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<ChatSession?> getById(String sessionId) async {
    final File file = _fileFor(sessionId);
    if (!await file.exists()) {
      return null;
    }
    final Object? decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Session payload must be an object.');
    }
    return ChatSession.fromJson(decoded);
  }

  @override
  Future<List<ChatSession>> list() async {
    if (!await _rootDirectory.exists()) {
      return const <ChatSession>[];
    }
    final List<ChatSession> sessions = <ChatSession>[];
    await for (final FileSystemEntity entity in _rootDirectory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) {
        continue;
      }
      final Object? decoded = jsonDecode(await entity.readAsString());
      if (decoded is Map<String, Object?>) {
        sessions.add(ChatSession.fromJson(decoded));
      } else if (decoded is Map) {
        sessions.add(ChatSession.fromJson(decoded.cast<String, Object?>()));
      }
    }
    sessions.sort(
        (ChatSession a, ChatSession b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  @override
  Future<void> put(ChatSession session) async {
    await _rootDirectory.create(recursive: true);
    final File file = _fileFor(session.id);
    await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(session.toJson()));
  }

  File _fileFor(String sessionId) {
    return File('${_rootDirectory.path}/$sessionId.json');
  }
}
