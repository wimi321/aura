import 'dart:async';
import 'package:aura_core/aura_core.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../application/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/character_cover_art.dart';
import '../../widgets/session_history_sheet.dart';

enum _ChatMenuAction { history, newConversation, clearHistory }

enum _ChatErrorType { timeout, recoveryFailed, generic }

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.characterId,
    this.initialSessionId,
    this.initialDraft,
  });

  final String characterId;
  final String? initialSessionId;
  final String? initialDraft;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  static const Duration _generationTimeout = Duration(seconds: 75);
  static const String _cancelSignal = 'AURA_GENERATION_CANCELLED';
  static const String _timeoutSignal = 'AURA_GENERATION_TIMEOUT';
  static const String _hiddenContinueAction = 'continue_scene';

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChatSession? _session;
  String? _sessionId;
  bool _isBootstrapping = true;
  bool _isSending = false;
  String? _error;
  _ChatErrorType? _errorType;
  Timer? _errorDismissTimer;
  int _generationEpoch = 0;
  String? _whisperInstruction;

  late AnimationController _ambientGlowController;

  CharacterCard get _character =>
      context.read<AppStateProvider>().characterById(widget.characterId);

  @override
  void initState() {
    super.initState();
    final String initialDraft = widget.initialDraft?.trim() ?? '';
    if (initialDraft.isNotEmpty) {
      _messageController.text = initialDraft;
    }
    _ambientGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !MediaQuery.of(context).disableAnimations) {
        _ambientGlowController.repeat(reverse: true);
      }
      _bootstrapSession();
    });
  }

  Future<void> _bootstrapSession({String? preferredSessionId}) async {
    final AppStateProvider appState = context.read<AppStateProvider>();
    try {
      final ChatSession session = await appState.resolveChatSession(
        widget.characterId,
        preferredSessionId: preferredSessionId ?? widget.initialSessionId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _sessionId = session.id;
        _session = session;
        _isBootstrapping = false;
        _isSending = false;
        _error = null;
      });
      _scrollToBottomSoon();
      if (appState.needsModelDownload) {
        _redirectToModelSetup(sessionId: session.id);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBootstrapping = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    final String? whisper = _whisperInstruction;
    await _submitTurn(
      text: text,
      clearComposer: true,
      whisperInstruction: whisper,
    );
    if (mounted) {
      setState(() {
        _whisperInstruction = null;
      });
    }
  }

  Future<void> _continueScene() async {
    await _submitTurn(
      text: _continueScenePrompt(context),
      showUserBubble: false,
      userMetadata: const <String, Object?>{
        'hidden_action': _hiddenContinueAction,
      },
    );
  }

  Future<void> _openWhisperSheet() async {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final TextEditingController whisperController =
        TextEditingController(text: _whisperInstruction ?? '');
    final String? result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.bgElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
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
              const SizedBox(height: 14),
              Text(
                l10n?.whisperSheetTitle ?? 'Whisper Instruction',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n?.whisperSheetDescription ??
                    'Influence the character\'s next turn from behind the scenes without breaking the story text.',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n?.whisperSheetExample ??
                    'Example: Reply more softly and hide concern under confidence.',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: whisperController,
                autofocus: true,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n?.whisperHint ??
                      'Whisper instruction (next turn only)...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.borderSubtle),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext)
                      .pop(whisperController.text.trim()),
                  child: Text(l10n?.applyWhisper ?? 'Apply Whisper'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted) {
      return;
    }
    if (result != null) {
      setState(() {
        _whisperInstruction = result.isEmpty ? null : result;
      });
    }
  }

  Future<void> _submitTurn({
    required String text,
    bool showUserBubble = true,
    bool clearComposer = false,
    Map<String, Object?> userMetadata = const <String, Object?>{},
    String? whisperInstruction,
  }) async {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final AppStateProvider appState = context.read<AppStateProvider>();
    final bool isConversationResetting =
        appState.isConversationActionInProgressFor(widget.characterId);
    final bool isModelBusy = appState.isRecoveringModel ||
        appState.modelState != AppModelState.ready;
    if (text.isEmpty ||
        _isSending ||
        _isBootstrapping ||
        isConversationResetting ||
        isModelBusy) {
      return;
    }

    if (appState.activeModel == null ||
        appState.modelState != AppModelState.ready) {
      if (appState.needsModelDownload) {
        _redirectToModelSetup(sessionId: _sessionId);
        return;
      }
      setState(() {
        _error = l10n?.chatModelPreparing ??
            'Aura is still preparing the local core. Please wait a moment.';
      });
      return;
    }

    final ChatSession? currentSession = _session;
    if (currentSession == null) {
      return;
    }
    final String? currentSessionId = _sessionId;
    if (currentSessionId == null) {
      return;
    }
    final int generationEpoch = ++_generationEpoch;

    final ChatMessage userMessage = ChatMessage(
      id: 'local-user-${DateTime.now().microsecondsSinceEpoch}',
      role: ChatRole.user,
      content: text,
      createdAt: DateTime.now(),
      metadata: userMetadata,
    );
    final ChatMessage placeholderAssistant = ChatMessage(
      id: 'local-assistant-${DateTime.now().microsecondsSinceEpoch}',
      role: ChatRole.assistant,
      content: '',
      createdAt: DateTime.now(),
    );

    if (clearComposer) {
      _messageController.clear();
    }
    setState(() {
      _error = null;
      _isSending = true;
      _session = currentSession.copyWith(
        messages: <ChatMessage>[
          ...currentSession.messages,
          if (showUserBubble) userMessage,
          placeholderAssistant
        ],
        updatedAt: DateTime.now(),
      );
    });
    _scrollToBottomSoon();

    final StringBuffer assistantBuffer = StringBuffer();

    try {
      await for (final StreamDelta delta in appState.engine
          .sendTextMessage(
        sessionId: currentSessionId,
        card: _character,
        message: text,
        userMetadata: userMetadata,
        whisper: whisperInstruction,
        localeTag: appState.effectiveLocaleTag,
        preset: appState.activePreset,
      )
          .timeout(_generationTimeout,
              onTimeout: (EventSink<StreamDelta> sink) {
        unawaited(appState.engine.cancelActiveGeneration());
        sink.addError(TimeoutException(_timeoutSignal));
        sink.close();
      })) {
        if (!mounted) {
          return;
        }
        if (generationEpoch != _generationEpoch) {
          continue;
        }
        if (delta.visibleText.isNotEmpty) {
          assistantBuffer.write(delta.visibleText);
          final ChatSession? active = _session;
          if (active == null || active.messages.isEmpty) {
            continue;
          }
          final List<ChatMessage> updated =
              List<ChatMessage>.from(active.messages);
          updated[updated.length - 1] = ChatMessage(
            id: updated.last.id,
            role: ChatRole.assistant,
            content: assistantBuffer.toString(),
            createdAt: updated.last.createdAt,
          );
          setState(() {
            _session =
                active.copyWith(messages: updated, updatedAt: DateTime.now());
          });
          _scrollToBottomSoon();
        }
        if (delta.isDone) {
          break;
        }
      }

      await _syncSessionFromStore(
        sessionId: currentSessionId,
        generationEpoch: generationEpoch,
      );
    } catch (error) {
      final String errorText = error.toString();
      final bool wasCancelled = errorText.contains(_cancelSignal);
      final bool timedOut = errorText.contains(_timeoutSignal);
      if (mounted && generationEpoch == _generationEpoch) {
        setState(() {
          _isSending = false;
          _session = _sessionWithoutPendingAssistant(_session);
        });
      }
      String? errorMessage;
      _ChatErrorType errorType = _ChatErrorType.generic;
      if (wasCancelled) {
        errorMessage = null;
      } else if (timedOut) {
        errorType = _ChatErrorType.timeout;
        errorMessage = l10n?.chatGenerationTimedOut ??
            'Aura response timed out. You can send again or retry after stopping.';
      } else {
        final bool recovered = await appState.recoverActiveModel();
        if (!mounted || generationEpoch != _generationEpoch) {
          return;
        }
        if (recovered) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.coreReconnectedToast ??
                    'Core reconnected. You can send again.',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          errorMessage = null;
        } else {
          errorType = _ChatErrorType.recoveryFailed;
          errorMessage = l10n?.chatRuntimeRecoveryFailed ??
              'Aura hit a runtime error and recovery failed. Please reactivate the model in settings.';
        }
      }
      await _syncSessionFromStore(
        sessionId: currentSessionId,
        generationEpoch: generationEpoch,
        clearPendingAssistant: true,
        errorMessage: errorMessage,
        errorType: errorType,
      );
    }
  }

  Future<void> _cancelGeneration() async {
    if (!_isSending) {
      return;
    }
    HapticFeedback.lightImpact();
    final String? activeSessionId = _sessionId;
    final int cancelledEpoch = ++_generationEpoch;
    if (mounted) {
      setState(() {
        _isSending = false;
        _error = null;
        _session = _sessionWithoutPendingAssistant(_session);
      });
    }
    try {
      await context.read<AppStateProvider>().engine.cancelActiveGeneration();
    } catch (_) {}
    if (activeSessionId != null) {
      await _syncSessionFromStore(
        sessionId: activeSessionId,
        generationEpoch: cancelledEpoch,
        clearPendingAssistant: true,
      );
    }
  }

  ChatSession? _sessionWithoutPendingAssistant(ChatSession? session) {
    final ChatSession? active = session;
    if (active == null || active.messages.isEmpty) {
      return active;
    }
    final List<ChatMessage> updated = List<ChatMessage>.from(active.messages);
    bool changed = false;
    final ChatMessage last = updated.last;
    if (last.role == ChatRole.assistant && last.content.isEmpty) {
      updated.removeLast();
      changed = true;
    }
    if (updated.isNotEmpty && _isHiddenContinueMessage(updated.last)) {
      updated.removeLast();
      changed = true;
    }
    return changed
        ? active.copyWith(messages: updated, updatedAt: DateTime.now())
        : active;
  }

  Future<void> _syncSessionFromStore({
    required String sessionId,
    required int generationEpoch,
    bool clearPendingAssistant = false,
    String? errorMessage,
    _ChatErrorType errorType = _ChatErrorType.generic,
  }) async {
    final ChatSession? persisted =
        await context.read<AppStateProvider>().engine.getSession(sessionId);
    if (!mounted || generationEpoch != _generationEpoch) {
      return;
    }
    final ChatSession? nextSession = persisted == null
        ? (clearPendingAssistant
            ? _sessionWithoutPendingAssistant(_session)
            : _session)
        : (clearPendingAssistant
            ? _sessionWithoutPendingAssistant(persisted)
            : persisted);
    _session = nextSession;
    _isSending = false;
    if (errorMessage != null) {
      _setError(errorMessage, type: errorType);
    } else {
      _setError(null);
    }
    _scrollToBottomSoon();
  }

  Future<void> _startNewConversation() async {
    final AppStateProvider appState = context.read<AppStateProvider>();
    if (appState.isConversationActionInProgressFor(widget.characterId)) {
      return;
    }
    if (_isSending) {
      await _cancelGeneration();
    }
    final ChatSession session =
        await appState.startNewConversation(widget.characterId);
    if (!mounted) {
      return;
    }
    setState(() {
      _sessionId = session.id;
      _session = session;
      _isBootstrapping = false;
      _isSending = false;
      _error = null;
    });
    _scrollToBottomSoon();
  }

  Future<void> _rerollLastMessage() async {
    final String? sessionId = _sessionId;
    if (sessionId == null || _isSending) {
      return;
    }
    final AppStateProvider appState = context.read<AppStateProvider>();
    try {
      final ({ChatSession session, String? lastUserText}) result =
          await appState.rerollLastMessage(sessionId);
      if (!mounted) {
        return;
      }
      setState(() {
        _session = result.session;
        _error = null;
      });
      final String? userText = result.lastUserText;
      if (userText != null && userText.isNotEmpty) {
        await _submitTurn(
          text: userText,
          showUserBubble: false,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    }
  }

  Future<void> _clearConversationHistory() async {
    final AppStateProvider appState = context.read<AppStateProvider>();
    if (appState.isConversationActionInProgressFor(widget.characterId)) {
      return;
    }
    if (_isSending) {
      await _cancelGeneration();
      if (!mounted) {
        return;
      }
    }
    final bool shouldClear = await showClearHistoryConfirmation(
      context,
      characterName: _character.name,
    );
    if (!mounted || !shouldClear) {
      return;
    }
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final ChatSession session =
        await appState.resetConversation(widget.characterId);
    if (!mounted) {
      return;
    }
    setState(() {
      _sessionId = session.id;
      _session = session;
      _isBootstrapping = false;
      _isSending = false;
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.historyClearedMessage ?? 'Conversation history cleared.',
        ),
      ),
    );
    _scrollToBottomSoon();
  }

  Future<void> _openSessionHistory() async {
    final AppStateProvider appState = context.read<AppStateProvider>();
    final List<ChatSession> sessions =
        await appState.engine.listSessionsForCharacter(widget.characterId);
    if (!mounted) {
      return;
    }
    final String? selectedSessionId = await showSessionHistorySheet(
      context,
      characterName: _character.name,
      sessions: sessions,
      currentSessionId: _sessionId,
    );
    if (!mounted ||
        selectedSessionId == null ||
        selectedSessionId == _sessionId) {
      return;
    }
    setState(() {
      _isBootstrapping = true;
      _error = null;
    });
    await _bootstrapSession(preferredSessionId: selectedSessionId);
  }

  Future<void> _showMessageActions(ChatMessage message) async {
    if (_isSending || _sessionId == null) {
      return;
    }
    HapticFeedback.lightImpact();
    final String? action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        final AppLocalizations? l10n = AppLocalizations.of(context);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.copy_rounded),
                  title: Text(
                    l10n?.copyToClipboard ?? 'Copy to clipboard',
                  ),
                  onTap: () => Navigator.of(context).pop('copy'),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(
                    l10n?.editMessageActionTitle ?? 'Edit this message',
                  ),
                  subtitle: Text(
                    l10n?.editMessageActionDescription ??
                        'Keep the story and revise this turn only.',
                  ),
                  onTap: () => Navigator.of(context).pop('edit'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.statusDanger,
                  ),
                  title: Text(
                    l10n?.deleteMessageActionTitle ?? 'Delete this message',
                    style: const TextStyle(color: AppTheme.statusDanger),
                  ),
                  subtitle: Text(
                    l10n?.deleteMessageActionDescription ??
                        'Remove this turn from the current session.',
                  ),
                  onTap: () => Navigator.of(context).pop('delete'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || action == null) {
      return;
    }
    switch (action) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: message.content));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.copiedToClipboard ??
                    'Copied to clipboard',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      case 'edit':
        await _editMessage(message);
      case 'delete':
        await _deleteMessage(message);
    }
  }

  Future<void> _editMessage(ChatMessage message) async {
    final String? sessionId = _sessionId;
    if (sessionId == null) {
      return;
    }
    final TextEditingController controller =
        TextEditingController(text: message.content);
    final String? edited = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final AppLocalizations? l10n = AppLocalizations.of(context);
        return AlertDialog(
          backgroundColor: AppTheme.bgElevated,
          title: Text(l10n?.editMessageDialogTitle ?? 'Edit message'),
          content: TextField(
            controller: controller,
            maxLines: 8,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n?.editMessageHint ?? 'Rewrite the message',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n?.cancelButton ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(l10n?.saveButton ?? 'Save'),
            ),
          ],
        );
      },
    );
    if (!mounted || edited == null || edited.trim().isEmpty) {
      return;
    }
    final AppStateProvider appState = context.read<AppStateProvider>();
    final ChatSession updated = await appState.editSessionMessage(
      sessionId: sessionId,
      messageId: message.id,
      newContent: edited,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _session = updated;
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.messageUpdated ?? 'Message updated.',
        ),
      ),
    );
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final String? sessionId = _sessionId;
    if (sessionId == null) {
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final AppLocalizations? l10n = AppLocalizations.of(context);
        return AlertDialog(
          backgroundColor: AppTheme.bgElevated,
          title: Text(l10n?.deleteMessageDialogTitle ?? 'Delete message'),
          content: Text(
            l10n?.deleteMessageDialogDescription ??
                'This message will be removed from the current session.',
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
    if (!mounted || confirmed != true) {
      return;
    }
    final AppStateProvider appState = context.read<AppStateProvider>();
    final ChatSession updated = await appState.deleteSessionMessage(
      sessionId: sessionId,
      messageId: message.id,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _session = updated;
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.messageDeleted ?? 'Message deleted.',
        ),
      ),
    );
  }

  void _scrollToBottomSoon() {
    Future<void>.delayed(const Duration(milliseconds: 60), () {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _redirectToModelSetup({String? sessionId}) {
    if (!mounted) {
      return;
    }
    final Uri returnTo = Uri(
      path: '/chat/${widget.characterId}',
      queryParameters: <String, String>{
        if ((sessionId ?? _sessionId)?.isNotEmpty ?? false)
          'session': sessionId ?? _sessionId!,
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.go(
        Uri(
          path: '/model-setup',
          queryParameters: <String, String>{
            'returnTo': returnTo.toString(),
          },
        ).toString(),
      );
    });
  }

  void _setError(String? message,
      {_ChatErrorType type = _ChatErrorType.generic}) {
    _errorDismissTimer?.cancel();
    _errorDismissTimer = null;
    setState(() {
      _error = message;
      _errorType = message == null ? null : type;
    });
    if (message != null && type == _ChatErrorType.timeout) {
      _errorDismissTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) {
          setState(() {
            _error = null;
            _errorType = null;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _errorDismissTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _ambientGlowController.dispose();
    super.dispose();
  }

  bool _isHiddenContinueMessage(ChatMessage message) {
    return message.role == ChatRole.user &&
        message.metadata['hidden_action']?.toString() == _hiddenContinueAction;
  }

  bool _showRerollButton(List<ChatMessage> messages) {
    if (_isSending || _isBootstrapping || messages.isEmpty) {
      return false;
    }
    return messages.last.role == ChatRole.assistant &&
        messages.last.content.trim().isNotEmpty;
  }

  String _continueScenePrompt(BuildContext context) {
    return AppLocalizations.of(context)?.continueScenePrompt ??
        'Continue the current scene naturally. Advance the tension, clues, or emotions without resetting the relationship or breaking character.';
  }

  void _showCharacterDetails() {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.bgElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                controller: scrollController,
                children: [
                  const SizedBox(height: 12),
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
                    l10n?.characterDetailsSheetTitle ?? 'Character Details',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_character.scenario.trim().isNotEmpty) ...[
                    Text(
                      l10n?.characterScenarioLabel ?? 'Scenario',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandAura,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _character.scenario,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_character.description.trim().isNotEmpty) ...[
                    Text(
                      l10n?.characterDescriptionLabel ?? 'Description',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandAura,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _character.description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_character.personality.trim().isNotEmpty) ...[
                    Text(
                      l10n?.characterPersonalityLabel ?? 'Personality',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandAura,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _character.personality,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _retryLastMessage() async {
    _setError(null);
    final ChatSession? session = _session;
    if (session == null || session.messages.isEmpty) {
      return;
    }
    final Iterable<ChatMessage> userMessages =
        session.messages.where((ChatMessage m) => m.role == ChatRole.user);
    if (userMessages.isEmpty) {
      return;
    }
    final ChatMessage lastUser = userMessages.last;
    await _submitTurn(
      text: lastUser.content,
      showUserBubble: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppStateProvider appState = context.watch<AppStateProvider>();
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final List<ChatMessage> messages =
        (_session?.messages ?? const <ChatMessage>[])
            .where((ChatMessage message) => !_isHiddenContinueMessage(message))
            .toList(growable: false);

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: Stack(
        children: [
          // Cinematic background cover
          Positioned.fill(
            child: Opacity(
              opacity: 0.15, // Keep it subtle so text is readable
              child: CharacterCoverArt(
                character: _character,
                height: MediaQuery.of(context).size.height,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.bgBase.withValues(alpha: 0.0),
                    AppTheme.bgBase.withValues(alpha: 0.6),
                    AppTheme.bgBase.withValues(alpha: 0.95),
                    AppTheme.bgBase,
                  ],
                  stops: const [0.0, 0.35, 0.6, 1.0],
                ),
              ),
            ),
          ),

          Column(
            children: [
              _buildGlassAppBar(context, appState),
              Expanded(
                child: _isBootstrapping
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(
                            top: 24, bottom: 24, left: 16, right: 16),
                        itemCount: messages.length +
                            (_showRerollButton(messages) ? 1 : 0),
                        itemBuilder: (BuildContext context, int index) {
                          // Reroll button after last message
                          if (index == messages.length &&
                              _showRerollButton(messages)) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  key: const ValueKey<String>(
                                      'chat-reroll-button'),
                                  onPressed: _rerollLastMessage,
                                  tooltip: l10n?.rerollButtonTooltip ??
                                      'Regenerate response',
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 20,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }
                          final ChatMessage message = messages[index];
                          // Do not render empty assistant messages unless it's the last one (currently generating)
                          if (message.content.isEmpty &&
                              message.role == ChatRole.assistant &&
                              index != messages.length - 1) {
                            return const SizedBox.shrink();
                          }
                          return _MessageBubble(
                            message: message,
                            characterName: _character.name,
                            characterExtensions: _character.extensions,
                            isGenerating:
                                _isSending && index == messages.length - 1,
                            onLongPress:
                                _isSending || message.content.trim().isEmpty
                                    ? null
                                    : () => _showMessageActions(message),
                          );
                        },
                      ),
              ),
              if (_error != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x33FF6B6B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x55FF6B6B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!,
                            style: const TextStyle(
                                color: Color(0xFFFF9B9B), fontSize: 13)),
                        if (_errorType == _ChatErrorType.timeout ||
                            _errorType == _ChatErrorType.recoveryFailed) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_errorType == _ChatErrorType.timeout)
                                TextButton.icon(
                                  onPressed: _retryLastMessage,
                                  icon: const Icon(Icons.refresh_rounded,
                                      size: 16),
                                  label:
                                      Text(l10n?.errorRetryMessage ?? 'Retry'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFFF9B9B),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              if (_errorType == _ChatErrorType.recoveryFailed)
                                TextButton.icon(
                                  onPressed: () => context.go('/settings'),
                                  icon: const Icon(Icons.settings_outlined,
                                      size: 16),
                                  label: Text(l10n?.errorGoToSettings ??
                                      'Go to Settings'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFFF9B9B),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              if (_whisperInstruction != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 12, color: AppTheme.brandCoral),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${l10n?.nextWhisperLabel ?? 'Next whisper'}: $_whisperInstruction',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.brandCoral,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _whisperInstruction = null;
                        }),
                        child: const Icon(Icons.close,
                            size: 14, color: AppTheme.brandCoral),
                      ),
                    ],
                  ),
                ),
              _buildInputArea(context, appState),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar(BuildContext context, AppStateProvider appState) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final bool isConversationResetting =
        appState.isConversationActionInProgressFor(widget.characterId);
    final bool disableOverflow =
        _isSending || appState.isRecoveringModel || isConversationResetting;

    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 16,
          left: 16,
          right: 16),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: l10n?.chatBackButtonTooltip ?? 'Back',
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: Colors.white,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              CharacterAvatar(
                character: _character,
                size: 36,
                borderRadius: BorderRadius.circular(999),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_character.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                    Text(
                      appState.activeModel?.name ??
                          (l10n?.noActiveModel ?? 'No active model'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_ChatMenuAction>(
                key: const ValueKey<String>('chat-overflow-button'),
                enabled: !disableOverflow,
                tooltip: l10n?.chatMoreActionsTooltip ?? 'Conversation actions',
                color: AppTheme.bgElevated,
                surfaceTintColor: Colors.transparent,
                icon: Icon(Icons.more_horiz,
                    color: disableOverflow
                        ? AppTheme.textMuted
                        : AppTheme.textSecondary),
                onSelected: (_ChatMenuAction action) {
                  switch (action) {
                    case _ChatMenuAction.history:
                      unawaited(_openSessionHistory());
                      break;
                    case _ChatMenuAction.newConversation:
                      unawaited(_startNewConversation());
                      break;
                    case _ChatMenuAction.clearHistory:
                      unawaited(_clearConversationHistory());
                      break;
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<_ChatMenuAction>>[
                  PopupMenuItem<_ChatMenuAction>(
                    key: const ValueKey<String>('chat-menu-history'),
                    value: _ChatMenuAction.history,
                    child: Row(
                      children: [
                        const Icon(Icons.history_rounded, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          l10n?.sessionHistoryShortLabel ?? 'History',
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<_ChatMenuAction>(
                    key: const ValueKey<String>('chat-menu-new-conversation'),
                    value: _ChatMenuAction.newConversation,
                    child: Row(
                      children: [
                        const Icon(Icons.add_comment_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          l10n?.newConversationButton ?? 'New Chat',
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<_ChatMenuAction>(
                    key: const ValueKey<String>('chat-menu-clear-history'),
                    value: _ChatMenuAction.clearHistory,
                    child: Row(
                      children: [
                        const Icon(Icons.auto_delete_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          l10n?.clearHistoryButton ?? 'Clear History',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showCharacterDetails,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _character.scenario,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more_rounded,
                    size: 16, color: AppTheme.textMuted),
              ],
            ),
          ),
          if (appState.isRecoveringModel ||
              isConversationResetting ||
              appState.modelState != AppModelState.ready) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appState.isRecoveringModel
                        ? (l10n?.chatRecoveringCore ??
                            'Recovering the local core...')
                        : isConversationResetting
                            ? (l10n?.chatConversationResetting ??
                                'Resetting this conversation...')
                            : (l10n?.chatModelPreparing ??
                                'Aura is still preparing the local core. Please wait a moment.'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.statusWarning,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, AppStateProvider appState) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final bool isConversationResetting =
        appState.isConversationActionInProgressFor(widget.characterId);
    final bool isModelReady = appState.activeModel != null &&
        appState.modelState == AppModelState.ready &&
        !appState.isRecoveringModel;
    final bool controlsLocked =
        _isBootstrapping || isConversationResetting || !isModelReady;
    final bool hasDraft = _messageController.text.trim().isNotEmpty;
    final bool canSend = !_isSending && !controlsLocked && hasDraft;
    final bool canContinue = !_isSending && !controlsLocked;
    final Color actionColor = _isSending
        ? AppTheme.brandCoral
        : (canSend
            ? AppTheme.brandAura
            : AppTheme.textMuted.withValues(alpha: 0.35));
    return Container(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgBase,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            key: const ValueKey<String>('chat-continue-button'),
            onPressed: canContinue ? _continueScene : null,
            tooltip: l10n?.continueSceneButtonTooltip ??
                'Continue the current scene',
            icon: Icon(
              Icons.play_circle_fill_rounded,
              color: canContinue ? AppTheme.brandAura : AppTheme.textMuted,
            ),
          ),
          IconButton(
            key: const ValueKey<String>('chat-whisper-button'),
            onPressed: controlsLocked ? null : _openWhisperSheet,
            tooltip:
                l10n?.chatWhisperButtonTooltip ?? 'Open whisper instruction',
            icon: Icon(
              Icons.auto_awesome,
              size: 20,
              color: _whisperInstruction != null
                  ? AppTheme.brandCoral
                  : (controlsLocked
                      ? AppTheme.textMuted
                      : AppTheme.textSecondary),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: TextField(
                key: const ValueKey<String>('chat-input-field'),
                controller: _messageController,
                enabled: !controlsLocked,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onChanged: (_) {
                  if (mounted) {
                    setState(() {});
                  }
                },
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: l10n?.chatInputPlaceholder ?? 'Message Aura...',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 48,
            width: 48,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: actionColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              key: const ValueKey<String>('chat-action-button'),
              tooltip: _isSending
                  ? (l10n?.chatStopButtonTooltip ?? 'Stop generation')
                  : (l10n?.chatSendButtonTooltip ?? 'Send message'),
              onPressed: _isSending
                  ? _cancelGeneration
                  : (canSend ? _sendMessage : null),
              icon: _isSending
                  ? const Icon(Icons.stop_rounded,
                      key: ValueKey<String>('chat-stop-icon'),
                      color: Color(0xFF2A1405),
                      size: 24)
                  : const Icon(Icons.arrow_upward_rounded,
                      key: ValueKey<String>('chat-send-icon'),
                      color: Color(0xFF04110C),
                      size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.characterName,
    this.characterExtensions,
    this.isGenerating = false,
    this.onLongPress,
  });

  final ChatMessage message;
  final String characterName;
  final Map<String, Object?>? characterExtensions;
  final bool isGenerating;
  final VoidCallback? onLongPress;

  String _formatTimestamp(DateTime time, AppLocalizations? l10n) {
    final Duration diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) {
      return l10n?.messageTimeJustNow ?? 'just now';
    }
    if (diff.inHours < 1) {
      return l10n?.messageTimeMinutesAgo(diff.inMinutes) ??
          '${diff.inMinutes} min ago';
    }
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final bool isUser = message.role == ChatRole.user;
    final String visibleContent = RoleplayTextFormatter.sanitizeModelOutput(
      message.content,
      characterName: characterName,
      localeTag: Localizations.localeOf(context).toLanguageTag(),
      userAlias: isUser ? null : null,
      extensions: characterExtensions,
    );
    final String? timestamp = message.createdAt != null
        ? _formatTimestamp(message.createdAt!, l10n)
        : null;

    if (!isUser) {
      return Semantics(
        label: '$characterName: $visibleContent',
        child: GestureDetector(
          key: ValueKey<String>('chat-message-${message.id}'),
          onLongPress: onLongPress,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        size: 14, color: AppTheme.brandAura),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (characterName.trim().isEmpty
                                ? (l10n?.assistantLabel ?? 'CHARACTER')
                                : characterName)
                            .toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.brandAura,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (!isGenerating && timestamp != null)
                      Text(
                        timestamp,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                              fontSize: 10,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (visibleContent.isEmpty && isGenerating)
                  const _TypingIndicator()
                else
                  Text(
                    visibleContent,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.7,
                        fontSize: 16.5,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.2),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // User Bubble
    return Semantics(
      label: 'You: $visibleContent',
      child: GestureDetector(
        key: ValueKey<String>('chat-message-${message.id}'),
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32, left: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  visibleContent,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6, fontSize: 15, color: AppTheme.textSecondary),
                ),
              ),
              if (timestamp != null) ...[
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(3, (int index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandAura,
              ),
            ),
          );
        }),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (int index) {
            final double offset = index * 0.2;
            final double value = (_controller.value - offset) % 1.0;
            final double opacity = (value < 0.5) ? value * 2 : (1 - value) * 2;
            final double bounce =
                (value < 0.5) ? -3.0 * (1 - (value * 2 - 1).abs()) : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Transform.translate(
                offset: Offset(0, bounce),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.brandAura
                        .withValues(alpha: opacity.clamp(0.2, 1.0)),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
