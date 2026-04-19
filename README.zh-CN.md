<p align="center">
  <img src="tooling/branding/aura_android_icon_master.png" alt="Aura 图标" width="140" />
</p>

<h1 align="center">Aura</h1>

<p align="center">
  <strong>端侧 AI 角色扮演引擎 — Tavern 角色卡、世界书、场景推进，全部在手机本地运行。</strong>
</p>

<p align="center">
  <a href="https://github.com/wimi321/aura/releases/latest"><strong>下载 APK</strong></a>
  &nbsp;·&nbsp;
  <a href="https://github.com/wimi321/aura/releases"><strong>所有版本</strong></a>
  &nbsp;·&nbsp;
  <a href="CHANGELOG.md"><strong>更新日志</strong></a>
  &nbsp;·&nbsp;
  <a href="README.md"><strong>English</strong></a>
</p>

<p align="center">
  <a href="https://github.com/wimi321/aura/releases/latest"><img alt="GitHub Release" src="https://img.shields.io/github/v/release/wimi321/aura?display_name=tag&sort=semver&style=flat-square"></a>
  <a href="https://github.com/wimi321/aura/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/wimi321/aura/ci.yml?branch=main&style=flat-square&label=CI"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/github/license/wimi321/aura?style=flat-square"></a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android%20%7C%20iOS-0F172A?style=flat-square">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter">
  <img alt="端侧推理" src="https://img.shields.io/badge/推理-100%25%20端侧-10B981?style=flat-square">
  <img alt="Tavern" src="https://img.shields.io/badge/Tavern-兼容-F97316?style=flat-square">
  <img alt="Languages" src="https://img.shields.io/badge/i18n-EN%20%7C%20ZH%20%7C%20JA%20%7C%20KO-6366F1?style=flat-square">
</p>

---

## Aura 是什么？

Aura 是一款开源、隐私优先的 AI 角色扮演应用，**完全在手机端侧运行**。不需要云端，不需要 API Key，没有任何数据离开你的设备。

导入任何 Tavern / SillyTavern 角色卡，加载一个本地 Gemma 4 模型，直接开始剧情 — 模型下载完成后完全离线可用。

### 核心特性

- **100% 端侧推理** — 通过 Google LiteRT-LM 运行 Gemma 4，支持 GPU/NPU 加速
- **Tavern 生态兼容** — 导入 PNG（隐写术）和 JSON 角色卡、世界书、设定集
- **剧情优先 UX** — 场景续写、耳语指令、表情系统、会话分支
- **隐私即设计** — 正常使用期间零网络请求，所有数据留在设备上
- **顶级暗色主题** — OLED 深黑优化，环境光效果，Material 3 语义化配色
- **四语言界面** — 英文、简体中文、日本語、한국어
- **无障碍** — 完整屏幕阅读器支持，尊重系统减弱动画设置

---

## 应用截图

<p align="center">
  <img src="docs/readme/story-library.png" alt="剧本库" width="180" />&nbsp;&nbsp;
  <img src="docs/readme/chat-scene.png" alt="剧情聊天" width="180" />&nbsp;&nbsp;
  <img src="docs/readme/model-setup.png" alt="模型选择" width="180" />&nbsp;&nbsp;
  <img src="docs/readme/import-flow.png" alt="导入流程" width="180" />
</p>

<p align="center">
  <sub>剧本库 &nbsp;·&nbsp; 沉浸式剧情 &nbsp;·&nbsp; 模型选择 &nbsp;·&nbsp; 卡片导入</sub>
</p>

<details>
<summary>内置剧情卡</summary>
<br />
<p align="center">
  <img src="assets/images/characters/palace-consort.png" alt="宫廷悬局" width="140" />&nbsp;&nbsp;
  <img src="assets/images/characters/deskmate.png" alt="校园慢热" width="140" />&nbsp;&nbsp;
  <img src="assets/images/characters/instance-monitor.png" alt="规则怪谈" width="140" />
</p>
<p align="center">
  <sub>宫廷悬局 &nbsp;·&nbsp; 校园慢热 &nbsp;·&nbsp; 规则怪谈</sub>
</p>
</details>

---

## 快速开始

### 安装（Android）

