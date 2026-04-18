<p align="center">
  <img src="tooling/branding/aura_android_icon_master.png" alt="Aura 图标" width="140" />
</p>

<h1 align="center">Aura</h1>

<p align="center">
  <strong>面向 Tavern 剧情卡的本地移动端沉浸式角色扮演应用。</strong>
</p>

<p align="center">
  Aura 不是通用聊天机器人壳子，而是为剧情推进、角色卡、世界书和手机端本地推理而做的产品形态。
</p>

<p align="center">
  <a href="https://github.com/wimi321/aura/releases/download/v0.1.0/Aura-android-arm64-v0.1.0.apk"><strong>下载 APK</strong></a>
  ·
  <a href="https://github.com/wimi321/aura/releases/tag/v0.1.0"><strong>最新版本</strong></a>
  ·
  <a href="README.md"><strong>English</strong></a>
</p>

<p align="center">
  <img alt="GitHub Release" src="https://img.shields.io/github/v/release/wimi321/aura?display_name=tag&sort=semver">
  <img alt="License" src="https://img.shields.io/github/license/wimi321/aura">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android%20%7C%20iOS-0F172A">
  <img alt="On-device inference" src="https://img.shields.io/badge/inference-on--device-10B981">
  <img alt="Tavern compatible" src="https://img.shields.io/badge/Tavern-compatible-F97316">
</p>

## 为什么会有人装 Aura

很多本地大模型 App 看起来还是像“技术演示器”：

- 页面像调试面板
- 术语太工程化
- 角色卡像在导文件，不像在进剧情
- 安装包大得离谱，普通用户根本不想碰

Aura 走的是相反的路线：

- 先把剧情体验做好，而不是先把技术名词摆出来
- 模型下载完成后走端侧本地推理
- 角色卡、世界书、会话推进都围绕“进戏”展开
- 安装包先变轻，首启再在 App 内选模型下载
- 文案尽量面向普通用户，而不是面向开发者

## Aura 有什么不一样

| 你想要什么 | Aura 现在真实提供什么 |
| --- | --- |
| 手机上直接跑 Tavern 剧情卡 | 支持 Tavern / SillyTavern PNG 与 JSON 角色卡导入 |
| 更私密的默认路径 | 模型下载后默认走本地推理 |
| 安装包别太夸张 | 轻量 APK + 首启双模型选择 |
| 更像剧情阅读，不像聊天工具 | 聊天页按场景沉浸去设计，并支持继续当前剧情 |
| 少一点工程味 | 用户向文案，不把后端术语怼到首页 |
| 会话管理别太原始 | 新建会话、历史会话、长按编辑/删除都已接通 |

## 内置题材预览

内置剧情卡已经在往“题材入口”而不是“聊天对象列表”这条路上走。

<table>
  <tr>
    <td align="center">
      <img src="assets/images/characters/palace-consort.png" alt="宫廷悬局封面" width="220" />
      <br />
      <strong>宫廷悬局</strong>
    </td>
    <td align="center">
      <img src="assets/images/characters/deskmate.png" alt="校园恋爱封面" width="220" />
      <br />
      <strong>校园慢热恋爱</strong>
    </td>
    <td align="center">
      <img src="assets/images/characters/instance-monitor.png" alt="规则怪谈封面" width="220" />
      <br />
      <strong>规则怪谈</strong>
    </td>
  </tr>
</table>

## 真实 App 预览

下面这些都是 Aura 真实运行中的页面截图，不是设计稿拼图。

<p align="center">
  <img src="docs/readme/quick-start.gif" alt="Aura 快速上手流程" width="780" />
</p>

<table>
  <tr>
    <td align="center">
      <img src="docs/readme/story-library.png" alt="Aura 剧本库页面" width="220" />
      <br />
      <strong>剧本库</strong>
    </td>
    <td align="center">
      <img src="docs/readme/model-setup.png" alt="Aura 首启模型选择页" width="220" />
      <br />
      <strong>首启模型选择</strong>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="docs/readme/chat-scene.png" alt="Aura 剧情聊天页" width="220" />
      <br />
      <strong>沉浸式剧情页</strong>
    </td>
    <td align="center">
      <img src="docs/readme/import-flow.png" alt="Aura 导入流程页" width="220" />
      <br />
      <strong>导入流程</strong>
    </td>
  </tr>
</table>

## 一分钟安装

### Android

