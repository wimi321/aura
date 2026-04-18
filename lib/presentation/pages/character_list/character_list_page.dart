import 'package:aura_core/aura_core.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../application/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/character_editor_dialog.dart';
import '../../widgets/character_cover_art.dart';
import '../../widgets/import_preview_dialog.dart';
import '../../widgets/session_history_sheet.dart';

class CharacterListPage extends StatelessWidget {
  const CharacterListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final AppStateProvider appState = context.watch<AppStateProvider>();
    final ModelManifest? activeModel = appState.activeModel;
    final List<CharacterCard> characters = appState.availableCharacters;
    final bool needsModelDownload = appState.needsModelDownload;

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          children: [
            _buildHeader(context),
            const SizedBox(height: 36),
            _StatusPill(appState: appState),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.characters ?? 'Story Library',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                FilledButton.tonal(
                  onPressed: () => _showImportDialog(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.bgElevated,
                    foregroundColor: AppTheme.textPrimary,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle_outline, size: 16),
                      const SizedBox(width: 8),
                      Text(l10n?.importCharacter ?? 'Import'),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            for (final CharacterCard character in characters) ...[
              _PremiumCharacterCard(character: character),
              const SizedBox(height: 24),
            ],
            const SizedBox(height: 48),
            _buildModelCenterCard(
              context,
              activeModel,
              needsModelDownload: needsModelDownload,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImportDialog(BuildContext context) async {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final CharacterCard? selectedCharacter = await showDialog<CharacterCard>(
      context: context,
      builder: (_) => const ImportPreviewDialog(),
    );
    if (!context.mounted || selectedCharacter == null) {
      return;
    }
    final bool isUserCreated =
        selectedCharacter.extensions['user_created'] == true &&
            selectedCharacter.extensions['imported'] != true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isUserCreated
              ? (l10n?.characterCreatedMessage(selectedCharacter.name) ??
                  '${selectedCharacter.name} created successfully.')
              : (l10n?.importSuccessMessage(selectedCharacter.name) ??
                  '${selectedCharacter.name} imported successfully.'),
        ),
        action: SnackBarAction(
          label: l10n?.importOpenChatAction ?? 'Chat Now',
          onPressed: () => context.push('/chat/${selectedCharacter.id}'),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aura', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 4),
            Text(
              l10n?.appTagline ?? 'Local intelligence, private by design.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderStrong),
          ),
          child: IconButton(
            onPressed: () => context.push('/settings'),
            tooltip: l10n?.settingsButtonTooltip ?? 'Open settings',
            icon: const Icon(Icons.tune_rounded, color: AppTheme.textPrimary),
          ),
        )
      ],
    );
  }

  Widget _buildModelCenterCard(
    BuildContext context,
    ModelManifest? activeModel, {
    required bool needsModelDownload,
  }) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () =>
          context.push(needsModelDownload ? '/model-setup' : '/settings'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgElevated,
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  const Icon(Icons.memory_rounded, color: AppTheme.brandAura),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.engineStatusTitle ?? 'Engine Control Center',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeModel != null
                        ? (l10n?.engineRunning(activeModel.name) ??
                            'Running ${activeModel.name}')
                        : needsModelDownload
                            ? (l10n?.storyCoreDownloadPrompt ??
                                'Download a story core to begin.')
                            : (l10n?.noActiveModel ?? 'No active model'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.appState});

  final AppStateProvider appState;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    if (appState.needsModelDownload) {
      final String label =
          l10n?.storyCoreDownloadStatus ?? 'Choose a story core';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderStrong),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.statusWarning,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.statusWarning.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n?.statusLabel(label) ?? 'Status $label',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.statusWarning,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      );
    }
    final bool isReady = appState.modelState == AppModelState.ready;
    final bool isLoading = appState.modelState == AppModelState.loading ||
        appState.modelState == AppModelState.initializing;
    final Color color = isReady
        ? AppTheme.statusSuccess
        : (isLoading ? AppTheme.statusWarning : AppTheme.textMuted);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 2),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _localizedModelStateChip(context, appState.modelState, l10n),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

String _localizedModelStateChip(
  BuildContext context,
  AppModelState state,
  AppLocalizations? l10n,
) {
  final String languageCode =
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
      (languageCode == 'zh' ? '状态 $label' : 'Status $label');
}

class _PremiumCharacterCard extends StatelessWidget {
  const _PremiumCharacterCard({required this.character});

  final CharacterCard character;

  String _sceneHookExcerpt() {
    final String raw =
        (character.preferredOpeningMessage ?? character.description).trim();
    if (raw.isEmpty) {
      return '';
    }
    final String firstSentence = _firstSentence(raw);
    if (firstSentence.length <= 72) {
      return firstSentence;
    }
    return '${firstSentence.substring(0, 72).trimRight()}...';
  }

  String _firstSentence(String input) {
    final String trimmed = input.trim();
    for (int index = 0; index < trimmed.length; index += 1) {
      final String char = trimmed[index];
      if ('.!?。！？'.contains(char)) {
        return trimmed.substring(0, index + 1).trim();
      }
    }
    return trimmed;
  }

