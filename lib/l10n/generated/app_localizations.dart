import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Aura'**
  String get appTitle;

  /// No description provided for @bootstrapLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Opening your private story space...'**
  String get bootstrapLoadingMessage;

  /// No description provided for @bootstrapErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Aura failed to launch'**
  String get bootstrapErrorTitle;

  /// No description provided for @bootstrapErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Aura could not finish startup. Check the details below.'**
  String get bootstrapErrorDescription;

  /// No description provided for @loadingModel.
  ///
  /// In en, this message translates to:
  /// **'Constructing scene...'**
  String get loadingModel;

  /// No description provided for @modelStateIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get modelStateIdle;

  /// No description provided for @modelStateError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get modelStateError;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status {state}'**
  String statusLabel(Object state);

  /// No description provided for @readyText.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get readyText;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Continue the story...'**
  String get chatInputHint;

  /// No description provided for @whisperHint.
  ///
  /// In en, this message translates to:
  /// **'Whisper instruction (next turn only)...'**
  String get whisperHint;

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'System Archives'**
  String get advancedSettings;

  /// No description provided for @characters.
  ///
  /// In en, this message translates to:
  /// **'Story Library'**
  String get characters;

  /// No description provided for @importCharacter.
  ///
  /// In en, this message translates to:
  /// **'Import Character'**
  String get importCharacter;

  /// No description provided for @importPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Story Card'**
  String get importPreviewTitle;

  /// No description provided for @lorebookIncluded.
  ///
  /// In en, this message translates to:
  /// **'📚 Includes Lorebook ({count} entries)'**
  String lorebookIncluded(Object count);

  /// No description provided for @companionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Story Library'**
  String get companionsTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Gemma 4 on your phone. No API, no cloud, no cost.'**
  String get appTagline;

  /// No description provided for @engineStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Local Inference Engine'**
  String get engineStatusTitle;

  /// No description provided for @engineRunning.
  ///
  /// In en, this message translates to:
  /// **'Inference Core: {modelName}'**
  String engineRunning(Object modelName);

  /// No description provided for @systemLabel.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM'**
  String get systemLabel;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage & Settings'**
  String get settingsTitle;

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionTitle;

  /// No description provided for @activeCoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Inference Core'**
  String get activeCoreTitle;

  /// No description provided for @systemOfflineText.
  ///
  /// In en, this message translates to:
  /// **'Offline. Please boot up a local inference core to enter the story.'**
  String get systemOfflineText;

  /// No description provided for @availableCoresTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Inference Cores'**
  String get availableCoresTitle;

  /// No description provided for @hardwareImportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hardware & Extensions'**
  String get hardwareImportsTitle;

  /// No description provided for @promptPresetTitle.
  ///
  /// In en, this message translates to:
  /// **'Story Directives'**
  String get promptPresetTitle;

  /// No description provided for @promptPresetActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Directive'**
  String get promptPresetActiveLabel;

  /// No description provided for @importPresetJsonButton.
  ///
  /// In en, this message translates to:
  /// **'Import Directive File'**
  String get importPresetJsonButton;

  /// No description provided for @editActivePresetButton.
  ///
  /// In en, this message translates to:
  /// **'Edit Current Directive'**
  String get editActivePresetButton;

  /// No description provided for @editPromptPresetTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit System Directive'**
  String get editPromptPresetTitle;

  /// No description provided for @presetNameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Directive Name'**
  String get presetNameFieldLabel;

  /// No description provided for @presetSystemPromptFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Story Behavior'**
  String get presetSystemPromptFieldLabel;

  /// No description provided for @presetTemperatureFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Creativity'**
  String get presetTemperatureFieldLabel;

  /// No description provided for @presetTopPFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Sampling Range'**
  String get presetTopPFieldLabel;

  /// No description provided for @presetTopKFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Candidate Count'**
  String get presetTopKFieldLabel;

  /// No description provided for @presetMaxOutputTokensFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Max Output Tokens'**
  String get presetMaxOutputTokensFieldLabel;

  /// No description provided for @defaultRoleplayPresetName.
  ///
  /// In en, this message translates to:
  /// **'Aura Default Story Directive'**
  String get defaultRoleplayPresetName;

  /// No description provided for @defaultRoleplayPresetPrompt.
  ///
  /// In en, this message translates to:
  /// **'You are fully immersed in the assigned role. Stay in character, write vividly, and never mention being an AI assistant unless the system explicitly allows it.'**
  String get defaultRoleplayPresetPrompt;

  /// No description provided for @importedPresetFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Imported Directive'**
  String get importedPresetFallbackName;

  /// No description provided for @neuralAccelerationTitle.
  ///
  /// In en, this message translates to:
  /// **'Neural Engine Acceleration'**
  String get neuralAccelerationTitle;

  /// No description provided for @neuralAccelerationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically routing to NPU/CoreML when possible'**
  String get neuralAccelerationSubtitle;

  /// No description provided for @expressionPackTitle.
  ///
  /// In en, this message translates to:
  /// **'Expression Pack (ZIP)'**
  String get expressionPackTitle;

  /// No description provided for @expressionPackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import complex 2D expression packs'**
  String get expressionPackSubtitle;

  /// No description provided for @activeBadge.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get activeBadge;

  /// No description provided for @builtInTag.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get builtInTag;

  /// No description provided for @downloadedTag.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloadedTag;

  /// No description provided for @alreadyActiveButton.
  ///
  /// In en, this message translates to:
  /// **'Already Active'**
  String get alreadyActiveButton;

  /// No description provided for @activateEngineButton.
  ///
  /// In en, this message translates to:
  /// **'Activate Core'**
  String get activateEngineButton;

  /// No description provided for @activateBuiltInEngineButton.
  ///
  /// In en, this message translates to:
  /// **'Activate Built-in Core'**
  String get activateBuiltInEngineButton;

  /// No description provided for @downloadInstallButton.
  ///
  /// In en, this message translates to:
  /// **'Download & Install'**
  String get downloadInstallButton;

  /// No description provided for @interfaceReplyLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Interface & Reply Language'**
  String get interfaceReplyLanguageTitle;

  /// No description provided for @interfaceReplyLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'UI follows the system by default. You can pin a language here, and chat replies will follow that preference unless the user explicitly switches.'**
  String get interfaceReplyLanguageDescription;

  /// No description provided for @languageFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageFieldLabel;

  /// No description provided for @followSystemLabel.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get followSystemLabel;

  /// No description provided for @chatNoActiveModel.
  ///
  /// In en, this message translates to:
  /// **'Offline. No inference core is loaded for the story.'**
  String get chatNoActiveModel;

  /// No description provided for @whisperSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Whisper Instruction'**
  String get whisperSheetTitle;

  /// No description provided for @whisperSheetDescription.
  ///
  /// In en, this message translates to:
  /// **'Influence the character\'s next turn from behind the scenes without breaking the story text.'**
  String get whisperSheetDescription;

  /// No description provided for @whisperSheetExample.
  ///
  /// In en, this message translates to:
  /// **'Example: Reply more softly and hide concern under confidence.'**
  String get whisperSheetExample;

  /// No description provided for @applyWhisper.
  ///
  /// In en, this message translates to:
  /// **'Apply Whisper'**
  String get applyWhisper;

  /// No description provided for @chatBackButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get chatBackButtonTooltip;

  /// No description provided for @chatWhisperButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open whisper instruction'**
  String get chatWhisperButtonTooltip;

  /// No description provided for @chatMoreActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scene actions'**
  String get chatMoreActionsTooltip;

  /// No description provided for @chatSendButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Progress story'**
  String get chatSendButtonTooltip;

  /// No description provided for @chatStopButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop generation'**
  String get chatStopButtonTooltip;

  /// No description provided for @nextWhisperLabel.
  ///
  /// In en, this message translates to:
  /// **'Next whisper'**
  String get nextWhisperLabel;

  /// No description provided for @chatInputPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write the next turn...'**
  String get chatInputPlaceholder;

  /// No description provided for @chatModelPreparing.
  ///
  /// In en, this message translates to:
  /// **'Aura is arranging the scene...'**
  String get chatModelPreparing;

  /// No description provided for @chatRecoveringCore.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting thought process...'**
  String get chatRecoveringCore;

  /// No description provided for @chatConversationResetting.
  ///
  /// In en, this message translates to:
  /// **'Resetting the timeline...'**
  String get chatConversationResetting;

  /// No description provided for @chatGenerationTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Aura didn\'t respond in time. You can send again.'**
  String get chatGenerationTimedOut;

  /// No description provided for @chatRuntimeRecovered.
  ///
  /// In en, this message translates to:
  /// **'Reconnection successful. You may continue.'**
  String get chatRuntimeRecovered;

  /// No description provided for @chatRuntimeRecoveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Inference core disconnected. Please reactivate in Settings.'**
  String get chatRuntimeRecoveryFailed;

  /// No description provided for @assistantLabel.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get assistantLabel;

  /// No description provided for @noActiveModel.
  ///
  /// In en, this message translates to:
  /// **'No active core'**
  String get noActiveModel;

  /// No description provided for @roleplayReadyLabel.
  ///
  /// In en, this message translates to:
  /// **'Ready to enter the story'**
  String get roleplayReadyLabel;

  /// No description provided for @newConversationButton.
  ///
  /// In en, this message translates to:
  /// **'New Scene'**
  String get newConversationButton;

  /// No description provided for @clearHistoryButton.
  ///
  /// In en, this message translates to:
  /// **'Reset Scene'**
  String get clearHistoryButton;

  /// No description provided for @clearHistoryConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all session history?'**
  String get clearHistoryConfirmTitle;

  /// No description provided for @clearHistoryConfirmDescription.
  ///
  /// In en, this message translates to:
  /// **'This deletes every saved session for {characterName} and the old branches cannot be restored.'**
  String clearHistoryConfirmDescription(Object characterName);

  /// No description provided for @clearHistoryConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get clearHistoryConfirmAction;

  /// No description provided for @historyClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'Scene progress has been reset for this character.'**
  String get historyClearedMessage;

  /// No description provided for @sessionHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Session History'**
  String get sessionHistoryTitle;

  /// No description provided for @sessionHistoryShortLabel.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get sessionHistoryShortLabel;

  /// No description provided for @sessionHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Jump back into an older branch for {characterName} and keep that storyline going.'**
  String sessionHistoryDescription(Object characterName);

  /// No description provided for @sessionHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved sessions for this role card yet.'**
  String get sessionHistoryEmpty;

  /// No description provided for @sessionCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Session'**
  String get sessionCurrentLabel;

  /// No description provided for @sessionMessageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} messages'**
  String sessionMessageCount(Object count);

  /// No description provided for @sessionBranchEmpty.
  ///
  /// In en, this message translates to:
  /// **'This branch has not started yet.'**
  String get sessionBranchEmpty;

  /// No description provided for @importingCardText.
  ///
  /// In en, this message translates to:
  /// **'Parsing character card...'**
  String get importingCardText;

  /// No description provided for @importCardEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Choose a Tavern PNG or JSON card to preview it.'**
  String get importCardEmptyState;

  /// No description provided for @chooseCardButton.
  ///
  /// In en, this message translates to:
  /// **'Choose Image or File'**
  String get chooseCardButton;

  /// No description provided for @confirmImportButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Import'**
  String get confirmImportButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @editCharacterTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Character'**
  String get editCharacterTitle;

  /// No description provided for @editCharacterButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit character'**
  String get editCharacterButtonTooltip;

  /// No description provided for @characterWorkbenchTitle.
  ///
  /// In en, this message translates to:
  /// **'Character Workbench'**
  String get characterWorkbenchTitle;

  /// No description provided for @characterWorkbenchDescription.
  ///
  /// In en, this message translates to:
  /// **'Tune the card body, portrait, and worldbook entries here. All changes are saved into the local library.'**
  String get characterWorkbenchDescription;

  /// No description provided for @characterPortraitImportedHint.
  ///
  /// In en, this message translates to:
  /// **'This role card already includes its original portrait art.'**
  String get characterPortraitImportedHint;

  /// No description provided for @characterPortraitAutoImportHint.
  ///
  /// In en, this message translates to:
  /// **'If you import a Tavern PNG card, Aura carries the art over automatically. The built-in cinematic cover is only used when no image exists.'**
  String get characterPortraitAutoImportHint;

  /// No description provided for @characterCoreFieldsTitle.
  ///
  /// In en, this message translates to:
  /// **'Core Card Fields'**
  String get characterCoreFieldsTitle;

  /// No description provided for @characterCoreFieldsDescription.
  ///
  /// In en, this message translates to:
  /// **'These fields define the role summary, scene setup, and opening momentum.'**
  String get characterCoreFieldsDescription;

  /// No description provided for @characterNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get characterNameLabel;

  /// No description provided for @characterDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get characterDescriptionLabel;

  /// No description provided for @characterPersonalityLabel.
  ///
  /// In en, this message translates to:
  /// **'Personality'**
  String get characterPersonalityLabel;

  /// No description provided for @characterScenarioLabel.
  ///
  /// In en, this message translates to:
  /// **'Scenario'**
  String get characterScenarioLabel;

  /// No description provided for @characterFirstMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'First Message'**
  String get characterFirstMessageLabel;

  /// No description provided for @characterExamplesLabel.
  ///
  /// In en, this message translates to:
  /// **'Example Dialogues'**
  String get characterExamplesLabel;

  /// No description provided for @characterAlternateGreetingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Alternate Greetings'**
  String get characterAlternateGreetingsLabel;

  /// No description provided for @characterCreatorNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Creator Notes'**
  String get characterCreatorNotesLabel;

  /// No description provided for @characterMainPromptLabel.
  ///
  /// In en, this message translates to:
  /// **'Main Prompt Override'**
  String get characterMainPromptLabel;

  /// No description provided for @characterPostHistoryInstructionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Post-History Instructions'**
  String get characterPostHistoryInstructionsLabel;

  /// No description provided for @characterAdvancedFieldsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tavern Advanced Fields'**
  String get characterAdvancedFieldsTitle;

  /// No description provided for @characterAdvancedFieldsDescription.
  ///
  /// In en, this message translates to:
  /// **'These fields feed directly into alternate greetings, prompt overrides, and next-turn reply constraints.'**
  String get characterAdvancedFieldsDescription;

  /// No description provided for @blankLineSeparatedHint.
  ///
  /// In en, this message translates to:
  /// **'Separate each block with a blank line.'**
  String get blankLineSeparatedHint;

  /// No description provided for @characterLorebookTitle.
  ///
  /// In en, this message translates to:
  /// **'Lorebook / Worldbook'**
  String get characterLorebookTitle;

  /// No description provided for @characterLorebookDescription.
  ///
  /// In en, this message translates to:
  /// **'Import standalone worldbooks or manage entries directly here. Imported worldbooks merge by default instead of overwriting existing lore.'**
  String get characterLorebookDescription;

  /// No description provided for @lorebookAttachedLabel.
  ///
  /// In en, this message translates to:
  /// **'Attached lorebook ({count} entries)'**
  String lorebookAttachedLabel(Object count);

  /// No description provided for @lorebookMissingLabel.
  ///
  /// In en, this message translates to:
  /// **'No lorebook attached yet.'**
  String get lorebookMissingLabel;

  /// No description provided for @importLorebookButton.
  ///
  /// In en, this message translates to:
  /// **'Import Lorebook'**
  String get importLorebookButton;

  /// No description provided for @importMergeWorldbookButton.
  ///
  /// In en, this message translates to:
  /// **'Import & Merge Worldbook'**
  String get importMergeWorldbookButton;

  /// No description provided for @addLorebookEntryButton.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addLorebookEntryButton;

  /// No description provided for @replaceLorebookButton.
  ///
  /// In en, this message translates to:
  /// **'Replace Lorebook'**
  String get replaceLorebookButton;

  /// No description provided for @removeLorebookButton.
  ///
  /// In en, this message translates to:
  /// **'Remove Lorebook'**
  String get removeLorebookButton;

  /// No description provided for @lorebookMetaPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Worldbook Name & Summary'**
  String get lorebookMetaPanelTitle;

  /// No description provided for @lorebookMetaSummaryFilled.
  ///
  /// In en, this message translates to:
  /// **'Name and summary are filled in.'**
  String get lorebookMetaSummaryFilled;

  /// No description provided for @lorebookMetaSummaryPartial.
  ///
  /// In en, this message translates to:
  /// **'One advanced field is filled in.'**
  String get lorebookMetaSummaryPartial;

  /// No description provided for @lorebookMetaSummaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Collapsed by default. Expand only if you need it.'**
  String get lorebookMetaSummaryEmpty;

  /// No description provided for @worldbookNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Worldbook Name'**
  String get worldbookNameLabel;

  /// No description provided for @worldbookDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Worldbook Description'**
  String get worldbookDescriptionLabel;

  /// No description provided for @lorebookEntriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Worldbook Entries'**
  String get lorebookEntriesTitle;

  /// No description provided for @lorebookEntriesCollapsedEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Collapsed by default so giant worldbooks do not flood the whole workbench.'**
  String get lorebookEntriesCollapsedEmptyHint;

  /// No description provided for @lorebookEntriesCollapsedHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal and manage every entry.'**
  String get lorebookEntriesCollapsedHint;

  /// No description provided for @lorebookEntryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String lorebookEntryCount(Object count);

  /// No description provided for @lorebookEntriesEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No entries yet. Import a Tavern worldbook or add keyword-triggered scene notes manually.'**
  String get lorebookEntriesEmptyState;

  /// No description provided for @lorebookEntryFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Entry {index}'**
  String lorebookEntryFallbackLabel(Object index);

  /// No description provided for @editEntryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntryTooltip;

  /// No description provided for @deleteEntryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get deleteEntryTooltip;

  /// No description provided for @secondaryKeywordsTag.
  ///
  /// In en, this message translates to:
  /// **'Secondary {keywords}'**
  String secondaryKeywordsTag(Object keywords);

  /// No description provided for @priorityTag.
  ///
  /// In en, this message translates to:
  /// **'Priority {value}'**
  String priorityTag(Object value);

  /// No description provided for @lorebookEntryEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Worldbook Entry'**
  String get lorebookEntryEditorTitle;

  /// No description provided for @lorebookEntryIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Entry ID'**
  String get lorebookEntryIdLabel;

  /// No description provided for @lorebookEntryPrimaryKeywordsLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary Keywords'**
  String get lorebookEntryPrimaryKeywordsLabel;

  /// No description provided for @lorebookEntryPrimaryKeywordsHelper.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated, for example: zhongli, contract, liyue'**
  String get lorebookEntryPrimaryKeywordsHelper;

  /// No description provided for @lorebookEntrySecondaryKeywordsLabel.
  ///
  /// In en, this message translates to:
  /// **'Secondary Keywords'**
  String get lorebookEntrySecondaryKeywordsLabel;

  /// No description provided for @lorebookEntrySecondaryKeywordsHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional, comma-separated.'**
  String get lorebookEntrySecondaryKeywordsHelper;

  /// No description provided for @lorebookEntryContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Entry Content'**
  String get lorebookEntryContentLabel;

  /// No description provided for @lorebookEntryCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get lorebookEntryCommentLabel;

  /// No description provided for @lorebookEntryPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get lorebookEntryPriorityLabel;

  /// No description provided for @lorebookEntryEnabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable Entry'**
  String get lorebookEntryEnabledLabel;

  /// No description provided for @lorebookEntrySelectiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Require Secondary Keywords'**
  String get lorebookEntrySelectiveLabel;

  /// No description provided for @lorebookEntryConstantLabel.
  ///
  /// In en, this message translates to:
  /// **'Always Inject'**
  String get lorebookEntryConstantLabel;

  /// No description provided for @lorebookEntryWholeWordLabel.
  ///
  /// In en, this message translates to:
  /// **'Whole Word Match'**
  String get lorebookEntryWholeWordLabel;

  /// No description provided for @lorebookEntryCaseSensitiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Case Sensitive'**
  String get lorebookEntryCaseSensitiveLabel;

  /// No description provided for @saveEntryButton.
  ///
  /// In en, this message translates to:
  /// **'Save Entry'**
  String get saveEntryButton;

  /// No description provided for @lorebookEntryValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please provide at least keywords and content.'**
  String get lorebookEntryValidationError;

  /// No description provided for @lorebookImportedMessage.
  ///
  /// In en, this message translates to:
  /// **'Lorebook attached ({count} entries).'**
  String lorebookImportedMessage(Object count);

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @savingButton.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingButton;

  /// No description provided for @importDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Tavern and SillyTavern cards import straight into the library. Standalone worldbooks can be attached to a role card in the next step.'**
  String get importDialogDescription;

  /// No description provided for @importPreviewRoleCardTag.
  ///
  /// In en, this message translates to:
  /// **'Story Card'**
  String get importPreviewRoleCardTag;

  /// No description provided for @embeddedWorldbookTag.
  ///
  /// In en, this message translates to:
  /// **'Embedded Worldbook'**
  String get embeddedWorldbookTag;

  /// No description provided for @createCharacterButton.
  ///
  /// In en, this message translates to:
  /// **'Create Character'**
  String get createCharacterButton;

  /// No description provided for @attachWorldbookButton.
  ///
  /// In en, this message translates to:
  /// **'Attach Worldbook'**
  String get attachWorldbookButton;

  /// No description provided for @importEmptyStateIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose an import source first: Photos are for Tavern PNG cards already saved to your gallery, while Files support Tavern or SillyTavern PNG cards, JSON cards, and standalone worldbooks. Cards with embedded worldbooks come in one step.'**
  String get importEmptyStateIntro;

  /// No description provided for @importEmptyStateDetails.
  ///
  /// In en, this message translates to:
  /// **'Aura will automatically preserve `character_book` world info, greetings, prompt overrides, and scene notes when the card includes them.'**
  String get importEmptyStateDetails;

  /// No description provided for @importCreateCharacterHint.
  ///
  /// In en, this message translates to:
  /// **'No existing role card yet? You can also create one from scratch here.'**
  String get importCreateCharacterHint;

  /// No description provided for @chooseAnotherCardButton.
  ///
  /// In en, this message translates to:
  /// **'Choose Another Image or File'**
  String get chooseAnotherCardButton;

  /// No description provided for @importSourceSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Import Source'**
  String get importSourceSheetTitle;

  /// No description provided for @importSourceSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photos are for Tavern PNG cards already saved to your gallery. Files support Tavern PNG and JSON cards.'**
  String get importSourceSheetSubtitle;

  /// No description provided for @importFromPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Import From Photos'**
  String get importFromPhotosTitle;

  /// No description provided for @importFromPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a Tavern PNG card that is already in your photo library.'**
  String get importFromPhotosSubtitle;

  /// No description provided for @importFromFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Import From Files'**
  String get importFromFilesTitle;

  /// No description provided for @importFromFilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a Tavern PNG card, JSON card, or standalone worldbook from Files.'**
  String get importFromFilesSubtitle;

  /// No description provided for @importWorldbookHint.
  ///
  /// In en, this message translates to:
  /// **'You can also choose a standalone worldbook JSON here. Aura will let you attach it to a role card in the next step.'**
  String get importWorldbookHint;

  /// No description provided for @importErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to import this file'**
  String get importErrorTitle;

  /// No description provided for @importFileLabel.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get importFileLabel;

  /// No description provided for @importCreatorLabel.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get importCreatorLabel;

  /// No description provided for @importNoDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'This card does not include a description.'**
  String get importNoDescriptionLabel;

  /// No description provided for @importNoFirstMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'This card does not include a first message.'**
  String get importNoFirstMessageLabel;

  /// No description provided for @importWorldbookErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'This file is a standalone worldbook. Aura can attach it directly to a role card from the import flow.'**
  String get importWorldbookErrorMessage;

  /// No description provided for @importUnsupportedFileMessage.
  ///
  /// In en, this message translates to:
  /// **'Only Tavern PNG and JSON character cards are supported here.'**
  String get importUnsupportedFileMessage;

  /// No description provided for @photoImportPngOnlyMessage.
  ///
  /// In en, this message translates to:
  /// **'Photo import currently supports Tavern PNG cards only.'**
  String get photoImportPngOnlyMessage;

  /// No description provided for @importInvalidCharacterFileMessage.
  ///
  /// In en, this message translates to:
  /// **'This file does not look like a supported character card.'**
  String get importInvalidCharacterFileMessage;

  /// No description provided for @importGenericErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Import failed. Please try another character card file.'**
  String get importGenericErrorMessage;

  /// No description provided for @importSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'{characterName} imported successfully.'**
  String importSuccessMessage(Object characterName);

  /// No description provided for @characterCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'{characterName} created successfully.'**
  String characterCreatedMessage(Object characterName);

  /// No description provided for @importOpenChatAction.
  ///
  /// In en, this message translates to:
  /// **'Open Scene'**
  String get importOpenChatAction;

  /// No description provided for @settingsButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get settingsButtonTooltip;

  /// No description provided for @editMessageActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit this message'**
  String get editMessageActionTitle;

  /// No description provided for @editMessageActionDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep the story and revise this turn only.'**
  String get editMessageActionDescription;

  /// No description provided for @deleteMessageActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this message'**
  String get deleteMessageActionTitle;

  /// No description provided for @deleteMessageActionDescription.
  ///
  /// In en, this message translates to:
  /// **'Remove this turn from the current session.'**
  String get deleteMessageActionDescription;

  /// No description provided for @editMessageDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get editMessageDialogTitle;

  /// No description provided for @editMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Rewrite the message'**
  String get editMessageHint;

  /// No description provided for @messageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Message updated.'**
  String get messageUpdated;

  /// No description provided for @deleteMessageDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get deleteMessageDialogTitle;

  /// No description provided for @deleteMessageDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'This message will be removed from the current session.'**
  String get deleteMessageDialogDescription;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @messageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted.'**
  String get messageDeleted;

  /// No description provided for @continueSceneButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Continue the current scene'**
  String get continueSceneButtonTooltip;

  /// No description provided for @continueScenePrompt.
  ///
  /// In en, this message translates to:
  /// **'Continue the current scene naturally. Advance the tension, clues, or emotions without resetting the relationship or breaking character.'**
  String get continueScenePrompt;

  /// No description provided for @storyCoreDownloadPrompt.
  ///
  /// In en, this message translates to:
  /// **'Download a story core before entering the scene.'**
  String get storyCoreDownloadPrompt;

  /// No description provided for @storyCoreChooseButton.
  ///
  /// In en, this message translates to:
  /// **'Choose Story Core'**
  String get storyCoreChooseButton;

  /// No description provided for @storyCoreDownloadStatus.
  ///
  /// In en, this message translates to:
  /// **'Choose a story core'**
  String get storyCoreDownloadStatus;

  /// No description provided for @firstRunModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your first story core'**
  String get firstRunModelTitle;

  /// No description provided for @firstRunModelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Aura needs one local story core before the first scene can begin. E2B starts faster. E4B gives you stronger quality, and Aura will return to your scene as soon as the download finishes.'**
  String get firstRunModelSubtitle;

  /// No description provided for @firstRunModelRecommendedBadge.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get firstRunModelRecommendedBadge;

  /// No description provided for @firstRunModelQualityBadge.
  ///
  /// In en, this message translates to:
  /// **'Higher quality'**
  String get firstRunModelQualityBadge;

  /// No description provided for @firstRunE2bHeadline.
  ///
  /// In en, this message translates to:
  /// **'Faster first start'**
  String get firstRunE2bHeadline;

  /// No description provided for @firstRunE2bSummary.
  ///
  /// In en, this message translates to:
  /// **'Best for a first install. Smaller download, quicker setup, and smoother story entry.'**
  String get firstRunE2bSummary;

  /// No description provided for @firstRunE4bHeadline.
  ///
  /// In en, this message translates to:
  /// **'Stronger scene detail'**
  String get firstRunE4bHeadline;

  /// No description provided for @firstRunE4bSummary.
  ///
  /// In en, this message translates to:
  /// **'Bigger download, but stronger writing quality, richer detail, and steadier scene control.'**
  String get firstRunE4bSummary;

  /// No description provided for @modelDownloadPreparingButton.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get modelDownloadPreparingButton;

  /// No description provided for @modelSetupRamHint.
  ///
  /// In en, this message translates to:
  /// **'Recommended RAM {memory}'**
  String modelSetupRamHint(Object memory);

  /// No description provided for @modelSetupDownloadProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {received} / {total}'**
  String modelSetupDownloadProgress(Object received, Object total);

  /// No description provided for @modelErrorNoSpace.
  ///
  /// In en, this message translates to:
  /// **'Not enough storage space. Free up some space and try again.'**
  String get modelErrorNoSpace;

  /// No description provided for @modelErrorCorrupt.
  ///
  /// In en, this message translates to:
  /// **'The downloaded file was incomplete. Please try again.'**
  String get modelErrorCorrupt;

  /// No description provided for @modelErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Download interrupted. Check your connection and try again.'**
  String get modelErrorNetwork;

  /// No description provided for @modelErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get modelErrorGeneric;

  /// No description provided for @modelSetupE2bSpeedChip.
  ///
  /// In en, this message translates to:
  /// **'Fast inference'**
  String get modelSetupE2bSpeedChip;

  /// No description provided for @modelSetupE4bQualityChip.
  ///
  /// In en, this message translates to:
  /// **'Richer vocabulary, longer scenes'**
  String get modelSetupE4bQualityChip;

  /// No description provided for @splashInitializingEngine.
  ///
  /// In en, this message translates to:
  /// **'Initializing Engine'**
  String get splashInitializingEngine;

  /// No description provided for @splashRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get splashRetryButton;

  /// No description provided for @splashPreparingRuntime.
  ///
  /// In en, this message translates to:
  /// **'Preparing runtime...'**
  String get splashPreparingRuntime;

  /// No description provided for @splashLoadingCore.
  ///
  /// In en, this message translates to:
  /// **'Loading story core...'**
  String get splashLoadingCore;

  /// No description provided for @splashGoToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get splashGoToSettings;

  /// No description provided for @splashDownloadCore.
  ///
  /// In en, this message translates to:
  /// **'Download a Core'**
  String get splashDownloadCore;

  /// No description provided for @splashTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get splashTryAgain;

  /// No description provided for @importEmbeddedWorldbookCount.
  ///
  /// In en, this message translates to:
  /// **'Embedded Worldbook {count}'**
  String importEmbeddedWorldbookCount(Object count);

  /// No description provided for @importAltGreetingsCount.
  ///
  /// In en, this message translates to:
  /// **'Alt Greetings {count}'**
  String importAltGreetingsCount(Object count);

  /// No description provided for @importCardMainPromptTag.
  ///
  /// In en, this message translates to:
  /// **'Card Main Prompt'**
  String get importCardMainPromptTag;

  /// No description provided for @importPostHistoryNoteTag.
  ///
  /// In en, this message translates to:
  /// **'Post-History Note'**
  String get importPostHistoryNoteTag;

  /// No description provided for @importPreservedFieldsTitle.
  ///
  /// In en, this message translates to:
  /// **'Imported As-Is'**
  String get importPreservedFieldsTitle;

  /// No description provided for @importPreservedFieldsContent.
  ///
  /// In en, this message translates to:
  /// **'Opening message / alternate greetings / scenario / persona / embedded worldbook / main prompt override / post-history rules'**
  String get importPreservedFieldsContent;

  /// No description provided for @importNoPersonalityLabel.
  ///
  /// In en, this message translates to:
  /// **'This card does not include a dedicated personality field.'**
  String get importNoPersonalityLabel;

  /// No description provided for @importNoScenarioLabel.
  ///
  /// In en, this message translates to:
  /// **'This card does not include a scenario field.'**
  String get importNoScenarioLabel;

  /// No description provided for @importCreatorNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Creator Notes'**
  String get importCreatorNotesTitle;

  /// No description provided for @importAltGreetingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alternate Greetings'**
  String get importAltGreetingsTitle;

  /// No description provided for @importStandaloneWorldbookTitle.
  ///
  /// In en, this message translates to:
  /// **'Standalone Worldbook'**
  String get importStandaloneWorldbookTitle;

  /// No description provided for @importWorldbookEntriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String importWorldbookEntriesCount(Object count);

  /// No description provided for @importWorldbookHelperNew.
  ///
  /// In en, this message translates to:
  /// **'Aura recognized this file as a standalone worldbook. Pick a role card and attach it directly.'**
  String get importWorldbookHelperNew;

  /// No description provided for @importWorldbookHelperMerge.
  ///
  /// In en, this message translates to:
  /// **'Aura recognized this file as a standalone worldbook. It will merge with the role card lore instead of overwriting it.'**
  String get importWorldbookHelperMerge;

  /// No description provided for @importWorldbookAttachTo.
  ///
  /// In en, this message translates to:
  /// **'Attach To'**
  String get importWorldbookAttachTo;

  /// No description provided for @importWorldbookNoCharacters.
  ///
  /// In en, this message translates to:
  /// **'No role cards are available yet.'**
  String get importWorldbookNoCharacters;

  /// No description provided for @importWorldbookChooseCard.
  ///
  /// In en, this message translates to:
  /// **'Choose Role Card'**
  String get importWorldbookChooseCard;

  /// No description provided for @importWorldbookMergeResult.
  ///
  /// In en, this message translates to:
  /// **'Merge Result'**
  String get importWorldbookMergeResult;

  /// No description provided for @importWorldbookMergeDetails.
  ///
  /// In en, this message translates to:
  /// **'Current role has {existing} entries, this file has {incoming}, and the merged card will keep about {merged} entries.'**
  String importWorldbookMergeDetails(
      Object existing, Object incoming, Object merged);

  /// No description provided for @importWorldbookDescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get importWorldbookDescriptionTitle;

  /// No description provided for @importWorldbookEntryPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Worldbook Entry Preview'**
  String get importWorldbookEntryPreviewTitle;

  /// No description provided for @importWorldbookChooseCharacterError.
  ///
  /// In en, this message translates to:
  /// **'Choose a role card before attaching the worldbook.'**
  String get importWorldbookChooseCharacterError;

  /// No description provided for @importPngNoMetadataError.
  ///
  /// In en, this message translates to:
  /// **'This PNG does not contain character card metadata. If it came from Photos, try importing the original Tavern PNG from Files.'**
  String get importPngNoMetadataError;

  /// No description provided for @starterCharacterName.
  ///
  /// In en, this message translates to:
  /// **'New Character'**
  String get starterCharacterName;

  /// No description provided for @starterCharacterDescription.
  ///
  /// In en, this message translates to:
  /// **'Write the role, relationship, and dramatic hook for this character.'**
  String get starterCharacterDescription;

  /// No description provided for @starterCharacterPersonality.
  ///
  /// In en, this message translates to:
  /// **'Stay in character, keep the scene moving, and respond with concrete actions and emotions.'**
  String get starterCharacterPersonality;

  /// No description provided for @starterCharacterScenario.
  ///
  /// In en, this message translates to:
  /// **'Describe the opening scene, location, conflict, and the relationship with the player.'**
  String get starterCharacterScenario;

  /// No description provided for @starterCharacterFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'The footsteps outside are getting closer. Now that you are here, there is no easy way back.'**
  String get starterCharacterFirstMessage;

  /// No description provided for @starterCharacterAltGreeting.
  ///
  /// In en, this message translates to:
  /// **'You arrived sooner than I expected.'**
  String get starterCharacterAltGreeting;

  /// No description provided for @searchCharactersHint.
  ///
  /// In en, this message translates to:
  /// **'Search characters...'**
  String get searchCharactersHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No characters match your search.'**
  String get searchNoResults;

  /// No description provided for @emptyLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your story library is empty'**
  String get emptyLibraryTitle;

  /// No description provided for @emptyLibraryDescription.
  ///
  /// In en, this message translates to:
  /// **'Import a Tavern card or create one from scratch. Everything runs on-device — no API keys, no cloud, no cost.'**
  String get emptyLibraryDescription;

  /// No description provided for @deleteCharacterTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Character'**
  String get deleteCharacterTitle;

  /// No description provided for @deleteCharacterConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {characterName}? This cannot be undone.'**
  String deleteCharacterConfirm(Object characterName);

  /// No description provided for @characterDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'{characterName} has been deleted.'**
  String characterDeletedMessage(Object characterName);

  /// No description provided for @copyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get copyToClipboard;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @messageTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get messageTimeJustNow;

  /// No description provided for @messageTimeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String messageTimeMinutesAgo(Object count);

  /// No description provided for @rerollButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Regenerate response'**
  String get rerollButtonTooltip;

  /// No description provided for @characterDetailsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Character Details'**
  String get characterDetailsSheetTitle;

  /// No description provided for @errorGoToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get errorGoToSettings;

  /// No description provided for @errorRetryMessage.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get errorRetryMessage;

  /// No description provided for @coreReconnectedToast.
  ///
  /// In en, this message translates to:
  /// **'Core reconnected. You can send again.'**
  String get coreReconnectedToast;

  /// No description provided for @storyCoresTitle.
  ///
  /// In en, this message translates to:
  /// **'Story Cores'**
  String get storyCoresTitle;

  /// No description provided for @deleteModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Model'**
  String get deleteModelTitle;

  /// No description provided for @deleteModelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {modelName}? You can re-download it later.'**
  String deleteModelConfirm(Object modelName);

  /// No description provided for @modelDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'{modelName} has been deleted.'**
  String modelDeletedMessage(Object modelName);

  /// No description provided for @diskSpaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Disk'**
  String get diskSpaceLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
