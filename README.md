<p align="center">
  <img src="docs/readme/aura-icon.png" alt="Aura icon" width="140" />
</p>

<h1 align="center">Aura</h1>

<p align="center">
  <strong>Run Gemma 4 on your phone. Roleplay offline. No API keys, no cloud, no cost.</strong>
</p>

<p align="center">
  <a href="https://github.com/wimi321/aura/releases/latest"><strong>Download APK</strong></a>
  &nbsp;·&nbsp;
  <a href="https://github.com/wimi321/aura/releases"><strong>All Releases</strong></a>
  &nbsp;·&nbsp;
  <a href="CHANGELOG.md"><strong>Changelog</strong></a>
  &nbsp;·&nbsp;
  <a href="README.zh-CN.md"><strong>简体中文</strong></a>
</p>

<p align="center">
  <a href="https://github.com/wimi321/aura/releases/latest"><img alt="GitHub Release" src="https://img.shields.io/github/v/release/wimi321/aura?display_name=tag&sort=semver&style=flat-square"></a>
  <a href="https://github.com/wimi321/aura/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/wimi321/aura/ci.yml?branch=main&style=flat-square&label=CI"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/github/license/wimi321/aura?style=flat-square"></a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android%20%7C%20iOS-0F172A?style=flat-square">
  <img alt="Gemma 4" src="https://img.shields.io/badge/model-Gemma%204-4285F4?style=flat-square&logo=google">
  <img alt="Offline" src="https://img.shields.io/badge/network-fully%20offline-10B981?style=flat-square">
  <img alt="Tavern" src="https://img.shields.io/badge/Tavern-compatible-F97316?style=flat-square">
  <img alt="Languages" src="https://img.shields.io/badge/i18n-EN%20%7C%20ZH%20%7C%20JA%20%7C%20KO-6366F1?style=flat-square">
</p>

---

## Why Aura?

Most AI roleplay apps require cloud APIs — that means **paying per token**, **sharing your conversations with a server**, and **losing access when the service goes down**.

Aura takes a different path:

| | Cloud API Apps | Aura |
|---|---|---|
| **LLM setup** | Find a provider, get API keys, manage billing | Download once inside the app, done |
| **Cost** | Pay per token / monthly subscription | Free forever after download |
| **Privacy** | Your conversations travel through servers | Everything stays on your phone |
| **Internet** | Required for every message | Only needed for initial model download |
| **Censorship** | Provider decides what you can say | You own the model, no restrictions |
| **Availability** | Service can go down or change terms | Works offline, forever yours |

