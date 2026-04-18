import 'dart:io';
import 'dart:typed_data';

import 'package:aura_app/l10n/generated/app_localizations.dart';
import 'package:aura_core/aura_core.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/providers/app_state_provider.dart';
import '../../backend/services/character_card_photo_picker.dart';
import '../../backend/services/character_library_store.dart';
import '../../core/platform/file_selector_type_groups.dart';
import '../../core/theme/app_theme.dart';
import 'character_editor_dialog.dart';

enum _ImportSource { photos, files }

class ImportPreviewDialog extends StatefulWidget {
  const ImportPreviewDialog({
    super.key,
    this.pickFile,
    this.pickPhotoFile,
    this.previewLoader,
    this.lorebookPreviewLoader,
    this.importAction,
    this.createCharacterAction,
  });

  final Future<XFile?> Function()? pickFile;
  final Future<File?> Function()? pickPhotoFile;
  final Future<CharacterImportPreview> Function(File sourceFile)? previewLoader;
  final Future<LorebookImportPreview> Function(File sourceFile)?
      lorebookPreviewLoader;
  final Future<CharacterCard> Function(CharacterImportPreview preview)?
      importAction;
  final Future<CharacterCard?> Function(BuildContext context)?
      createCharacterAction;

  @override
  State<ImportPreviewDialog> createState() => _ImportPreviewDialogState();
}

