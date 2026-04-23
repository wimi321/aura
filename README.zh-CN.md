<p align="center">
  <img src="tooling/branding/aura_android_icon_master.png" alt="Aura 图标" width="140" />
</p>

<h1 align="center">Aura</h1>

<p align="center">
  <strong>手机直接跑 Gemma 4。离线角色扮演。不用 API、不花钱、不上网。</strong>
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
  <img alt="Gemma 4" src="https://img.shields.io/badge/model-Gemma%204-4285F4?style=flat-square&logo=google">
  <img alt="离线" src="https://img.shields.io/badge/网络-完全离线-10B981?style=flat-square">
  <img alt="Tavern" src="https://img.shields.io/badge/Tavern-兼容-F97316?style=flat-square">
  <img alt="Languages" src="https://img.shields.io/badge/i18n-EN%20%7C%20ZH%20%7C%20JA%20%7C%20KO-6366F1?style=flat-square">
</p>

---

## 为什么选 Aura？

大多数 AI 角色扮演应用都依赖云端 API — 这意味着**按量付费**、**对话内容经过服务器**、**断网就用不了**。

Aura 走了一条完全不同的路：

| | 云端 API 应用 | Aura |
|---|---|---|
| **大模型配置** | 注册账号、申请 API Key、绑定支付 | 在 App 里下载一次，搞定 |
| **费用** | 按 token 计费 / 包月订阅 | 下载后永久免费 |
| **隐私** | 对话内容经过第三方服务器 | 所有内容留在手机上 |
| **网络** | 每条消息都需要联网 | 仅首次下载模型需要网络 |
| **内容审查** | 服务商决定你能说什么 | 你拥有模型，没有限制 |
| **可用性** | 服务可能停机或修改条款 | 离线运行，永远可用 |

