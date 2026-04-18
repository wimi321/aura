<p align="center">
  <img src="tooling/branding/aura_android_icon_master.png" alt="Aura 图标" width="140" />
</p>

<h1 align="center">Aura</h1>

<p align="center">
  <strong>面向 Tavern 剧情角色卡的本地移动端沉浸式角色扮演应用。</strong>
</p>

<p align="center">
  Aura 不是通用聊天机器人壳子，而是为剧情推进、角色卡、世界书和本地推理而做的移动端体验。
</p>

<p align="center">
  <a href="https://github.com/wimi321/aura/releases">下载 APK</a>
  ·
  <a href="https://github.com/wimi321/aura/releases/tag/v0.1.0">最新版本</a>
  ·
  <a href="README.md">English</a>
</p>

## 这是什么项目

很多本地大模型 App 现在看起来更像“模型演示器”：

- 术语太工程化
- 页面像调试工具
- 角色卡像数据库条目
- 安装包动不动就是几个 G

Aura 走的是另一条路线：

- 以剧情推进为核心，而不是问答聊天
- 以角色卡和世界书为中心，而不是一堆参数面板
- 以移动端沉浸体验为目标，而不是开发者测试壳
- 以小包体 + 首启下载模型的方式，让普通用户也能装得动、用得明白

## 用户为什么会喜欢 Aura

| 你想要什么 | Aura 现在提供什么 |
| --- | --- |
| 手机上直接跑 Tavern 剧情卡 | 支持 Tavern / SillyTavern PNG 与 JSON 角色卡导入 |
| 更私密的体验 | 模型下载后走端侧本地推理 |
| 不想下载超大安装包 | 安装包轻量化，首启在 App 内选模型下载 |
| 更像剧情阅读而不是聊天软件 | UI 按剧情沉浸感设计，而不是普通 IM 气泡 |
| 少一点“工程味” | 文案和流程尽量面向普通用户 |

## 现在已经有的能力

- Android 首发可直接体验
- 仓库内已包含 iOS 工程
- 首启双模型选择：`Gemma 4 E2B` / `Gemma 4 E4B`
- 支持内置剧情卡与外部 Tavern 角色卡导入
- 支持世界书与 `character_book`
- 支持新建会话、历史会话、重置流程
- 支持长按编辑与删除用户 / 角色消息
- 支持多语言 UI
- 支持继续当前剧情的推进式体验

## 内置剧情风格预览

下面这些封面，代表了 Aura 当前已经在做的内置剧情方向。

<table>
  <tr>
    <td align="center">
      <img src="assets/images/characters/palace-consort.png" alt="宫廷夜审封面" width="220" />
      <br />
      <strong>宫廷悬局</strong>
    </td>
    <td align="center">
      <img src="assets/images/characters/young-marshal.png" alt="少帅雨夜封面" width="220" />
      <br />
      <strong>民国雨夜疑局</strong>
    </td>
    <td align="center">
      <img src="assets/images/characters/shelter-captain.png" alt="末日避难站封面" width="220" />
      <br />
      <strong>末日生死抉择</strong>
    </td>
  </tr>
</table>

## 一分钟上手

### 安卓用户

