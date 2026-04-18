// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Aura';

  @override
  String get bootstrapLoadingMessage => '당신만의 로컬 스토리 공간을 여는 중...';

  @override
  String get bootstrapErrorTitle => 'Aura를 시작하지 못했습니다';

  @override
  String get bootstrapErrorDescription =>
      '로컬 환경 초기화를 완료하지 못했습니다. 아래 상세 정보를 확인해 주세요.';

  @override
  String get loadingModel => '모델을 깨우는 중...';

  @override
  String get modelStateIdle => '대기';

  @override
  String get modelStateError => '오류';

  @override
  String statusLabel(Object state) {
    return '상태 $state';
  }

  @override
  String get readyText => '준비 완료';

  @override
  String get chatInputHint => '메시지 입력...';

  @override
  String get whisperHint => '속삭임 지시...';

  @override
  String get advancedSettings => '고급 설정';

  @override
  String get characters => '캐릭터';

  @override
  String get importCharacter => '캐릭터 가져오기';

  @override
  String get importPreviewTitle => '스토리 카드 가져오기';

  @override
  String lorebookIncluded(Object count) {
    return '📚 로어북 포함 ($count개 항목)';
  }

  @override
  String get companionsTitle => '당신의 동료들';

  @override
  String get appTagline => '로컬 지능, 프라이버시 우선.';

  @override
  String get engineStatusTitle => '엔진 상태';

  @override
  String engineRunning(Object modelName) {
    return '$modelName 실행 중';
  }

  @override
  String get systemLabel => '시스템';

  @override
  String get settingsTitle => '엔진 제어 센터';

  @override
  String get languageSectionTitle => '언어';

  @override
  String get activeCoreTitle => '현재 코어';

  @override
  String get systemOfflineText => '시스템이 오프라인입니다. 코어를 먼저 활성화하세요.';

  @override
  String get availableCoresTitle => '사용 가능한 코어';

  @override
  String get hardwareImportsTitle => '하드웨어 및 가져오기';

  @override
  String get promptPresetTitle => '프롬프트 프리셋';

  @override
  String get promptPresetActiveLabel => '현재 프리셋';

  @override
  String get importPresetJsonButton => '프리셋 JSON 가져오기';

  @override
  String get editActivePresetButton => '현재 프리셋 편집';

  @override
  String get editPromptPresetTitle => '프롬프트 프리셋 편집';

  @override
  String get presetNameFieldLabel => '프리셋 이름';

  @override
  String get presetSystemPromptFieldLabel => '시스템 프롬프트';

  @override
  String get presetTemperatureFieldLabel => 'Temperature';

  @override
  String get presetTopPFieldLabel => 'Top P';

  @override
  String get presetTopKFieldLabel => 'Top K';

  @override
  String get presetMaxOutputTokensFieldLabel => '최대 출력 토큰';

  @override
  String get defaultRoleplayPresetName => 'Aura 기본 롤플레이';

  @override
  String get defaultRoleplayPresetPrompt =>
      '지정된 역할에 완전히 몰입하세요. 항상 캐릭터를 유지하고, 생생하게 묘사하며, 시스템이 명시적으로 허용하지 않는 한 자신이 AI 어시스턴트라고 언급하지 마세요.';

  @override
  String get importedPresetFallbackName => '가져온 프리셋';

  @override
  String get neuralAccelerationTitle => '신경 엔진 가속';

  @override
  String get neuralAccelerationSubtitle => '가능하면 자동으로 NPU/CoreML로 전환합니다';

  @override
  String get expressionPackTitle => '표정 팩 (ZIP)';

  @override
  String get expressionPackSubtitle => '복잡한 2D 표정 팩을 가져옵니다';

  @override
  String get activeBadge => '활성';

  @override
  String get builtInTag => '내장';

  @override
  String get downloadedTag => '다운로드됨';

  @override
  String get alreadyActiveButton => '이미 활성화됨';

  @override
  String get activateEngineButton => '엔진 활성화';

  @override
  String get activateBuiltInEngineButton => '내장 엔진 활성화';

  @override
  String get downloadInstallButton => '다운로드 및 설치';

  @override
  String get interfaceReplyLanguageTitle => '인터페이스 및 답변 언어';

  @override
  String get interfaceReplyLanguageDescription =>
      '기본적으로 시스템 언어를 따릅니다. 여기서 고정하면, 대화 중 명시적으로 바꾸지 않는 한 답변도 그 언어를 따릅니다.';

  @override
  String get languageFieldLabel => '언어';

  @override
  String get chatNoActiveModel => '아직 활성 모델이 로드되지 않았습니다.';

  @override
  String get whisperSheetTitle => '속삭임 지시';

  @override
  String get whisperSheetDescription =>
      '다음 답변에만 영향을 주며, 이 지시는 화면의 대화에는 표시되지 않습니다.';

  @override
  String get whisperSheetExample => '예: 좀 더 부드럽게 답하고, 걱정은 침착함 뒤에 숨겨 주세요.';

  @override
  String get applyWhisper => '적용';

  @override
  String get chatBackButtonTooltip => '뒤로';

  @override
  String get chatWhisperButtonTooltip => '속삭임 지시 열기';

  @override
  String get chatMoreActionsTooltip => '대화 작업';

  @override
  String get chatSendButtonTooltip => '메시지 보내기';

  @override
  String get chatStopButtonTooltip => '생성 중지';

  @override
  String get nextWhisperLabel => '다음 속삭임';

  @override
  String get chatInputPlaceholder => 'Aura에게 메시지 보내기...';

  @override
  String get chatModelPreparing => '모델을 준비하고 있어요. 잠시만 기다려 주세요...';

  @override
  String get chatRecoveringCore => '조금 불안정해서 자동으로 복구하고 있어요...';

  @override
  String get chatConversationResetting => '이 대화를 정리하고 있어요...';

  @override
  String get chatGenerationTimedOut =>
      '이번 답변이 시간 초과되었습니다. 바로 다시 보내거나 중지 후 재시도할 수 있습니다.';

  @override
  String get chatRuntimeRecovered => '복구가 끝났어요. 다시 메시지를 보낼 수 있습니다.';

  @override
  String get chatRuntimeRecoveryFailed => '복구에 실패했습니다. 설정에서 모델을 다시 활성화해 주세요.';

  @override
  String get assistantLabel => 'Aura';

  @override
  String get noActiveModel => '활성 모델 없음';

  @override
  String get roleplayReadyLabel => '롤플레이 컨텍스트 준비 완료';

  @override
  String get newConversationButton => '새 대화';

  @override
  String get clearHistoryButton => '기록 지우기';

  @override
  String get clearHistoryConfirmTitle => '모든 기록을 지울까요?';

  @override
  String clearHistoryConfirmDescription(Object characterName) {
    return '$characterName의 저장된 모든 기록이 삭제되며, 이전 분기는 복구할 수 없습니다.';
  }

  @override
  String get clearHistoryConfirmAction => '모두 삭제';

  @override
  String get historyClearedMessage => '이 캐릭터의 대화 기록을 지웠습니다.';

  @override
  String get sessionHistoryTitle => '기록';

  @override
  String get sessionHistoryShortLabel => '기록';

  @override
  String sessionHistoryDescription(Object characterName) {
    return '$characterName의 이전 분기로 돌아가 그 장면을 이어서 진행할 수 있습니다.';
  }

  @override
  String get sessionHistoryEmpty => '이 역할 카드에는 아직 저장된 기록이 없습니다.';

  @override
  String get sessionCurrentLabel => '현재 대화';

  @override
  String sessionMessageCount(Object count) {
    return '$count개 메시지';
  }

  @override
  String get sessionBranchEmpty => '이 분기는 아직 시작되지 않았습니다.';

  @override
  String get importingCardText => '캐릭터 카드를 분석하는 중...';

  @override
  String get importCardEmptyState => 'Tavern PNG 또는 JSON 카드를 선택해 미리보기를 확인하세요.';

  @override
  String get chooseCardButton => '이미지 또는 파일 선택';

  @override
  String get confirmImportButton => '가져오기 확인';

  @override
  String get cancelButton => '취소';

  @override
  String get editCharacterTitle => '캐릭터 편집';

  @override
  String get editCharacterButtonTooltip => '캐릭터 편집';

  @override
  String get characterWorkbenchTitle => '캐릭터 작업대';

  @override
  String get characterWorkbenchDescription =>
      '카드 본문, 초상 이미지, 로어북 항목을 여기서 다듬을 수 있습니다. 모든 변경 사항은 로컬 라이브러리에 저장됩니다.';

  @override
  String get characterPortraitImportedHint => '이 역할 카드는 원본 이미지를 이미 포함하고 있습니다.';

  @override
  String get characterPortraitAutoImportHint =>
      'Tavern PNG 카드를 가져오면 이미지도 자동으로 함께 들어옵니다. 이미지가 없을 때만 내장 커버를 사용합니다.';

  @override
  String get characterCoreFieldsTitle => '기본 정보';

  @override
  String get characterCoreFieldsDescription =>
      '이 항목들이 역할 소개, 장면 시작, 이야기의 흐름을 결정합니다.';

  @override
  String get characterNameLabel => '이름';

  @override
  String get characterDescriptionLabel => '설명';

  @override
  String get characterPersonalityLabel => '성격';

  @override
  String get characterScenarioLabel => '시나리오';

  @override
  String get characterFirstMessageLabel => '첫 메시지';

  @override
  String get characterExamplesLabel => '예시 대화';

  @override
  String get characterAlternateGreetingsLabel => '추가 도입문';

  @override
  String get characterCreatorNotesLabel => '작성자 메모';

  @override
  String get characterMainPromptLabel => '카드 내 메인 지시';

  @override
  String get characterPostHistoryInstructionsLabel => '응답 후 규칙';

  @override
  String get characterAdvancedFieldsTitle => '고급 설정';

  @override
  String get characterAdvancedFieldsDescription =>
      '추가 도입문, 작성자 메모, 카드 내 메인 지시, 응답 후 규칙은 필요할 때만 편집합니다.';

  @override
  String get blankLineSeparatedHint => '각 블록 사이를 한 줄 비워 주세요.';

  @override
  String get characterLorebookTitle => '로어북 / 월드북';

  @override
  String get characterLorebookDescription =>
      '독립 로어북을 가져오거나 여기서 항목을 직접 편집할 수 있습니다. 가져올 때는 기존 설정을 덮어쓰지 않고 기본적으로 병합합니다.';

  @override
  String lorebookAttachedLabel(Object count) {
    return '로어북 연결됨 ($count개 항목)';
  }

  @override
  String get lorebookMissingLabel => '아직 연결된 로어북이 없습니다.';

  @override
  String get importLorebookButton => '로어북 가져오기';

  @override
  String get importMergeWorldbookButton => '로어북 가져와 병합';

  @override
  String get addLorebookEntryButton => '항목 추가';

  @override
  String get replaceLorebookButton => '로어북 바꾸기';

  @override
  String get removeLorebookButton => '로어북 제거';

  @override
  String get lorebookMetaPanelTitle => '월드북 이름 / 요약';

  @override
  String get lorebookMetaSummaryFilled => '이름과 요약이 입력되어 있습니다.';

  @override
  String get lorebookMetaSummaryPartial => '고급 항목 1개가 입력되어 있습니다.';

  @override
  String get lorebookMetaSummaryEmpty => '필요할 때만 펼칠 수 있도록 기본적으로 접혀 있습니다.';

  @override
  String get worldbookNameLabel => '월드북 이름';

  @override
  String get worldbookDescriptionLabel => '월드북 설명';

  @override
  String get lorebookEntriesTitle => '월드북 항목';

  @override
  String get lorebookEntriesCollapsedEmptyHint =>
      '거대한 월드북이 화면 전체를 덮지 않도록 기본적으로 접혀 있습니다.';

  @override
  String get lorebookEntriesCollapsedHint => '탭해서 모든 항목을 보고 편집하세요.';

  @override
  String lorebookEntryCount(Object count) {
    return '$count개 항목';
  }

  @override
  String get lorebookEntriesEmptyState =>
      '아직 항목이 없습니다. Tavern 로어북을 가져오거나 키워드로 발동되는 설정 항목을 직접 추가해 주세요.';

  @override
  String lorebookEntryFallbackLabel(Object index) {
    return '항목 $index';
  }

  @override
  String get editEntryTooltip => '항목 편집';

  @override
  String get deleteEntryTooltip => '항목 삭제';

  @override
  String secondaryKeywordsTag(Object keywords) {
    return '보조 $keywords';
  }

  @override
  String priorityTag(Object value) {
    return '우선순위 $value';
  }

  @override
  String get lorebookEntryEditorTitle => '월드북 항목 편집';

  @override
  String get lorebookEntryIdLabel => '항목 ID';

  @override
  String get lorebookEntryPrimaryKeywordsLabel => '주 키워드';

  @override
  String get lorebookEntryPrimaryKeywordsHelper =>
      '쉼표로 구분합니다. 예: zhongli, contract, liyue';

  @override
  String get lorebookEntrySecondaryKeywordsLabel => '보조 키워드';

  @override
  String get lorebookEntrySecondaryKeywordsHelper => '선택 사항이며 쉼표로 구분합니다.';

  @override
  String get lorebookEntryContentLabel => '항목 내용';

  @override
  String get lorebookEntryCommentLabel => '메모';

  @override
  String get lorebookEntryPriorityLabel => '우선순위';

  @override
  String get lorebookEntryEnabledLabel => '항목 활성화';

  @override
  String get lorebookEntrySelectiveLabel => '보조 키워드 필요';

  @override
  String get lorebookEntryConstantLabel => '항상 주입';

  @override
  String get lorebookEntryWholeWordLabel => '단어 전체 일치';

  @override
  String get lorebookEntryCaseSensitiveLabel => '대소문자 구분';

  @override
  String get saveEntryButton => '항목 저장';

  @override
  String get lorebookEntryValidationError => '최소한 키워드와 내용을 입력해 주세요.';

  @override
  String lorebookImportedMessage(Object count) {
    return '로어북을 연결했습니다 ($count개 항목).';
  }

  @override
  String get saveButton => '저장';

  @override
  String get savingButton => '저장 중...';

  @override
  String get importDialogDescription =>
      'Tavern / SillyTavern 카드는 바로 라이브러리에 들어갑니다. 독립 로어북은 다음 단계에서 대상 카드에 연결할 수 있습니다.';

  @override
  String get importPreviewRoleCardTag => '스토리 카드';

  @override
  String get embeddedWorldbookTag => '내장 로어북';

  @override
  String get createCharacterButton => '직접 만들기';

  @override
  String get attachWorldbookButton => '로어북 연결';

  @override
  String get importEmptyStateIntro =>
      '먼저 가져올 경로를 선택하세요. 사진은 갤러리에 저장된 Tavern PNG용이고, 파일은 Tavern / SillyTavern PNG, JSON 카드와 독립 로어북을 지원합니다. 로어북이 내장된 카드는 한 번에 들어옵니다.';

  @override
  String get importEmptyStateDetails =>
      '카드에 `character_book` / 로어북이 포함되어 있으면 Aura가 첫 메시지, 대체 오프닝, 지시문, 장면 설정을 그대로 보존합니다.';

  @override
  String get importCreateCharacterHint => '기존 카드가 없다면 여기서 새로 만들 수도 있습니다.';

  @override
  String get chooseAnotherCardButton => '다른 이미지 또는 파일 선택';

  @override
  String get importSourceSheetTitle => '가져오기 방식 선택';

  @override
  String get importSourceSheetSubtitle =>
      '사진은 사진 보관함에 저장된 Tavern PNG 카드용입니다. 파일에서는 Tavern PNG / JSON 카드를 고를 수 있습니다.';

  @override
  String get importFromPhotosTitle => '사진에서 가져오기';

  @override
  String get importFromPhotosSubtitle => '사진 보관함에 저장된 Tavern PNG 카드를 선택합니다.';

  @override
  String get importFromFilesTitle => '파일에서 가져오기';

  @override
  String get importFromFilesSubtitle =>
      'Files 에서 Tavern PNG, JSON 카드, 독립 월드북을 선택합니다.';

  @override
  String get importWorldbookHint => '독립 월드북은 여기서가 아니라 캐릭터 편집 화면에서 가져옵니다.';

  @override
  String get importErrorTitle => '이 파일은 가져올 수 없습니다';

  @override
  String get importFileLabel => '파일';

  @override
  String get importCreatorLabel => '제작자';

  @override
  String get importNoDescriptionLabel => '이 카드에는 설명이 없습니다.';

  @override
  String get importNoFirstMessageLabel => '이 카드에는 첫 메시지가 없습니다.';

  @override
  String get importWorldbookErrorMessage =>
      '이 파일은 독립 월드북으로 보입니다. 캐릭터를 연 뒤 로어북 영역에서 가져와 주세요.';

  @override
  String get importUnsupportedFileMessage =>
      '여기서는 Tavern PNG 와 JSON 캐릭터 카드만 지원합니다.';

  @override
  String get photoImportPngOnlyMessage => '사진에서 가져오기는 현재 Tavern PNG 카드만 지원합니다.';

  @override
  String get importInvalidCharacterFileMessage =>
      '이 파일은 지원되는 캐릭터 카드처럼 보이지 않습니다.';

  @override
  String get importGenericErrorMessage => '가져오기에 실패했습니다. 다른 카드 파일로 다시 시도해 주세요.';

  @override
  String importSuccessMessage(Object characterName) {
    return '$characterName 가져오기를 완료했습니다.';
  }

  @override
  String characterCreatedMessage(Object characterName) {
    return '$characterName 캐릭터를 만들었습니다.';
  }

  @override
  String get importOpenChatAction => '바로 대화';

  @override
  String get settingsButtonTooltip => '설정 열기';

  @override
  String get editMessageActionTitle => '이 메시지 수정';

  @override
  String get editMessageActionDescription => '이야기의 흐름은 유지한 채 이 턴만 고칩니다.';

  @override
  String get deleteMessageActionTitle => '이 메시지 삭제';

  @override
  String get deleteMessageActionDescription => '현재 대화에서 이 턴을 제거합니다.';

  @override
  String get editMessageDialogTitle => '메시지 수정';

  @override
  String get editMessageHint => '메시지를 다시 써 주세요';

  @override
  String get messageUpdated => '메시지를 수정했습니다.';

  @override
  String get deleteMessageDialogTitle => '메시지 삭제';

  @override
  String get deleteMessageDialogDescription => '이 메시지는 현재 대화에서 제거됩니다.';

  @override
  String get deleteButton => '삭제';

  @override
  String get messageDeleted => '메시지를 삭제했습니다.';

  @override
  String get continueSceneButtonTooltip => '현재 장면 이어가기';

  @override
  String get continueScenePrompt =>
      '현재 장면을 자연스럽게 이어 주세요. 관계를 초기화하거나 역할에서 벗어나지 말고, 긴장감과 단서, 감정의 흐름을 앞으로 밀어 주세요.';

  @override
  String get storyCoreDownloadPrompt => '장면에 들어가기 전에 스토리 코어를 먼저 내려받아 주세요.';

  @override
  String get storyCoreChooseButton => '스토리 코어 선택';

  @override
  String get storyCoreDownloadStatus => '스토리 코어 선택';

  @override
  String get firstRunModelTitle => '첫 스토리 코어 선택';

  @override
  String get firstRunModelSubtitle =>
      'Aura를 처음 열 때는 로컬 스토리 코어 하나가 필요합니다. E2B는 더 빠르게 시작할 수 있고, E4B는 더 높은 품질을 제공합니다. 다운로드가 끝나면 바로 방금 보던 장면으로 돌아갑니다.';

  @override
  String get firstRunModelRecommendedBadge => '추천';

  @override
  String get firstRunModelQualityBadge => '고품질';

  @override
  String get firstRunE2bHeadline => '빠르게 시작';

  @override
  String get firstRunE2bSummary =>
      '처음 설치할 때 가장 적합합니다. 다운로드가 더 가볍고 설정이 빨라서 바로 장면에 들어가기 쉽습니다.';

  @override
  String get firstRunE4bHeadline => '더 강한 장면 디테일';

  @override
  String get firstRunE4bSummary => '다운로드는 더 크지만, 문장 품질과 디테일, 장면 안정감이 더 좋아집니다.';

  @override
  String get modelDownloadPreparingButton => '다운로드 중...';

  @override
  String modelSetupRamHint(Object memory) {
    return '권장 메모리 $memory';
  }

  @override
  String modelSetupDownloadProgress(Object received, Object total) {
    return '다운로드됨 $received / $total';
  }

  @override
  String get modelErrorNoSpace => '저장 공간이 부족합니다. 공간을 확보한 뒤 다시 시도해 주세요.';

  @override
  String get modelErrorCorrupt => '다운로드한 파일이 완전하지 않습니다. 다시 내려받아 주세요.';

  @override
  String get modelErrorNetwork => '다운로드가 중단되었습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.';

  @override
  String get modelErrorGeneric => '문제가 발생했습니다. 잠시 후 다시 시도해 주세요.';
}
