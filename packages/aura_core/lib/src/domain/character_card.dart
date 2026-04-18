import 'package:meta/meta.dart';

import '../utils/roleplay_text_formatter.dart';
import 'lorebook.dart';

@immutable
class CharacterCard {
  const CharacterCard({
    required this.id,
    required this.name,
    required this.description,
    required this.personality,
    required this.scenario,
    required this.firstMessage,
    required this.exampleDialogues,
    this.alternateGreetings = const <String>[],
    this.creator,
    this.creatorNotes,
    this.mainPromptOverride,
    this.postHistoryInstructions,
    this.avatarPath,
    this.lorebook,
    this.extensions = const <String, Object?>{},
    this.tags = const <String>[],
    this.characterVersion,
    this.spec,
    this.specVersion,
  });

  final String id;
  final String name;
  final String description;
  final String personality;
  final String scenario;
  final String firstMessage;
  final List<String> exampleDialogues;
  final List<String> alternateGreetings;
  final String? creator;
  final String? creatorNotes;
  final String? mainPromptOverride;
  final String? postHistoryInstructions;
  final String? avatarPath;
  final Lorebook? lorebook;
  final Map<String, Object?> extensions;
  final List<String> tags;
  final String? characterVersion;
  final String? spec;
  final String? specVersion;

  CharacterCard copyWith({
    String? id,
    String? name,
    String? description,
    String? personality,
    String? scenario,
    String? firstMessage,
    List<String>? exampleDialogues,
    List<String>? alternateGreetings,
    String? creator,
    String? creatorNotes,
    String? mainPromptOverride,
    String? postHistoryInstructions,
    String? avatarPath,
    Lorebook? lorebook,
    bool clearLorebook = false,
    Map<String, Object?>? extensions,
    List<String>? tags,
    String? characterVersion,
    String? spec,
    String? specVersion,
  }) {
    return CharacterCard(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      personality: personality ?? this.personality,
      scenario: scenario ?? this.scenario,
      firstMessage: firstMessage ?? this.firstMessage,
      exampleDialogues: exampleDialogues ?? this.exampleDialogues,
      alternateGreetings: alternateGreetings ?? this.alternateGreetings,
      creator: creator ?? this.creator,
      creatorNotes: creatorNotes ?? this.creatorNotes,
      mainPromptOverride: mainPromptOverride ?? this.mainPromptOverride,
      postHistoryInstructions:
          postHistoryInstructions ?? this.postHistoryInstructions,
      avatarPath: avatarPath ?? this.avatarPath,
      lorebook: clearLorebook ? null : (lorebook ?? this.lorebook),
      extensions: extensions ?? this.extensions,
      tags: tags ?? this.tags,
      characterVersion: characterVersion ?? this.characterVersion,
      spec: spec ?? this.spec,
      specVersion: specVersion ?? this.specVersion,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'description': description,
      'personality': personality,
      'scenario': scenario,
      'firstMessage': firstMessage,
      'exampleDialogues': exampleDialogues,
      'alternateGreetings': alternateGreetings,
      'creator': creator,
      'creatorNotes': creatorNotes,
      'mainPromptOverride': mainPromptOverride,
      'postHistoryInstructions': postHistoryInstructions,
      'avatarPath': avatarPath,
      'lorebook': lorebook?.toJson(),
      'extensions': extensions,
      'tags': tags,
      'characterVersion': characterVersion,
      'spec': spec,
      'specVersion': specVersion,
    };
  }

  factory CharacterCard.fromJson(Map<String, Object?> json) {
    return CharacterCard(
      id: json['id']?.toString() ?? 'unknown',
      name: json['name']?.toString() ?? 'Unknown Character',
      description: json['description']?.toString() ?? '',
      personality: json['personality']?.toString() ?? '',
      scenario: json['scenario']?.toString() ?? '',
      firstMessage: json['firstMessage']?.toString() ?? '',
      exampleDialogues:
          ((json['exampleDialogues'] as List?) ?? const <Object>[])
              .map((Object? item) => item.toString())
              .toList(growable: false),
      alternateGreetings:
          ((json['alternateGreetings'] as List?) ?? const <Object>[])
              .map((Object? item) => item.toString())
              .toList(growable: false),
      creator: json['creator']?.toString(),
      creatorNotes: json['creatorNotes']?.toString(),
      mainPromptOverride: json['mainPromptOverride']?.toString(),
      postHistoryInstructions: json['postHistoryInstructions']?.toString(),
      avatarPath: json['avatarPath']?.toString(),
      lorebook: json['lorebook'] is Map<String, Object?>
          ? Lorebook.fromJson(json['lorebook']! as Map<String, Object?>)
          : json['lorebook'] is Map
              ? Lorebook.fromJson(
                  (json['lorebook']! as Map).cast<String, Object?>())
              : null,
      extensions: json['extensions'] is Map<String, Object?>
          ? json['extensions']! as Map<String, Object?>
          : json['extensions'] is Map
              ? (json['extensions']! as Map).cast<String, Object?>()
              : const <String, Object?>{},
      tags: ((json['tags'] as List?) ?? const <Object>[])
          .map((Object? item) => item.toString())
          .toList(growable: false),
      characterVersion: json['characterVersion']?.toString(),
      spec: json['spec']?.toString(),
      specVersion: json['specVersion']?.toString(),
    );
  }

