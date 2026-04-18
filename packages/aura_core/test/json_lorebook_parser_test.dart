import 'package:aura_core/aura_core.dart';
import 'package:test/test.dart';

void main() {
  test('parses SillyTavern-style standalone lorebook object entries', () {
    const JsonLorebookParser parser = JsonLorebookParser();

    final Lorebook lorebook = parser.parseJsonObject(<String, Object?>{
      'name': '璃月旅行笔记',
      'description': 'A small imported worldbook.',
      'scan_depth': '4',
      'entries': <String, Object?>{
        '0': <String, Object?>{
          'key': <String>['璃月', 'Liyue'],
          'keysecondary': <String>['契约'],
          'content': '提到璃月与契约时，应补充港口秩序与契约文化。',
          'selective': true,
          'matchWholeWords': true,
          'order': '12',
        },
        '5': <String, Object?>{
          'key': '群玉阁, 凝光',
          'content': '群玉阁象征凝光的权势与审美。',
          'constant': 1,
          'disable': false,
        },
      },
    });

    expect(lorebook.name, '璃月旅行笔记');
    expect(lorebook.scanDepth, 4);
    expect(lorebook.entries, hasLength(2));
    expect(lorebook.entries.first.id, '0');
    expect(lorebook.entries.first.secondaryKeywords, contains('契约'));
    expect(lorebook.entries.first.selective, isTrue);
    expect(lorebook.entries.first.matchWholeWords, isTrue);
    expect(lorebook.entries.first.insertionOrder, 12);
    expect(lorebook.entries.last.constant, isTrue);
    expect(lorebook.entries.last.keywords, containsAll(<String>['群玉阁', '凝光']));
  });
}
