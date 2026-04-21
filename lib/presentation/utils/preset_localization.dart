import 'package:aura_app/l10n/generated/app_localizations.dart';
import 'package:aura_core/aura_core.dart';
import 'package:flutter/widgets.dart';

String localizedPresetName(BuildContext context, Preset preset) {
  final AppLocalizations? l10n = AppLocalizations.of(context);
  if (preset.id == 'default-roleplay') {
    return l10n?.defaultRoleplayPresetName ?? preset.name;
  }
  if (preset.name == 'Imported Preset') {
    return l10n?.importedPresetFallbackName ?? preset.name;
  }
  return preset.name;
}

String localizedPresetPromptTemplate(BuildContext context, Preset preset) {
  final AppLocalizations? l10n = AppLocalizations.of(context);
  if (preset.id == 'default-roleplay') {
    return l10n?.defaultRoleplayPresetPrompt ?? preset.systemPromptTemplate;
  }
  return preset.systemPromptTemplate;
}