  String buildSystemRole({
    String? userAlias,
    String? localeTag,
    bool includeExamples = true,
  }) {
    final String resolvedCharacterName = name.trim().isEmpty ? 'Character' : name;
    final String formattedDescription = RoleplayTextFormatter.formatCardField(
      description,
      characterName: resolvedCharacterName,
      userAlias: userAlias,
      localeTag: localeTag,
      extensions: extensions,
      applyPromptRegex: true,
    );
    final String formattedPersonality = RoleplayTextFormatter.formatCardField(
      personality,
      characterName: resolvedCharacterName,
      userAlias: userAlias,
      localeTag: localeTag,
      extensions: extensions,
      applyPromptRegex: true,
    );
    final String formattedScenario = RoleplayTextFormatter.formatCardField(
      scenario,
      characterName: resolvedCharacterName,
      userAlias: userAlias,
      localeTag: localeTag,
      extensions: extensions,
      applyPromptRegex: true,
    );
    final String formattedCreatorNotes = RoleplayTextFormatter.formatCardField(
      creatorNotes ?? '',
      characterName: resolvedCharacterName,
      userAlias: userAlias,
      localeTag: localeTag,
      extensions: extensions,
      applyPromptRegex: true,
    );
    final StringBuffer buffer = StringBuffer()
      ..writeln('Roleplay Packet')
      ..writeln('- Character: $resolvedCharacterName');

    if (formattedDescription.isNotEmpty) {
      buffer.writeln('- Core Role: $formattedDescription');
    }
    if (formattedPersonality.isNotEmpty) {
      buffer.writeln('- Behavioral Style: $formattedPersonality');
    }
    if (formattedScenario.isNotEmpty) {
      buffer.writeln('- Current Scenario: $formattedScenario');
    }

    if (includeExamples && exampleDialogues.isNotEmpty) {
      buffer.writeln('- Example Dialogue Blocks:');
      for (final String example in exampleDialogues) {
        final String formattedExample = RoleplayTextFormatter.formatCardField(
          example,
          characterName: resolvedCharacterName,
          userAlias: userAlias,
          localeTag: localeTag,
          extensions: extensions,
          applyPromptRegex: true,
        );
        if (formattedExample.isEmpty) {
          continue;
        }
        buffer.writeln('  <START>');
        for (final String line in formattedExample.split('\n')) {
          buffer.writeln('  $line');
        }
      }
    }

    if (formattedCreatorNotes.isNotEmpty) {
      buffer.writeln('- Creator Notes: $formattedCreatorNotes');
    }

    return buffer.toString().trimRight();
  }

  String? get preferredOpeningMessage {
    final String trimmedFirstMessage = firstMessage.trim();
    if (trimmedFirstMessage.isNotEmpty) {
      return trimmedFirstMessage;
    }
    for (final String greeting in alternateGreetings) {
      final String trimmedGreeting = greeting.trim();
      if (trimmedGreeting.isNotEmpty) {
        return trimmedGreeting;
      }
    }
    return null;
  }

  String? resolveOpeningMessage({
    String? userAlias,
    String? localeTag,
  }) {
    final String resolvedCharacterName = name.trim().isEmpty ? 'Character' : name;
    final List<String> candidates = <String>[
      firstMessage,
      ...alternateGreetings,
    ];
    for (final String candidate in candidates) {
      final String formatted = RoleplayTextFormatter.formatCardField(
        candidate,
        characterName: resolvedCharacterName,
        userAlias: userAlias,
        localeTag: localeTag,
        extensions: extensions,
      );
      if (formatted.isNotEmpty) {
        return formatted;
      }
    }
    return null;
  }
}