**Aura 在你的手机上直接运行 [Gemma 4](https://ai.google.dev/gemma)**，通过 Google LiteRT-LM 推理引擎，支持 GPU / NPU 硬件加速。首次下载模型后（约 2.5 GB），App 再也不会联系任何服务器。你的故事、你的角色、你的对话 — 永远不会离开你的设备。

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

## 核心特性

- **Gemma 4 端侧运行** — Google 最新开放模型通过 LiteRT-LM 原生运行在手机上，支持 GPU/NPU 加速
- **不用 API、不花钱** — 没有账号、没有订阅、没有 token 费用。下载一次，永久使用
- **真正的隐私** — 使用过程中零网络请求。对话内容永远不会离开设备。无数据分析，无遥测
- **Tavern 生态** — 导入 PNG（隐写术）和 JSON 角色卡、世界书、设定集
- **剧情优先** — 场景续写、耳语指令、表情系统、会话分支
- **顶级暗色主题** — OLED 深黑优化，环境光效果
- **四语言** — English、简体中文、日本語、한국어
- **无障碍** — 屏幕阅读器支持，减弱动画适配

---

## 快速开始

### 安装（Android）

1. 从 [GitHub Releases](https://github.com/wimi321/aura/releases/latest) 下载最新 APK
2. 打开 Aura，选择剧情引擎（E2B 更快启动，E4B 品质更高）
3. 等待一次性模型下载完成（约 2.5 GB）
4. 选一个内置剧情，或导入你自己的 Tavern 角色卡
5. **从此以后，完全离线可用**

> **APK 大小**：Android arm64 发布包约 103 MB — 模型在首次启动时单独下载，之后再也不需要联网。

### 从源码构建

```bash
git clone https://github.com/wimi321/aura.git
cd aura
flutter pub get
flutter run
```

详细构建指南（含 iOS）请参阅 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

## 模型

Aura 内置两个精选 Gemma 4 变体，下载后完全在设备端运行。

| 模型 | 下载大小 | 内存要求 | 适用场景 |
|------|----------|----------|----------|
| **Gemma 4 E2B** | ~2.5 GB | 6 GB+ | 快速启动，轻量设备 |
| **Gemma 4 E4B** | ~3.6 GB | 8 GB+ | 更丰富的词汇，更长的场景 |

模型从 HuggingFace 下载，支持 SHA256 校验和断点续传。随时可以在设置中删除或重新下载。

---

## 隐私保障

Aura 的设计确保**你的对话只属于你自己**：

- **无云端**：模型下载后，App 不发起任何网络请求
- **无账号**：不需要注册、登录、绑定任何身份
- **无遥测**：没有数据分析、没有崩溃上报、没有使用统计
- **无同步**：对话数据存在本地，永远不会上传
- **本地模型**：AI 跑在你手机的处理器上，不是远程服务器
- **开源透明**：每一行代码都可以审查

这不只是一份隐私政策 — 这是架构层面的保证。根本就没有服务器可以把数据发过去。

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

Aura 自动清理包裹标签、隐藏块，并规范化导入卡片的格式。

---

## 架构

<details>
<summary>系统架构概览</summary>

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

**消息流**：用户输入 → ChatOrchestrator（提示词组装 + 世界书注入 + 耳语指令）→ 原生桥接 → Gemma 4 端侧推理 → 流式文本 + 情绪信号 → UI 渲染
</details>

---

## 路线图

- [x] 端侧 Gemma 4 推理（E2B + E4B）
- [x] Tavern PNG/JSON 角色卡导入 + 世界书
- [x] 会话历史与分支管理
- [x] 耳语指令与表情系统
- [x] 四语言界面（EN/ZH/JA/KO）
- [x] 沉浸式 OLED 暗色主题
- [x] 消息复制、时间戳、触觉反馈
- [x] 无障碍（语义化标签 + 减弱动画）
- [x] 弱网环境下载恢复
- [ ] 更广泛的 Tavern 卡格式兼容
- [ ] 更多内置剧情题材
- [ ] 平板适配布局
- [ ] 社区卡片分享

---

## 常见问题

<details>
<summary><strong>需要 API Key 或注册账号吗？</strong></summary>
不需要。Aura 直接在手机上运行 Gemma 4。没有 API、没有账号、没有订阅。下载模型后永久免费使用。
</details>

<details>
<summary><strong>数据真的安全吗？</strong></summary>
安全。模型下载完成后，Aura 不发起任何网络请求。对话、角色和所有数据留在设备上。没有服务器、没有云端、没有遥测。这是架构层面的保证，不只是承诺。
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
<summary><strong>离线能用吗？</strong></summary>
能。首次下载模型后，Aura 完全离线运行。飞行模式、无信号区、关掉 Wi-Fi 都可以正常使用。
</details>

<details>
<summary><strong>为什么 APK 约 103 MB？</strong></summary>
Android arm64 APK 包含 Flutter 应用和 LiteRT-LM 运行时，但不含模型权重。模型（约 2.5–3.6 GB）在首次启动时下载，这样安装包才方便分享。
</details>

---

## 参与贡献

欢迎贡献！请参阅 [CONTRIBUTING.md](CONTRIBUTING.md) 了解开发环境搭建、代码规范和 PR 流程。

- **Bug 报告**：[Bug 模板](https://github.com/wimi321/aura/issues/new?template=bug_report.md)
- **功能建议**：[功能请求模板](https://github.com/wimi321/aura/issues/new?template=feature_request.md)
- **安全问题**：[SECURITY.md](SECURITY.md)

---

## 许可证

[MIT](LICENSE) — 自由使用、Fork、在此基础上构建。

---

<p align="center">
  <sub>基于 Flutter 构建，由 Gemma 4 在手机端侧 100% 本地运行（Google LiteRT-LM）。</sub>
  <br />
  <sub>不用 API。不花钱。不上网。你的故事只属于你。</sub>
  <br /><br />
  <sub>如果 Aura 对你有用，欢迎给个 <a href="https://github.com/wimi321/aura">Star</a>。</sub>
</p>
