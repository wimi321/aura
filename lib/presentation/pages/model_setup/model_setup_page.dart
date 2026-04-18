import 'package:aura_app/backend/models/default_assets.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:aura_core/aura_core.dart';

import '../../../application/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';

class ModelSetupPage extends StatelessWidget {
  const ModelSetupPage({super.key, this.returnTo});

  final String? returnTo;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final AppStateProvider appState = context.watch<AppStateProvider>();
    final ModelManifest? e2b = _manifestById(
      appState.availableModels,
      downloadableE2bModelManifest.id,
    );
    final ModelManifest? e4b = _manifestById(
      appState.availableModels,
      downloadableE4bModelManifest.id,
    );
    final bool canGoBack = (returnTo?.trim().isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (canGoBack)
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppTheme.textPrimary,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (canGoBack) const SizedBox(height: 20),
              Text(
                l10n?.firstRunModelTitle ?? 'Choose your first story core',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n?.firstRunModelSubtitle ??
                    'Aura needs one local story core before the first scene can begin. E2B starts faster. E4B gives you stronger quality.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.55,
                    ),
              ),
              if ((appState.errorMessage ?? '').isNotEmpty) ...<Widget>[
                const SizedBox(height: 20),
                _ErrorBanner(
                    message:
                        _localizedModelError(context, appState.errorMessage!)),
              ],
              const SizedBox(height: 28),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool useWideLayout = constraints.maxWidth >= 860;
                    final List<Widget> cards = <Widget>[
                      if (e2b != null)
                        _SetupModelCard(
                          manifest: e2b,
                          badgeLabel: l10n?.firstRunModelRecommendedBadge ??
                              'Recommended',
                          badgeColor: AppTheme.brandAura,
                          headline:
                              l10n?.firstRunE2bHeadline ?? 'Faster first start',
                          summary: l10n?.firstRunE2bSummary ??
                              'Best for a first install. Smaller download, quicker setup, and smooth story entry.',
                          qualityChip: l10n?.modelSetupE2bSpeedChip ??
                              'Fast inference',
                          onPressed: () => _activateOrDownload(
                            context,
                            appState,
                            e2b,
                          ),
                        ),
                      if (e4b != null)
                        _SetupModelCard(
                          manifest: e4b,
                          badgeLabel: l10n?.firstRunModelQualityBadge ??
                              'Higher quality',
                          badgeColor: AppTheme.brandCoral,
                          headline: l10n?.firstRunE4bHeadline ??
                              'Stronger scene detail',
                          summary: l10n?.firstRunE4bSummary ??
                              'Bigger download, but stronger writing quality, richer detail, and steadier scene control.',
                          qualityChip: l10n?.modelSetupE4bQualityChip ??
                              'Richer vocabulary, longer scenes',
                          onPressed: () => _activateOrDownload(
                            context,
                            appState,
                            e4b,
                          ),
                        ),
                    ];

                    if (useWideLayout) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          for (int index = 0;
                              index < cards.length;
                              index += 1) ...<Widget>[
                            Expanded(child: cards[index]),
                            if (index != cards.length - 1)
                              const SizedBox(width: 20),
                          ],
                        ],
                      );
                    }

                    return ListView.separated(
                      itemCount: cards.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 18),
                      itemBuilder: (BuildContext context, int index) =>
                          cards[index],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _activateOrDownload(
    BuildContext context,
    AppStateProvider appState,
    ModelManifest manifest,
  ) async {
    if (appState.isDownloading(manifest)) {
      return;
    }
    if (appState.isInstalled(manifest)) {
      await appState.switchModel(manifest);
    } else {
      await appState.downloadModel(manifest);
    }
    if (!context.mounted) {
      return;
    }
    if (appState.isActive(manifest) &&
        appState.modelState == AppModelState.ready) {
      context.go(_resolvedReturnLocation());
    }
  }

  String _resolvedReturnLocation() {
    final String trimmed = returnTo?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '/characters';
    }
    return trimmed;
  }

  ModelManifest? _manifestById(List<ModelManifest> models, String id) {
    for (final ModelManifest manifest in models) {
      if (manifest.id == id) {
        return manifest;
      }
    }
    return null;
  }
}

class _SetupModelCard extends StatefulWidget {
  const _SetupModelCard({
    required this.manifest,
    required this.badgeLabel,
    required this.badgeColor,
    required this.headline,
    required this.summary,
    required this.onPressed,
    this.qualityChip,
  });

  final ModelManifest manifest;
  final String badgeLabel;
  final Color badgeColor;
  final String headline;
  final String summary;
  final Future<void> Function() onPressed;
  final String? qualityChip;

  @override
  State<_SetupModelCard> createState() => _SetupModelCardState();
}

class _SetupModelCardState extends State<_SetupModelCard> {
  int _lastReceivedBytes = 0;
  DateTime _lastTimestamp = DateTime.now();
  double _speedBytesPerSecond = 0;

  void _updateSpeed(int receivedBytes) {
    final DateTime now = DateTime.now();
    final double elapsed =
        now.difference(_lastTimestamp).inMilliseconds / 1000.0;
    if (elapsed >= 0.5 && receivedBytes > _lastReceivedBytes) {
      final double speed =
          (receivedBytes - _lastReceivedBytes) / elapsed;
      setState(() {
        _speedBytesPerSecond = speed;
        _lastReceivedBytes = receivedBytes;
        _lastTimestamp = now;
      });
    } else if (_lastReceivedBytes == 0 && receivedBytes > 0) {
      _lastReceivedBytes = receivedBytes;
      _lastTimestamp = now;
    }
  }

