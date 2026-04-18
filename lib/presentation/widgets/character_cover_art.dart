import 'dart:io';

import 'package:aura_core/aura_core.dart';
import 'package:flutter/material.dart';

import '../../backend/models/default_assets.dart';
import '../../core/theme/app_theme.dart';

class CharacterCoverArt extends StatelessWidget {
  const CharacterCoverArt({
    super.key,
    required this.character,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  final CharacterCard character;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final _CharacterPalette palette = _CharacterPalette.forCharacter(character);
    final ImageProvider<Object>? provider = _imageProvider(character);
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    palette.base,
                    palette.mid,
                    palette.deep,
                  ],
                ),
              ),
            ),
            if (provider != null)
              Image(
                key: ValueKey<String>('character-art-image-${character.id}'),
                image: provider,
                fit: BoxFit.cover,
                errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                  return _GeneratedBackdrop(
                    character: character,
                    palette: palette,
                  );
                },
              )
            else
              _GeneratedBackdrop(
                character: character,
                palette: palette,
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.16),
                    Colors.black.withValues(alpha: 0.52),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider<Object>? _imageProvider(CharacterCard character) {
    final String normalized = (character.avatarPath ?? '').trim();
    if (normalized.isNotEmpty) {
      if (normalized.startsWith('assets/')) {
        return AssetImage(normalized);
      }
      final File file = File(normalized);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }

    if (isBuiltInCharacterId(character.id)) {
      return AssetImage('assets/images/characters/${character.id}.png');
    }

    return null;
  }
}

class CharacterAvatar extends StatelessWidget {
  const CharacterAvatar({
    super.key,
    required this.character,
    this.size = 48,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  final CharacterCard character;
  final double size;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CharacterCoverArt(
        character: character,
        height: size,
        borderRadius: borderRadius,
      ),
    );
  }
}

class _GeneratedBackdrop extends StatelessWidget {
  const _GeneratedBackdrop({
    required this.character,
    required this.palette,
  });

  final CharacterCard character;
  final _CharacterPalette palette;

