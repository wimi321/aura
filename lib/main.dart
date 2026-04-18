import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'application/providers/app_state_provider.dart';
import 'backend/services/aura_backend_bootstrap.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AuraBootstrapApp());
}

class AuraBootstrapApp extends StatefulWidget {
  const AuraBootstrapApp({super.key});

  @override
  State<AuraBootstrapApp> createState() => _AuraBootstrapAppState();
}

class _AuraBootstrapAppState extends State<AuraBootstrapApp> {
  late final Future<AuraBackendContext> _bootstrapFuture;
  AppStateProvider? _appStateProvider;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = AuraBackendBootstrap().createContext();
  }

  @override
  void dispose() {
    _appStateProvider?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuraBackendContext>(
      future: _bootstrapFuture,
      builder:
          (BuildContext context, AsyncSnapshot<AuraBackendContext> snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            title: 'Aura',
            theme: AppTheme.darkTheme,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: BootstrapErrorView(message: snapshot.error.toString()),
          );
        }

        final AuraBackendContext? backendContext = snapshot.data;
        if (backendContext == null) {
          return MaterialApp(
            title: 'Aura',
            theme: AppTheme.darkTheme,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const BootstrapLoadingView(),
          );
        }

        _appStateProvider ??= AppStateProvider(
          backendContext.engine,
          catalogRepository: backendContext.catalogRepository,
          downloadManager: backendContext.downloadManager,
          curatedModels: backendContext.curatedModels,
          preferencesStore: backendContext.preferencesStore,
          characterLibraryStore: backendContext.characterLibraryStore,
          presetLibraryStore: backendContext.presetLibraryStore,
        )..markInitialized(
            deviceProfile: backendContext.deviceProfile,
          );

        return ChangeNotifierProvider<AppStateProvider>.value(
          value: _appStateProvider!,
          child: const AuraApp(),
        );
      },
    );
  }
}

class AuraApp extends StatelessWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStateProvider appState = context.watch<AppStateProvider>();
    return MaterialApp.router(
      title: 'Aura',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      locale: appState.localeOverride,
      routerConfig: AppRouter.router,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

class BootstrapLoadingView extends StatefulWidget {
  const BootstrapLoadingView({super.key});

  @override
  State<BootstrapLoadingView> createState() => _BootstrapLoadingViewState();
}

class _BootstrapLoadingViewState extends State<BootstrapLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (BuildContext context, Widget? child) {
                final double scale = 0.96 + (_pulseController.value * 0.06);
                final double glowOpacity =
                    0.22 + (_pulseController.value * 0.12);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.2, -0.3),
                        radius: 0.8,
                        colors: <Color>[
                          Colors.white,
                          AppTheme.primary,
                          Color(0xFF1B6A51),
                        ],
                        stops: <double>[0.0, 0.42, 1.0],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color:
                              AppTheme.primary.withValues(alpha: glowOpacity),
                          blurRadius: 70,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: AppTheme.highlight
                              .withValues(alpha: glowOpacity * 0.7),
                          blurRadius: 110,
                          spreadRadius: 18,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 96,
            child: Column(
              children: <Widget>[
                Text(
                  'AURA',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 8,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.bootstrapLoadingMessage ??
                      'Opening your private story space...',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BootstrapErrorView extends StatelessWidget {
  const BootstrapErrorView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardElevated,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.danger),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.warning_amber_rounded,
                    color: AppTheme.danger, size: 42),
                const SizedBox(height: 12),
                Text(
                  l10n?.bootstrapErrorTitle ?? 'Aura failed to launch',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.bootstrapErrorDescription ??
                      'Aura could not finish startup. Check the details below.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
