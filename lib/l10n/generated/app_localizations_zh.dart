// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Aura';

  @override
  String get bootstrapLoadingMessage => '正在开启你的本地剧情空间...';

  @override
  String get bootstrapErrorTitle => 'Aura 启动失败';

  @override
  String get bootstrapErrorDescription => '本地环境未能完成初始化。你可以先查看下面的错误信息。';

  @override
  String get loadingModel => '构建世界中...';

  @override
  String get modelStateIdle => '待命';

  @override
  String get modelStateError => '异常';

  @override
  String statusLabel(Object state) {
    return '状态 $state';
  }

  @override
  String get readyText => '已就绪';

  @override
  String get chatInputHint => '发送消息...';

  @override
  String get whisperHint => '耳语指令（仅影响下一条回复）...';

  @override
  String get advancedSettings => '本地运算与设置';

  @override
  String get characters => '剧本库';

  @override
  String get importCharacter => '导入角色';

  @override
  String get importPreviewTitle => '导入剧情卡';

  @override
  String lorebookIncluded(Object count) {
    return '📚 附带世界观设定 ($count个词条)';
  }

  @override
  String get companionsTitle => '剧本库';

  @override
  String get appTagline => '本地剧情角色扮演，隐私优先。';

  @override
  String get engineStatusTitle => '本地运算引擎';

  @override
  String engineRunning(Object modelName) {
    return '正在运行 $modelName';
  }

  @override
  String get systemLabel => '系统';

  @override
  String get settingsTitle => '运算与存储设置';

  @override
  String get languageSectionTitle => '首选语言';

  @override
  String get activeCoreTitle => '当前运行引擎';

  @override
  String get systemOfflineText => '当前未开启本地计算。请先启动一个引擎以进入剧情。';

  @override
  String get availableCoresTitle => '可用引擎';

  @override
  String get hardwareImportsTitle => '扩展与导入';

  @override
  String get promptPresetTitle => '基础行为准则';

  @override
  String get promptPresetActiveLabel => '当前准则';

  @override
  String get importPresetJsonButton => '导入准则文件';

  @override
  String get editActivePresetButton => '编辑当前准则';

  @override
  String get editPromptPresetTitle => '编辑行为准则';

  @override
  String get presetNameFieldLabel => '准则名称';

  @override
  String get presetSystemPromptFieldLabel => '基础行为说明';

  @override
  String get presetTemperatureFieldLabel => '发散度';

  @override
  String get presetTopPFieldLabel => '采样范围';

  @override
  String get presetTopKFieldLabel => '候选数量';

  @override
  String get presetMaxOutputTokensFieldLabel => '最大回复长度';

  @override
  String get defaultRoleplayPresetName => 'Aura 默认剧情准则';

  @override
  String get defaultRoleplayPresetPrompt =>
      '你将完全沉浸于当前角色设定中。始终保持角色视角，写得具体、有画面感；除非系统明确允许，否则绝对不要承认自己是一台 AI。';

  @override
  String get importedPresetFallbackName => '导入准则';

  @override
  String get neuralAccelerationTitle => '神经处理器加速';

  @override
  String get neuralAccelerationSubtitle => '条件允许时自动切换到 NPU/CoreML';

  @override
  String get expressionPackTitle => '动态立绘 (ZIP)';

  @override
  String get expressionPackSubtitle => '导入高级 Live2D 表情资源';

  @override
  String get activeBadge => '运行中';

  @override
  String get builtInTag => '内置';

  @override
  String get downloadedTag => '已下载';

  @override
  String get alreadyActiveButton => '当前已启用';

  @override
  String get activateEngineButton => '启用该引擎';

  @override
  String get activateBuiltInEngineButton => '启用内置引擎';

  @override
  String get downloadInstallButton => '下载并安装';

  @override
  String get interfaceReplyLanguageTitle => '界面与回复语言';

  @override
  String get interfaceReplyLanguageDescription =>
      '默认跟随系统语言。你也可以固定语言，角色的回复将会尽力遵循此设定。';

  @override
  String get languageFieldLabel => '语言';

  @override
  String get chatNoActiveModel => '尚未加载本地引擎，无法开始剧情。';

  @override
  String get whisperSheetTitle => '耳语指令';

  @override
  String get whisperSheetDescription => '此指令只在幕后影响角色的下一次行动，不会出现在剧本对话中。';

  @override
  String get whisperSheetExample => '例如：语气更冰冷一些，表现得不耐烦。';

  @override
  String get applyWhisper => '应用耳语';

  @override
  String get chatBackButtonTooltip => '返回';

  @override
  String get chatWhisperButtonTooltip => '打开耳语';

  @override
  String get chatMoreActionsTooltip => '剧情操作';

  @override
  String get chatSendButtonTooltip => '推进剧情';

  @override
  String get chatStopButtonTooltip => '停止生成';

  @override
  String get nextWhisperLabel => '下一条耳语';

  @override
  String get chatInputPlaceholder => '写下剧情发展...';

  @override
  String get chatModelPreparing => 'Aura 正在构筑剧情背景，请稍候...';

  @override
  String get chatRecoveringCore => '思维链正在重组，稍等片刻...';

  @override
  String get chatConversationResetting => '正在重置时间线...';

  @override
  String get chatGenerationTimedOut => 'Aura 暂无反应。请重试。';

  @override
  String get chatRuntimeRecovered => '重组完成，剧情继续。';

  @override
  String get chatRuntimeRecoveryFailed => '剧情引擎意外断开。请在设置中重新启用。';

  @override
  String get assistantLabel => '角色';

  @override
  String get noActiveModel => '暂无引擎连接';

  @override
  String get roleplayReadyLabel => '已准备就绪，可以进入剧情';

  @override
  String get newConversationButton => '重新开始剧情';

  @override
  String get clearHistoryButton => '清空进度';

  @override
  String get clearHistoryConfirmTitle => '确认清空历史？';

  @override
  String clearHistoryConfirmDescription(Object characterName) {
    return '这会删除 $characterName 的全部历史会话，原来的剧情分支无法恢复。';
  }

  @override
  String get clearHistoryConfirmAction => '确认清空';

  @override
  String get historyClearedMessage => '该角色的历史会话已清空。';

  @override
  String get sessionHistoryTitle => '历史会话';

  @override
  String get sessionHistoryShortLabel => '历史记录';

  @override
  String sessionHistoryDescription(Object characterName) {
    return '回到 $characterName 的旧剧情分支，继续原来的线。';
  }

  @override
  String get sessionHistoryEmpty => '这个角色还没有历史会话。';

  @override
  String get sessionCurrentLabel => '当前会话';

  @override
  String sessionMessageCount(Object count) {
    return '$count 条消息';
  }

  @override
  String get sessionBranchEmpty => '这条剧情线还没有正式开始。';

  @override
  String get importingCardText => '正在解析角色卡...';

  @override
  String get importCardEmptyState => '选择一张酒馆 PNG 或 JSON 角色卡进行预览。';

  @override
  String get chooseCardButton => '选择图片或文件';

  @override
  String get confirmImportButton => '确认导入';

  @override
  String get cancelButton => '取消';

  @override
  String get editCharacterTitle => '编辑角色';

  @override
  String get editCharacterButtonTooltip => '编辑角色';

  @override
  String get characterWorkbenchTitle => '角色工作台';

  @override
  String get characterWorkbenchDescription =>
      '在这里调整角色卡正文、角色头像，以及世界书词条。所有修改都会直接落到本地卡库。';

  @override
  String get characterPortraitImportedHint => '这张角色卡已自带原始图片。';

  @override
  String get characterPortraitAutoImportHint =>
      '如果导入的是 Tavern PNG 角色卡，图片会自动带进来；没有图时才会使用内置剧情卡面。';

  @override
  String get characterCoreFieldsTitle => '基础信息';

  @override
  String get characterCoreFieldsDescription => '这些字段决定角色简介、场景开场和剧情走向。';

  @override
  String get characterNameLabel => '名称';

  @override
  String get characterDescriptionLabel => '简介';

  @override
  String get characterPersonalityLabel => '性格';

  @override
  String get characterScenarioLabel => '场景设定';

  @override
  String get characterFirstMessageLabel => '开场白';

  @override
  String get characterExamplesLabel => '示例对话';

  @override
  String get characterAlternateGreetingsLabel => '备用开场白';

  @override
  String get characterCreatorNotesLabel => '作者注记';

  @override
  String get characterMainPromptLabel => '主提示词覆盖';

  @override
  String get characterPostHistoryInstructionsLabel => '回复后置指令';

  @override
  String get characterAdvancedFieldsTitle => '酒馆高级字段';

  @override
  String get characterAdvancedFieldsDescription =>
      '这些字段会直接影响角色卡的备用开场白、主提示词与下一轮回复约束。';

  @override
  String get blankLineSeparatedHint => '每段之间空一行。';

  @override
  String get characterLorebookTitle => '世界书 / 设定集';

  @override
  String get characterLorebookDescription =>
      '支持导入独立世界书，也可以直接在这里增删改词条。导入时默认合并，不覆盖已有设定。';

  @override
  String lorebookAttachedLabel(Object count) {
    return '已挂载世界书（$count个词条）';
  }

  @override
  String get lorebookMissingLabel => '当前还没有挂载世界书。';

  @override
  String get importLorebookButton => '导入世界书';

  @override
  String get importMergeWorldbookButton => '导入并合并世界书';

  @override
  String get addLorebookEntryButton => '新增词条';

  @override
  String get replaceLorebookButton => '替换世界书';

  @override
  String get removeLorebookButton => '移除世界书';

  @override
  String get lorebookMetaPanelTitle => '世界书名称 / 简介';

  @override
  String get lorebookMetaSummaryFilled => '已填写名称与简介。';

  @override
  String get lorebookMetaSummaryPartial => '已填写 1 项高级信息。';

  @override
  String get lorebookMetaSummaryEmpty => '默认折叠，需要时再补充。';

  @override
  String get worldbookNameLabel => '世界书名称';

  @override
  String get worldbookDescriptionLabel => '世界书简介';

  @override
  String get lorebookEntriesTitle => '世界书词条';

  @override
  String get lorebookEntriesCollapsedEmptyHint => '默认折叠，避免大型世界书直接铺满整个工作台。';

  @override
  String get lorebookEntriesCollapsedHint => '点击展开，查看或编辑全部词条。';

  @override
  String lorebookEntryCount(Object count) {
    return '$count 条词条';
  }

  @override
  String get lorebookEntriesEmptyState => '当前没有词条。你可以导入酒馆世界书，或手动添加关键词触发的设定条目。';

  @override
  String lorebookEntryFallbackLabel(Object index) {
    return '词条 $index';
  }

  @override
  String get editEntryTooltip => '修改词条';

  @override
  String get deleteEntryTooltip => '删除词条';

  @override
  String secondaryKeywordsTag(Object keywords) {
    return '次级 $keywords';
  }

  @override
  String priorityTag(Object value) {
    return '优先级 $value';
  }

  @override
  String get lorebookEntryEditorTitle => '编辑世界书词条';

  @override
  String get lorebookEntryIdLabel => '词条 ID';

  @override
  String get lorebookEntryPrimaryKeywordsLabel => '主关键词';

  @override
  String get lorebookEntryPrimaryKeywordsHelper => '用英文逗号分隔，例如：钟离, 契约, 璃月';

  @override
  String get lorebookEntrySecondaryKeywordsLabel => '次级关键词';

  @override
  String get lorebookEntrySecondaryKeywordsHelper => '可选，用英文逗号分隔。';

  @override
  String get lorebookEntryContentLabel => '词条内容';

  @override
  String get lorebookEntryCommentLabel => '备注';

  @override
  String get lorebookEntryPriorityLabel => '优先级';

  @override
  String get lorebookEntryEnabledLabel => '启用词条';

  @override
  String get lorebookEntrySelectiveLabel => '启用次级关键词匹配';

  @override
  String get lorebookEntryConstantLabel => '恒定注入';

  @override
  String get lorebookEntryWholeWordLabel => '整词匹配';

  @override
  String get lorebookEntryCaseSensitiveLabel => '区分大小写';

  @override
  String get saveEntryButton => '保存词条';

  @override
  String get lorebookEntryValidationError => '至少填写关键词和词条内容。';

  @override
  String lorebookImportedMessage(Object count) {
    return '世界书已挂载（$count个词条）。';
  }

  @override
  String get saveButton => '保存';

  @override
  String get savingButton => '保存中...';

  @override
  String get importDialogDescription =>
      'Tavern / SillyTavern 角色卡会直接导入本地卡库；如果选中的是独立世界书，下一步可以把它挂到目标角色上。';

  @override
  String get importPreviewRoleCardTag => '剧情卡';

  @override
  String get embeddedWorldbookTag => '内置世界书';

  @override
  String get createCharacterButton => '手动创建角色';

  @override
  String get attachWorldbookButton => '挂载世界书';

  @override
  String get importEmptyStateIntro =>
      '先选导入来源：照片适合已保存到相册的 Tavern PNG，文件支持 Tavern / SillyTavern 的 PNG、JSON 角色卡与独立世界书。带内置世界书的角色卡会一步导入。';

  @override
  String get importEmptyStateDetails =>
      '如果文件里带有 `character_book` / 世界书，Aura 会自动识别并保留开场白、备用开场、剧情提示与设定词条。';

  @override
  String get importCreateCharacterHint => '如果你没有现成角色卡，也可以直接在这里手动新建一张。';

  @override
  String get chooseAnotherCardButton => '重新选择图片或文件';

  @override
  String get importSourceSheetTitle => '选择导入方式';

  @override
  String get importSourceSheetSubtitle =>
      '照片适合已经存进相册的 Tavern PNG 角色卡，文件支持 Tavern PNG、JSON 角色卡和独立世界书。';

  @override
  String get importFromPhotosTitle => '从照片导入 PNG';

  @override
  String get importFromPhotosSubtitle => '适合已经保存到相册里的 Tavern PNG 角色卡。';

  @override
  String get importFromFilesTitle => '从文件导入';

  @override
  String get importFromFilesSubtitle => '支持 PNG 角色卡、JSON 角色卡和独立世界书。';

  @override
  String get importWorldbookHint => '这里也可以直接选择独立世界书 JSON。下一步里把它挂到对应角色上就行。';

  @override
  String get importErrorTitle => '这个文件暂时不能导入';

  @override
  String get importFileLabel => '文件';

  @override
  String get importCreatorLabel => '作者';

  @override
  String get importNoDescriptionLabel => '这张角色卡没有填写简介。';

  @override
  String get importNoFirstMessageLabel => '这张角色卡没有填写开场白。';

  @override
  String get importWorldbookErrorMessage =>
      '这个文件看起来是独立世界书，Aura 可以在导入流程里直接把它挂到角色上。';

  @override
  String get importUnsupportedFileMessage => '这里目前只支持 Tavern PNG 与 JSON 角色卡。';

  @override
  String get photoImportPngOnlyMessage => '从照片导入时目前只支持 Tavern PNG 角色卡。';

  @override
  String get importInvalidCharacterFileMessage => '这个文件看起来不像可导入的角色卡。';

  @override
  String get importGenericErrorMessage => '导入失败，请换一个角色卡文件再试。';

  @override
  String importSuccessMessage(Object characterName) {
    return '已导入 $characterName';
  }

  @override
  String characterCreatedMessage(Object characterName) {
    return '已创建角色卡：$characterName';
  }

  @override
  String get importOpenChatAction => '进入剧情';

  @override
  String get settingsButtonTooltip => '打开设置';

  @override
  String get editMessageActionTitle => '修改这条消息';

  @override
  String get editMessageActionDescription => '保留当前剧情，只改这一条记录。';

  @override
  String get deleteMessageActionTitle => '删除这条消息';

  @override
  String get deleteMessageActionDescription => '从当前会话里移除这条记录。';

  @override
  String get editMessageDialogTitle => '修改消息';

  @override
  String get editMessageHint => '输入新的消息内容';

  @override
  String get messageUpdated => '消息已修改。';

  @override
  String get deleteMessageDialogTitle => '删除消息';

  @override
  String get deleteMessageDialogDescription => '这条消息会从当前会话中移除。';

  @override
  String get deleteButton => '删除';

  @override
  String get messageDeleted => '消息已删除。';

  @override
  String get continueSceneButtonTooltip => '自动续写当前剧情';

  @override
  String get continueScenePrompt => '延续当前剧情场景，自然推进冲突、线索或情绪，不要重置关系，也不要跳出角色。';

  @override
  String get storyCoreDownloadPrompt => '先下载一个剧情引擎，再进入故事。';

  @override
  String get storyCoreChooseButton => '选择剧情引擎';

  @override
  String get storyCoreDownloadStatus => '选择剧情引擎';

  @override
  String get firstRunModelTitle => '先选一个剧情引擎';

  @override
  String get firstRunModelSubtitle =>
      'Aura 第一次打开需要先下载一个本地剧情引擎。E2B 更快开始，E4B 质量更强，下载完成后会自动进入你刚才要打开的剧情。';

  @override
  String get firstRunModelRecommendedBadge => '推荐';

  @override
  String get firstRunModelQualityBadge => '更高质量';

  @override
  String get firstRunE2bHeadline => '更快开始';

  @override
  String get firstRunE2bSummary => '适合第一次安装。下载更轻、启动更快，能够更顺滑地进入剧情。';

  @override
  String get firstRunE4bHeadline => '更强细节表现';

  @override
  String get firstRunE4bSummary => '下载更大，但剧情细节、场景稳定性和整体表现都会更强。';

  @override
  String get modelDownloadPreparingButton => '下载中...';

  @override
  String modelSetupRamHint(Object memory) {
    return '建议内存 $memory';
  }

  @override
  String modelSetupDownloadProgress(Object received, Object total) {
    return '已下载 $received / $total';
  }

  @override
  String get modelErrorNoSpace => '存储空间不足。请先清理一些空间再试。';

  @override
  String get modelErrorCorrupt => '下载文件不完整，请重新下载一次。';

  @override
  String get modelErrorNetwork => '下载被中断了。请检查网络后重试。';

  @override
  String get modelErrorGeneric => '出了点问题，请稍后再试。';
}
