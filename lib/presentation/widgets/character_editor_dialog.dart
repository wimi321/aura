import 'dart:io';

import 'package:aura_app/l10n/generated/app_localizations.dart';
import 'package:aura_core/aura_core.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/providers/app_state_provider.dart';
import '../../core/platform/file_selector_type_groups.dart';
import '../../core/theme/app_theme.dart';
import 'character_cover_art.dart';

class CharacterEditorDialog extends StatefulWidget {
  const CharacterEditorDialog({
    super.key,
    required this.character,
    this.onSaved,
  });

  final CharacterCard character;
  final ValueChanged<CharacterCard>? onSaved;

  @override
  State<CharacterEditorDialog> createState() => _CharacterEditorDialogState();
}

class _CharacterEditorDialogState extends State<CharacterEditorDialog> {
  late CharacterCard _draftCharacter;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _personalityController;
  late final TextEditingController _scenarioController;
  late final TextEditingController _firstMessageController;
  late final TextEditingController _examplesController;
  late final TextEditingController _alternateGreetingsController;
  late final TextEditingController _creatorNotesController;
  late final TextEditingController _mainPromptController;
  late final TextEditingController _postHistoryInstructionsController;
  late final TextEditingController _lorebookNameController;
  late final TextEditingController _lorebookDescriptionController;
  late List<LorebookEntry> _draftLorebookEntries;

  bool _saving = false;
  bool _importingLorebook = false;
  bool _lorebookMetaExpanded = false;
  bool _lorebookEntriesExpanded = false;
  String? _lorebookError;

  @override
  void initState() {
    super.initState();
    _draftCharacter = widget.character;
    _draftLorebookEntries = List<LorebookEntry>.from(
      widget.character.lorebook?.entries ?? const <LorebookEntry>[],
    );
    _nameController = TextEditingController(text: widget.character.name);
    _descriptionController =
        TextEditingController(text: widget.character.description);
    _personalityController =
        TextEditingController(text: widget.character.personality);
    _scenarioController =
        TextEditingController(text: widget.character.scenario);
    _firstMessageController =
        TextEditingController(text: widget.character.firstMessage);
    _examplesController = TextEditingController(
      text: widget.character.exampleDialogues.join('\n\n'),
    );
    _alternateGreetingsController = TextEditingController(
      text: widget.character.alternateGreetings.join('\n\n'),
    );
    _creatorNotesController =
        TextEditingController(text: widget.character.creatorNotes ?? '');
    _mainPromptController =
        TextEditingController(text: widget.character.mainPromptOverride ?? '');
    _postHistoryInstructionsController = TextEditingController(
      text: widget.character.postHistoryInstructions ?? '',
    );
    _lorebookNameController =
        TextEditingController(text: widget.character.lorebook?.name ?? '');
    _lorebookDescriptionController = TextEditingController(
      text: widget.character.lorebook?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _personalityController.dispose();
    _scenarioController.dispose();
    _firstMessageController.dispose();
    _examplesController.dispose();
    _alternateGreetingsController.dispose();
    _creatorNotesController.dispose();
    _mainPromptController.dispose();
    _postHistoryInstructionsController.dispose();
    _lorebookNameController.dispose();
    _lorebookDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _lorebookError = null;
    });

