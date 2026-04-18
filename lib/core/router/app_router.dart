import 'package:go_router/go_router.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/character_list/character_list_page.dart';
import '../../presentation/pages/chat/chat_page.dart';
import '../../presentation/pages/model_setup/model_setup_page.dart';
import '../../presentation/pages/settings/advanced_settings_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/characters',
        builder: (context, state) => const CharacterListPage(),
      ),
      GoRoute(
        path: '/model-setup',
        builder: (context, state) => ModelSetupPage(
          returnTo: state.uri.queryParameters['returnTo'],
        ),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final String? sessionId = state.uri.queryParameters['session'];
          final String? initialDraft = state.uri.queryParameters['draft'];
          return ChatPage(
            characterId: id,
            initialSessionId: sessionId,
            initialDraft: initialDraft,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const AdvancedSettingsPage(),
      ),
    ],
  );
}
