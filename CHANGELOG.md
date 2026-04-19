# Changelog

All notable changes to Aura are documented here.  
Format follows [Keep a Changelog](https://keepachangelog.com/).

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

[0.2.0]: https://github.com/wimi321/aura/releases/tag/v0.2.0
[0.1.1]: https://github.com/wimi321/aura/releases/tag/v0.1.1
[0.1.0]: https://github.com/wimi321/aura/releases/tag/v0.1.0
