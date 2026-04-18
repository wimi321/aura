import 'dart:io';

import 'package:aura_app/l10n/generated/app_localizations.dart';
import 'package:aura_core/aura_core.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/app_state_provider.dart';
import '../../../backend/models/default_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../utils/preset_localization.dart';
import '../../widgets/preset_editor_dialog.dart';

class AdvancedSettingsPage extends StatelessWidget {
  const AdvancedSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      appBar: AppBar(
        title: Text(l10n?.settingsTitle ?? 'Engine Control Center',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Consumer<AppStateProvider>(
        builder: (BuildContext context, AppStateProvider appState, _) {
          final List<ModelManifest> models = appState.availableModels;
          final ModelManifest? activeModel = appState.activeModel;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              if (appState.errorMessage != null) ...[
                _buildSystemAlert(appState.errorMessage!),
                const SizedBox(height: 24),
              ],
              _buildSectionHeader(
                  context,
                  l10n?.languageSectionTitle ?? 'Language',
                  Icons.language_rounded),
              const SizedBox(height: 12),
              _LanguageCard(appState: appState),
              const SizedBox(height: 36),
              _buildSectionHeader(
                  context,
                  l10n?.promptPresetTitle ?? 'Prompt Preset',
                  Icons.psychology_alt_rounded),
              const SizedBox(height: 12),
              _PromptPresetCard(appState: appState),
              const SizedBox(height: 36),
              _buildSectionHeader(context,
                  l10n?.storyCoresTitle ?? 'Story Cores', Icons.memory_rounded),
              const SizedBox(height: 12),
              if (activeModel != null) ...[
                _ActiveCoreCard(manifest: activeModel, appState: appState),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.bgElevated,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        appState.needsModelDownload
                            ? (l10n?.storyCoreDownloadPrompt ??
                                'Download a story core to begin.')
                            : (l10n?.systemOfflineText ??
                                'System offline. Please activate a core.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      if (appState.needsModelDownload) ...<Widget>[
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: () => context.push('/model-setup'),
                          child: Text(
                            l10n?.storyCoreChooseButton ?? 'Choose story core',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              for (final ModelManifest manifest in models)
                if (manifest.id != activeModel?.id) ...[
                  _ModelModuleCard(
                      manifest: manifest,
                      activeModel: activeModel,
                      appState: appState),
                  const SizedBox(height: 16),
                ],
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.statusWarning),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                letterSpacing: 0.3,
              ),
        ),
      ],
    );
  }

  Widget _buildSystemAlert(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.dangerSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.danger),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.danger),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message,
                  style:
                      const TextStyle(color: Color(0xFFFFC5C5), height: 1.4))),
        ],
      ),
    );
  }
}

class _PromptPresetCard extends StatelessWidget {
  const _PromptPresetCard({required this.appState});