    final Lorebook? lorebook = _buildLorebookDraft();
    final CharacterCard next = _draftCharacter.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      personality: _personalityController.text.trim(),
      scenario: _scenarioController.text.trim(),
      firstMessage: _firstMessageController.text.trim(),
      exampleDialogues: _splitParagraphs(_examplesController.text),
      alternateGreetings: _splitParagraphs(_alternateGreetingsController.text),
      creatorNotes: _nullIfEmpty(_creatorNotesController.text),
      mainPromptOverride: _nullIfEmpty(_mainPromptController.text),
      postHistoryInstructions:
          _nullIfEmpty(_postHistoryInstructionsController.text),
      lorebook: lorebook,
      clearLorebook: lorebook == null,
      extensions: <String, Object?>{
        ..._draftCharacter.extensions,
        'edited': true,
        'user_customized': true,
      },
    );
    final CharacterCard stored =
        await context.read<AppStateProvider>().saveCharacter(next);
    if (!mounted) {
      return;
    }
    widget.onSaved?.call(stored);
    Navigator.of(context).pop(true);
  }

  Future<void> _importLorebook() async {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final AppStateProvider appState = context.read<AppStateProvider>();
    setState(() {
      _importingLorebook = true;
      _lorebookError = null;
    });

    try {
      final XFile? file = await openFile(
        acceptedTypeGroups: lorebookImportTypeGroups,
      );
      if (file == null) {
        setState(() {
          _importingLorebook = false;
        });
        return;
      }

      final preview = await appState.previewLorebookImport(File(file.path));
      if (!mounted) {
        return;
      }
      final Lorebook merged =
          _mergeLorebooks(_buildLorebookDraft(), preview.lorebook);
      setState(() {
        _applyLorebookDraft(
          merged,
          extensions: <String, Object?>{
            ..._draftCharacter.extensions,
            'attached_lorebook_source': preview.fileName,
            'attached_lorebook_mode': 'merge',
          },
        );
        _importingLorebook = false;
        _lorebookMetaExpanded = true;
        _lorebookEntriesExpanded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.lorebookImportedMessage(preview.lorebook.entries.length) ??
                'Lorebook attached (${preview.lorebook.entries.length} entries).',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _importingLorebook = false;
        _lorebookError = error.toString();
      });
    }
  }

  void _removeLorebook() {
    setState(() {
      _draftLorebookEntries = <LorebookEntry>[];
      _lorebookNameController.clear();
      _lorebookDescriptionController.clear();
      _draftCharacter = _draftCharacter.copyWith(clearLorebook: true);
      _lorebookMetaExpanded = false;
      _lorebookEntriesExpanded = false;
      _lorebookError = null;
    });
  }

  Future<void> _addLorebookEntry() async {
    final LorebookEntry? entry = await showDialog<LorebookEntry>(
      context: context,
      builder: (BuildContext context) => const _LorebookEntryEditorDialog(),
    );
    if (!mounted || entry == null) {
      return;
    }
    setState(() {
      _draftLorebookEntries = <LorebookEntry>[..._draftLorebookEntries, entry];
      _ensureLorebookExists();
      _lorebookEntriesExpanded = true;
    });
  }

  Future<void> _editLorebookEntry(int index) async {
    final LorebookEntry original = _draftLorebookEntries[index];
    final LorebookEntry? entry = await showDialog<LorebookEntry>(
      context: context,
      builder: (BuildContext context) =>
          _LorebookEntryEditorDialog(entry: original),
    );
    if (!mounted || entry == null) {
      return;
    }
    setState(() {
      _draftLorebookEntries = List<LorebookEntry>.from(_draftLorebookEntries)
        ..[index] = entry;
      _ensureLorebookExists();
      _lorebookEntriesExpanded = true;
    });
  }

  void _deleteLorebookEntry(int index) {
    setState(() {
      _draftLorebookEntries = List<LorebookEntry>.from(_draftLorebookEntries)
        ..removeAt(index);
      _ensureLorebookExists();
      if (_draftLorebookEntries.isEmpty) {
        _lorebookEntriesExpanded = false;
      }
    });
  }

  void _ensureLorebookExists() {
    _draftCharacter = _draftCharacter.copyWith(
      lorebook: _buildLorebookDraft() ??
          const Lorebook(
            entries: <LorebookEntry>[],
          ),
    );
  }

  void _applyLorebookDraft(
    Lorebook lorebook, {
    Map<String, Object?>? extensions,
  }) {
    _draftLorebookEntries = List<LorebookEntry>.from(lorebook.entries);
    _lorebookNameController.text = lorebook.name ?? '';
    _lorebookDescriptionController.text = lorebook.description ?? '';
    _draftCharacter = _draftCharacter.copyWith(
      lorebook: lorebook,
      extensions: extensions ?? _draftCharacter.extensions,
    );
  }

  Lorebook? _buildLorebookDraft() {
    final String? name = _nullIfEmpty(_lorebookNameController.text);
    final String? description =
        _nullIfEmpty(_lorebookDescriptionController.text);
    if (_draftLorebookEntries.isEmpty && name == null && description == null) {
      return null;
    }
    final Lorebook? current = _draftCharacter.lorebook;
    return Lorebook(
      entries: List<LorebookEntry>.unmodifiable(_draftLorebookEntries),
      name: name,
      description: description,
      scanDepth: current?.scanDepth,
      tokenBudget: current?.tokenBudget,
      recursiveScanning: current?.recursiveScanning ?? false,
      extensions: current?.extensions ?? const <String, Object?>{},
    );
  }

  Lorebook _mergeLorebooks(Lorebook? current, Lorebook incoming) {
    final List<LorebookEntry> currentEntries =
        current?.entries ?? const <LorebookEntry>[];
    final Map<String, LorebookEntry> merged = <String, LorebookEntry>{
      for (final LorebookEntry entry in currentEntries)
        _lorebookEntryKey(entry): entry,
    };
    for (final LorebookEntry entry in incoming.entries) {
      merged.putIfAbsent(_lorebookEntryKey(entry), () => entry);
    }
    return Lorebook(
      entries: merged.values.toList(growable: false),
      name: (current?.name?.trim().isNotEmpty ?? false)
          ? current!.name
          : incoming.name,
      description: (current?.description?.trim().isNotEmpty ?? false)
          ? current!.description
          : incoming.description,
      scanDepth: current?.scanDepth ?? incoming.scanDepth,
      tokenBudget: current?.tokenBudget ?? incoming.tokenBudget,
      recursiveScanning:
          (current?.recursiveScanning ?? false) || incoming.recursiveScanning,
      extensions: <String, Object?>{
        ...?current?.extensions,
        ...incoming.extensions,
      },
    );
  }

  String _lorebookEntryKey(LorebookEntry entry) {
    final List<String> normalized = <String>[
      entry.id.trim().toLowerCase(),
      ...entry.keywords.map((String value) => value.trim().toLowerCase()),
      ...entry.secondaryKeywords
          .map((String value) => value.trim().toLowerCase()),
      entry.content.trim().toLowerCase(),
    ]..sort();
    return normalized.join('|');
  }

  List<String> _splitParagraphs(String input) {
    return input
        .split(RegExp(r'\n{2,}'))
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String? _nullIfEmpty(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _lorebookMetaSummary(AppLocalizations? l10n) {
    final bool hasName = _nullIfEmpty(_lorebookNameController.text) != null;
    final bool hasDescription =
        _nullIfEmpty(_lorebookDescriptionController.text) != null;

    if (hasName && hasDescription) {
      return l10n?.lorebookMetaSummaryFilled ??
          'Name and summary are filled in.';
    }
    if (hasName || hasDescription) {
      return l10n?.lorebookMetaSummaryPartial ??
          'One advanced field is filled in.';
    }
    return l10n?.lorebookMetaSummaryEmpty ??
        'Collapsed by default. Expand only if you need it.';
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final bool hasLorebook = _buildLorebookDraft() != null;
    final bool hasAvatar = (_draftCharacter.avatarPath ?? '').trim().isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      backgroundColor: AppTheme.bgElevated,
      child: SizedBox(
        width: 920,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.characterWorkbenchTitle ??
                                'Character Workbench',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n?.characterWorkbenchDescription ??
                                'Tune the card body, portrait, and worldbook entries here. All changes are saved into the local library.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      child: Text(l10n?.cancelButton ?? 'Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(
                        _saving
                            ? (l10n?.savingButton ?? 'Saving...')
                            : (l10n?.saveButton ?? 'Save'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CharacterCoverArt(
                        character: _draftCharacter.copyWith(
                          name: _nameController.text.trim().isEmpty
                              ? _draftCharacter.name
                              : _nameController.text.trim(),
                          scenario: _scenarioController.text.trim().isEmpty
                              ? _draftCharacter.scenario
                              : _scenarioController.text.trim(),
                        ),
                        height: 220,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CharacterAvatar(
                            character: _draftCharacter,
                            size: 72,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.trim().isEmpty
                                      ? _draftCharacter.name
                                      : _nameController.text.trim(),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  hasAvatar
                                      ? (l10n?.characterPortraitImportedHint ??
                                          'This role card already includes its original portrait art.')
                                      : (l10n
                                              ?.characterPortraitAutoImportHint ??
                                          'If you import a Tavern PNG card, Aura carries the art over automatically. The built-in cinematic cover is only used when no image exists.'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title:
                      l10n?.characterCoreFieldsTitle ?? 'Core Card Fields',
                  subtitle: l10n?.characterCoreFieldsDescription ??
                      'These fields define the role summary, scene setup, and opening momentum.',
                  child: Column(
                    children: [
                      _field(
                          l10n?.characterNameLabel ?? 'Name', _nameController),
                      _field(
                        l10n?.characterDescriptionLabel ?? 'Description',
                        _descriptionController,
                        maxLines: 4,
                      ),
                      _field(
                        l10n?.characterPersonalityLabel ?? 'Personality',
                        _personalityController,
                        maxLines: 4,
                      ),
                      _field(
                        l10n?.characterScenarioLabel ?? 'Scenario',
                        _scenarioController,
                        maxLines: 4,
                      ),
                      _field(
                        l10n?.characterFirstMessageLabel ?? 'First Message',
                        _firstMessageController,
                        maxLines: 5,
                      ),
                      _field(
                        l10n?.characterExamplesLabel ?? 'Example Dialogues',
                        _examplesController,
                        maxLines: 6,
                        helperText: l10n?.blankLineSeparatedHint ??
                            'Separate each block with a blank line.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: l10n?.characterAdvancedFieldsTitle ??
                      'Tavern Advanced Fields',
                  subtitle: l10n?.characterAdvancedFieldsDescription ??
                      'These fields feed directly into alternate greetings, prompt overrides, and next-turn reply constraints.',
                  child: Column(
                    children: [
                      _field(
                        l10n?.characterAlternateGreetingsLabel ??
                            'Alternate Greetings',
                        _alternateGreetingsController,
                        maxLines: 4,
                        helperText: l10n?.blankLineSeparatedHint ??
                            'Separate each block with a blank line.',
                      ),
                      _field(
                        l10n?.characterCreatorNotesLabel ?? 'Creator Notes',
                        _creatorNotesController,
                        maxLines: 4,
                      ),
                      _field(
                        l10n?.characterMainPromptLabel ??
                            'Main Prompt Override',
                        _mainPromptController,
                        maxLines: 5,
                      ),
                      _field(
                        l10n?.characterPostHistoryInstructionsLabel ??
                            'Post-History Instructions',
                        _postHistoryInstructionsController,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: l10n?.characterLorebookTitle ?? 'Lorebook / Worldbook',
                  subtitle: l10n?.characterLorebookDescription ??
                      'Import standalone worldbooks or manage entries directly here. Imported worldbooks merge by default instead of overwriting existing lore.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasLorebook
                            ? (l10n?.lorebookAttachedLabel(
                                    _draftLorebookEntries.length) ??
                                'Attached lorebook (${_draftLorebookEntries.length} entries)')
                            : (l10n?.lorebookMissingLabel ??
                                'No lorebook attached yet.'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (_lorebookError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _lorebookError!,
                          style: const TextStyle(color: AppTheme.statusDanger),
                        ),
                      ],
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: (_saving || _importingLorebook)
                                ? null
                                : _importLorebook,
                            icon: _importingLorebook
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.library_books_outlined),
                            label: Text(
                              hasLorebook
                                  ? (l10n?.importMergeWorldbookButton ??
                                      'Import & Merge Worldbook')
                                  : (l10n?.importLorebookButton ??
                                      'Import Lorebook'),
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: _saving ? null : _addLorebookEntry,
                            icon: const Icon(Icons.add_rounded),
                            label: Text(
                              l10n?.addLorebookEntryButton ?? 'Add Entry',
                            ),
                          ),
                          if (hasLorebook)
                            OutlinedButton.icon(
                              onPressed: (_saving || _importingLorebook)
                                  ? null
                                  : _removeLorebook,
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: Text(
                                l10n?.removeLorebookButton ?? 'Remove Lorebook',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _CompactDisclosurePanel(
                        toggleKey: const ValueKey<String>(
                            'lorebook-meta-panel-toggle'),
                        expanded: _lorebookMetaExpanded,
                        title: l10n?.lorebookMetaPanelTitle ??
                            'Worldbook Name & Summary',
                        summary: _lorebookMetaSummary(l10n),
                        onToggle: () {
                          setState(() {
                            _lorebookMetaExpanded = !_lorebookMetaExpanded;
                          });
                        },
                        child: Column(
                          children: <Widget>[
                            _field(
                              l10n?.worldbookNameLabel ?? 'Worldbook Name',
                              _lorebookNameController,
                            ),
                            _field(
                              l10n?.worldbookDescriptionLabel ??
                                  'Worldbook Description',
                              _lorebookDescriptionController,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LorebookEntryPanel(
                        expanded: _lorebookEntriesExpanded,
                        hasEntries: _draftLorebookEntries.isNotEmpty,
                        title:
                            l10n?.lorebookEntriesTitle ?? 'Worldbook Entries',
                        collapsedHint: _draftLorebookEntries.isEmpty
                            ? (l10n?.lorebookEntriesCollapsedEmptyHint ??
                                'Collapsed by default so giant worldbooks do not flood the whole workbench.')
                            : (l10n?.lorebookEntriesCollapsedHint ??
                                'Tap to reveal and manage every entry.'),
                        entryCountLabel:
                            l10n?.lorebookEntryCount(_draftLorebookEntries.length) ??
                                '${_draftLorebookEntries.length} entries',
                        onToggle: () {
                          setState(() {
                            _lorebookEntriesExpanded =
                                !_lorebookEntriesExpanded;
                          });
                        },
                        child: _draftLorebookEntries.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgCard,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.borderSubtle,
                                  ),
                                ),
                                child: Text(
                                  l10n?.lorebookEntriesEmptyState ??
                                      'No entries yet. Import a Tavern worldbook or add keyword-triggered scene notes manually.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                              )
                            : Column(
                                children: [
                                  for (int index = 0;
                                      index < _draftLorebookEntries.length;
                                      index += 1) ...[
                                    _LorebookEntryCard(
                                      entry: _draftLorebookEntries[index],
                                      index: index,
                                      onEdit: () => _editLorebookEntry(index),
                                      onDelete: () =>
                                          _deleteLorebookEntry(index),
                                    ),
                                    if (index !=
                                        _draftLorebookEntries.length - 1)
                                      const SizedBox(height: 10),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
        ),
      ),
    );
  }
}

class _CompactDisclosurePanel extends StatelessWidget {
  const _CompactDisclosurePanel({
    required this.toggleKey,
    required this.expanded,
    required this.title,
    required this.summary,
    required this.onToggle,
    required this.child,
  });

  final Key toggleKey;
  final bool expanded;
  final String title;
  final String summary;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: <Widget>[
          InkWell(
            key: toggleKey,
            borderRadius: BorderRadius.circular(18),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                    height: 1.4,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: child,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.title,
    this.subtitle,
  });

  final String? title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((title ?? '').trim().isNotEmpty) ...[
            Text(title!, style: Theme.of(context).textTheme.titleMedium),
            if ((subtitle ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textSecondary, height: 1.4),
              ),
            ],
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _LorebookEntryPanel extends StatelessWidget {
  const _LorebookEntryPanel({
    required this.expanded,
    required this.hasEntries,
    required this.title,
    required this.collapsedHint,
    required this.entryCountLabel,
    required this.onToggle,
    required this.child,
  });

  final bool expanded;
  final bool hasEntries;
  final String title;
  final String collapsedHint;
  final String entryCountLabel;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: const ValueKey<String>('lorebook-entry-panel-toggle'),
            borderRadius: BorderRadius.circular(18),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expanded ? entryCountLabel : collapsedHint,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                    height: 1.4,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (hasEntries && expanded)
                    Text(
                      entryCountLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: child,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _LorebookEntryCard extends StatelessWidget {
  const _LorebookEntryCard({
    required this.entry,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final LorebookEntry entry;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.id.trim().isEmpty
                      ? (l10n?.lorebookEntryFallbackLabel(index + 1) ??
                          'Entry ${index + 1}')
                      : entry.id,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n?.editEntryTooltip ?? 'Edit entry',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.statusDanger,
                ),
                tooltip: l10n?.deleteEntryTooltip ?? 'Delete entry',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final String keyword in entry.keywords.take(6))
                _EntryTag(label: keyword),
              if (entry.secondaryKeywords.isNotEmpty)
                _EntryTag(
                  label: l10n?.secondaryKeywordsTag(
                        entry.secondaryKeywords.take(4).join(' / '),
                      ) ??
                      'Secondary ${entry.secondaryKeywords.take(4).join(' / ')}',
                  highlighted: true,
                ),
              _EntryTag(
                label: l10n?.priorityTag(entry.priority.toString()) ??
                    'Priority ${entry.priority}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.content,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _EntryTag extends StatelessWidget {
  const _EntryTag({required this.label, this.highlighted = false});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final Color accent =
        highlighted ? AppTheme.brandAura : AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: accent),
      ),
    );
  }
}

class _LorebookEntryEditorDialog extends StatefulWidget {
  const _LorebookEntryEditorDialog({this.entry});

  final LorebookEntry? entry;

  @override
  State<_LorebookEntryEditorDialog> createState() =>
      _LorebookEntryEditorDialogState();
}

class _LorebookEntryEditorDialogState
    extends State<_LorebookEntryEditorDialog> {
  late final TextEditingController _idController;
  late final TextEditingController _keywordsController;
  late final TextEditingController _secondaryKeywordsController;
  late final TextEditingController _contentController;
  late final TextEditingController _commentController;
  late final TextEditingController _priorityController;
  late bool _enabled;
  late bool _selective;
  late bool _constant;
  late bool _matchWholeWords;
  late bool _caseSensitive;

  @override
  void initState() {
    super.initState();
    final LorebookEntry? entry = widget.entry;
    _idController = TextEditingController(text: entry?.id ?? '');
    _keywordsController = TextEditingController(
      text: (entry?.keywords ?? const <String>[]).join(', '),
    );
    _secondaryKeywordsController = TextEditingController(
      text: (entry?.secondaryKeywords ?? const <String>[]).join(', '),
    );
    _contentController = TextEditingController(text: entry?.content ?? '');
    _commentController = TextEditingController(text: entry?.comment ?? '');
    _priorityController =
        TextEditingController(text: (entry?.priority ?? 0).toString());
    _enabled = entry?.enabled ?? true;
    _selective = entry?.selective ?? false;
    _constant = entry?.constant ?? false;
    _matchWholeWords = entry?.matchWholeWords ?? false;
    _caseSensitive = entry?.caseSensitive ?? false;
  }

  @override
  void dispose() {
    _idController.dispose();
    _keywordsController.dispose();
    _secondaryKeywordsController.dispose();
    _contentController.dispose();
    _commentController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  List<String> _splitCsv(String input) {
    return input
        .split(',')
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  void _submit() {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final List<String> keywords = _splitCsv(_keywordsController.text);
    if (keywords.isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.lorebookEntryValidationError ??
                'Please provide at least keywords and content.',
          ),
        ),
      );
      return;
    }
    final LorebookEntry original = widget.entry ??
        const LorebookEntry(
          id: '',
          content: '',
          keywords: <String>[],
        );
    Navigator.of(context).pop(
      LorebookEntry(
        id: _idController.text.trim().isEmpty
            ? (original.id.isEmpty
                ? 'entry-${DateTime.now().microsecondsSinceEpoch}'
                : original.id)
            : _idController.text.trim(),
        content: _contentController.text.trim(),
        keywords: keywords,
        secondaryKeywords: _splitCsv(_secondaryKeywordsController.text),
        enabled: _enabled,
        caseSensitive: _caseSensitive,
        priority: int.tryParse(_priorityController.text.trim()) ?? 0,
        insertionOrder: original.insertionOrder,
        selective: _selective,
        constant: _constant,
        matchWholeWords: _matchWholeWords,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        extensions: original.extensions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: AppTheme.bgElevated,
      title: Text(
        l10n?.lorebookEntryEditorTitle ?? 'Edit Worldbook Entry',
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: l10n?.lorebookEntryIdLabel ?? 'Entry ID',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _keywordsController,
                decoration: InputDecoration(
                  labelText: l10n?.lorebookEntryPrimaryKeywordsLabel ??
                      'Primary Keywords',
                  helperText: l10n?.lorebookEntryPrimaryKeywordsHelper ??
                      'Comma-separated, for example: zhongli, contract, liyue',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _secondaryKeywordsController,
                decoration: InputDecoration(
                  labelText: l10n?.lorebookEntrySecondaryKeywordsLabel ??
                      'Secondary Keywords',
                  helperText:
                      l10n?.lorebookEntrySecondaryKeywordsHelper ??
                          'Optional, comma-separated.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText:
                      l10n?.lorebookEntryContentLabel ?? 'Entry Content',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n?.lorebookEntryCommentLabel ?? 'Comment',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priorityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      l10n?.lorebookEntryPriorityLabel ?? 'Priority',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: _enabled,
                onChanged: (bool value) => setState(() => _enabled = value),
                title: Text(
                  l10n?.lorebookEntryEnabledLabel ?? 'Enable Entry',
                ),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile.adaptive(
                value: _selective,
                onChanged: (bool value) => setState(() => _selective = value),
                title: Text(
                  l10n?.lorebookEntrySelectiveLabel ??
                      'Require Secondary Keywords',
                ),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile.adaptive(
                value: _constant,
                onChanged: (bool value) => setState(() => _constant = value),
                title: Text(
                  l10n?.lorebookEntryConstantLabel ?? 'Always Inject',
                ),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile.adaptive(
                value: _matchWholeWords,
                onChanged: (bool value) =>
                    setState(() => _matchWholeWords = value),
                title: Text(
                  l10n?.lorebookEntryWholeWordLabel ?? 'Whole Word Match',
                ),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile.adaptive(
                value: _caseSensitive,
                onChanged: (bool value) =>
                    setState(() => _caseSensitive = value),
                title: Text(
                  l10n?.lorebookEntryCaseSensitiveLabel ?? 'Case Sensitive',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.cancelButton ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n?.saveEntryButton ?? 'Save Entry'),
        ),
      ],
    );
  }
}