  String _formatEta(int receivedBytes, int totalBytes) {
    if (_speedBytesPerSecond <= 0 || totalBytes <= receivedBytes) {
      return '';
    }
    final int remainingBytes = totalBytes - receivedBytes;
    final int remainingSeconds =
        (remainingBytes / _speedBytesPerSecond).ceil();
    if (remainingSeconds < 60) {
      return '<1 min';
    }
    return '~${(remainingSeconds / 60).ceil()} min';
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final AppStateProvider appState = context.watch<AppStateProvider>();
    final bool isInstalled = appState.isInstalled(widget.manifest);
    final bool isActive = appState.isActive(widget.manifest);
    final bool isDownloading = appState.isDownloading(widget.manifest);
    final bool anotherDownloadInProgress =
        appState.downloadingModelId != null &&
            appState.downloadingModelId != widget.manifest.id;
    final bool canTapPrimary = !isDownloading && !anotherDownloadInProgress;

    if (isDownloading) {
      _updateSpeed(appState.downloadReceivedBytes);
    } else if (_lastReceivedBytes > 0) {
      _lastReceivedBytes = 0;
      _speedBytesPerSecond = 0;
    }

    final int percent = appState.downloadTotalBytes > 0
        ? (appState.downloadReceivedBytes * 100 ~/ appState.downloadTotalBytes)
        : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isActive
              ? widget.badgeColor.withValues(alpha: 0.55)
              : AppTheme.borderSubtle,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: widget.badgeColor.withValues(alpha: 0.14),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _Badge(label: widget.badgeLabel, color: widget.badgeColor),
              const Spacer(),
              if (isInstalled && !isActive)
                _Badge(
                  label: l10n?.downloadedTag ?? 'Downloaded',
                  color: AppTheme.mist,
                ),
              if (isActive)
                _Badge(
                  label: l10n?.activeBadge ?? 'ACTIVE',
                  color: AppTheme.brandAura,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            widget.manifest.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.headline,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.55,
                ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _InfoChip(
                icon: Icons.download_rounded,
                label: _formatBytes(widget.manifest.sizeBytes),
              ),
              _InfoChip(
                icon: Icons.memory_rounded,
                label: _localizedRamHint(context, widget.manifest),
              ),
              if (widget.qualityChip != null)
                _InfoChip(
                  icon: Icons.auto_awesome_outlined,
                  label: widget.qualityChip!,
                ),
            ],
          ),
          if (isDownloading) ...<Widget>[
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: appState.downloadProgress,
                minHeight: 8,
                backgroundColor: AppTheme.bgElevated,
                color: widget.badgeColor,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.badgeColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _buildDownloadDetail(context, appState),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton(
                  onPressed: canTapPrimary ? widget.onPressed : null,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isActive ? AppTheme.bgElevated : widget.badgeColor,
                    foregroundColor:
                        isActive ? AppTheme.textMuted : AppTheme.ink,
                    disabledBackgroundColor: AppTheme.bgElevated,
                    disabledForegroundColor: AppTheme.textMuted,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    isDownloading
                        ? (l10n?.modelDownloadPreparingButton ??
                            'Downloading...')
                        : isActive
                            ? (l10n?.alreadyActiveButton ?? 'Already Active')
                            : isInstalled
                                ? (l10n?.activateEngineButton ??
                                    'Activate Core')
                                : (l10n?.downloadInstallButton ??
                                    'Download & Install'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (isDownloading) ...<Widget>[
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: appState.cancelModelDownload,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(88, 52),
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.borderStrong),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(l10n?.cancelButton ?? 'Cancel'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _buildDownloadDetail(
      BuildContext context, AppStateProvider appState) {
    final String received = _formatBytes(appState.downloadReceivedBytes);
    final String total = _formatBytes(appState.downloadTotalBytes);
    final StringBuffer buf = StringBuffer('$received / $total');
    if (_speedBytesPerSecond > 0) {
      buf.write(' · ${_formatBytes(_speedBytesPerSecond.round())}/s');
      final String eta = _formatEta(
          appState.downloadReceivedBytes, appState.downloadTotalBytes);
      if (eta.isNotEmpty) {
        buf.write(' · $eta');
      }
    }
    return buf.toString();
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.dangerSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.danger),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.warning_amber_rounded, color: AppTheme.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFFC5C5),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _localizedRamHint(BuildContext context, ModelManifest manifest) {
  final AppLocalizations? l10n = AppLocalizations.of(context);
  final String memory = '${manifest.recommendedMinRamGb ?? 0}GB+';
  return l10n?.modelSetupRamHint(memory) ?? 'Recommended RAM $memory';
}

String _localizedModelError(BuildContext context, String message) {
  final AppLocalizations? l10n = AppLocalizations.of(context);
  switch (message) {
    case 'Not enough storage space. Free up some space and try again.':
      return l10n?.modelErrorNoSpace ?? message;
    case 'The downloaded file was incomplete. Please try again.':
      return l10n?.modelErrorCorrupt ?? message;
    case 'Download interrupted. Check your connection and try again.':
      return l10n?.modelErrorNetwork ?? message;
    case 'Something went wrong. Please try again.':
      return l10n?.modelErrorGeneric ?? message;
  }
  return message;
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
