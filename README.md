<p align="center">
  <img src="tooling/branding/aura_android_icon_master.png" alt="Aura icon" width="140" />
</p>

<h1 align="center">Aura</h1>

<p align="center">
  <strong>Private, on-device Tavern-style roleplay for mobile.</strong>
</p>

<p align="center">
  Aura is built for story cards, worldbooks, and scene progression on your phone, not generic chatbot Q&A.
</p>

<p align="center">
  <a href="https://github.com/wimi321/aura/releases">Download APK</a>
  ·
  <a href="https://github.com/wimi321/aura/releases/tag/v0.1.0">Latest Release</a>
  ·
  <a href="README.zh-CN.md">简体中文</a>
</p>

<p align="center">
  <img alt="GitHub Release" src="https://img.shields.io/github/v/release/wimi321/aura?display_name=tag&sort=semver">
  <img alt="License" src="https://img.shields.io/github/license/wimi321/aura">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android%20%7C%20iOS-0F172A">
  <img alt="Runtime" src="https://img.shields.io/badge/inference-on--device-10B981">
  <img alt="Tavern Compatible" src="https://img.shields.io/badge/Tavern-compatible-F97316">
</p>

## Why People Try Aura

Most local-LLM mobile apps still feel like model demos.
They expose engine jargon, ship awkward chat layouts, and make Tavern cards feel like raw files instead of living story setups.

Aura takes the opposite approach:

- import a Tavern card and start the scene on your phone
- keep inference on-device after the model is downloaded
- use a story-first UI instead of assistant-style chat chrome
- preserve embedded worldbooks instead of flattening everything into plain text
- keep the installer small by downloading the model inside the app on first launch

## What Makes Aura Different

| If you want... | Aura gives you... |
| --- | --- |
| Tavern roleplay on mobile | PNG and JSON character-card import with worldbook support |
| Privacy | On-device inference instead of cloud chat as the default product shape |
| A simple install flow | A lightweight APK plus first-run model download |
| A story-reading feel | Scene continuation UX instead of generic IM bubbles |
| Less engineering noise | Consumer-facing copy instead of backend-heavy terminology |

## At a Glance

- Android-first public release, with iOS source included in the repo
- first-run model chooser with `Gemma 4 E2B` and `Gemma 4 E4B`
- built-in multilingual experience
- long-press edit and delete for both user and character turns
- new conversation, session history, and reset flow
- one-tap continue action for pushing the current scene forward
- imported PNG portraits shown directly in the story library

## Built-in Story Preview

These are examples of the built-in story directions Aura is already leaning into.

<table>
  <tr>
    <td align="center">
      <img src="assets/images/characters/palace-consort.png" alt="Palace Consort cover" width="220" />
      <br />
      <strong>Palace intrigue</strong>
    </td>
    <td align="center">
      <img src="assets/images/characters/young-marshal.png" alt="Young Marshal cover" width="220" />
      <br />
      <strong>Republic-era suspense</strong>
    </td>
    <td align="center">
      <img src="assets/images/characters/shelter-captain.png" alt="Shelter Captain cover" width="220" />
      <br />
      <strong>Post-collapse survival</strong>
    </td>
  </tr>
</table>

## Install in a Minute

### Android