  Future<void> _showSessionHistory(BuildContext context) async {
    final AppStateProvider appState = context.read<AppStateProvider>();
    final List<ChatSession> sessions =
        await appState.engine.listSessionsForCharacter(character.id);
    if (!context.mounted) {
      return;
    }
    final String? sessionId = await showSessionHistorySheet(
      context,
      characterName: character.name,
      sessions: sessions,
      currentSessionId: sessions.isEmpty ? null : sessions.first.id,
    );
    if (!context.mounted || sessionId == null) {
      return;
    }
    final Uri target = Uri(
      path: '/chat/${character.id}',
      queryParameters: <String, String>{'session': sessionId},
    );
    context.push(target.toString());
  }

  Future<void> _confirmAndClearHistory(BuildContext context) async {
    final AppStateProvider appState = context.read<AppStateProvider>();
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final bool shouldClear = await showClearHistoryConfirmation(
      context,
      characterName: character.name,
    );
    if (!context.mounted || !shouldClear) {
      return;
    }
    await appState.clearConversationHistory(character.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.historyClearedMessage ?? 'Conversation history cleared.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppStateProvider appState = context.watch<AppStateProvider>();
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final bool needsModelDownload = appState.needsModelDownload;
    final bool isConversationBusy =
        appState.isConversationActionInProgressFor(character.id);
    final bool isChatReady = appState.activeModel != null &&
        appState.modelState == AppModelState.ready &&
        !appState.isRecoveringModel &&
        !isConversationBusy;

    final String? availabilityLabel = needsModelDownload
        ? (l10n?.storyCoreDownloadPrompt ?? 'Download a story core to begin.')
        : appState.isRecoveringModel
            ? (l10n?.chatRecoveringCore ?? 'Recovering the local core...')
            : isConversationBusy
                ? (l10n?.chatConversationResetting ??
                    'Resetting this conversation...')
                : isChatReady
                    ? null
                    : (l10n?.chatModelPreparing ??
                        'Aura is strictly preparing the local core.');

    final Color availabilityColor = isChatReady
        ? AppTheme.brandAura
        : needsModelDownload
            ? AppTheme.statusWarning
            : appState.isRecoveringModel || isConversationBusy
                ? AppTheme.statusWarning
                : AppTheme.textMuted;
    final String sceneHookExcerpt = _sceneHookExcerpt();

    return Container(
      key: ValueKey<String>('character-card-${character.id}'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(20), // Tighter borders for premium feel
        color: AppTheme.bgCard,
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: isChatReady
                ? () => context.push('/chat/${character.id}')
                : needsModelDownload
                    ? () => context.push(
                          Uri(
                            path: '/model-setup',
                            queryParameters: <String, String>{
                              'returnTo': '/chat/${character.id}',
                            },
                          ).toString(),
                        )
                    : null,
            child: Stack(
              children: [
                CharacterCoverArt(
                  character: character,
                  height: 440, // Epic, full-bleed poster ratio
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.85),
                          AppTheme.bgCard,
                        ],
                        stops: const [0.0, 0.4, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((availabilityLabel ?? '').isNotEmpty) ...[
                                  Text(
                                    availabilityLabel!.toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: availabilityColor,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.5,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Text(
                                  character.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                        letterSpacing: -0.5,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await showDialog<void>(
                                context: context,
                                builder: (_) =>
                                    CharacterEditorDialog(character: character),
                              );
                            },
                            tooltip: l10n?.editCharacterButtonTooltip ??
                                'Edit character',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.tune_rounded,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        sceneHookExcerpt,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: ValueKey<String>(
                        'character-new-conversation-${character.id}'),
                    onPressed: isChatReady
                        ? () async {
                            final AppStateProvider appState =
                                context.read<AppStateProvider>();
                            final ChatSession session = await appState
                                .startNewConversation(character.id);
                            if (!context.mounted) return;
                            final Uri target = Uri(
                              path: '/chat/${character.id}',
                              queryParameters: <String, String>{
                                'session': session.id
                              },
                            );
                            context.push(target.toString());
                          }
                        : needsModelDownload
                            ? () => context.push(
                                  Uri(
                                    path: '/model-setup',
                                    queryParameters: <String, String>{
                                      'returnTo': '/chat/${character.id}',
                                    },
                                  ).toString(),
                                )
                            : null,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      l10n?.newConversationButton ?? 'Start Story',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                  ),
                ),
                Container(width: 1, height: 20, color: AppTheme.borderSubtle),
                Expanded(
                  child: TextButton(
                    key: ValueKey<String>('character-history-${character.id}'),
                    onPressed:
                        isChatReady ? () => _showSessionHistory(context) : null,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      l10n?.sessionHistoryShortLabel ?? 'History',
                    ),
                  ),
                ),
                Container(width: 1, height: 20, color: AppTheme.borderSubtle),
                Tooltip(
                  message: l10n?.clearHistoryButton ?? 'Clear History',
                  child: IconButton(
                    key: ValueKey<String>(
                      'character-clear-history-${character.id}',
                    ),
                    onPressed: isChatReady
                        ? () => _confirmAndClearHistory(context)
                        : null,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