  final AppStateProvider appState;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DropdownButtonFormField<String>(
            initialValue: appState.activePresetId,
            decoration: InputDecoration(
              labelText: l10n?.promptPresetActiveLabel ?? 'Current Preset',
            ),
            items: appState.availablePresets
                .map(
                  (Preset preset) => DropdownMenuItem<String>(
                    value: preset.id,
                    child: Text(localizedPresetName(context, preset)),
                  ),
                )
                .toList(growable: false),
            onChanged: (String? value) {
              if (value != null) {
                appState.setActivePresetId(value);
              }
            },
          ),
          const SizedBox(height: 12),
          Text(
            localizedPresetPromptTemplate(context, appState.activePreset),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) =>
                      PresetEditorDialog(preset: appState.activePreset),
                );
              },
              child: Text(
                l10n?.editActivePresetButton ?? 'Edit Current Preset',
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.file_open_rounded, size: 18),
              onPressed: () async {
                final XFile? picked = await openFile(
                  acceptedTypeGroups: const <XTypeGroup>[
                    XTypeGroup(
                      label: 'JSON',
                      extensions: <String>['json'],
                      uniformTypeIdentifiers: <String>[
                        'public.json',
                      ],
                    ),
                  ],
                );
                if (picked == null) {
                  return;
                }
                try {
                  final Preset imported =
                      await appState.importPresetFile(File(picked.path));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(imported.name),
                      ),
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error.toString()),
                      ),
                    );
                  }
                }
              },
              label: Text(
                l10n?.importPresetJsonButton ?? 'Import Directive File',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveCoreCard extends StatelessWidget {
  const _ActiveCoreCard({required this.manifest, required this.appState});

  final ModelManifest manifest;
  final AppStateProvider appState;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B6A51), Color(0xFF17473B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: AppTheme.brandAura.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(l10n?.activeBadge ?? 'ACTIVE',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: AppTheme.textPrimary)),
              ),
              const Spacer(),
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.brandAura, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          Text(manifest.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text(_localizedCoreSummary(context, manifest),
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.memory_rounded,
                  color: AppTheme.brandAura, size: 16),
              const SizedBox(width: 8),
              Text(
                _localizedSettingsStateLabel(
                    context, appState.modelState, l10n),
                style: const TextStyle(
                    color: AppTheme.brandAura,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _ModelModuleCard extends StatelessWidget {
  const _ModelModuleCard(
      {required this.manifest,
      required this.activeModel,
      required this.appState});

  final ModelManifest manifest;
  final ModelManifest? activeModel;
  final AppStateProvider appState;

  Future<void> _confirmDelete(
    BuildContext context,
    AppStateProvider appState,
    ModelManifest model,
  ) async {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.bgElevated,
          title: Text(l10n?.deleteModelTitle ?? 'Delete Model'),
          content: Text(
            l10n?.deleteModelConfirm(model.name) ??
                'Delete ${model.name}? You can re-download it later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n?.cancelButton ?? 'Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.statusDanger,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n?.deleteButton ?? 'Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final bool deleted = await appState.deleteInstalledModel(model);
    if (deleted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.modelDeletedMessage(model.name) ??
                '${model.name} has been deleted.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final bool installed = appState.isInstalled(manifest);
    final bool downloading = appState.isDownloading(manifest);
    final bool isActive = activeModel?.id == manifest.id;
    final String? badgeLabel = _localizedModelBadge(context, manifest);
    final Color? badgeColor = _localizedModelBadgeColor(manifest);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.bgCard : AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isActive
                ? AppTheme.brandAura.withValues(alpha: 0.5)
                : AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(manifest.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (installed && !isActive)
                IconButton(
                  onPressed: () => _confirmDelete(context, appState, manifest),
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 20, color: AppTheme.statusDanger),
                  tooltip: l10n?.deleteModelTitle ?? 'Delete Model',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 8),
              if (badgeLabel != null)
                _Tag(label: badgeLabel, color: badgeColor ?? AppTheme.brandAura)
              else if (installed && !isActive)
                _Tag(
                    label: l10n?.downloadedTag ?? 'Downloaded',
                    color: AppTheme.mist)
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _localizedCoreMarketingSummary(context, manifest),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _localizedCoreSummary(context, manifest),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppTheme.textMuted),
                ),
              ),
              if (installed)
                Text(
                  '${l10n?.diskSpaceLabel ?? 'Disk'}: ${_formatBytes(manifest.sizeBytes)}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppTheme.textMuted),
                ),
            ],
          ),
          if (downloading) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: appState.downloadProgress,
                      backgroundColor: Colors.black26,
                      color: AppTheme.statusWarning,
                      minHeight: 6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _localizedDownloadSummary(
                context,
                appState.downloadReceivedBytes,
                appState.downloadTotalBytes,
              ),
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            )
          ] else ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: isActive
                      ? AppTheme.bgCard
                      : (installed
                          ? AppTheme.bgCard
                          : AppTheme.brandAura.withValues(alpha: 0.18)),
                  foregroundColor: isActive
                      ? AppTheme.textMuted
                      : (installed ? AppTheme.textPrimary : AppTheme.brandAura),
                  elevation: 0,
                  side: isActive
                      ? const BorderSide(color: AppTheme.borderSubtle)
                      : BorderSide.none,
                ),
                onPressed: downloading
                    ? null
                    : isActive
                        ? null
                        : installed
                            ? () => appState.switchModel(manifest)
                            : () => appState.downloadModel(manifest),
                child: Text(
                  isActive
                      ? (l10n?.alreadyActiveButton ?? 'Already Active')
                      : installed
                          ? (l10n?.activateEngineButton ?? 'Activate Engine')
                          : (l10n?.downloadInstallButton ??
                              'Download & Install'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            )
          ]
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.appState});

  final AppStateProvider appState;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String value = appState.localeCode ?? 'system';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.interfaceReplyLanguageTitle ?? 'Interface & Reply Language',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.interfaceReplyLanguageDescription ??
                'UI follows the system by default. You can pin a language here, and chat replies will follow that preference unless the user explicitly switches.',
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: value,
            decoration: InputDecoration(
              labelText: l10n?.languageFieldLabel ?? 'Language',
            ),
            items: _localizedLanguageLabels(context)
                .entries
                .map(
                  (MapEntry<String, String> entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(growable: false),
            onChanged: (String? next) {
              appState.setLocaleCode(
                  next == null || next == 'system' ? null : next);
            },
          ),
        ],
      ),
    );
  }
}