1. 去 [GitHub Releases](https://github.com/wimi321/aura/releases) 下载最新版，或者直接点这个 [APK 链接](https://github.com/wimi321/aura/releases/download/v0.1.0/Aura-android-arm64-v0.1.0.apk)。
2. 打开 Aura。
3. 在首启页选择 `Gemma 4 E2B` 或 `Gemma 4 E4B`。
4. 等模型下载完成。
5. 进入内置剧情卡，或者导入你自己的 Tavern 角色卡。

当前公开安装路径仍以 Android 为主；iOS 工程已经在仓库中，构建说明放在后面。

## 为什么包体现在更小

Aura 不再把完整大模型直接塞进 APK。
现在的路径是先发一个轻量安装包，第一次打开时再在 App 内下载你想用的模型。

这样做的价值很直接：

- 安装包更容易下载和分发
- GitHub Release 可以直接承接公开发布
- 普通用户第一次打开就能看懂要做什么
- “更快开始” 和 “更高质量” 两条模型路线可以在 App 内自己选

当前公开 Android arm64 APK 体积：

- 约 `100.5MB`

此前把模型一起打包时的大致体积：

- 约 `2.2GB`

## Tavern 兼容性

Aura 是按“剧情代入 / 场景推进”来做的，不是普通问答壳子。

当前支持：

- Tavern / SillyTavern PNG 角色卡
- Tavern / SillyTavern JSON 角色卡
- 内嵌 `character_book`
- 独立 lorebook / worldbook JSON
- 导入 PNG 卡后把头像直接展示到剧本库里

更适合的玩法是：

- 剧情代入
- 角色扮演
- 世界书驱动设定展开
- 在手机上持续推进场景，而不是只做一轮一问一答

## 常见问题

### APK 里面已经自带完整模型了吗？

没有。
Aura 现在走的是“小包体 + 首启应用内下载模型”的方案。

### 模型下载完成以后，是本地推理吗？

是。
Aura 的目标产品路径是模型下载到设备之后在本地完成推理。

### 能直接导入 Tavern 的 PNG 卡吗？

可以。
Aura 支持 Tavern 风格 PNG 卡、Tavern / SillyTavern JSON 卡，以及卡里带的嵌入式元数据。

### 世界书支持吗？

支持。
内嵌 `character_book` 可以识别，独立 lorebook / worldbook JSON 也支持导入。

### iOS 有吗？

有。
仓库已经包含 iOS 工程和本地构建脚本，只是体积较大的原生运行时框架改成按需本地生成，没有直接塞进 Git 历史。

## 当前验证

这份仓库在 2026 年 4 月 18 日已验证通过：

```bash
flutter analyze
flutter test
./scripts/build_release_android_arm64.sh
./scripts/build_ios_simulator.sh
./scripts/build_ios_device_no_codesign.sh
./tooling/readme/capture_readme_assets.sh
```

当前可确认的结果：

- 静态检查通过
- 单元测试与组件测试通过
- Android arm64 Release 构建通过
- iOS Simulator 构建通过
- iOS 设备无签名构建链路通过
- README 用到的截图和 GIF 来自真实运行中的 Aura 构建

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

产物：

- `build/app/outputs/flutter-apk/app-release.apk`

### iOS Simulator

```bash
./scripts/build_ios_simulator.sh
```

产物：

- `build/ios/iphonesimulator/Runner.app`

### iOS 设备无签名构建

```bash
./scripts/build_ios_device_no_codesign.sh
```

产物：

- `build/ios/iphoneos/Runner.app`

### iOS XCFramework 说明

如果 Flutter 提示 iOS 环境没配好，通常是因为系统当前指向的是 Command Line Tools，而不是完整 Xcode：

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

如果本地缺少原生 LiteRT 运行时框架，可以用下面的脚本重新生成：

```bash
./tooling/ios/build_litert_native_xcframework.sh
```

补充说明：

- [ios/Frameworks/README.md](ios/Frameworks/README.md)

## 路线图

- 继续提升对野生 Tavern 卡格式的兼容性
- 继续扩充更像剧情入口的内置题材卡
- 继续打磨弱网、断点恢复和下载失败后的体验
- 持续补更多手机和平板设备上的真实验证
- 继续把用户可见界面的工程味往下压

## 反馈与贡献

如果你遇到角色卡导入兼容问题、机型适配问题、模型下载问题，或者剧情流出现明显回退，欢迎提 [issue](https://github.com/wimi321/aura/issues)。

如果你愿意一起补代码、补设备验证、补内容打磨，也欢迎直接发 PR。
