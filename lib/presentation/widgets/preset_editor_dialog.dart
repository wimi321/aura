import 'package:aura_core/aura_core.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/providers/app_state_provider.dart';
import '../utils/preset_localization.dart';

class PresetEditorDialog extends StatefulWidget {
  const PresetEditorDialog({
    super.key,
    required this.preset,
  });

  final Preset preset;

  @override
  State<PresetEditorDialog> createState() => _PresetEditorDialogState();
}

class _PresetEditorDialogState extends State<PresetEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _promptController;
  late final TextEditingController _temperatureController;
  late final TextEditingController _topPController;
  late final TextEditingController _topKController;
  late final TextEditingController _maxTokensController;
  bool _saving = false;
  bool _didSeedLocalizedDefaults = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset.name);
    _promptController =
        TextEditingController(text: widget.preset.systemPromptTemplate);
    _temperatureController = TextEditingController(text: widget.preset.generationConfig.temperature.toString());
    _topPController = TextEditingController(text: widget.preset.generationConfig.topP.toString());
    _topKController = TextEditingController(text: widget.preset.generationConfig.topK.toString());
    _maxTokensController = TextEditingController(text: widget.preset.generationConfig.maxOutputTokens.toString());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSeedLocalizedDefaults) {
      return;
    }
    _didSeedLocalizedDefaults = true;
    _nameController.text = localizedPresetName(context, widget.preset);
    _promptController.text =
        localizedPresetPromptTemplate(context, widget.preset);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    _temperatureController.dispose();
    _topPController.dispose();
    _topKController.dispose();
    _maxTokensController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
    });
    final Preset preset = Preset(
      id: widget.preset.id,
      name: _nameController.text.trim(),
      systemPromptTemplate: _promptController.text.trim(),
      generationConfig: GenerationConfig(
        temperature: double.tryParse(_temperatureController.text.trim()) ?? widget.preset.generationConfig.temperature,
        topP: double.tryParse(_topPController.text.trim()) ?? widget.preset.generationConfig.topP,
        topK: int.tryParse(_topKController.text.trim()) ?? widget.preset.generationConfig.topK,
        maxOutputTokens: int.tryParse(_maxTokensController.text.trim()) ?? widget.preset.generationConfig.maxOutputTokens,
        repetitionPenalty: widget.preset.generationConfig.repetitionPenalty,
        stopSequences: widget.preset.generationConfig.stopSequences,
      ),
      metadata: <String, Object?>{
        ...widget.preset.metadata,
        'edited': true,
      },
    );
    await context.read<AppStateProvider>().savePreset(preset);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Dialog(
      child: SizedBox(
        width: 680,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n?.editPromptPresetTitle ?? 'Edit Prompt Preset',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _field(
                  l10n?.presetNameFieldLabel ?? 'Preset Name',
                  _nameController,
                ),
                _field(
                  l10n?.presetSystemPromptFieldLabel ?? 'System Prompt',
                  _promptController,
                  maxLines: 10,
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _field(
                        l10n?.presetTemperatureFieldLabel ?? 'Temperature',
                        _temperatureController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        l10n?.presetTopPFieldLabel ?? 'Top P',
                        _topPController,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _field(
                        l10n?.presetTopKFieldLabel ?? 'Top K',
                        _topKController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        l10n?.presetMaxOutputTokensFieldLabel ??
                            'Max Output Tokens',
                        _maxTokensController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