  @override
  Widget build(BuildContext context) {
    final String accentGlyph = _accentGlyph(character.name);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          right: -24,
          top: -18,
          child: Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.glow.withValues(alpha: 0.18),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: palette.glow.withValues(alpha: 0.34),
                  blurRadius: 44,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: -36,
          bottom: -54,
          child: Transform.rotate(
            angle: -0.18,
            child: Container(
              width: 220,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
        ),
        Positioned(
          right: 18,
          bottom: -8,
          child: Text(
            accentGlyph,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.18),
              fontSize: 140,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        Positioned(
          left: 18,
          top: 18,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  palette.icon,
                  size: 14,
                  color: AppTheme.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  _storyTag(character),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _accentGlyph(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return String.fromCharCode(trimmed.runes.first);
  }

  String _storyTag(CharacterCard character) {
    final Object? explicitTag = character.extensions['story_tag'];
    final String tag = explicitTag?.toString().trim() ?? '';
    if (tag.isNotEmpty) {
      return tag;
    }
    final String scenario = character.scenario.trim();
    if (scenario.isEmpty) {
      return 'SCENE';
    }
    final List<String> words = scenario.split(RegExp(r'\s+'));
    return words.first.toUpperCase();
  }
}

class _CharacterPalette {
  const _CharacterPalette({
    required this.base,
    required this.mid,
    required this.deep,
    required this.glow,
    required this.icon,
  });

  final Color base;
  final Color mid;
  final Color deep;
  final Color glow;
  final IconData icon;

  static const List<_CharacterPalette> _fallback = <_CharacterPalette>[
    _CharacterPalette(
      base: Color(0xFF16243C),
      mid: Color(0xFF233B66),
      deep: Color(0xFF08111D),
      glow: Color(0xFF89C6FF),
      icon: Icons.explore_rounded,
    ),
    _CharacterPalette(
      base: Color(0xFF2B1F17),
      mid: Color(0xFF7A472B),
      deep: Color(0xFF120C09),
      glow: Color(0xFFFFB36F),
      icon: Icons.local_fire_department_rounded,
    ),
    _CharacterPalette(
      base: Color(0xFF112420),
      mid: Color(0xFF1E5A4B),
      deep: Color(0xFF071310),
      glow: Color(0xFF85F0C9),
      icon: Icons.auto_awesome_rounded,
    ),
    _CharacterPalette(
      base: Color(0xFF271A24),
      mid: Color(0xFF6B3B57),
      deep: Color(0xFF100912),
      glow: Color(0xFFFF93C2),
      icon: Icons.nightlight_round,
    ),
  ];

  static final Map<String, _CharacterPalette> _mapped =
      <String, _CharacterPalette>{
    'sun-wukong': const _CharacterPalette(
      base: Color(0xFF37200B),
      mid: Color(0xFF9A4E12),
      deep: Color(0xFF160A04),
      glow: Color(0xFFFFB85B),
      icon: Icons.wb_sunny_rounded,
    ),
    'lin-daiyu': const _CharacterPalette(
      base: Color(0xFF18261F),
      mid: Color(0xFF3B6F5A),
      deep: Color(0xFF08120E),
      glow: Color(0xFFA7F0D0),
      icon: Icons.local_florist_rounded,
    ),
    'di-renjie': const _CharacterPalette(
      base: Color(0xFF162033),
      mid: Color(0xFF2F4F7A),
      deep: Color(0xFF09101B),
      glow: Color(0xFFFFD37A),
      icon: Icons.gavel_rounded,
    ),
    'nie-xiaoqian': const _CharacterPalette(
      base: Color(0xFF132229),
      mid: Color(0xFF2E5865),
      deep: Color(0xFF060C10),
      glow: Color(0xFF90E7FF),
      icon: Icons.mode_night_rounded,
    ),
    'archive-keeper': const _CharacterPalette(
      base: Color(0xFF171C2E),
      mid: Color(0xFF39548D),
      deep: Color(0xFF090D17),
      glow: Color(0xFF8FB2FF),
      icon: Icons.menu_book_rounded,
    ),
    'void-captain': const _CharacterPalette(
      base: Color(0xFF221B27),
      mid: Color(0xFF654A7C),
      deep: Color(0xFF0D0910),
      glow: Color(0xFFFFB2E8),
      icon: Icons.rocket_launch_rounded,
    ),
    'blood-duchess': const _CharacterPalette(
      base: Color(0xFF2C1316),
      mid: Color(0xFF7A2C39),
      deep: Color(0xFF110608),
      glow: Color(0xFFFF95A5),
      icon: Icons.shield_moon_rounded,
    ),
    'icefield-ranger': const _CharacterPalette(
      base: Color(0xFF152833),
      mid: Color(0xFF35667A),
      deep: Color(0xFF081015),
      glow: Color(0xFF89E7FF),
      icon: Icons.ac_unit_rounded,
    ),
    'palace-consort': const _CharacterPalette(
      base: Color(0xFF27161E),
      mid: Color(0xFF6E3348),
      deep: Color(0xFF12090D),
      glow: Color(0xFFF5C27B),
      icon: Icons.auto_awesome_rounded,
    ),
    'young-marshal': const _CharacterPalette(
      base: Color(0xFF1A2230),
      mid: Color(0xFF455A80),
      deep: Color(0xFF0A1018),
      glow: Color(0xFFB7CCFF),
      icon: Icons.thunderstorm_rounded,
    ),
    'contract-heir': const _CharacterPalette(
      base: Color(0xFF201A1E),
      mid: Color(0xFF6C495A),
      deep: Color(0xFF0E0A0C),
      glow: Color(0xFFFFC9D8),
      icon: Icons.diamond_rounded,
    ),
    'scandal-idol': const _CharacterPalette(
      base: Color(0xFF25171B),
      mid: Color(0xFF92465A),
      deep: Color(0xFF10080A),
      glow: Color(0xFFFFB1C3),
      icon: Icons.mic_external_on_rounded,
    ),
    'instance-monitor': const _CharacterPalette(
      base: Color(0xFF131B24),
      mid: Color(0xFF2C4B68),
      deep: Color(0xFF080D12),
      glow: Color(0xFF8EE7FF),
      icon: Icons.rule_folder_rounded,
    ),
    'shelter-captain': const _CharacterPalette(
      base: Color(0xFF18211D),
      mid: Color(0xFF40624E),
      deep: Color(0xFF09100C),
      glow: Color(0xFFBCE7C2),
      icon: Icons.shield_rounded,
    ),
    'jianghu-young-master': const _CharacterPalette(
      base: Color(0xFF241912),
      mid: Color(0xFF8C5032),
      deep: Color(0xFF100905),
      glow: Color(0xFFFFC68A),
      icon: Icons.gavel_rounded,
    ),
  };

  factory _CharacterPalette.forCharacter(CharacterCard character) {
    return _mapped[character.id] ??
        _fallback[character.id.hashCode.abs() % _fallback.length];
  }
}