String _localizedSettingsStateLabel(
  BuildContext context,
  AppModelState state,
  AppLocalizations? l10n,
) {
  final String code =
      Localizations.localeOf(context).languageCode.toLowerCase();
  final String label = switch (state) {
    AppModelState.idle => l10n?.modelStateIdle ?? 'Idle',
    AppModelState.initializing ||
    AppModelState.loading ||
    AppModelState.switching =>
      l10n?.loadingModel ?? 'Loading',
    AppModelState.ready => l10n?.readyText ?? 'Ready',
    AppModelState.error => l10n?.modelStateError ?? 'Error',
  };
  return l10n?.statusLabel(label) ??
      (code == 'zh' ? '状态 $label' : 'Status $label');
}

String _localizedCoreSummary(BuildContext context, ModelManifest manifest) {
  final String code =
      Localizations.localeOf(context).languageCode.toLowerCase();
  final String size = _formatBytes(manifest.sizeBytes);
  final String memory = '${manifest.recommendedMinRamGb}GB+';
  if (code == 'zh') {
    return '$size · 建议内存 $memory';
  }
  if (code == 'ja') {
    return '$size · 推奨メモリ $memory';
  }
  if (code == 'ko') {
    return '$size · 권장 메모리 $memory';
  }
  return '$size · Recommended RAM $memory';
}

String _localizedCoreMarketingSummary(
  BuildContext context,
  ModelManifest manifest,
) {
  final AppLocalizations? l10n = AppLocalizations.of(context);
  if (manifest.id == downloadableE2bModelManifest.id) {
    return l10n?.firstRunE2bSummary ??
        'Best for a first install. Smaller download and faster setup.';
  }
  if (manifest.id == downloadableE4bModelManifest.id) {
    return l10n?.firstRunE4bSummary ??
        'Bigger download, but stronger quality and steadier scene detail.';
  }
  return _localizedCoreSummary(context, manifest);
}

String? _localizedModelBadge(BuildContext context, ModelManifest manifest) {
  final AppLocalizations? l10n = AppLocalizations.of(context);
  if (manifest.id == downloadableE2bModelManifest.id) {
    return l10n?.firstRunModelRecommendedBadge ?? 'Recommended';
  }
  if (manifest.id == downloadableE4bModelManifest.id) {
    return l10n?.firstRunModelQualityBadge ?? 'Higher quality';
  }
  return null;
}

Color? _localizedModelBadgeColor(ModelManifest manifest) {
  if (manifest.id == downloadableE2bModelManifest.id) {
    return AppTheme.brandAura;
  }
  if (manifest.id == downloadableE4bModelManifest.id) {
    return AppTheme.brandCoral;
  }
  return null;
}

String _localizedDownloadSummary(
  BuildContext context,
  int receivedBytes,
  int totalBytes,
) {
  final String code =
      Localizations.localeOf(context).languageCode.toLowerCase();
  final String received = _formatBytes(receivedBytes);
  final String total = _formatBytes(totalBytes);
  if (code == 'zh') {
    return '已下载 $received / $total';
  }
  if (code == 'ja') {
    return 'ダウンロード済み $received / $total';
  }
  if (code == 'ko') {
    return '다운로드됨 $received / $total';
  }
  return 'Downloaded $received / $total';
}

Map<String, String> _localizedLanguageLabels(BuildContext context) {
  final String code =
      Localizations.localeOf(context).languageCode.toLowerCase();
  final String followSystem = switch (code) {
    'zh' => '跟随系统',
    'ja' => 'システムに従う',
    'ko' => '시스템 설정 따르기',
    _ => 'Follow System',
  };
  return <String, String>{
    'system': followSystem,
    'en': 'English',
    'zh': '简体中文',
    'ja': '日本語',
    'ko': '한국어',
  };
}

String _formatBytes(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }

  const List<String> units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  double value = bytes.toDouble();
  int unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex += 1;
  }
  final String precision =
      unitIndex >= 3 ? value.toStringAsFixed(2) : value.toStringAsFixed(0);
  return '$precision ${units[unitIndex]}';
}