class _ImportPreviewDialogState extends State<ImportPreviewDialog> {
  static const CharacterCardPhotoPicker _photoPicker =
      CharacterCardPhotoPicker();
  static const List<int> _pngSignature = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ];

  CharacterImportPreview? _preview;
  LorebookImportPreview? _lorebookPreview;
  bool _busy = false;
  bool _pickingFile = false;
  String? _error;
  String? _selectedLorebookTargetCharacterId;

  Future<void> _createCharacter() async {
    final Future<CharacterCard?> Function(BuildContext context)
        createCharacterAction =
        widget.createCharacterAction ?? _showCreateCharacterDialog;
    final CharacterCard? created = await createCharacterAction(context);
    if (!mounted || created == null) {
      return;
    }
    Navigator.pop(context, created);
  }

  Future<CharacterCard?> _showCreateCharacterDialog(
      BuildContext context) async {
    CharacterCard? createdCharacter;
    await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CharacterEditorDialog(
          character: _starterCharacter(dialogContext),
          onSaved: (CharacterCard value) {
            createdCharacter = value;
          },
        );
      },
    );
    return createdCharacter;
  }

  Future<void> _pickAndParse() async {
    if (_busy || _pickingFile) {
      return;
    }
    final _ImportSource? source = await _chooseImportSource();
    if (source == null) {
      return;
    }
    await _pickAndParseFromSource(source);
  }

  Future<void> _pickAndParseFromSource(_ImportSource source) async {
    if (_busy || _pickingFile) {
      return;
    }
    final AppStateProvider appState = context.read<AppStateProvider>();
    final Future<CharacterImportPreview> Function(File sourceFile)
        previewLoader = widget.previewLoader ?? appState.previewCharacterImport;
    final Future<LorebookImportPreview> Function(File sourceFile)
        lorebookPreviewLoader =
        widget.lorebookPreviewLoader ?? appState.previewLorebookImport;
    setState(() {
      _pickingFile = true;
      _error = null;
    });

    final File? sourceFile;
    try {
      sourceFile = await _pickSourceFile(source);
      if (sourceFile != null && source == _ImportSource.photos) {
        await _ensurePhotoImportIsPng(sourceFile);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pickingFile = false;
        _busy = false;
        _error = _friendlyErrorMessage(error);
      });
      return;
    }
    if (sourceFile == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pickingFile = false;
        _busy = false;
      });
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _pickingFile = false;
      _busy = true;
    });
    try {
      final CharacterImportPreview preview = await previewLoader(sourceFile);
      await _importCharacterDirectly(preview);
      return;
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (error.toString().contains('standalone worldbook')) {
        try {
          final LorebookImportPreview lorebookPreview =
              await lorebookPreviewLoader(sourceFile);
          if (!mounted) {
            return;
          }
          setState(() {
            _preview = null;
            _lorebookPreview = lorebookPreview;
            _selectedLorebookTargetCharacterId ??=
                appState.availableCharacters.isEmpty
                    ? null
                    : appState.availableCharacters.first.id;
            _busy = false;
            _error = null;
          });
          return;
        } catch (lorebookError) {
          setState(() {
            _busy = false;
            _error = _friendlyErrorMessage(lorebookError);
          });
          return;
        }
      }
      setState(() {
        _busy = false;
        _error = _friendlyErrorMessage(error);
      });
    }
  }

  Future<void> _importCharacterDirectly(CharacterImportPreview preview) async {
    final AppStateProvider appState = context.read<AppStateProvider>();
    try {
      final Future<CharacterCard> Function(CharacterImportPreview preview)
          importAction = widget.importAction ?? appState.importCharacterPreview;
      final CharacterCard imported = await importAction(preview);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, imported);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = _friendlyErrorMessage(error);
      });
    }
  }

  bool get _supportsPhotoImport {
    if (widget.pickPhotoFile != null) {
      return true;
    }
    return Platform.isIOS || Platform.isAndroid;
  }

  Future<_ImportSource?> _chooseImportSource() async {
    if (!_supportsPhotoImport) {
      return _ImportSource.files;
    }
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return showModalBottomSheet<_ImportSource>(
      context: context,
      backgroundColor: AppTheme.cardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.importSourceSheetTitle ?? 'Choose Import Source',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n?.importSourceSheetSubtitle ??
                        'Photos are for Tavern PNG cards already saved to your gallery. Files support Tavern PNG and JSON cards.',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildImportSourceTile(
                    context: sheetContext,
                    icon: Icons.photo_library_rounded,
                    title: l10n?.importFromPhotosTitle ?? 'Import From Photos',
                    subtitle: l10n?.importFromPhotosSubtitle ??
                        'Pick a Tavern PNG card that is already in your photo library.',
                    source: _ImportSource.photos,
                  ),
                  const SizedBox(height: 10),
                  _buildImportSourceTile(
                    context: sheetContext,
                    icon: Icons.folder_open_rounded,
                    title: l10n?.importFromFilesTitle ?? 'Import From Files',
                    subtitle: l10n?.importFromFilesSubtitle ??
                        'Pick a Tavern PNG card, JSON card, or standalone worldbook from Files.',
                    source: _ImportSource.files,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImportSourceTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required _ImportSource source,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.pop(context, source),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.ink,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<File?> _pickSourceFile(_ImportSource source) async {
    switch (source) {
      case _ImportSource.photos:
        return widget.pickPhotoFile?.call() ?? _pickPhotoFile();
      case _ImportSource.files:
        final XFile? picked = await (widget.pickFile?.call() ??
            openFile(
              acceptedTypeGroups: characterCardImportTypeGroups,
            ));
        return picked == null ? null : File(picked.path);
    }
  }

  Future<File?> _pickPhotoFile() async {
    return _photoPicker.pick();
  }

  Future<void> _ensurePhotoImportIsPng(File sourceFile) async {
    final RandomAccessFile handle = await sourceFile.open();
    try {
      final Uint8List signature = await handle.read(_pngSignature.length);
      if (signature.length != _pngSignature.length) {
        throw StateError('photo import expects png');
      }
      for (int index = 0; index < _pngSignature.length; index += 1) {
        if (signature[index] != _pngSignature[index]) {
          throw StateError('photo import expects png');
        }
      }
    } finally {
      await handle.close();
    }
  }

  Future<void> _confirmImport() async {
    final CharacterImportPreview? preview = _preview;
    final LorebookImportPreview? lorebookPreview = _lorebookPreview;
    if (preview == null && lorebookPreview == null) {
      return;
    }
    final AppStateProvider appState = context.read<AppStateProvider>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      late final CharacterCard imported;
      if (preview != null) {
        final Future<CharacterCard> Function(CharacterImportPreview preview)
            importAction =
            widget.importAction ?? appState.importCharacterPreview;
        imported = await importAction(preview);
      } else {
        final String? characterId = _selectedLorebookTargetCharacterId;
        if (characterId == null || characterId.isEmpty) {
          throw StateError(_isChineseUi(context)
              ? '请先选择要挂载世界书的角色。'
              : 'Choose a role card before attaching the worldbook.');
        }
        imported = await appState.attachLorebookToCharacter(
          characterId: characterId,
          preview: lorebookPreview!,
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.pop(context, imported);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = _friendlyErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final CharacterImportPreview? preview = _preview;
    final LorebookImportPreview? lorebookPreview = _lorebookPreview;
    final bool isWorldbookFlow = lorebookPreview != null;
    final bool isLocked = _busy || _pickingFile;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppTheme.cardElevated,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: AppTheme.ink,
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: const Icon(
                        Icons.library_add_rounded,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.importPreviewTitle ?? 'Import Story Card',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n?.importDialogDescription ??
                                'Tavern and SillyTavern cards import straight into the library. Standalone worldbooks can be attached to a role card in the next step.',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_busy)
                  _buildLoadingState(l10n)
                else if (preview != null)
                  _buildPreviewState(context, preview, l10n)
                else if (lorebookPreview != null)
                  _buildLorebookPreviewState(context, lorebookPreview, l10n)
                else if (_error != null)
                  _buildErrorState(l10n)
                else
                  _buildEmptyState(context, l10n),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    TextButton(
                      onPressed: isLocked ? null : () => Navigator.pop(context),
                      child: Text(l10n?.cancelButton ?? 'Cancel'),
                    ),
                    if (preview == null && lorebookPreview == null)
                      OutlinedButton.icon(
                        onPressed: isLocked ? null : () => _createCharacter(),
                        icon: const Icon(Icons.draw_rounded, size: 18),
                        label: Text(
                          l10n?.createCharacterButton ?? 'Create Character',
                        ),
                      ),
                    if (preview != null || lorebookPreview != null)
                      OutlinedButton(
                        onPressed: isLocked ? null : _pickAndParse,
                        child: Text(
                          l10n?.chooseAnotherCardButton ??
                              'Choose Another Image or File',
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: isLocked
                          ? null
                          : (preview == null && lorebookPreview == null
                              ? _pickAndParse
                              : isWorldbookFlow
                                  ? _confirmImport
                                  : null),
                      icon: Icon(
                        isWorldbookFlow
                            ? Icons.library_books_rounded
                            : preview == null
                                ? Icons.upload_file_rounded
                                : Icons.upload_file_rounded,
                        size: 18,
                      ),
                      label: Text(
                        isWorldbookFlow
                            ? (l10n?.attachWorldbookButton ??
                                'Attach Worldbook')
                            : (l10n?.chooseCardButton ??
                                'Choose Image or File'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations? l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.ink,
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.importingCardText ?? 'Parsing character card...',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations? l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.ink,
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.importEmptyStateIntro ??
                'Choose an import source first: Photos are for Tavern PNG cards already saved to your gallery, while Files support Tavern or SillyTavern PNG cards, JSON cards, and standalone worldbooks. Cards with embedded worldbooks come in one step.',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _tag('PNG'),
              _tag('JSON'),
              _tag(l10n?.importPreviewRoleCardTag ?? 'Story Card'),
              _tag(l10n?.embeddedWorldbookTag ?? 'Embedded Worldbook'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.importEmptyStateDetails ??
                'Aura will automatically preserve `character_book` world info, greetings, prompt overrides, and scene notes when the card includes them.',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.importCreateCharacterHint ??
                'No existing role card yet? You can also create one from scratch here.',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations? l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0x26FF8F8F),
        border: Border.all(color: const Color(0x55FF8F8F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 22,
                color: Color(0xFFFFB3B3),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n?.importErrorTitle ?? 'Unable to import this file',
                  style: const TextStyle(
                    color: Color(0xFFFFD3D3),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _error ?? '',
            style: const TextStyle(
              color: Color(0xFFFFD3D3),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewState(
    BuildContext context,
    CharacterImportPreview preview,
    AppLocalizations? l10n,
  ) {
    final CharacterCard character = preview.character;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.ink,
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatarPreview(character),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _tag(
                          _isJsonFile(preview.fileName) ? 'JSON' : 'PNG',
                        ),
                        if (preview.hasLorebook)
                          _tag(
                            _isChineseUi(context)
                                ? '内置世界书 ${character.lorebook?.entries.length ?? 0}'
                                : 'Embedded Worldbook ${character.lorebook?.entries.length ?? 0}',
                            highlighted: true,
                          ),
                        if (character.alternateGreetings.isNotEmpty)
                          _tag(
                            _isChineseUi(context)
                                ? '多开场白 ${character.alternateGreetings.length}'
                                : 'Alt Greetings ${character.alternateGreetings.length}',
                          ),
                        if ((character.mainPromptOverride ?? '')
                            .trim()
                            .isNotEmpty)
                          _tag(
                            _isChineseUi(context)
                                ? '内置主提示词'
                                : 'Card Main Prompt',
                          ),
                        if ((character.postHistoryInstructions ?? '')
                            .trim()
                            .isNotEmpty)
                          _tag(
                            _isChineseUi(context)
                                ? '回复后置指令'
                                : 'Post-History Note',
                          ),
                      ],
                    ),
                    if ((character.creator ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${l10n?.importCreatorLabel ?? 'Creator'}: ${character.creator}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _previewBlock(
            title: _isChineseUi(context) ? '导入后保留' : 'Imported As-Is',
            content: _isChineseUi(context)
                ? '开场白 / 备用开场 / 场景设定 / 角色人设 / 内置世界书 / 主提示词覆盖 / 回复后置规则'
                : 'Opening message / alternate greetings / scenario / persona / embedded worldbook / main prompt override / post-history rules',
          ),
          const SizedBox(height: 12),
          _previewBlock(
            title: l10n?.characterDescriptionLabel ?? 'Description',
            content: character.description.trim().isEmpty
                ? (l10n?.importNoDescriptionLabel ??
                    'This card does not include a description.')
                : character.description,
          ),
          const SizedBox(height: 12),
          _previewBlock(
            title: _isChineseUi(context) ? '角色性格' : 'Personality',
            content: character.personality.trim().isEmpty
                ? (_isChineseUi(context)
                    ? '这张卡没有单独写出性格字段。'
                    : 'This card does not include a dedicated personality field.')
                : character.personality,
          ),
          const SizedBox(height: 12),
          _previewBlock(
            title: _isChineseUi(context) ? '当前剧情场景' : 'Scenario',
            content: character.scenario.trim().isEmpty
                ? (_isChineseUi(context)
                    ? '这张卡没有单独写出场景字段。'
                    : 'This card does not include a scenario field.')
                : character.scenario,
          ),
          const SizedBox(height: 12),
          _previewBlock(
            title: l10n?.characterFirstMessageLabel ?? 'First Message',
            content: (character.preferredOpeningMessage ?? '').trim().isEmpty
                ? (l10n?.importNoFirstMessageLabel ??
                    'This card does not include a first message.')
                : character.preferredOpeningMessage!,
          ),
          if ((character.creatorNotes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _previewBlock(
              title: _isChineseUi(context) ? '作者注记' : 'Creator Notes',
              content: character.creatorNotes!.trim(),
            ),
          ],
          if (character.alternateGreetings.isNotEmpty) ...[
            const SizedBox(height: 12),
            _previewBlock(
              title: _isChineseUi(context) ? '备用开场预览' : 'Alternate Greetings',
              content: character.alternateGreetings.take(3).join('\n\n'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLorebookPreviewState(
    BuildContext context,
    LorebookImportPreview preview,
    AppLocalizations? l10n,
  ) {
    final AppStateProvider appState = context.watch<AppStateProvider>();
    final List<CharacterCard> characters = appState.availableCharacters;
    final String? selectedCharacterId = _selectedLorebookTargetCharacterId ??
        (characters.isEmpty ? null : characters.first.id);
    final CharacterCard? targetCharacter = selectedCharacterId == null
        ? null
        : appState.characterById(selectedCharacterId);
    final int existingLoreCount =
        targetCharacter?.lorebook?.entries.length ?? 0;
    final int incomingLoreCount = preview.lorebook.entries.length;
    final int mergedLoreCount = _mergedLorebookEntryCount(
      targetCharacter?.lorebook,
      preview.lorebook,
    );
    final String helperText = _isChineseUi(context)
        ? existingLoreCount == 0
            ? '已识别为独立世界书。选择一个角色后，Aura 会把这份设定直接挂上去。'
            : '已识别为独立世界书。Aura 会把它与该角色现有世界书合并，不会覆盖原本设定。'
        : existingLoreCount == 0
            ? 'Aura recognized this file as a standalone worldbook. Pick a role card and attach it directly.'
            : 'Aura recognized this file as a standalone worldbook. It will merge with the role card lore instead of overwriting it.';
    final String entryLabel = _isChineseUi(context)
        ? '词条 ${preview.lorebook.entries.length}'
        : '${preview.lorebook.entries.length} entries';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.ink,
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: AppTheme.cardElevated,
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: const Icon(
                  Icons.library_books_rounded,
                  color: AppTheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview.lorebook.name?.trim().isNotEmpty == true
                          ? preview.lorebook.name!
                          : (_isChineseUi(context)
                              ? '独立世界书'
                              : 'Standalone Worldbook'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _tag('JSON'),
                        _tag(entryLabel, highlighted: true),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      helperText,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _previewBlock(
            title: _isChineseUi(context) ? '挂载到角色' : 'Attach To',
            content: selectedCharacterId == null
                ? (_isChineseUi(context)
                    ? '当前没有可挂载的角色。'
                    : 'No role cards are available yet.')
                : targetCharacter!.name,
          ),
          if (characters.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedCharacterId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: _isChineseUi(context) ? '选择角色' : 'Choose Role Card',
              ),
              items: characters
                  .map(
                    (CharacterCard card) => DropdownMenuItem<String>(
                      value: card.id,
                      child: Text(
                        card.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _busy
                  ? null
                  : (String? value) {
                      setState(() {
                        _selectedLorebookTargetCharacterId = value;
                      });
                    },
            ),
          ],
          if (selectedCharacterId != null) ...[
            const SizedBox(height: 12),
            _previewBlock(
              title: _isChineseUi(context) ? '合并结果' : 'Merge Result',
              content: _isChineseUi(context)
                  ? '当前角色已有 $existingLoreCount 条，导入文件有 $incomingLoreCount 条，合并后预计保留 $mergedLoreCount 条。'
                  : 'Current role has $existingLoreCount entries, this file has $incomingLoreCount, and the merged card will keep about $mergedLoreCount entries.',
            ),
          ],
          if ((preview.lorebook.description?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 12),
            _previewBlock(
              title: _isChineseUi(context) ? '简介' : 'Description',
              content: preview.lorebook.description!.trim(),
            ),
          ],
          if (preview.lorebook.entries.isNotEmpty) ...[
            const SizedBox(height: 12),
            _previewBlock(
              title:
                  _isChineseUi(context) ? '世界书词条预览' : 'Worldbook Entry Preview',
              content:
                  preview.lorebook.entries.take(3).map((LorebookEntry entry) {
                final String keys = entry.keywords.take(4).join(' / ');
                return '[$keys]\n${entry.content.trim()}';
              }).join('\n\n'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatarPreview(CharacterCard character) {
    final String? avatarPath = character.avatarPath;
    final String trimmedName = character.name.trim();
    final String initial =
        trimmedName.isEmpty ? '?' : trimmedName.substring(0, 1);
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFA87A), Color(0xFF6EF2C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: avatarPath != null && File(avatarPath).existsSync()
            ? Image.file(
                File(avatarPath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(initial),
              )
            : _avatarFallback(initial),
      ),
    );
  }

  Widget _avatarFallback(String initial) {
    return Container(
      color: Colors.black.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _previewBlock({
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.cardElevated,
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, {bool highlighted = false}) {
    final Color borderColor =
        highlighted ? const Color(0xFF45E6B0) : AppTheme.borderSubtle;
    final Color textColor =
        highlighted ? const Color(0xFF45E6B0) : AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor.withValues(alpha: 0.65)),
        color: borderColor.withValues(alpha: highlighted ? 0.12 : 0.06),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  bool _isJsonFile(String fileName) => fileName.toLowerCase().endsWith('.json');

  CharacterCard _starterCharacter(BuildContext context) {
    final bool isChinese = _isChineseUi(context);
    return CharacterCard(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      name: isChinese ? '新角色' : 'New Character',
      description: isChinese
          ? '写下这个角色在剧情里的定位、关系和危险感。'
          : 'Write the role, relationship, and dramatic hook for this character.',
      personality: isChinese
          ? '保持角色视角，主动推进剧情，给出具体动作与情绪反馈。'
          : 'Stay in character, keep the scene moving, and respond with concrete actions and emotions.',
      scenario: isChinese
          ? '描述当前剧情开场、地点、冲突，以及你与用户的关系。'
          : 'Describe the opening scene, location, conflict, and the relationship with the player.',
      firstMessage: isChinese
          ? '门外的脚步声越来越近。既然你来了，我们就没有退路了。'
          : 'The footsteps outside are getting closer. Now that you are here, there is no easy way back.',
      exampleDialogues: const <String>[],
      alternateGreetings: <String>[
        isChinese ? '你来的比我预想得更快。' : 'You arrived sooner than I expected.',
      ],
      creator: 'Aura',
      mainPromptOverride: isChinese
          ? '{{original}}\n保持剧情向角色扮演，持续推进当前场景，补足动作、环境和情绪细节。'
          : '{{original}}\nKeep the experience story-first roleplay, keep the current scene moving, and add concrete actions, setting details, and emotional beats.',
      postHistoryInstructions: isChinese
          ? '始终延续当前剧情线，不要跳出角色，不要把回应写成总结。'
          : 'Always continue the current storyline, never break character, and do not turn replies into summaries.',
      extensions: const <String, Object?>{
        'user_created': true,
      },
    );
  }

  bool _isChineseUi(BuildContext context) {
    return Localizations.localeOf(context).languageCode.toLowerCase() == 'zh';
  }

  String _friendlyErrorMessage(Object error) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String message = error.toString();
    if (message.contains('standalone worldbook')) {
      return l10n?.importWorldbookErrorMessage ??
          'This file is a standalone worldbook. Open a character and import it from the lorebook section instead.';
    }
    if (message.contains('Unsupported file type')) {
      return l10n?.importUnsupportedFileMessage ??
          'Only Tavern PNG and JSON character cards are supported here.';
    }
    if (message.contains('photo import expects png')) {
      return l10n?.photoImportPngOnlyMessage ??
          'Photo import currently supports Tavern PNG cards only.';
    }
    if (message.contains('PNG does not contain character metadata.')) {
      return _isChineseUi(context)
          ? '这张 PNG 没有检测到角色卡元数据。若图片来自相册，请优先从“文件”导入原始角色卡 PNG。'
          : 'This PNG does not contain character card metadata. If it came from Photos, try importing the original Tavern PNG from Files.';
    }
    if (message.contains('does not look like a character card')) {
      return l10n?.importInvalidCharacterFileMessage ??
          'This file does not look like a supported character card.';
    }
    if (message
            .contains('Choose a role card before attaching the worldbook.') ||
        message.contains('请先选择要挂载世界书的角色。')) {
      return message;
    }
    return l10n?.importGenericErrorMessage ??
        'Import failed. Please try another character card file.';
  }

  int _mergedLorebookEntryCount(Lorebook? current, Lorebook incoming) {
    final Set<String> keys = <String>{};
    for (final LorebookEntry entry
        in current?.entries ?? const <LorebookEntry>[]) {
      keys.add(_lorebookEntryKey(entry));
    }
    for (final LorebookEntry entry in incoming.entries) {
      keys.add(_lorebookEntryKey(entry));
    }
    return keys.length;
  }

  String _lorebookEntryKey(LorebookEntry entry) {
    final List<String> values = <String>[
      entry.id.trim().toLowerCase(),
      ...entry.keywords.map((String value) => value.trim().toLowerCase()),
      ...entry.secondaryKeywords
          .map((String value) => value.trim().toLowerCase()),
      entry.content.trim().toLowerCase(),
    ]..sort();
    return values.join('|');
  }
}
