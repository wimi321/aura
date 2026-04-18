# Contributing to Aura

Thanks for considering contributing to Aura! This guide will help you get started.

## Development Setup

### Prerequisites

- Flutter SDK (stable channel, ≥3.0)
- Dart SDK ≥3.0
- Android Studio or Xcode (for mobile builds)
- A physical device or emulator

### Getting Started

```bash
git clone https://github.com/wimi321/aura.git
cd aura
flutter pub get
flutter analyze
flutter test
```

### Running Locally

For desktop development without a real model:

```bash
AURA_USE_FAKE_GATEWAY=true flutter run -d macos
```

For Android with real inference:

```bash
flutter run -d <device-id>
```

## Project Structure

```
lib/
├── application/providers/   # AppStateProvider (central ChangeNotifier)
├── backend/services/        # Bootstrap, platform channels, stores
├── core/router/             # GoRouter routes
├── l10n/                    # ARB localization files (EN/ZH/JA/KO)
└── presentation/pages/      # UI pages (splash, characters, chat, settings)

packages/aura_core/          # Pure Dart domain + orchestration library
├── domain/                  # Immutable models, policy objects
├── application/             # AuraEngine, ChatOrchestrator, ModelManager
└── infrastructure/          # Parsers, persistence adapters
```

## Code Style

- Follow the lints configured in `analysis_options.yaml`
- `aura_core` enforces stricter rules: `strict-casts`, `strict-inference`, `strict-raw-types`
- Domain models use `@immutable` with `copyWith()`
- All UI strings go through ARB files — no hardcoded strings
- Prefer `const` constructors wherever possible

## Testing

Before submitting a PR, ensure all checks pass:

```bash
# App-level
flutter analyze
flutter test

# Core package
cd packages/aura_core
dart analyze
dart test
```

## Localization

Aura supports four languages. When adding new UI strings:

1. Add the key + English text to `lib/l10n/app_en.arb`
2. Add translations to `app_zh.arb`, `app_ja.arb`, `app_ko.arb`
3. Run `flutter gen-l10n`
4. Use `AppLocalizations.of(context)!.yourKey` in widgets

## Pull Request Process

1. Fork the repo and create a feature branch from `main`
2. Make your changes with clear, focused commits
3. Ensure `flutter analyze` and `flutter test` both pass
4. Fill in the PR template with summary and test plan
5. Include before/after screenshots for any UI changes

## What We're Looking For

- Tavern card import compatibility improvements
- Device-specific testing and bug reports
- UI/UX polish and accessibility improvements
- Localization corrections and new language support
- Performance optimizations for on-device inference

## Reporting Issues

Please use the [issue templates](https://github.com/wimi321/aura/issues/new/choose) to report bugs or request features. Include device info, Aura version, and steps to reproduce.
