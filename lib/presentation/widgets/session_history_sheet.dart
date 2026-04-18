import 'package:aura_app/core/theme/app_theme.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';
import 'package:aura_core/aura_core.dart';
import 'package:flutter/material.dart';

const String _hiddenContinueAction = 'continue_scene';

Future<String?> showSessionHistorySheet(
  BuildContext context, {
  required String characterName,
  required List<ChatSession> sessions,
  required String? currentSessionId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppTheme.bgElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (BuildContext context) {
      final AppLocalizations? l10n = AppLocalizations.of(context);
      final MaterialLocalizations material = MaterialLocalizations.of(context);
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n?.sessionHistoryTitle ?? 'Session History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                l10n?.sessionHistoryDescription(characterName) ??
                    'Jump back into an older branch for $characterName and keep that storyline going.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              if (sessions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Text(
                    l10n?.sessionHistoryEmpty ??
                        'No saved sessions for this role card yet.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final ChatSession session = sessions[index];
                      final bool isCurrent = session.id == currentSessionId;
                      final List<ChatMessage> visibleMessages =
                          _visibleMessages(session);
                      final String preview = _previewText(
                        visibleMessages,
                        l10n: l10n,
                      );
                      final String updatedLabel = _formatSessionTime(
                        material,
                        session.updatedAt,
                      );
                      final String countLabel =
                          l10n?.sessionMessageCount(visibleMessages.length) ??
                              '${visibleMessages.length} messages';

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.of(context).pop(session.id),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isCurrent
                                    ? AppTheme.brandAura
                                    : AppTheme.borderSubtle,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isCurrent
                                            ? (l10n?.sessionCurrentLabel ??
                                                'Current Session')
                                            : updatedLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: isCurrent
                                                  ? AppTheme.brandAura
                                                  : AppTheme.textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      countLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                    ),
                                    if (isCurrent) ...[
                                      const SizedBox(width: 10),
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 18,
                                        color: AppTheme.brandAura,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  preview,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                        height: 1.45,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

Future<bool> showClearHistoryConfirmation(
  BuildContext context, {
  required String characterName,
}) async {
  final AppLocalizations? l10n = AppLocalizations.of(context);
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: AppTheme.bgElevated,
        title: Text(
          l10n?.clearHistoryConfirmTitle ?? 'Clear all session history?',
        ),
        content: Text(
          l10n?.clearHistoryConfirmDescription(characterName) ??
              'This deletes every saved session for $characterName and the old branches cannot be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n?.cancelButton ?? 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.statusDanger,
              foregroundColor: AppTheme.textPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n?.clearHistoryConfirmAction ?? 'Delete All',
            ),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

List<ChatMessage> _visibleMessages(ChatSession session) {
  return session.messages
      .where((ChatMessage message) => message.content.trim().isNotEmpty)
      .where(
        (ChatMessage message) =>
            message.metadata['hidden_action']?.toString() !=
            _hiddenContinueAction,
      )
      .toList(growable: false);
}

String _previewText(
  List<ChatMessage> messages, {
  required AppLocalizations? l10n,
}) {
  if (messages.isEmpty) {
    return l10n?.sessionBranchEmpty ?? 'This branch has not started yet.';
  }
  return messages.last.content.trim();
}

String _formatSessionTime(
  MaterialLocalizations material,
  DateTime updatedAt,
) {
  final DateTime local = updatedAt.toLocal();
  final String date = material.formatShortDate(local);
  final String time = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: true,
  );
  return '$date $time';
}