1. 从 [GitHub Releases](https://github.com/wimi321/aura/releases/latest) 下载最新 APK
2. 打开 Aura，选择剧情引擎（E2B 更快启动，E4B 品质更高）
3. 等待约 2.5 GB 模型下载完成
4. 选一个内置剧情，或导入你自己的 Tavern 角色卡

> **APK 大小**：约 155 MB（模型在首次启动时单独下载）

### 从源码构建

```bash
git clone https://github.com/wimi321/aura.git
cd aura
flutter pub get
flutter run
```

详细构建指南（含 iOS）请参阅 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

## 架构

```
┌─────────────────────────────────────────────┐
│                Flutter UI                    │
│           (页面、组件、主题)                    │
├─────────────────────────────────────────────┤
│            AppStateProvider                  │
│       (中央 ChangeNotifier + Provider)        │
├─────────────────────────────────────────────┤
│              后端服务层                        │
│     (启动引导、平台通道、持久化存储)                │
├─────────────────────────────────────────────┤
│              aura_core                       │
│      (纯 Dart：领域模型 → 编排逻辑)              │
│                                              │
│  ┌──────────┐ ┌──────────────┐ ┌──────────┐ │
│  │ 领域模型  │ │  应用编排层    │ │ 基础设施  │ │
│  │ 策略对象  │ │ AuraEngine   │ │ 解析/持久 │ │
│  └──────────┘ └──────────────┘ └──────────┘ │
├─────────────────────────────────────────────┤
│          LiteRT 原生桥接层                    │
│   Android (LiteRT-LM)  │  iOS (XCFramework) │
│       GPU / NNAPI       │    CoreML / CPU    │
└─────────────────────────────────────────────┘
```

### 消息处理流程

```
用户输入 → AppStateProvider → AuraEngine → ChatOrchestrator
  → 提示词组装（系统提示 + 世界书注入 + 耳语指令）
  → InferenceGateway → 原生桥接 → Gemma 4 端侧推理
  → StreamDelta（文本 + 情绪信号）→ UI 渲染
```

---

## Tavern 兼容性

| 格式 | 状态 |
|------|------|
| Tavern PNG（隐写术，`tEXt`/`iTXt` 块） | 已支持 |
| Tavern / SillyTavern JSON 角色卡 | 已支持 |
| 内嵌 `character_book` | 已支持 |
| 独立 lorebook / worldbook JSON | 已支持 |
| 备用开场白（alternate greetings） | 已支持 |
| `{{char}}` / `{{user}}` 宏替换 | 已支持 |
| 表情包（ZIP） | 已支持 |

Aura 自动清理包裹标签（`<gametxt>`、`<options>` 等）、隐藏块（`<thinking>`、`<UpdateVariable>`），并规范化 `<START>` 标记。

---

## 模型

| 模型 | 大小 | 内存要求 | 适用场景 |
|------|------|----------|----------|
| Gemma 4 E2B | ~2.5 GB | 6 GB+ | 快速启动，轻量设备 |
| Gemma 4 E4B | ~3.6 GB | 8 GB+ | 更丰富的词汇，更长的场景 |

模型从 HuggingFace 下载，支持 SHA256 校验和断点续传。下载完成后，**所有推理 100% 本地运行**。

---

## 路线图

- [x] 端侧 Gemma 4 推理（E2B + E4B）
- [x] Tavern PNG/JSON 角色卡导入 + 世界书
- [x] 会话历史与分支管理
- [x] 耳语指令与表情系统
- [x] 四语言界面（EN/ZH/JA/KO）
- [x] 顶级 OLED 暗色主题
- [x] 消息复制、时间戳、触觉反馈
- [x] 无障碍（语义化标签 + 减弱动画）
- [ ] 更广泛的 Tavern 卡格式兼容
- [ ] 更多内置剧情题材
- [ ] 平板适配布局
- [ ] 弱网环境下载恢复
- [ ] 社区卡片分享

---

## 常见问题

<details>
<summary><strong>推理真的是本地的吗？</strong></summary>
是的。模型下载完成后，Aura 不会发起任何网络请求。所有文本生成都在设备端通过 LiteRT-LM 完成。
</details>

<details>
<summary><strong>支持哪些设备？</strong></summary>
6 GB+ 内存的 Android 设备（E2B）或 8 GB+（E4B）。iOS 可从源码构建。硬件加速在 Android 上使用 GPU，iOS 上使用 CoreML。
</details>

<details>
<summary><strong>能导入已有的 Tavern 角色卡吗？</strong></summary>
可以。Aura 支持 Tavern PNG 卡（通过隐写术读取嵌入元数据）、JSON 卡，以及独立的世界书文件。内嵌的 lorebook 会自动保留。
</details>

<details>
<summary><strong>数据安全吗？</strong></summary>
安全。对话记录、角色卡和所有用户数据都留在设备上。没有数据分析、没有遥测、没有云同步。
</details>

<details>
<summary><strong>为什么 APK 约 155 MB？</strong></summary>
APK 包含 Flutter 应用和 LiteRT-LM 运行时，但不含模型权重。模型（约 2.5–3.6 GB）在首次启动时下载，这样安装包才方便分享。
</details>

---

## 参与贡献

欢迎贡献！请参阅 [CONTRIBUTING.md](CONTRIBUTING.md) 了解开发环境搭建、代码规范和 PR 流程。

- **Bug 报告**：使用 [Bug 模板](https://github.com/wimi321/aura/issues/new?template=bug_report.md)
- **功能建议**：使用 [功能请求模板](https://github.com/wimi321/aura/issues/new?template=feature_request.md)
- **安全问题**：请参阅 [SECURITY.md](SECURITY.md)

---

## 许可证

[MIT](LICENSE) — 自由使用、Fork、在此基础上构建。

---

<p align="center">
  <sub>基于 Flutter 构建，由 Gemma 4 端侧推理驱动（Google LiteRT-LM）。</sub>
  <br />
  <sub>如果 Aura 对你有用，欢迎给个 <a href="https://github.com/wimi321/aura">Star</a>。</sub>
</p>
