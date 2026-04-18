# Aura Core Backend Notes

## Runtime split

- `application/`: 会话编排、模型生命周期管理
- `domain/`: 角色卡、预设、上下文策略、下载状态
- `infrastructure/`: PNG/JSON 导入解析
- `utils/`: 情绪标签过滤等纯工具逻辑

## Flutter integration direction

1. Flutter UI 通过 platform channel 或 plugin API 调用原生 LiteRT runtime。
2. runtime 负责 model init / load / unload / stream infer。
3. `ChatOrchestrator` 在 Dart 层完成系统提示拼装与世界书注入。
4. 推理返回的 token stream 先经过 `EmotionTagFilter`，再把文本和表情指令拆开发给 UI。
