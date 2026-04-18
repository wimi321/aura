import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';

import '../../../application/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStateProvider appState = context.watch<AppStateProvider>();
    final AppLocalizations? l10n = AppLocalizations.of(context);

    if (appState.startupResolved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(
          appState.hasInstalledModels ? '/characters' : '/model-setup',
        );
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // The Ambient Glow of the Eclipse Core
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
                        // Rotating glowing outer ring
                        Transform.rotate(
                          angle: _rotationController.value * 2 * 3.14159,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppTheme.brandAura
                                      .withValues(alpha: 0.25),
                                  blurRadius: blur,
                                  spreadRadius: 8,
                                  offset: const Offset(-8, -8),
                                ),
                                BoxShadow(
                                  color: AppTheme.brandCoral
                                      .withValues(alpha: 0.15),
                                  blurRadius: blur,
                                  spreadRadius: 8,
                                  offset: const Offset(8, 8),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Central Void (Absolute Privacy / Local Run)
                        Container(
                          width: 136,
                          height: 136,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF020406),
                            border: Border.all(
                                color: AppTheme.borderSubtle, width: 1.5),
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
              opacity:
                  Tween<double>(begin: 0.5, end: 1.0).animate(_pulseController),
              child: Column(
                children: [
                  Text(
                    'AURA',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 10,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n != null ? l10n.loadingModel : 'Initialize Engine',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                          letterSpacing: 2,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