1. 打开 [GitHub Releases](https://github.com/wimi321/aura/releases) 下载 APK。
2. 安装并打开 Aura。
3. 首次启动时选择模型：
   - `Gemma 4 E2B`：更适合快速开始，推荐首选
   - `Gemma 4 E4B`：效果更强，但下载更大
4. 等待模型下载完成。
5. 进入内置剧情卡，或者导入你自己的 Tavern 角色卡开始体验。

## 为什么现在更适合普通用户安装

Aura 不再把多 GB 模型直接塞进 APK 里。

这意味着：

- 安装包明显更小
- GitHub Release 可以直接分发
- 用户安装后打开 App，自然进入“选模型下载”的消费级流程
- 不需要在下载 App 之前就理解一堆模型概念

当前 Android arm64 APK 体积：

- 约 `100.5MB`

此前捆绑模型方向的体积：

- 约 `2.2GB`

## 兼容什么角色卡

Aura 目前支持：

- Tavern / SillyTavern PNG 角色卡
- Tavern / SillyTavern JSON 角色卡
- PNG 角色卡内嵌头像展示
- `character_book` / 世界书解析
- 独立 lorebook / worldbook JSON 导入与合并

它更适合这类玩法：

- 剧情代入
- 角色扮演
- 世界书驱动的设定展开
- 按场景推进，而不是单轮问答

## Aura 想做成什么样

Aura 不想做“AI 陪伴应用”。

它更像：

- 手机上的互动剧情入口
- 能直接吃 Tavern 卡的本地剧情 App
- 一个你点开角色卡就能进戏的移动端阅读 / 扮演产品

方向上我们更重视：

- 更强的剧情连续性
- 更自然的角色一致性
- 更轻的导入学习成本
- 更少的工程术语暴露
- 更完整的消费级质感

## 当前验证状态

以下检查已经在这个仓库里跑通：

```bash
flutter analyze
flutter test
./scripts/build_release_android_arm64.sh
./scripts/build_ios_simulator.sh
./scripts/build_ios_device_no_codesign.sh
```

已验证结果：

- `flutter analyze` 通过
- `flutter test` 通过
- Android arm64 Release 构建通过
- iOS Simulator 构建通过
- iOS 无签名设备构建流程通过

## 下载入口

- Releases 页面：[github.com/wimi321/aura/releases](https://github.com/wimi321/aura/releases)
- 最新 Android APK：[Aura-android-arm64-v0.1.0.apk](https://github.com/wimi321/aura/releases/download/v0.1.0/Aura-android-arm64-v0.1.0.apk)
- 最新版本说明：[Aura v0.1.0](https://github.com/wimi321/aura/releases/tag/v0.1.0)

`v0.1.0` APK 校验值：

- `SHA256`: `b69e2d8a04154f78ad03bc290ef9f6efcdeb9d646397bbff96e29ac2a7c87610`

## 常见问题

### APK 里面已经自带完整模型了吗？

没有。
Aura 现在走的是“小安装包 + 首启应用内下载模型”的方案。

### 下载完模型以后，是本地推理吗？

是的。
Aura 的目标产品路径是模型下载到设备后在本地完成推理。

### 能直接导入 Tavern 的 PNG 卡吗？

可以。
Aura 支持 Tavern 风格 PNG 卡，也支持 JSON 卡。

### 世界书支持吗？

支持。
内嵌 `character_book` 可以识别，独立 lorebook / worldbook JSON 也支持导入与合并。

### iOS 有吗？

有。
仓库内已经包含 iOS 工程；只是因为 GitHub 单文件大小限制，iOS 本地原生运行时框架改成按需本地生成，而不是直接塞进 Git 历史。

## 开发者快速开始

```bash
flutter pub get
flutter analyze
flutter test
```

### Android arm64 Release

```bash
./scripts/build_release_android_arm64.sh
```

### iOS Simulator

```bash
./scripts/build_ios_simulator.sh
```

### iOS 设备无签名构建

```bash
./scripts/build_ios_device_no_codesign.sh
```

## iOS 说明

如果 Flutter 提示 iOS 未正确配置，常见原因是系统指向了 Command Line Tools，而不是完整 Xcode。

Aura 的 iOS 脚本默认使用：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

如果本地缺少原生 LiteRT 运行时封装，可通过下面脚本重新生成：

```bash
./tooling/ios/build_litert_native_xcframework.sh
```

补充说明见：

- [ios/Frameworks/README.md](ios/Frameworks/README.md)

## 项目结构

```text
lib/                     Flutter 应用壳、页面、状态和本地化
packages/aura_core/      剧情引擎、角色卡解析、世界书解析
android/                 Android 原生 LiteRT-LM 桥接
ios/                     iOS 原生 LiteRT-LM 桥接
assets/images/           内置资源与角色封面图
scripts/                 构建脚本
tooling/                 品牌资源与本地辅助工具
```

## 后续方向

Aura 已经可用，但目标不是“能跑就行”，而是继续打磨成真正的消费级产品。

当前重点包括：

- 更强的长上下文剧情连续性
- 更成熟的内置剧情卡与封面体系
- 更顺手的真实社区角色卡导入体验
- 更完整的 iOS 首发链路
- 在不增加工程味的前提下继续提升 UI 质感

## 致谢

Aura 的运行时和产品方向参考了这些生态：

- [google-ai-edge/gallery](https://github.com/google-ai-edge/gallery)
- [google-ai-edge/LiteRT-LM](https://github.com/google-ai-edge/LiteRT-LM)
- Tavern / SillyTavern 角色卡生态

## License

本项目使用 MIT License，详见 [LICENSE](LICENSE)。
