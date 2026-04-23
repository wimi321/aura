import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';

import '../../../application/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/aura_stage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );
  }

  void _ensureAnimations(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      if (_pulseController.isAnimating) _pulseController.stop();
      if (_rotationController.isAnimating) _rotationController.stop();
    } else {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
      if (!_rotationController.isAnimating) _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  String _stageLabel(AppStateProvider appState, AppLocalizations? l10n) {
    return switch (appState.modelState) {
      AppModelState.idle ||
      AppModelState.initializing =>
        l10n?.splashPreparingRuntime ?? 'Preparing runtime...',
      AppModelState.loading ||
      AppModelState.switching =>
        l10n?.splashLoadingCore ?? 'Loading story core...',
      AppModelState.ready => l10n?.readyText ?? 'Ready',
      AppModelState.error => l10n?.modelStateError ?? 'Error',
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppStateProvider appState = context.watch<AppStateProvider>();
    final AppLocalizations? l10n = AppLocalizations.of(context);

    _ensureAnimations(context);

    if (!_hasNavigated &&
        appState.startupResolved &&
        appState.modelState != AppModelState.error) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(
            appState.hasInstalledModels ? '/characters' : '/model-setup',
          );
        }
      });
    }

    final bool isError =
        appState.startupResolved && appState.modelState == AppModelState.error;

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: AuraStage(
        showEclipse: false,
        atmosphereOpacity: 0.98,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AnimatedBuilder(
                animation:
                    Listenable.merge([_pulseController, _rotationController]),
                builder: (BuildContext context, Widget? child) {
                  final double scale = 0.98 + (_pulseController.value * 0.04);
                  final double blur = 60 + (_pulseController.value * 20);

                  return Transform.scale(
                    scale: scale,
                    child: Hero(
                      tag: 'aura_logo',
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 168,
                            height: 168,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppTheme.brandAura
                                      .withValues(alpha: 0.24),
                                  blurRadius: blur,
                                  spreadRadius: 10,
                                  offset: const Offset(-8, -8),
                                ),
                                BoxShadow(
                                  color: AppTheme.brandCoral
                                      .withValues(alpha: 0.16),
                                  blurRadius: blur,
                                  spreadRadius: 10,
                                  offset: const Offset(8, 8),
                                ),
                              ],
                            ),
                          ),
                          Transform.rotate(
                            angle: _rotationController.value * 2 * 3.14159,
                            child: Image.asset(
                              AuraStage.eclipseCoreAsset,
                              width: 184,
                              height: 184,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.5, end: 1.0)
                    .animate(_pulseController),
                child: Column(
                  children: [
                    Text(
                      'AURA',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 10,
                                color: AppTheme.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 12),
                    if (isError) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          appState.errorMessage ??
                              (l10n?.modelErrorGeneric ??
                                  'Something went wrong. Please try again.'),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.statusDanger,
                                    height: 1.4,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.tonal(
                            onPressed: () {
                              context.go(appState.hasInstalledModels
                                  ? '/settings'
                                  : '/model-setup');
                            },
                            child: Text(appState.hasInstalledModels
                                ? (l10n?.splashGoToSettings ?? 'Go to Settings')
                                : (l10n?.splashDownloadCore ??
                                    'Download a Core')),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () async {
                              await appState.recoverActiveModel();
                            },
                            child: Text(l10n?.splashTryAgain ?? 'Try Again'),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        _stageLabel(appState, l10n),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.textMuted,
                              letterSpacing: 2,
                            ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 120,
                        child: LinearProgressIndicator(
                          value: null,
                          backgroundColor: AppTheme.borderSubtle,
                          color: AppTheme.brandAura.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                          minHeight: 2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