**Aura runs [Gemma 4](https://ai.google.dev/gemma) directly on your phone** via Google's LiteRT-LM runtime, with GPU and NPU hardware acceleration. After a one-time model download (~2.5 GB), the app never contacts any server again. Your stories, your characters, your conversations — they never leave your device.

---

## Screenshots

<p align="center">
  <img src="docs/readme/story-library.png" alt="Story library" width="180" />&nbsp;&nbsp;
  <img src="docs/readme/chat-scene.png" alt="Chat scene" width="180" />&nbsp;&nbsp;
  <img src="docs/readme/model-setup.png" alt="Model setup" width="180" />&nbsp;&nbsp;
  <img src="docs/readme/import-flow.png" alt="Import flow" width="180" />
</p>

<p align="center">
  <sub>Story Library &nbsp;·&nbsp; Scene Chat &nbsp;·&nbsp; Model Setup &nbsp;·&nbsp; Card Import</sub>
</p>

<details>
<summary>Built-in story cards</summary>
<br />
<p align="center">
  <img src="assets/images/characters/palace-consort.png" alt="Palace intrigue" width="140" />&nbsp;&nbsp;
  <img src="assets/images/characters/deskmate.png" alt="Campus romance" width="140" />&nbsp;&nbsp;
  <img src="assets/images/characters/instance-monitor.png" alt="Rule-based horror" width="140" />
</p>
<p align="center">
  <sub>Palace Intrigue &nbsp;·&nbsp; Campus Slow-Burn &nbsp;·&nbsp; Rule-Based Horror</sub>
</p>
</details>

---

## Features

- **Gemma 4 On-Device** — Google's latest open model runs natively on your phone via LiteRT-LM, with GPU/NPU acceleration
- **No API Keys, No Cost** — No accounts, no subscriptions, no tokens to buy. Download the model once and use it forever
- **Truly Private** — Zero network requests during use. Conversations never leave your device. No analytics, no telemetry
- **Tavern Ecosystem** — Import PNG (steganography) and JSON character cards, worldbooks, lorebooks from Tavern/SillyTavern
- **Story-First UX** — Scene continuation, whisper directives, emotion expressions, session branching
- **Premium Dark Theme** — OLED-optimized with ambient glow effects
- **4 Languages** — English, 简体中文, 日本語, 한국어
- **Accessible** — Screen reader support, reduce-motion compliance

---

## Quick Start

### Install (Android)

1. Download the latest APK from [GitHub Releases](https://github.com/wimi321/aura/releases/latest)
2. Open Aura and choose a story core (E2B for speed, E4B for quality)
3. Wait for the one-time model download (~2.5 GB)
4. Start a built-in story or import your own Tavern card
5. **From now on, everything works offline**

> **APK size**: ~103 MB for the Android arm64 release — the model downloads separately on first launch, then you never need internet again.

### Build from Source

```bash
git clone https://github.com/wimi321/aura.git
cd aura
flutter pub get
flutter run
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed build instructions including iOS.

---

## Models

Aura ships with two curated Gemma 4 variants. Both run entirely on-device after download.

| Model | Download | RAM | Best For |
|-------|----------|-----|----------|
| **Gemma 4 E2B** | ~2.5 GB | 6 GB+ | Fast start, lighter devices |
| **Gemma 4 E4B** | ~3.6 GB | 8 GB+ | Richer vocabulary, longer scenes |

Models download from HuggingFace with SHA256 verification and resume support. You can delete and re-download models at any time from Settings.

---

## Privacy

Aura is designed so that **your conversations are yours alone**:

- **No cloud**: After model download, the app makes zero network requests
- **No accounts**: No sign-up, no login, no user tracking
- **No telemetry**: No analytics, no crash reporting, no usage data
- **No data sync**: Conversations are stored locally and never uploaded
- **Local model**: The AI runs on your phone's processor, not a remote server
- **Open source**: You can audit every line of code

This isn't just a privacy policy — it's an architectural guarantee. There is literally no server to send data to.

---

## Tavern Compatibility

| Format | Status |
|--------|--------|
| Tavern PNG (steganography, `tEXt`/`iTXt` chunks) | Supported |
| Tavern / SillyTavern JSON cards | Supported |
| Embedded `character_book` | Supported |
| Standalone lorebook / worldbook JSON | Supported |
| Alternate greetings | Supported |
| `{{char}}` / `{{user}}` macros | Supported |
| Expression packs (ZIP) | Supported |

Aura automatically strips wrapper tags, removes hidden blocks, and normalizes formatting from imported cards.

---

## Architecture

<details>
<summary>System overview</summary>

```
┌─────────────────────────────────────────────┐
│                Flutter UI                    │
│         (Pages, Widgets, Theme)              │
├─────────────────────────────────────────────┤
│            AppStateProvider                  │
│      (Central ChangeNotifier + Provider)     │
├─────────────────────────────────────────────┤
│           Backend Services                   │
│  (Bootstrap, Platform Channels, Stores)      │
├─────────────────────────────────────────────┤
│              aura_core                       │
│    (Pure Dart: Domain → Orchestration)       │
│                                              │
│  ┌──────────┐ ┌──────────────┐ ┌──────────┐ │
│  │  Domain   │ │ Application  │ │  Infra   │ │
│  │ Models &  │ │ AuraEngine   │ │ Parsers  │ │
│  │  Policy   │ │ Orchestrator │ │ Persist  │ │
│  └──────────┘ └──────────────┘ └──────────┘ │
├─────────────────────────────────────────────┤
│          LiteRT Native Bridge                │
│   Android (LiteRT-LM)  │  iOS (XCFramework) │
│         GPU / NNAPI     │    CoreML / CPU    │
└─────────────────────────────────────────────┘
```

**Message flow**: User input → ChatOrchestrator (prompt assembly + lorebook injection + whisper) → Native Bridge → Gemma 4 on-device → streamed text + emotion signals → UI
</details>

---

## Roadmap

- [x] On-device Gemma 4 inference (E2B + E4B)
- [x] Tavern PNG/JSON card import with worldbook
- [x] Session history and branching
- [x] Whisper directives and emotion system
- [x] 4-language UI (EN/ZH/JA/KO)
- [x] Premium OLED dark theme
- [x] Message copy, timestamps, haptic feedback
- [x] Accessibility (Semantics + reduce-motion)
- [x] Model download recovery for flaky networks
- [ ] Wider Tavern card format compatibility
- [ ] More built-in story genres
- [ ] Tablet-optimized layouts
- [ ] Community card sharing

---

## FAQ

<details>
<summary><strong>Do I need an API key or account?</strong></summary>
No. Aura runs Gemma 4 directly on your phone. There's no API, no account, no subscription. Download the model once and use it forever, completely free.
</details>

<details>
<summary><strong>Is my data really private?</strong></summary>
Yes. After the one-time model download, Aura makes zero network requests — ever. Your conversations, characters, and all data stay on your device. There is no server, no cloud, no telemetry. This is an architectural guarantee, not just a promise.
</details>

<details>
<summary><strong>What devices are supported?</strong></summary>
Android devices with 6 GB+ RAM (for E2B) or 8 GB+ (for E4B). iOS builds from source. Hardware acceleration uses GPU on Android and CoreML on iOS.
</details>

<details>
<summary><strong>Can I import my existing Tavern cards?</strong></summary>
Yes. Aura reads Tavern PNG cards (with embedded metadata via steganography), JSON cards, and standalone worldbook files. Embedded lorebooks are preserved automatically.
</details>

<details>
<summary><strong>Does it work without internet?</strong></summary>
Yes. After the initial model download, Aura works completely offline. You can use it on airplane mode, in areas with no signal, or with Wi-Fi turned off.
</details>

<details>
<summary><strong>Why is the APK ~103 MB?</strong></summary>
The arm64 APK contains the Flutter app and LiteRT-LM runtime but not the model weights. Models (~2.5–3.6 GB) download on first launch so the installer stays shareable.
</details>

---

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for setup instructions, code style, and PR process.

- **Bug reports**: [Bug report template](https://github.com/wimi321/aura/issues/new?template=bug_report.md)
- **Feature ideas**: [Feature request template](https://github.com/wimi321/aura/issues/new?template=feature_request.md)
- **Security issues**: [SECURITY.md](SECURITY.md)

---

## License

[MIT](LICENSE) — use it, fork it, build on it.

---

<p align="center">
  <sub>Built with Flutter. Powered by Gemma 4 running 100% on-device via Google LiteRT-LM.</sub>
  <br />
  <sub>No API keys. No cloud. No cost. Your stories stay yours.</sub>
  <br /><br />
  <sub>If Aura is useful to you, consider giving it a <a href="https://github.com/wimi321/aura">star</a>.</sub>
</p>
