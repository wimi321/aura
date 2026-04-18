import 'package:aura_app/presentation/widgets/character_editor_dialog.dart';
import 'package:aura_core/aura_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'character workbench shows role-card and worldbook editing surfaces',
      (WidgetTester tester) async {
    const CharacterCard character = CharacterCard(
      id: 'storm-archivist',
      name: 'Storm Archivist',
      description: 'Keeps track of scene state.',
      personality: 'Precise and story-first.',
      scenario: 'Rain hammers the observatory roof.',
      firstMessage: 'You made it before the storm shutters closed.',
      exampleDialogues: <String>[
        'Stay in character and keep the plot moving.',
      ],
      lorebook: Lorebook(
        name: 'Observatory Secrets',
        description: 'World state and trigger notes.',
        entries: <LorebookEntry>[
          LorebookEntry(
            id: 'storm-signal',
            content: 'When the storm siren sounds, the observatory seals.',
            keywords: <String>['storm', 'siren'],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CharacterEditorDialog(character: character),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Character Workbench'), findsOneWidget);
    expect(find.text('Core Card Fields'), findsOneWidget);
    expect(find.text('Tavern Advanced Fields'), findsOneWidget);
    expect(find.text('Lorebook / Worldbook'), findsOneWidget);
    expect(find.text('Worldbook Name & Summary'), findsOneWidget);
    expect(find.text('Observatory Secrets'), findsNothing);
    expect(find.text('World state and trigger notes.'), findsNothing);
    expect(find.text('Worldbook Entries'), findsOneWidget);
    expect(find.text('When the storm siren sounds, the observatory seals.'),
        findsNothing);
    expect(find.text('Import & Merge Worldbook'), findsOneWidget);
    expect(find.text('Add Entry'), findsOneWidget);
    expect(find.text('Import Portrait'), findsNothing);
    expect(
      find.textContaining('built-in cinematic cover is only used'),
      findsOneWidget,
    );

    final Finder metaPanelToggle = find.byKey(
      const ValueKey<String>('lorebook-meta-panel-toggle'),
    );
    await tester.ensureVisible(metaPanelToggle);
    await tester.tap(metaPanelToggle);
    await tester.pumpAndSettle();

    expect(find.text('Observatory Secrets'), findsOneWidget);
    expect(find.text('World state and trigger notes.'), findsOneWidget);

    final Finder entryPanelToggle = find.byKey(
      const ValueKey<String>('lorebook-entry-panel-toggle'),
    );
    await tester.ensureVisible(entryPanelToggle);
    await tester.tap(entryPanelToggle);
    await tester.pumpAndSettle();

    expect(find.text('When the storm siren sounds, the observatory seals.'),
        findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
