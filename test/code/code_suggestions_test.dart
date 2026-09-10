import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/code/src/code_suggestions.dart';
import 'package:layrz_ui/src/code/src/code_theme_extension.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCodeSuggestions.caretWord', () {
    test('extracts the identifier run ending exactly at the caret', () {
      final word = LayrzCodeSuggestions.caretWord('result = averag', 15);
      expect(word.word, 'averag');
      expect(word.start, 9);
      expect(word.end, 15);
    });

    test('caret in the middle of an identifier only extracts the left half', () {
      final word = LayrzCodeSuggestions.caretWord('average', 3);
      expect(word.word, 'ave');
      expect(word.start, 0);
      expect(word.end, 3);
    });

    test('caret right after whitespace yields an empty word', () {
      final word = LayrzCodeSuggestions.caretWord('x = ', 4);
      expect(word.word, isEmpty);
      expect(word.start, 4);
      expect(word.end, 4);
    });

    test('caret right after punctuation yields an empty word', () {
      final word = LayrzCodeSuggestions.caretWord('foo(', 4);
      expect(word.word, isEmpty);
      expect(word.start, 4);
      expect(word.end, 4);
    });

    test('caret at the very start of the text yields an empty word', () {
      final word = LayrzCodeSuggestions.caretWord('average', 0);
      expect(word.word, isEmpty);
      expect(word.start, 0);
      expect(word.end, 0);
    });

    test('underscores and digits count as identifier characters', () {
      final word = LayrzCodeSuggestions.caretWord('my_var_2', 8);
      expect(word.word, 'my_var_2');
      expect(word.start, 0);
      expect(word.end, 8);
    });

    test('caret beyond the text length returns an empty word at that offset', () {
      final word = LayrzCodeSuggestions.caretWord('abc', 10);
      expect(word.word, isEmpty);
      expect(word.start, 10);
      expect(word.end, 10);
    });

    test('negative caret returns an empty word at that offset', () {
      final word = LayrzCodeSuggestions.caretWord('abc', -1);
      expect(word.word, isEmpty);
      expect(word.start, -1);
      expect(word.end, -1);
    });

    test('caret at exactly text.length after an identifier extracts the whole trailing word', () {
      final word = LayrzCodeSuggestions.caretWord('avg', 3);
      expect(word.word, 'avg');
      expect(word.start, 0);
      expect(word.end, 3);
    });
  });

  group('LayrzCodeSuggestions.matches', () {
    test('empty prefix without includeAllOnEmpty returns nothing', () {
      final result = LayrzCodeSuggestions.matches('', builtins: const ['print', 'len'], extras: const []);
      expect(result, isEmpty);
    });

    test('empty prefix with includeAllOnEmpty returns the full de-duplicated list', () {
      final result = LayrzCodeSuggestions.matches(
        '',
        builtins: const ['print', 'len'],
        extras: const ['assetName'],
        includeAllOnEmpty: true,
      );
      expect(result, ['print', 'len', 'assetName']);
    });

    test('filters by case-insensitive prefix', () {
      final result = LayrzCodeSuggestions.matches(
        'PR',
        builtins: const ['print', 'len', 'propagate'],
        extras: const [],
      );
      expect(result, ['print', 'propagate']);
    });

    test('preserves builtins-then-extras order', () {
      final result = LayrzCodeSuggestions.matches(
        'a',
        builtins: const ['average', 'abs'],
        extras: const ['assetName'],
      );
      expect(result, ['average', 'abs', 'assetName']);
    });

    test('drops an entry exactly equal to the prefix', () {
      final result = LayrzCodeSuggestions.matches('print', builtins: const ['print', 'printer'], extras: const []);
      expect(result, ['printer']);
    });

    test('de-duplicates repeated candidates across builtins and extras', () {
      final result = LayrzCodeSuggestions.matches(
        'ass',
        builtins: const ['assetName'],
        extras: const ['assetName', 'assetName'],
      );
      expect(result, ['assetName']);
    });

    test('caps results at the limit', () {
      final result = LayrzCodeSuggestions.matches(
        'x',
        builtins: const ['x1', 'x2', 'x3', 'x4'],
        extras: const [],
        limit: 2,
      );
      expect(result, hasLength(2));
      expect(result, ['x1', 'x2']);
    });

    test('a candidate shorter than or equal to the prefix length never matches', () {
      final result = LayrzCodeSuggestions.matches('abcd', builtins: const ['abc', 'abcd'], extras: const []);
      expect(result, isEmpty);
    });

    test('no candidate starts with the prefix yields an empty list', () {
      final result = LayrzCodeSuggestions.matches('zzz', builtins: const ['print', 'len'], extras: const []);
      expect(result, isEmpty);
    });
  });

  group('LayrzCodeSuggestions.builtinsFor', () {
    test('python returns keywords followed by builtins', () {
      final result = LayrzCodeSuggestions.builtinsFor(LayrzCodeLanguage.python);
      expect(result, contains('def'));
      expect(result, contains('return'));
      expect(result, contains('print'));
      expect(result, contains('len'));
      expect(result.indexOf('def'), lessThan(result.indexOf('print')));
    });

    test('lcl returns the LCL function names', () {
      final result = LayrzCodeSuggestions.builtinsFor(LayrzCodeLanguage.lcl);
      expect(result, contains('GET_SENSOR'));
      expect(result, contains('COMPARE'));
    });

    test('lml has no built-in completions', () {
      final result = LayrzCodeSuggestions.builtinsFor(LayrzCodeLanguage.lml);
      expect(result, isEmpty);
    });
  });

  group('LayrzCaretWord', () {
    test('stores the given fields verbatim', () {
      const word = LayrzCaretWord(word: 'abc', start: 2, end: 5);
      expect(word.word, 'abc');
      expect(word.start, 2);
      expect(word.end, 5);
    });
  });

  group('LayrzCodeSuggestionList widget', () {
    testWidgets('renders one row per match with the selected index highlighted', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const codeTheme = LayrzCodeThemeExtension.dark();
      String? accepted;

      await pumpThemed(
        tester,
        LayrzCodeSuggestionList(
          matches: const ['average', 'abs', 'assetName'],
          selectedIndex: 1,
          codeTheme: codeTheme,
          fontSize: 14,
          onAccept: (value) => accepted = value,
        ),
      );

      expect(find.text('average'), findsOneWidget);
      expect(find.text('abs'), findsOneWidget);
      expect(find.text('assetName'), findsOneWidget);

      final coloredBoxes = tester.widgetList<ColoredBox>(find.byType(ColoredBox)).toList();
      final highlighted = coloredBoxes.where((box) => box.color == codeTheme.currentLineBackground);
      expect(highlighted, hasLength(1));

      await tester.tap(find.text('abs'));
      await tester.pump();
      expect(accepted, 'abs');
    });
  });
}