1. Download the latest APK from [GitHub Releases](https://github.com/wimi321/aura/releases).
2. Install and open Aura.
3. Pick your first local story core:
   - `Gemma 4 E2B`: recommended, faster to get started
   - `Gemma 4 E4B`: higher quality, larger download
4. Wait for the in-app download to finish.
5. Open a built-in story card or import your own Tavern card.

### What happens on first launch

Aura no longer bundles a multi-GB model inside the installer.
That means:

- the APK stays practical to download and share
- users still get a simple first-run experience
- model choice happens inside the app instead of before install

Current Android arm64 release APK size:

- about `100.5MB`

Earlier bundled-model direction:

- about `2.2GB`

## Tavern Compatibility

Aura is built around story-card workflows, not just open-ended chatbot prompts.

Supported today:

- Tavern / SillyTavern PNG character cards
- Tavern / SillyTavern JSON character cards
- embedded `character_book` / worldbook data
- standalone lorebook / worldbook JSON import and merge
- imported PNG portrait display in the library UI

Aura is especially aimed at users who want:

- scenario roleplay
- scene continuation
- worldbook-aware progression
- stronger sense of atmosphere than a typical messenger UI

## What the Experience Feels Like

Aura is intentionally not positioned as an “AI companion” app.
It is closer to:

- interactive fiction on mobile
- Tavern-style roleplay with built-in local inference
- a story library you can step into, not a bot list you poke at

The product direction is simple:

- less tool feel
- more scene feel
- less prompt babysitting
- more natural progression through cards, context, and worldbook entries

## Current Status

Aura is already usable as a local mobile story-roleplay app.

What is already working in this repo:

- `flutter analyze`
- `flutter test`
- Android arm64 release build
- iOS simulator build
- iOS device no-codesign build flow

Validated in this workspace on April 18, 2026:

```bash
flutter analyze
flutter test
./scripts/build_release_android_arm64.sh
./scripts/build_ios_simulator.sh
./scripts/build_ios_device_no_codesign.sh
```

## Download

- Releases page: [github.com/wimi321/aura/releases](https://github.com/wimi321/aura/releases)
- Latest Android APK: [Aura-android-arm64-v0.1.0.apk](https://github.com/wimi321/aura/releases/download/v0.1.0/Aura-android-arm64-v0.1.0.apk)
- Latest release notes: [Aura v0.1.0](https://github.com/wimi321/aura/releases/tag/v0.1.0)

APK checksum for `v0.1.0`:

- `SHA256`: `b69e2d8a04154f78ad03bc290ef9f6efcdeb9d646397bbff96e29ac2a7c87610`

## FAQ

### Does the APK already contain the full model?

No.
Aura now uses a smaller installer and downloads the selected model inside the app on first launch.

### Is inference local after that?

Yes.
The intended product path is on-device inference once the model has been downloaded to the device.

### Can I import Tavern PNG cards directly?

Yes.
Aura supports Tavern-style PNG cards and also supports JSON card import.

### Does Aura support worldbooks?

Yes.
Embedded `character_book` content is supported, and standalone lorebook / worldbook JSON can also be merged.

### Is iOS included?

Yes, the iOS project is included in the repository.
For GitHub compatibility, the large generated iOS native runtime XCFramework is rebuilt locally instead of being stored in Git history.

## Developer Quick Start

```bash
flutter pub get
flutter analyze
flutter test
```

### Android arm64 release

```bash
./scripts/build_release_android_arm64.sh
```

Output:

- `build/app/outputs/flutter-apk/app-release.apk`

### iOS simulator

```bash
./scripts/build_ios_simulator.sh
```

Output:

- `build/ios/iphonesimulator/Runner.app`

### iOS device build without codesign

```bash
./scripts/build_ios_device_no_codesign.sh
```

Output:

- `build/ios/iphoneos/Runner.app`

## iOS Build Note

If Flutter says the app is not configured for iOS, the usual cause is that your machine is pointing at Command Line Tools instead of the full Xcode developer directory.

Aura's iOS build scripts solve this by exporting:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

If your Xcode lives elsewhere, override `DEVELOPER_DIR` before running the scripts.

If the local iOS runtime wrapper is missing, Aura can regenerate it through:

```bash
./tooling/ios/build_litert_native_xcframework.sh
```

See also:

- [ios/Frameworks/README.md](ios/Frameworks/README.md)

## Repository Layout

```text
lib/                     Flutter app shell, pages, providers, localization
packages/aura_core/      Core roleplay engine, card import, worldbook parsing
android/                 Android native LiteRT-LM bridge
ios/                     iOS native LiteRT-LM bridge
assets/images/           Bundled visual assets and character covers
scripts/                 Repeatable build commands
tooling/                 Branding and local device-side tooling
```

## Roadmap

Aura is already usable, but the direction is still pushing toward a more polished consumer product.

Current priorities:

- better long-context scene continuity
- richer built-in cards and cover art
- even smoother import flow for real community cards
- stronger iOS packaging and first-run parity
- more visual polish without adding engineering clutter

## Acknowledgements

Aura learns from the local inference ecosystem around:

- [google-ai-edge/gallery](https://github.com/google-ai-edge/gallery)
- [google-ai-edge/LiteRT-LM](https://github.com/google-ai-edge/LiteRT-LM)
- Tavern / SillyTavern character-card conventions

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
