# Aura Backend Architecture

## Goals

- Keep all roleplay orchestration in Dart so Flutter can iterate quickly.
- Push hardware-specific inference to native LiteRT runtime adapters.
- Make imports, context trimming, lorebook triggering, and emotion routing deterministic and testable.

## Package boundaries

- `lib/src/domain/`: immutable product concepts and policy objects
- `lib/src/application/`: orchestration flows and runtime contracts
- `lib/src/infrastructure/`: file-format parsing and persistence adapters
- `test/`: pure unit tests that should run without device hardware

## Planned native bridge

1. iOS adapter initializes LiteRT-LM with `CoreML` delegate enabled by default.
2. Android adapter initializes LiteRT-LM with `NNAPI`; fallback chain may include GPU then CPU.
3. Adapters expose a token stream back to Dart.
4. Dart applies `EmotionTagFilter`, context summarization policy, lorebook trigger injection, and whisper augmentation.

## Delivery order

1. Pure Dart orchestration and parsers
2. Native LiteRT model lifecycle bridge
3. Resumable model downloader and storage index
4. Audio-frame streaming path
5. Telemetry, thermal fallback, and regression suite

## Implemented in this repository

- `AuraEngine`: high-level entry point for session lifecycle and text/audio turns
- `ChatOrchestrator`: prompt assembly, lore injection, whisper handling, emotion stripping
- `FileSessionRepository` and `MemorySessionRepository`
- `FileModelCatalogRepository` and `MemoryModelCatalogRepository`
- `HttpResumableModelDownloader`
- `PngCharacterCardParser` and `ZipExpressionPackParser`
- `HeuristicSummarizer`

## Environment-dependent remaining work

- Bind `InferenceGateway` to real `flutter_litert` plugin or native platform channel
- Verify delegate fallback order on physical iOS and Android devices
- Replace heuristic summarization with on-device summary inference when model budget allows
