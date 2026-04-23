import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AuraStage extends StatelessWidget {
  const AuraStage({
    super.key,
    required this.child,
    this.showEclipse = true,
    this.showConstellation = false,
    this.eclipseAlignment = Alignment.topRight,
    this.atmosphereOpacity = 0.72,
  });

  static const String atmosphereAsset =
      'assets/images/ui/aura-eclipse-atmosphere.jpg';
  static const String deepSpaceAsset = 'assets/images/ui/deep-space-grain.jpg';
  static const String eclipseCoreAsset = 'assets/images/ui/eclipse-core.png';
  static const String constellationAsset =
      'assets/images/ui/model-constellation.png';

  final Widget child;
  final bool showEclipse;
  final bool showConstellation;
  final Alignment eclipseAlignment;
  final double atmosphereOpacity;

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final double orbSize = (screen.shortestSide * 0.92).clamp(280.0, 520.0);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        DecoratedBox(
          decoration: const BoxDecoration(color: AppTheme.bgBase),
          child: Opacity(
            opacity: atmosphereOpacity,
            child: Image.asset(
              atmosphereAsset,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        Opacity(
          opacity: 0.20,
          child: Image.asset(
            deepSpaceAsset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
          ),
        ),
        if (showConstellation)
          Positioned(
            left: -screen.width * 0.18,
            right: -screen.width * 0.18,
            top: screen.height * 0.16,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.18,
                child: Image.asset(
                  constellationAsset,
                  fit: BoxFit.fitWidth,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        if (showEclipse)
          _AlignedEclipse(
            alignment: eclipseAlignment,
            size: orbSize,
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0x26000000),
                Color(0x03000000),
                Color(0xA603070A),
                AppTheme.bgBase,
              ],
              stops: <double>[0.0, 0.34, 0.78, 1.0],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _AlignedEclipse extends StatelessWidget {
  const _AlignedEclipse({
    required this.alignment,
    required this.size,
  });

  final Alignment alignment;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final double left = switch (alignment.x) {
      < -0.5 => -size * 0.42,
      > 0.5 => screen.width - size * 0.56,
      _ => (screen.width - size) / 2,
    };
    final double top = switch (alignment.y) {
      < -0.5 => -size * 0.38,
      > 0.5 => screen.height - size * 0.62,
      _ => screen.height * 0.16,
    };
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.58,
          child: Image.asset(
            AuraStage.eclipseCoreAsset,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
