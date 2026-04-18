// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Aura';

  @override
  String get bootstrapLoadingMessage => 'あなただけのローカル物語空間を開いています...';

  @override
  String get bootstrapErrorTitle => 'Aura を起動できませんでした';

  @override
  String get bootstrapErrorDescription =>
      'ローカル環境の初期化を完了できませんでした。下の詳細を確認してください。';

  @override
  String get loadingModel => 'モデルを起動しています...';

  @override
  String get modelStateIdle => '待機';

  @override
  String get modelStateError => '異常';

  @override
  String statusLabel(Object state) {
    return '状態 $state';
  }

  @override
  String get readyText => '準備完了';

  @override
  String get chatInputHint => 'メッセージを入力...';

  @override
  String get whisperHint => 'ウィスパー指示...';

  @override
  String get advancedSettings => '詳細設定';

  @override
  String get characters => 'キャラクター';

  @override
  String get importCharacter => 'キャラクターを追加';

  @override
  String get importPreviewTitle => 'ストーリーカードを取り込む';

  @override
  String lorebookIncluded(Object count) {
    return '📚 ロアブックあり ($count 件)';
  }

  @override
  String get companionsTitle => 'あなたの仲間たち';

  @override
  String get appTagline => 'ローカル知能、プライバシー第一。';

  @override
  String get engineStatusTitle => 'エンジン状態';

  @override
  String engineRunning(Object modelName) {
    return '$modelName を実行中';
  }

  @override
  String get systemLabel => 'システム';

  @override
  String get settingsTitle => 'エンジンコントロールセンター';

  @override
  String get languageSectionTitle => '言語';

  @override
  String get activeCoreTitle => '現在のコア';

  @override
  String get systemOfflineText => 'システムはオフラインです。コアを有効化してください。';

  @override
  String get availableCoresTitle => '利用可能なコア';

  @override
  String get hardwareImportsTitle => 'ハードウェアとインポート';

  @override
  String get promptPresetTitle => 'プロンプトプリセット';

  @override
  String get promptPresetActiveLabel => '現在のプリセット';

  @override
  String get importPresetJsonButton => 'プリセット JSON を取り込む';

  @override
  String get editActivePresetButton => '現在のプリセットを編集';

  @override
  String get editPromptPresetTitle => 'プロンプトプリセットを編集';

  @override
  String get presetNameFieldLabel => 'プリセット名';

  @override
  String get presetSystemPromptFieldLabel => 'システムプロンプト';

  @override
  String get presetTemperatureFieldLabel => 'Temperature';

  @override
  String get presetTopPFieldLabel => 'Top P';

  @override
  String get presetTopKFieldLabel => 'Top K';

  @override
  String get presetMaxOutputTokensFieldLabel => '最大出力トークン';

  @override
  String get defaultRoleplayPresetName => 'Aura デフォルトロールプレイ';

  @override
  String get defaultRoleplayPresetPrompt =>
      '与えられた役に深く没入してください。常にキャラクターとして振る舞い、臨場感豊かに描写し、システムが明示的に許可しない限り AI アシスタントであることに触れないでください。';

  @override
  String get importedPresetFallbackName => '取り込み済みプリセット';

  @override
  String get neuralAccelerationTitle => 'ニューラルエンジン加速';

  @override
  String get neuralAccelerationSubtitle => '可能な場合は自動で NPU/CoreML に切り替えます';

  @override
  String get expressionPackTitle => '表情パック（ZIP）';

  @override
  String get expressionPackSubtitle => '複雑な 2D 表情パックを取り込みます';

  @override
  String get activeBadge => '有効';

  @override
  String get builtInTag => '内蔵';

  @override
  String get downloadedTag => 'ダウンロード済み';

  @override
  String get alreadyActiveButton => 'すでに有効です';

  @override
  String get activateEngineButton => 'エンジンを有効化';

  @override
  String get activateBuiltInEngineButton => '内蔵エンジンを有効化';

  @override
  String get downloadInstallButton => 'ダウンロードしてインストール';

  @override
  String get interfaceReplyLanguageTitle => 'UI と返信言語';

  @override
  String get interfaceReplyLanguageDescription =>
      '既定ではシステム言語に従います。ここで固定すると、会話中で明示的に変更しない限り返信もその言語に従います。';

  @override
  String get languageFieldLabel => '言語';

  @override
  String get chatNoActiveModel => '有効なモデルがまだ読み込まれていません。';

  @override
  String get whisperSheetTitle => 'ウィスパー指示';

  @override
  String get whisperSheetDescription => '次の返信だけに影響し、この指示は画面上の会話には表示されません。';

  @override
  String get whisperSheetExample => '例：少し柔らかく返答し、不安を自信の裏に隠して。';

  @override
  String get applyWhisper => '適用';

  @override
  String get chatBackButtonTooltip => '戻る';

  @override
  String get chatWhisperButtonTooltip => 'ウィスパー指示を開く';

  @override
  String get chatMoreActionsTooltip => '会話アクション';

  @override
  String get chatSendButtonTooltip => 'メッセージを送信';

  @override
  String get chatStopButtonTooltip => '生成を停止';

  @override
  String get nextWhisperLabel => '次のウィスパー';

  @override
  String get chatInputPlaceholder => 'Aura にメッセージ...';

  @override
  String get chatModelPreparing => 'モデルを準備しています。少しお待ちください...';

  @override
  String get chatRecoveringCore => '少し不安定だったため、自動で整えています...';

  @override
  String get chatConversationResetting => 'この会話を整えています...';

  @override
  String get chatGenerationTimedOut =>
      '今回の返信はタイムアウトしました。もう一度送信するか、停止してから再試行できます。';

  @override
  String get chatRuntimeRecovered => '復旧しました。もう一度送信できます。';

  @override
  String get chatRuntimeRecoveryFailed => '復旧に失敗しました。設定からモデルを再度有効にしてください。';

  @override
  String get assistantLabel => 'Aura';

  @override
  String get noActiveModel => '有効なモデルはありません';

  @override
  String get roleplayReadyLabel => 'ロールプレイの文脈準備完了';

  @override
  String get newConversationButton => '新しい会話';

  @override
  String get clearHistoryButton => '履歴を消去';

  @override
  String get clearHistoryConfirmTitle => '履歴をすべて消去しますか？';

  @override
  String clearHistoryConfirmDescription(Object characterName) {
    return '$characterName の保存済み履歴がすべて削除され、この分岐は元に戻せません。';
  }

  @override
  String get clearHistoryConfirmAction => 'すべて削除';

  @override
  String get historyClearedMessage => 'このキャラクターの会話履歴を消去しました。';

  @override
  String get sessionHistoryTitle => '履歴';

  @override
  String get sessionHistoryShortLabel => '履歴';

  @override
  String sessionHistoryDescription(Object characterName) {
    return '$characterName の過去の分岐に戻り、その続きから進めます。';
  }

  @override
  String get sessionHistoryEmpty => 'このカードにはまだ保存済みの履歴がありません。';

  @override
  String get sessionCurrentLabel => '現在の会話';

  @override
  String sessionMessageCount(Object count) {
    return '$count 件のメッセージ';
  }

  @override
  String get sessionBranchEmpty => 'この分岐はまだ始まっていません。';

  @override
  String get importingCardText => 'キャラクターカードを解析しています...';

  @override
  String get importCardEmptyState => 'Tavern PNG または JSON カードを選んでプレビューします。';

  @override
  String get chooseCardButton => '画像またはファイルを選択';

  @override
  String get confirmImportButton => 'インポートを確定';

  @override
  String get cancelButton => 'キャンセル';

  @override
  String get editCharacterTitle => 'キャラクターを編集';

  @override
  String get editCharacterButtonTooltip => 'キャラクターを編集';

  @override
  String get characterWorkbenchTitle => 'キャラクターワークベンチ';

  @override
  String get characterWorkbenchDescription =>
      'カード本文、立ち絵、ロアブック項目をここで調整できます。変更はすべてローカルライブラリに保存されます。';

  @override
  String get characterPortraitImportedHint => 'このカードには元の画像がすでに含まれています。';

  @override
  String get characterPortraitAutoImportHint =>
      'Tavern PNG カードを取り込むと画像も自動で引き継がれます。画像がない場合だけ内蔵カバーを使います。';

  @override
  String get characterCoreFieldsTitle => '基本情報';

  @override
  String get characterCoreFieldsDescription => 'これらの項目で役柄紹介、シーン開始、物語の流れを決めます。';

  @override
  String get characterNameLabel => '名前';

  @override
  String get characterDescriptionLabel => '説明';

  @override
  String get characterPersonalityLabel => '性格';

  @override
  String get characterScenarioLabel => 'シナリオ';

  @override
  String get characterFirstMessageLabel => '最初のメッセージ';

  @override
  String get characterExamplesLabel => '会話例';

  @override
  String get characterAlternateGreetingsLabel => '追加の導入文';

  @override
  String get characterCreatorNotesLabel => '作者メモ';

  @override
  String get characterMainPromptLabel => 'カード内メイン指示';

  @override
  String get characterPostHistoryInstructionsLabel => '返信後ルール';

  @override
  String get characterAdvancedFieldsTitle => '詳細設定';

  @override
  String get characterAdvancedFieldsDescription =>
      '追加の導入文、作者メモ、カード内メイン指示、返信後ルールを必要なときだけ編集します。';

  @override
  String get blankLineSeparatedHint => '各ブロックの間は 1 行空けてください。';

  @override
  String get characterLorebookTitle => 'ロアブック / ワールドブック';

  @override
  String get characterLorebookDescription =>
      '単独ロアブックの取り込みにも対応しており、ここで直接項目を編集できます。取り込み時は既存設定を上書きせず、既定でマージします。';

  @override
  String lorebookAttachedLabel(Object count) {
    return 'ロアブックを接続済み ($count 件)';
  }

  @override
  String get lorebookMissingLabel => 'ロアブックはまだ接続されていません。';

  @override
  String get importLorebookButton => 'ロアブックを取り込む';

  @override
  String get importMergeWorldbookButton => 'ロアブックを取り込みマージ';

  @override
  String get addLorebookEntryButton => '項目を追加';

  @override
  String get replaceLorebookButton => 'ロアブックを差し替える';

  @override
  String get removeLorebookButton => 'ロアブックを外す';

  @override
  String get lorebookMetaPanelTitle => 'ワールドブック名 / 概要';

  @override
  String get lorebookMetaSummaryFilled => '名前と概要が入力されています。';

  @override
  String get lorebookMetaSummaryPartial => '高度な項目が 1 つ入力されています。';

  @override
  String get lorebookMetaSummaryEmpty => '必要になるまで折りたたまれます。';

  @override
  String get worldbookNameLabel => 'ワールドブック名';

  @override
  String get worldbookDescriptionLabel => 'ワールドブック概要';

  @override
  String get lorebookEntriesTitle => 'ワールドブック項目';

  @override
  String get lorebookEntriesCollapsedEmptyHint =>
      '大きなワールドブックで画面が埋まらないよう、初期状態では折りたたまれます。';

  @override
  String get lorebookEntriesCollapsedHint => 'タップしてすべての項目を表示・編集します。';

  @override
  String lorebookEntryCount(Object count) {
    return '$count 件';
  }

  @override
  String get lorebookEntriesEmptyState =>
      '項目はまだありません。Tavern のロアブックを取り込むか、キーワードで発火する設定項目を手動で追加してください。';

  @override
  String lorebookEntryFallbackLabel(Object index) {
    return '項目 $index';
  }

  @override
  String get editEntryTooltip => '項目を編集';

  @override
  String get deleteEntryTooltip => '項目を削除';

  @override
  String secondaryKeywordsTag(Object keywords) {
    return '補助 $keywords';
  }

  @override
  String priorityTag(Object value) {
    return '優先度 $value';
  }

  @override
  String get lorebookEntryEditorTitle => 'ワールドブック項目を編集';

  @override
  String get lorebookEntryIdLabel => '項目 ID';

  @override
  String get lorebookEntryPrimaryKeywordsLabel => '主キーワード';

  @override
  String get lorebookEntryPrimaryKeywordsHelper =>
      'カンマ区切りです。例: zhongli, contract, liyue';

  @override
  String get lorebookEntrySecondaryKeywordsLabel => '補助キーワード';

  @override
  String get lorebookEntrySecondaryKeywordsHelper => '任意、カンマ区切りです。';

  @override
  String get lorebookEntryContentLabel => '項目内容';

  @override
  String get lorebookEntryCommentLabel => 'メモ';

  @override
  String get lorebookEntryPriorityLabel => '優先度';

  @override
  String get lorebookEntryEnabledLabel => '項目を有効化';

  @override
  String get lorebookEntrySelectiveLabel => '補助キーワード必須';

  @override
  String get lorebookEntryConstantLabel => '常時注入';

  @override
  String get lorebookEntryWholeWordLabel => '完全一致';

  @override
  String get lorebookEntryCaseSensitiveLabel => '大文字小文字を区別';

  @override
  String get saveEntryButton => '項目を保存';

  @override
  String get lorebookEntryValidationError => '少なくともキーワードと内容を入力してください。';

  @override
  String lorebookImportedMessage(Object count) {
    return 'ロアブックを接続しました ($count 件)。';
  }

  @override
  String get saveButton => '保存';

  @override
  String get savingButton => '保存中...';

  @override
  String get importDialogDescription =>
      'Tavern / SillyTavern のカードはそのままライブラリに取り込まれます。単体のロアブックは次の手順で対象カードへ接続できます。';

  @override
  String get importPreviewRoleCardTag => 'ストーリーカード';

  @override
  String get embeddedWorldbookTag => '内蔵ロアブック';

  @override
  String get createCharacterButton => '手動で作成';

  @override
  String get attachWorldbookButton => 'ロアブックを接続';

  @override
  String get importEmptyStateIntro =>
      'まず取り込み元を選んでください。写真はフォトライブラリに保存済みの Tavern PNG 向け、ファイルは Tavern / SillyTavern の PNG・JSON カードと単体ロアブックに対応します。ロアブック内蔵カードは一度で取り込めます。';

  @override
  String get importEmptyStateDetails =>
      'カードに `character_book` / ロアブックが含まれていれば、Aura が開幕文、予備の挨拶、指示文、シーン設定をそのまま保持します。';

  @override
  String get importCreateCharacterHint => '手元にカードがなくても、ここから新しく作成できます。';

  @override
  String get chooseAnotherCardButton => '別の画像またはファイルを選ぶ';

  @override
  String get importSourceSheetTitle => '取り込み方法を選択';

  @override
  String get importSourceSheetSubtitle =>
      '写真はフォトライブラリに保存済みの Tavern PNG 向けです。ファイルでは Tavern PNG / JSON カードを選べます。';

  @override
  String get importFromPhotosTitle => '写真から取り込む';

  @override
  String get importFromPhotosSubtitle => 'フォトライブラリに保存済みの Tavern PNG カードを選びます。';

  @override
  String get importFromFilesTitle => 'ファイルから取り込む';

  @override
  String get importFromFilesSubtitle =>
      'Files から Tavern PNG、JSON カード、単独ワールドブックを選びます。';

  @override
  String get importWorldbookHint => '単独のワールドブックはここではなく、キャラクター編集から取り込みます。';

  @override
  String get importErrorTitle => 'このファイルは取り込めません';

  @override
  String get importFileLabel => 'ファイル';

  @override
  String get importCreatorLabel => '作者';

  @override
  String get importNoDescriptionLabel => 'このカードには説明がありません。';

  @override
  String get importNoFirstMessageLabel => 'このカードには最初のメッセージがありません。';

  @override
  String get importWorldbookErrorMessage =>
      'このファイルは単独のワールドブックです。キャラクターを開き、ロアブック欄から取り込んでください。';

  @override
  String get importUnsupportedFileMessage =>
      'ここで対応しているのは Tavern PNG と JSON のキャラクターカードのみです。';

  @override
  String get photoImportPngOnlyMessage =>
      '写真からの取り込みは現在 Tavern PNG カードのみ対応しています。';

  @override
  String get importInvalidCharacterFileMessage =>
      'このファイルは対応しているキャラクターカードには見えません。';

  @override
  String get importGenericErrorMessage => 'インポートに失敗しました。別のカードファイルでお試しください。';

  @override
  String importSuccessMessage(Object characterName) {
    return '$characterName を取り込みました。';
  }

  @override
  String characterCreatedMessage(Object characterName) {
    return '$characterName を作成しました。';
  }

  @override
  String get importOpenChatAction => '会話を始める';

  @override
  String get settingsButtonTooltip => '設定を開く';

  @override
  String get editMessageActionTitle => 'このメッセージを編集';

  @override
  String get editMessageActionDescription => '物語の流れを保ったまま、この発言だけを直します。';

  @override
  String get deleteMessageActionTitle => 'このメッセージを削除';

  @override
  String get deleteMessageActionDescription => '現在の会話からこの発言を取り除きます。';

  @override
  String get editMessageDialogTitle => 'メッセージを編集';

  @override
  String get editMessageHint => 'メッセージを書き直す';

  @override
  String get messageUpdated => 'メッセージを更新しました。';

  @override
  String get deleteMessageDialogTitle => 'メッセージを削除';

  @override
  String get deleteMessageDialogDescription => 'このメッセージは現在の会話から削除されます。';

  @override
  String get deleteButton => '削除';

  @override
  String get messageDeleted => 'メッセージを削除しました。';

  @override
  String get continueSceneButtonTooltip => '現在のシーンを続ける';

  @override
  String get continueScenePrompt =>
      '現在のシーンを自然に続けてください。関係性をリセットしたり、役から外れたりせず、緊張感、手掛かり、感情を前に進めてください。';

  @override
  String get storyCoreDownloadPrompt => 'シーンに入る前にストーリーコアをダウンロードしてください。';

  @override
  String get storyCoreChooseButton => 'ストーリーコアを選ぶ';

  @override
  String get storyCoreDownloadStatus => 'ストーリーコアを選択';

  @override
  String get firstRunModelTitle => '最初のストーリーコアを選択';

  @override
  String get firstRunModelSubtitle =>
      'Aura を初めて開くときは、まず 1 つのローカルストーリーコアが必要です。E2B は導入が速く、E4B はより高品質です。完了後はそのままシーンに戻ります。';

  @override
  String get firstRunModelRecommendedBadge => 'おすすめ';

  @override
  String get firstRunModelQualityBadge => '高品質';

  @override
  String get firstRunE2bHeadline => 'すばやく始める';

  @override
  String get firstRunE2bSummary =>
      '初回導入向けです。ダウンロードが軽く、セットアップも速いため、シーンに入りやすくなります。';

  @override
  String get firstRunE4bHeadline => 'より豊かな描写';

  @override
  String get firstRunE4bSummary => 'ダウンロードは大きめですが、描写の密度やシーンの安定感はさらに高くなります。';

  @override
  String get modelDownloadPreparingButton => 'ダウンロード中...';

  @override
  String modelSetupRamHint(Object memory) {
    return '推奨メモリ $memory';
  }

  @override
  String modelSetupDownloadProgress(Object received, Object total) {
    return 'ダウンロード済み $received / $total';
  }

  @override
  String get modelErrorNoSpace => '空き容量が不足しています。容量を空けてから再試行してください。';

  @override
  String get modelErrorCorrupt => 'ダウンロードしたファイルが不完全でした。もう一度お試しください。';

  @override
  String get modelErrorNetwork => 'ダウンロードが中断されました。接続を確認して再試行してください。';

  @override
  String get modelErrorGeneric => '問題が発生しました。しばらくしてからもう一度お試しください。';
}
