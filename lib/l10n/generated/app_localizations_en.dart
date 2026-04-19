// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Aura';

  @override
  String get bootstrapLoadingMessage => 'Opening your private story space...';

  @override
  String get bootstrapErrorTitle => 'Aura failed to launch';

  @override
  String get bootstrapErrorDescription =>
      'Aura could not finish startup. Check the details below.';

  @override
  String get loadingModel => 'Constructing scene...';

  @override
  String get modelStateIdle => 'Idle';

  @override
  String get modelStateError => 'Error';

  @override
  String statusLabel(Object state) {
    return 'Status $state';
  }

  @override
  String get readyText => 'Ready';

  @override
  String get chatInputHint => 'Continue the story...';

  @override
  String get whisperHint => 'Whisper instruction (next turn only)...';

  @override
  String get advancedSettings => 'System Archives';

  @override
  String get characters => 'Story Library';

  @override
  String get importCharacter => 'Import Character';

  @override
  String get importPreviewTitle => 'Import Story Card';

  @override
  String lorebookIncluded(Object count) {
    return '📚 Includes Lorebook ($count entries)';
  }

  @override
  String get companionsTitle => 'Story Library';

  @override
  String get appTagline => 'Gemma 4 on your phone. No API, no cloud, no cost.';

  @override
  String get engineStatusTitle => 'Local Inference Engine';

  @override
  String engineRunning(Object modelName) {
    return 'Inference Core: $modelName';
  }

  @override
  String get systemLabel => 'SYSTEM';

  @override
  String get settingsTitle => 'Storage & Settings';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get activeCoreTitle => 'Active Inference Core';

  @override
  String get systemOfflineText =>
      'Offline. Please boot up a local inference core to enter the story.';

  @override
  String get availableCoresTitle => 'Available Inference Cores';

  @override
  String get hardwareImportsTitle => 'Hardware & Extensions';

  @override
  String get promptPresetTitle => 'Story Directives';

  @override
  String get promptPresetActiveLabel => 'Current Directive';

  @override
  String get importPresetJsonButton => 'Import Directive File';

  @override
  String get editActivePresetButton => 'Edit Current Directive';

  @override
  String get editPromptPresetTitle => 'Edit System Directive';

  @override
  String get presetNameFieldLabel => 'Directive Name';

  @override
  String get presetSystemPromptFieldLabel => 'Story Behavior';

  @override
  String get presetTemperatureFieldLabel => 'Creativity';

  @override
  String get presetTopPFieldLabel => 'Sampling Range';

  @override
  String get presetTopKFieldLabel => 'Candidate Count';

  @override
  String get presetMaxOutputTokensFieldLabel => 'Max Output Tokens';

  @override
  String get defaultRoleplayPresetName => 'Aura Default Story Directive';

  @override
  String get defaultRoleplayPresetPrompt =>
      'You are fully immersed in the assigned role. Stay in character, write vividly, and never mention being an AI assistant unless the system explicitly allows it.';

  @override
  String get importedPresetFallbackName => 'Imported Directive';

  @override
  String get neuralAccelerationTitle => 'Neural Engine Acceleration';

  @override
  String get neuralAccelerationSubtitle =>
      'Automatically routing to NPU/CoreML when possible';

  @override
  String get expressionPackTitle => 'Expression Pack (ZIP)';

  @override
  String get expressionPackSubtitle => 'Import complex 2D expression packs';

  @override
  String get activeBadge => 'ACTIVE';

  @override
  String get builtInTag => 'Built-in';

  @override
  String get downloadedTag => 'Downloaded';

  @override
  String get alreadyActiveButton => 'Already Active';

  @override
  String get activateEngineButton => 'Activate Core';

  @override
  String get activateBuiltInEngineButton => 'Activate Built-in Core';

  @override
  String get downloadInstallButton => 'Download & Install';

  @override
  String get interfaceReplyLanguageTitle => 'Interface & Reply Language';

  @override
  String get interfaceReplyLanguageDescription =>
      'UI follows the system by default. You can pin a language here, and chat replies will follow that preference unless the user explicitly switches.';

  @override
  String get languageFieldLabel => 'Language';

  @override
  String get chatNoActiveModel =>
      'Offline. No inference core is loaded for the story.';

  @override
  String get whisperSheetTitle => 'Whisper Instruction';

  @override
  String get whisperSheetDescription =>
      'Influence the character\'s next turn from behind the scenes without breaking the story text.';

  @override
  String get whisperSheetExample =>
      'Example: Reply more softly and hide concern under confidence.';

  @override
  String get applyWhisper => 'Apply Whisper';

  @override
  String get chatBackButtonTooltip => 'Back';

  @override
  String get chatWhisperButtonTooltip => 'Open whisper instruction';

  @override
  String get chatMoreActionsTooltip => 'Scene actions';

  @override
  String get chatSendButtonTooltip => 'Progress story';

  @override
  String get chatStopButtonTooltip => 'Stop generation';

  @override
  String get nextWhisperLabel => 'Next whisper';

  @override
  String get chatInputPlaceholder => 'Write the next turn...';

  @override
  String get chatModelPreparing => 'Aura is arranging the scene...';

  @override
  String get chatRecoveringCore => 'Reconnecting thought process...';

  @override
  String get chatConversationResetting => 'Resetting the timeline...';

  @override
  String get chatGenerationTimedOut =>
      'Aura didn\'t respond in time. You can send again.';

  @override
  String get chatRuntimeRecovered =>
      'Reconnection successful. You may continue.';

  @override
  String get chatRuntimeRecoveryFailed =>
      'Inference core disconnected. Please reactivate in Settings.';

  @override
  String get assistantLabel => 'Character';

  @override
  String get noActiveModel => 'No active core';

  @override
  String get roleplayReadyLabel => 'Ready to enter the story';

  @override
  String get newConversationButton => 'New Scene';

  @override
  String get clearHistoryButton => 'Reset Scene';

  @override
  String get clearHistoryConfirmTitle => 'Clear all session history?';

  @override
  String clearHistoryConfirmDescription(Object characterName) {
    return 'This deletes every saved session for $characterName and the old branches cannot be restored.';
  }

  @override
  String get clearHistoryConfirmAction => 'Delete All';

  @override
  String get historyClearedMessage =>
      'Scene progress has been reset for this character.';

  @override
  String get sessionHistoryTitle => 'Session History';

  @override
  String get sessionHistoryShortLabel => 'History';

  @override
  String sessionHistoryDescription(Object characterName) {
    return 'Jump back into an older branch for $characterName and keep that storyline going.';
  }

  @override
  String get sessionHistoryEmpty => 'No saved sessions for this role card yet.';

  @override
  String get sessionCurrentLabel => 'Current Session';

  @override
  String sessionMessageCount(Object count) {
    return '$count messages';
  }

  @override
  String get sessionBranchEmpty => 'This branch has not started yet.';

  @override
  String get importingCardText => 'Parsing character card...';

  @override
  String get importCardEmptyState =>
      'Choose a Tavern PNG or JSON card to preview it.';

  @override
  String get chooseCardButton => 'Choose Image or File';

  @override
  String get confirmImportButton => 'Confirm Import';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get editCharacterTitle => 'Edit Character';

  @override
  String get editCharacterButtonTooltip => 'Edit character';

  @override
  String get characterWorkbenchTitle => 'Character Workbench';

  @override
  String get characterWorkbenchDescription =>
      'Tune the card body, portrait, and worldbook entries here. All changes are saved into the local library.';

  @override
  String get characterPortraitImportedHint =>
      'This role card already includes its original portrait art.';

  @override
  String get characterPortraitAutoImportHint =>
      'If you import a Tavern PNG card, Aura carries the art over automatically. The built-in cinematic cover is only used when no image exists.';

  @override
  String get characterCoreFieldsTitle => 'Core Card Fields';

  @override
  String get characterCoreFieldsDescription =>
      'These fields define the role summary, scene setup, and opening momentum.';

  @override
  String get characterNameLabel => 'Name';

  @override
  String get characterDescriptionLabel => 'Description';

  @override
  String get characterPersonalityLabel => 'Personality';

  @override
  String get characterScenarioLabel => 'Scenario';

  @override
  String get characterFirstMessageLabel => 'First Message';

  @override
  String get characterExamplesLabel => 'Example Dialogues';

  @override
  String get characterAlternateGreetingsLabel => 'Alternate Greetings';

  @override
  String get characterCreatorNotesLabel => 'Creator Notes';

  @override
  String get characterMainPromptLabel => 'Main Prompt Override';

  @override
  String get characterPostHistoryInstructionsLabel =>
      'Post-History Instructions';

  @override
  String get characterAdvancedFieldsTitle => 'Tavern Advanced Fields';

  @override
  String get characterAdvancedFieldsDescription =>
      'These fields feed directly into alternate greetings, prompt overrides, and next-turn reply constraints.';

  @override
  String get blankLineSeparatedHint => 'Separate each block with a blank line.';

  @override
  String get characterLorebookTitle => 'Lorebook / Worldbook';

  @override
  String get characterLorebookDescription =>
      'Import standalone worldbooks or manage entries directly here. Imported worldbooks merge by default instead of overwriting existing lore.';

  @override
  String lorebookAttachedLabel(Object count) {
    return 'Attached lorebook ($count entries)';
  }

  @override
  String get lorebookMissingLabel => 'No lorebook attached yet.';

  @override
  String get importLorebookButton => 'Import Lorebook';

  @override
  String get importMergeWorldbookButton => 'Import & Merge Worldbook';

  @override
  String get addLorebookEntryButton => 'Add Entry';

  @override
  String get replaceLorebookButton => 'Replace Lorebook';

  @override
  String get removeLorebookButton => 'Remove Lorebook';

  @override
  String get lorebookMetaPanelTitle => 'Worldbook Name & Summary';

  @override
  String get lorebookMetaSummaryFilled => 'Name and summary are filled in.';

  @override
  String get lorebookMetaSummaryPartial => 'One advanced field is filled in.';

  @override
  String get lorebookMetaSummaryEmpty =>
      'Collapsed by default. Expand only if you need it.';

  @override
  String get worldbookNameLabel => 'Worldbook Name';

  @override
  String get worldbookDescriptionLabel => 'Worldbook Description';

  @override
  String get lorebookEntriesTitle => 'Worldbook Entries';

  @override
  String get lorebookEntriesCollapsedEmptyHint =>
      'Collapsed by default so giant worldbooks do not flood the whole workbench.';

  @override
  String get lorebookEntriesCollapsedHint =>
      'Tap to reveal and manage every entry.';

  @override
  String lorebookEntryCount(Object count) {
    return '$count entries';
  }

  @override
  String get lorebookEntriesEmptyState =>
      'No entries yet. Import a Tavern worldbook or add keyword-triggered scene notes manually.';

  @override
  String lorebookEntryFallbackLabel(Object index) {
    return 'Entry $index';
  }

  @override
  String get editEntryTooltip => 'Edit entry';

  @override
  String get deleteEntryTooltip => 'Delete entry';

  @override
  String secondaryKeywordsTag(Object keywords) {
    return 'Secondary $keywords';
  }

  @override
  String priorityTag(Object value) {
    return 'Priority $value';
  }

  @override
  String get lorebookEntryEditorTitle => 'Edit Worldbook Entry';

  @override
  String get lorebookEntryIdLabel => 'Entry ID';

  @override
  String get lorebookEntryPrimaryKeywordsLabel => 'Primary Keywords';

  @override
  String get lorebookEntryPrimaryKeywordsHelper =>
      'Comma-separated, for example: zhongli, contract, liyue';

  @override
  String get lorebookEntrySecondaryKeywordsLabel => 'Secondary Keywords';

  @override
  String get lorebookEntrySecondaryKeywordsHelper =>
      'Optional, comma-separated.';

  @override
  String get lorebookEntryContentLabel => 'Entry Content';

  @override
  String get lorebookEntryCommentLabel => 'Comment';

  @override
  String get lorebookEntryPriorityLabel => 'Priority';

  @override
  String get lorebookEntryEnabledLabel => 'Enable Entry';

  @override
  String get lorebookEntrySelectiveLabel => 'Require Secondary Keywords';

  @override
  String get lorebookEntryConstantLabel => 'Always Inject';

  @override
  String get lorebookEntryWholeWordLabel => 'Whole Word Match';

  @override
  String get lorebookEntryCaseSensitiveLabel => 'Case Sensitive';

  @override
  String get saveEntryButton => 'Save Entry';

  @override
  String get lorebookEntryValidationError =>
      'Please provide at least keywords and content.';

  @override
  String lorebookImportedMessage(Object count) {
    return 'Lorebook attached ($count entries).';
  }

  @override
  String get saveButton => 'Save';

  @override
  String get savingButton => 'Saving...';

  @override
  String get importDialogDescription =>
      'Tavern and SillyTavern cards import straight into the library. Standalone worldbooks can be attached to a role card in the next step.';

  @override
  String get importPreviewRoleCardTag => 'Story Card';

  @override
  String get embeddedWorldbookTag => 'Embedded Worldbook';

  @override
  String get createCharacterButton => 'Create Character';

  @override
  String get attachWorldbookButton => 'Attach Worldbook';

  @override
  String get importEmptyStateIntro =>
      'Choose an import source first: Photos are for Tavern PNG cards already saved to your gallery, while Files support Tavern or SillyTavern PNG cards, JSON cards, and standalone worldbooks. Cards with embedded worldbooks come in one step.';

  @override
  String get importEmptyStateDetails =>
      'Aura will automatically preserve `character_book` world info, greetings, prompt overrides, and scene notes when the card includes them.';

  @override
  String get importCreateCharacterHint =>
      'No existing role card yet? You can also create one from scratch here.';

  @override
  String get chooseAnotherCardButton => 'Choose Another Image or File';

  @override
  String get importSourceSheetTitle => 'Choose Import Source';

  @override
  String get importSourceSheetSubtitle =>
      'Photos are for Tavern PNG cards already saved to your gallery. Files support Tavern PNG and JSON cards.';

  @override
  String get importFromPhotosTitle => 'Import From Photos';

  @override
  String get importFromPhotosSubtitle =>
      'Pick a Tavern PNG card that is already in your photo library.';

  @override
  String get importFromFilesTitle => 'Import From Files';

  @override
  String get importFromFilesSubtitle =>
      'Pick a Tavern PNG card, JSON card, or standalone worldbook from Files.';

  @override
  String get importWorldbookHint =>
      'You can also choose a standalone worldbook JSON here. Aura will let you attach it to a role card in the next step.';

  @override
  String get importErrorTitle => 'Unable to import this file';

  @override
  String get importFileLabel => 'File';

  @override
  String get importCreatorLabel => 'Creator';

  @override
  String get importNoDescriptionLabel =>
      'This card does not include a description.';

  @override
  String get importNoFirstMessageLabel =>
      'This card does not include a first message.';

  @override
  String get importWorldbookErrorMessage =>
      'This file is a standalone worldbook. Aura can attach it directly to a role card from the import flow.';

  @override
  String get importUnsupportedFileMessage =>
      'Only Tavern PNG and JSON character cards are supported here.';

  @override
  String get photoImportPngOnlyMessage =>
      'Photo import currently supports Tavern PNG cards only.';

  @override
  String get importInvalidCharacterFileMessage =>
      'This file does not look like a supported character card.';

  @override
  String get importGenericErrorMessage =>
      'Import failed. Please try another character card file.';

  @override
  String importSuccessMessage(Object characterName) {
    return '$characterName imported successfully.';
  }

  @override
  String characterCreatedMessage(Object characterName) {
    return '$characterName created successfully.';
  }

  @override
  String get importOpenChatAction => 'Open Scene';

  @override
  String get settingsButtonTooltip => 'Open settings';

  @override
  String get editMessageActionTitle => 'Edit this message';

  @override
  String get editMessageActionDescription =>
      'Keep the story and revise this turn only.';

  @override
  String get deleteMessageActionTitle => 'Delete this message';

  @override
  String get deleteMessageActionDescription =>
      'Remove this turn from the current session.';

  @override
  String get editMessageDialogTitle => 'Edit message';

  @override
  String get editMessageHint => 'Rewrite the message';

  @override
  String get messageUpdated => 'Message updated.';

  @override
  String get deleteMessageDialogTitle => 'Delete message';

  @override
  String get deleteMessageDialogDescription =>
      'This message will be removed from the current session.';

  @override
  String get deleteButton => 'Delete';

  @override
  String get messageDeleted => 'Message deleted.';

  @override
  String get continueSceneButtonTooltip => 'Continue the current scene';

  @override
  String get continueScenePrompt =>
      'Continue the current scene naturally. Advance the tension, clues, or emotions without resetting the relationship or breaking character.';

  @override
  String get storyCoreDownloadPrompt =>
      'Download a story core before entering the scene.';

  @override
  String get storyCoreChooseButton => 'Choose Story Core';

  @override
  String get storyCoreDownloadStatus => 'Choose a story core';

  @override
  String get firstRunModelTitle => 'Choose your first story core';

  @override
  String get firstRunModelSubtitle =>
      'Aura needs one local story core before the first scene can begin. E2B starts faster. E4B gives you stronger quality, and Aura will return to your scene as soon as the download finishes.';

  @override
  String get firstRunModelRecommendedBadge => 'Recommended';

  @override
  String get firstRunModelQualityBadge => 'Higher quality';

  @override
  String get firstRunE2bHeadline => 'Faster first start';

  @override
  String get firstRunE2bSummary =>
      'Best for a first install. Smaller download, quicker setup, and smoother story entry.';

  @override
  String get firstRunE4bHeadline => 'Stronger scene detail';

  @override
  String get firstRunE4bSummary =>
      'Bigger download, but stronger writing quality, richer detail, and steadier scene control.';

  @override
  String get modelDownloadPreparingButton => 'Downloading...';

  @override
  String modelSetupRamHint(Object memory) {
    return 'Recommended RAM $memory';
  }

  @override
  String modelSetupDownloadProgress(Object received, Object total) {
    return 'Downloaded $received / $total';
  }

  @override
  String get modelErrorNoSpace =>
      'Not enough storage space. Free up some space and try again.';

  @override
  String get modelErrorCorrupt =>
      'The downloaded file was incomplete. Please try again.';

  @override
  String get modelErrorNetwork =>
      'Download interrupted. Check your connection and try again.';

  @override
  String get modelErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get modelSetupE2bSpeedChip => 'Fast inference';

  @override
  String get modelSetupE4bQualityChip => 'Richer vocabulary, longer scenes';

  @override
  String get splashInitializingEngine => 'Initializing Engine';

  @override
  String get splashRetryButton => 'Retry';

  @override
  String get splashPreparingRuntime => 'Preparing runtime...';

  @override
  String get splashLoadingCore => 'Loading story core...';

  @override
  String get splashGoToSettings => 'Go to Settings';

  @override
  String get splashDownloadCore => 'Download a Core';

  @override
  String get splashTryAgain => 'Try Again';

  @override
  String importEmbeddedWorldbookCount(Object count) {
    return 'Embedded Worldbook $count';
  }

  @override
  String importAltGreetingsCount(Object count) {
    return 'Alt Greetings $count';
  }

  @override
  String get importCardMainPromptTag => 'Card Main Prompt';

  @override
  String get importPostHistoryNoteTag => 'Post-History Note';

  @override
  String get importPreservedFieldsTitle => 'Imported As-Is';

  @override
  String get importPreservedFieldsContent =>
      'Opening message / alternate greetings / scenario / persona / embedded worldbook / main prompt override / post-history rules';

  @override
  String get importNoPersonalityLabel =>
      'This card does not include a dedicated personality field.';

  @override
  String get importNoScenarioLabel =>
      'This card does not include a scenario field.';

  @override
  String get importCreatorNotesTitle => 'Creator Notes';

  @override
  String get importAltGreetingsTitle => 'Alternate Greetings';

  @override
  String get importStandaloneWorldbookTitle => 'Standalone Worldbook';

  @override
  String importWorldbookEntriesCount(Object count) {
    return '$count entries';
  }

  @override
  String get importWorldbookHelperNew =>
      'Aura recognized this file as a standalone worldbook. Pick a role card and attach it directly.';

  @override
  String get importWorldbookHelperMerge =>
      'Aura recognized this file as a standalone worldbook. It will merge with the role card lore instead of overwriting it.';

  @override
  String get importWorldbookAttachTo => 'Attach To';

  @override
  String get importWorldbookNoCharacters => 'No role cards are available yet.';

  @override
  String get importWorldbookChooseCard => 'Choose Role Card';

  @override
  String get importWorldbookMergeResult => 'Merge Result';

  @override
  String importWorldbookMergeDetails(
      Object existing, Object incoming, Object merged) {
    return 'Current role has $existing entries, this file has $incoming, and the merged card will keep about $merged entries.';
  }

  @override
  String get importWorldbookDescriptionTitle => 'Description';

  @override
  String get importWorldbookEntryPreviewTitle => 'Worldbook Entry Preview';

  @override
  String get importWorldbookChooseCharacterError =>
      'Choose a role card before attaching the worldbook.';

  @override
  String get importPngNoMetadataError =>
      'This PNG does not contain character card metadata. If it came from Photos, try importing the original Tavern PNG from Files.';

  @override
  String get starterCharacterName => 'New Character';

  @override
  String get starterCharacterDescription =>
      'Write the role, relationship, and dramatic hook for this character.';

  @override
  String get starterCharacterPersonality =>
      'Stay in character, keep the scene moving, and respond with concrete actions and emotions.';

  @override
  String get starterCharacterScenario =>
      'Describe the opening scene, location, conflict, and the relationship with the player.';

  @override
  String get starterCharacterFirstMessage =>
      'The footsteps outside are getting closer. Now that you are here, there is no easy way back.';

  @override
  String get starterCharacterAltGreeting =>
      'You arrived sooner than I expected.';

  @override
  String get searchCharactersHint => 'Search characters...';

  @override
  String get searchNoResults => 'No characters match your search.';

  @override
  String get emptyLibraryTitle => 'Your story library is empty';

  @override
  String get emptyLibraryDescription =>
      'Import a Tavern card or create one from scratch. Everything runs on-device — no API keys, no cloud, no cost.';

  @override
  String get deleteCharacterTitle => 'Delete Character';

  @override
  String deleteCharacterConfirm(Object characterName) {
    return 'Are you sure you want to delete $characterName? This cannot be undone.';
  }

  @override
  String characterDeletedMessage(Object characterName) {
    return '$characterName has been deleted.';
  }

  @override
  String get copyToClipboard => 'Copy to clipboard';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get messageTimeJustNow => 'just now';

  @override
  String messageTimeMinutesAgo(Object count) {
    return '$count min ago';
  }

  @override
  String get rerollButtonTooltip => 'Regenerate response';

  @override
  String get characterDetailsSheetTitle => 'Character Details';

  @override
  String get errorGoToSettings => 'Go to Settings';

  @override
  String get errorRetryMessage => 'Retry';

  @override
  String get coreReconnectedToast => 'Core reconnected. You can send again.';

  @override
  String get storyCoresTitle => 'Story Cores';

  @override
  String get deleteModelTitle => 'Delete Model';

  @override
  String deleteModelConfirm(Object modelName) {
    return 'Delete $modelName? You can re-download it later.';
  }

  @override
  String modelDeletedMessage(Object modelName) {
    return '$modelName has been deleted.';
  }

  @override
  String get diskSpaceLabel => 'Disk';
}
