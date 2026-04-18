import 'package:aura_app/core/platform/file_selector_type_groups.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('file selector type groups', () {
    test('character card groups carry iOS-safe UTIs', () {
      expect(characterCardImportTypeGroups, hasLength(2));

      final pngGroup = characterCardImportTypeGroups.firstWhere(
        (group) => group.extensions?.contains('png') ?? false,
      );
      final jsonGroup = characterCardImportTypeGroups.firstWhere(
        (group) => group.extensions?.contains('json') ?? false,
      );

      expect(pngGroup.uniformTypeIdentifiers, contains('public.png'));
      expect(jsonGroup.uniformTypeIdentifiers, contains('public.json'));
    });

    test('lorebook group carries iOS-safe UTI', () {
      expect(lorebookImportTypeGroups, hasLength(1));
      expect(
        lorebookImportTypeGroups.single.uniformTypeIdentifiers,
        contains('public.json'),
      );
    });
  });
}
