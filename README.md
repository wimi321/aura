# Aura

Aura is a private, on-device mobile app for Tavern-style roleplay and scene progression.
It is built for story cards, worldbooks, and interactive fiction flow instead of generic chatbot Q&A.

- Repository: [github.com/wimi321/aura](https://github.com/wimi321/aura)
- Android downloads: [GitHub Releases](https://github.com/wimi321/aura/releases)

## What Aura Is

Aura is designed around one clear product idea:

- local, private inference on the device
- story-first UX instead of assistant-style chrome
- direct support for Tavern / SillyTavern character cards
- built-in multilingual consumer experience
- lightweight installer, with model download handled inside the app

## Why It Feels Different

Most local-LLM mobile apps still feel like demos:

- too much engine jargon
- awkward debugging-style interfaces
- character cards treated like raw data rows
- giant install packages because the model is bundled into the APK

Aura goes in the opposite direction:

- cinematic story library and reading-oriented chat layout
- first-run dual-model selection inside the app
- preserved Tavern card metadata and embedded worldbooks
- consumer-facing copy instead of backend-facing terminology

## Highlights

### Story-first experience

- plot-driven built-in cards aimed at scene continuation
- one-tap continue action for advancing the current story beat
- session history, new conversation, and reset flow
- long-press edit and delete for both user and character messages

### Tavern compatibility

- Tavern / SillyTavern PNG card import
- Tavern / SillyTavern JSON card import
- embedded `character_book` and worldbook parsing
- standalone lorebook / worldbook merge support
- imported PNG portrait displayed directly in the library UI

### Local runtime

- Android native LiteRT-LM bridge
- iOS native LiteRT-LM bridge
- no bundled multi-GB model inside the installer
- first-run in-app chooser for:
  - `Gemma 4 E2B` as the recommended path
  - `Gemma 4 E4B` as the higher-quality option

## First-Run Model Flow

Aura no longer ships a multi-GB model inside the app package.

Instead, after install:

1. the app opens normally
2. the user sees a first-run model selection page
3. the user chooses `Gemma 4 E2B` or `Gemma 4 E4B`
4. download finishes inside the app
5. Aura enters the story library and is ready to use

This keeps distribution practical while preserving a simple user journey.

### Package impact

- previous Android package direction: around `2.2GB`
- current Android arm64 release APK: around `100.5MB`

## User Flow

### Android

1. Install the APK from Releases.
2. Open Aura.
3. Choose `Gemma 4 E2B` or `Gemma 4 E4B`.
4. Wait for the download to finish.
5. Start a built-in story card or import a Tavern card.

### iOS

The iOS project is included and builds locally.
The runtime path is being kept aligned with the Android product experience, including first-run downloadable model behavior.

## Current Validation

The following checks were run successfully in this workspace on April 18, 2026:

```bash
flutter analyze
flutter test
./scripts/build_release_android_arm64.sh
./scripts/build_ios_simulator.sh
./scripts/build_ios_device_no_codesign.sh
```

Validated outcomes:

- `flutter analyze`: passed
- `flutter test`: passed
- Android arm64 release APK built successfully
- iOS simulator app built successfully
- iOS device build completed through no-codesign build flow

## Build Commands

### Flutter checks

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

On a clean clone, the scripts will first ensure the local Aura iOS native LiteRT runtime exists.
That XCFramework is not committed to Git because GitHub rejects files above 100MB.

## Xcode Setup Note

If Flutter reports that the app is not configured for iOS, the usual cause is that the machine is pointing at Command Line Tools instead of the full Xcode developer directory.

Aura's iOS helper scripts solve this by exporting:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

If your Xcode installation lives elsewhere, override `DEVELOPER_DIR` before running the scripts.

The iOS native runtime wrapper is intentionally rebuilt locally instead of stored in Git history.
If the XCFramework is missing, the build scripts will attempt to generate it through:

```bash
./tooling/ios/build_litert_native_xcframework.sh
```

## Repository Layout

```text
lib/                     Flutter app shell, pages, providers, localization
packages/aura_core/      Core roleplay engine, card import, worldbook parsing
android/                 Android native LiteRT-LM bridge
ios/                     iOS native LiteRT-LM bridge
assets/images/           Bundled visual assets and character covers
scripts/                 Repeatable build commands
tooling/                 Local tooling for branding and device-side smoke work
```

## Product Direction

Aura is intentionally not positioned as an “AI companion” app.

Its product direction is closer to:

- interactive fiction
- scenario roleplay
- story-card driven progression
- worldbook-aware scene continuation
- mobile-native local inference

The long-term priorities are:

- stronger Tavern card compatibility
- cleaner worldbook handling at scale
- better scene continuity under long conversations
- lower-friction import for community cards
- increasingly polished consumer UX

## Acknowledgements

Aura learns from the local inference ecosystem around:

- [google-ai-edge/gallery](https://github.com/google-ai-edge/gallery)
- [google-ai-edge/LiteRT-LM](https://github.com/google-ai-edge/LiteRT-LM)
- Tavern / SillyTavern character-card conventions

## Status

Aura is already usable as a local mobile story-roleplay app, with Android currently the most release-ready path.

The next release steps are:

- publish the source to GitHub
- attach the Android release APK to GitHub Releases
- keep polishing built-in cards, covers, onboarding, and iOS packaging

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
