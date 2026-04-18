<p align="center">
  <img src="tooling/branding/aura_android_icon_master.png" alt="Aura icon" width="140" />
</p>

<h1 align="center">Aura</h1>

<p align="center">
  <strong>On-device Tavern-style roleplay for mobile.</strong>
</p>

<p align="center">
  Aura is built for story cards, worldbooks, and scene progression on your phone, not generic chatbot Q&amp;A.
</p>

<p align="center">
  <a href="https://github.com/wimi321/aura/releases/download/v0.1.1/Aura-android-arm64-v0.1.1.apk"><strong>Download APK</strong></a>
  ·
  <a href="https://github.com/wimi321/aura/releases/tag/v0.1.1"><strong>Latest Release</strong></a>
  ·
  <a href="README.zh-CN.md"><strong>简体中文</strong></a>
</p>

<p align="center">
  <img alt="GitHub Release" src="https://img.shields.io/github/v/release/wimi321/aura?display_name=tag&sort=semver">
  <img alt="License" src="https://img.shields.io/github/license/wimi321/aura">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android%20%7C%20iOS-0F172A">
  <img alt="On-device inference" src="https://img.shields.io/badge/inference-on--device-10B981">
  <img alt="Tavern compatible" src="https://img.shields.io/badge/Tavern-compatible-F97316">
</p>

## Why People Try Aura

A lot of local LLM apps still feel like engineering demos.
They surface model jargon, ship chat UIs that look like debugging tools, make Tavern cards feel like raw files, and often ask people to download installers that are far too large for casual mobile use.

Aura goes in the opposite direction:

- story-first UX instead of assistant-style chrome
- on-device inference after the model is downloaded
- Tavern card and worldbook workflows that stay focused on scene progression
- a smaller installer with first-run model download inside the app
- mobile flows written for regular users instead of backend-heavy terminology

## What Makes Aura Different

| If you want... | Aura currently gives you... |
| --- | --- |
| Tavern-style roleplay on mobile | PNG and JSON character-card import with embedded worldbook support |
| A private default path | On-device inference after model download |
| A smaller install | A lightweight APK plus first-run model chooser |
| Story progression instead of generic Q&A | A scene-first chat page and one-tap continue flow |
| Less tool noise | Consumer-facing copy instead of backend-heavy labels |
| Session control that feels usable on mobile | New conversation, session history, and long-press edit/delete |

## Built-in Story Preview

Aura's built-in library is already leaning toward scenario cards, not generic character chat.

<table>
  <tr>
    <td align="center">
      <img src="assets/images/characters/palace-consort.png" alt="Palace intrigue cover" width="220" />
      <br />
      <strong>Palace intrigue</strong>
    </td>
    <td align="center">
      <img src="assets/images/characters/deskmate.png" alt="Campus romance cover" width="220" />
      <br />
      <strong>Campus slow-burn</strong>
    </td>
    <td align="center">
      <img src="assets/images/characters/instance-monitor.png" alt="Rule-based horror cover" width="220" />
      <br />
      <strong>Rule-based horror</strong>
    </td>
  </tr>
</table>

## Real App Preview

These are screenshots from a running Aura build, not concept mockups.

<p align="center">
  <img src="docs/readme/quick-start.gif" alt="Aura quick start flow" width="780" />
</p>

<table>
  <tr>
    <td align="center">
      <img src="docs/readme/story-library.png" alt="Aura story library" width="220" />
      <br />
      <strong>Story library</strong>
    </td>
    <td align="center">
      <img src="docs/readme/model-setup.png" alt="Aura first-run model setup" width="220" />
      <br />
      <strong>First-run model choice</strong>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="docs/readme/chat-scene.png" alt="Aura chat scene" width="220" />
      <br />
      <strong>Scene-reading chat view</strong>
    </td>
    <td align="center">
      <img src="docs/readme/import-flow.png" alt="Aura import flow" width="220" />
      <br />
      <strong>Import flow</strong>
    </td>
  </tr>
</table>

## Install in a Minute

### Android

1. Download the latest APK from [GitHub Releases](https://github.com/wimi321/aura/releases) or use the direct [APK link](https://github.com/wimi321/aura/releases/download/v0.1.1/Aura-android-arm64-v0.1.1.apk).
2. Open Aura.
3. Choose `Gemma 4 E2B` or `Gemma 4 E4B`.
4. Wait for the download to finish.
5. Start a built-in story card or import your own Tavern card.

iOS source is included in this repo, but Android remains the primary public install path right now.

## Why the App Is Smaller Now

Aura no longer ships a full multi-GB model inside the APK.
Instead, the app starts with a lightweight installer and lets the user download the story core they want on first launch.

That means:

- the installer is practical to download and share
- GitHub Releases can host the public Android build cleanly
- first-time setup stays understandable for regular users
- people choose between a quicker start and a higher-quality model inside the app

Current public Android arm64 APK:

- about `126.8MB`

Earlier bundled-model direction:

- about `2.2GB`

## Tavern Compatibility

Aura is built for scenario roleplay and scene progression, not ordinary assistant chat.

Supported today:

- Tavern / SillyTavern PNG character cards
- Tavern / SillyTavern JSON character cards
- embedded `character_book`
- standalone lorebook / worldbook JSON
- imported PNG portraits shown in the library UI

In practice, Aura is meant for:

- scenario roleplay
- scene continuation
- worldbook-aware progression
- mobile reading and writing flows that feel less like an IM client

## FAQ

### Does the APK already contain the full model?

No.
Aura now ships as a smaller installer and downloads the selected model inside the app on first launch.

### Is inference local after the download finishes?

Yes.
The intended product path is on-device inference after the chosen model is stored on the device.

### Can I import Tavern PNG cards directly?

Yes.
Aura supports Tavern-style PNG cards, Tavern / SillyTavern JSON cards, and embedded card metadata.

### Does Aura support worldbooks?

Yes.
Embedded `character_book` data is supported, and standalone lorebook / worldbook JSON can also be imported.

### Is iOS included?

Yes.
The iOS project is part of this repository, and local iOS build scripts are included below.
The large generated native runtime framework is rebuilt locally instead of being stored in Git history.

## Current Validation

Validated in this workspace on April 18, 2026:

```bash
flutter analyze
flutter test
./scripts/build_release_android_arm64.sh
./scripts/build_ios_simulator.sh
./scripts/build_ios_device_no_codesign.sh
./tooling/readme/capture_readme_assets.sh
```

What this covers today:

- static analysis passes
- unit and widget tests pass
- Android arm64 release build works
- iOS simulator build works
- iOS device no-codesign build flow works
- README media assets are generated from a running app build

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

### iOS XCFramework note

If Flutter reports that iOS is not configured correctly, make sure your machine points at the full Xcode developer directory instead of Command Line Tools:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

If the native LiteRT runtime framework is missing locally, rebuild it with:

```bash
./tooling/ios/build_litert_native_xcframework.sh
```

More context:

- [ios/Frameworks/README.md](ios/Frameworks/README.md)

## Roadmap

- improve Tavern card import compatibility across more wild-format cards
- keep expanding built-in scenario cards with stronger genre variety
- polish model download recovery for flaky networks and interrupted setups
- keep validating layout and flows on more phones and tablets
- keep reducing tool-like language in user-facing surfaces

## Contributing / Feedback

If you hit an import compatibility issue, device-specific UI problem, model download failure, or a roleplay flow regression, please open an [issue](https://github.com/wimi321/aura/issues).

If you want to contribute code, content polish, or device validation feedback, pull requests are welcome.
