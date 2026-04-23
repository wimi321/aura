# Changelog

All notable changes to Aura are documented here.  
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [0.2.4] — 2026-04-24

### Added
- Generated Eclipse Core app icon source artwork and reproducible brand asset pipeline
- Platform validation for Android, iOS, macOS, README, and launch logo assets

### Changed
- Rebuilt Android launcher icons, iOS AppIcon, macOS AppIcon, README logo, and iOS launch mark from the same generated source
- Updated the iOS native launch screen background to match Aura's dark startup color
- Kept app icon foreground artwork inside the adaptive-icon safe zone for launcher masks

## [0.2.3] — 2026-04-24

### Added
- Generated Eclipse Core atmosphere artwork for the app-wide visual stage
- Reusable AuraStage background widget shared across launch, library, setup, and reading surfaces

### Changed
- Upgraded the launch experience with the generated eclipse-core artwork and smoother brand continuity
- Refined the story library, first-run model chooser, and chat scene backgrounds with a unified cinematic depth layer
- Kept the Android release installer small while adding the new UI artwork assets

## [0.2.2] — 2026-04-24

### Added
- Release validation for the small Android installer path without bundled model weights
- Extra regression coverage for model download fallback, model manager cleanup, roleplay text formatting, and emotion tag filtering

### Changed
- Android release packaging now prioritizes the arm64-v8a APK for a smaller public download, reducing the installer to about 103 MB
- First-run model setup keeps E2B as the recommended fast-start core and E4B as the higher-quality option
- README and Chinese README now reflect the current small-installer release flow

### Fixed
- Stabilized first-run model activation after choosing and downloading a story core
- Hardened model download retry and mirror fallback behavior for flaky networks
- Ensured local inference resources are released cleanly between scene sessions

## [0.2.0] — 2026-04-19

### Added
- **Splash**: Multi-stage progress labels (preparing runtime → loading core) with contextual error recovery
- **Model Setup**: Real-time download speed, ETA, percentage display; clearer E2B vs E4B comparison chips
- **Character Library**: Search by name, empty-state onboarding guide, long-press delete for imported characters
- **Chat**: Copy message text to clipboard, relative timestamps on messages, haptic feedback on interactions
- **Chat**: Bouncing typing indicator with reduce-motion fallback
- **Chat**: Tap scenario header to expand full character details sheet
- **Chat**: Inline retry button on timeout errors, inline settings button on fatal errors
- **Chat**: Auto-dismiss timeout/recovery banners after 8 seconds
- **Settings**: Grouped sections (Language / Prompt Preset / Story Cores)
- **Settings**: Delete installed models to free disk space, with size display
- **Accessibility**: Semantics labels on all interactive chat elements
- **Accessibility**: Respect system reduce-motion preference for all animations
- Localization: All new strings added to EN, ZH, JA, KO

### Fixed
- Reroll button tooltip was incorrectly reusing "continue scene" text
- Recovery success showed persistent banner instead of brief toast

## [0.1.1] — 2026-04-18

### Added
- Reproducible built-in story poster generation pipeline
- Refined story cover artwork for all three built-in scenarios
- Consumer-facing README with real app screenshots and GIF walkthrough
- Chinese README (README.zh-CN.md)

### Changed
- Installer size reduced from ~2.2 GB (bundled model) to ~127 MB (model downloaded on first launch)
- README rewritten to lead with user value, not technical implementation

## [0.1.0] — 2026-04-17

### Added
- On-device inference via Google LiteRT-LM (Gemma 4 E2B / E4B)
- Tavern PNG and JSON character card import with steganography extraction
- Embedded and standalone lorebook / worldbook support
- Whisper directives (one-turn director instructions)
- Emotion tag extraction and expression pack system
- Prompt preset editor with temperature, top-p, top-k, max tokens
- Session history with branching (new conversation, resume past branches)
- Message edit and delete (long-press actions)
- Scene continuation (one-tap "continue" button)
- First-run model chooser with download progress
- Neural engine acceleration toggle (NPU/CoreML)
- Four-language UI: English, Chinese, Japanese, Korean
- Three built-in story scenarios: palace intrigue, campus romance, rule-based horror
- Premium OLED dark theme with ambient glow effects
- Hardware delegate auto-selection (CoreML / GPU / CPU)
- Context window management with heuristic summarization

[0.2.4]: https://github.com/wimi321/aura/releases/tag/v0.2.4
[0.2.3]: https://github.com/wimi321/aura/releases/tag/v0.2.3
[0.2.2]: https://github.com/wimi321/aura/releases/tag/v0.2.2
[0.2.0]: https://github.com/wimi321/aura/releases/tag/v0.2.0
[0.1.1]: https://github.com/wimi321/aura/releases/tag/v0.1.1
[0.1.0]: https://github.com/wimi321/aura/releases/tag/v0.1.0
