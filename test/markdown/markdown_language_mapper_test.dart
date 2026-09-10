import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/highlight/highlight.dart';
import 'package:layrz_ui/src/markdown/src/markdown_language_mapper.dart';

void main() {
  group('mapMarkdownLanguage — recognized aliases', () {
    test('maps "python" to LayrzCodeLanguage.python', () {
      expect(mapMarkdownLanguage('python'), LayrzCodeLanguage.python);
    });

    test('maps "py" to LayrzCodeLanguage.python', () {
      expect(mapMarkdownLanguage('py'), LayrzCodeLanguage.python);
    });

    test('maps "lcl" to LayrzCodeLanguage.lcl', () {
      expect(mapMarkdownLanguage('lcl'), LayrzCodeLanguage.lcl);
    });

    test('maps "lml" to LayrzCodeLanguage.lml', () {
      expect(mapMarkdownLanguage('lml'), LayrzCodeLanguage.lml);
    });
  });

  group('mapMarkdownLanguage — case-insensitive and trimmed', () {
    test('matches regardless of case', () {
      expect(mapMarkdownLanguage('PYTHON'), LayrzCodeLanguage.python);
      expect(mapMarkdownLanguage('Python'), LayrzCodeLanguage.python);
      expect(mapMarkdownLanguage('PY'), LayrzCodeLanguage.python);
      expect(mapMarkdownLanguage('LCL'), LayrzCodeLanguage.lcl);
      expect(mapMarkdownLanguage('Lcl'), LayrzCodeLanguage.lcl);
      expect(mapMarkdownLanguage('LML'), LayrzCodeLanguage.lml);
      expect(mapMarkdownLanguage('Lml'), LayrzCodeLanguage.lml);
    });

    test('trims surrounding whitespace before comparing', () {
      expect(mapMarkdownLanguage('  python  '), LayrzCodeLanguage.python);
      expect(mapMarkdownLanguage('\tlcl\n'), LayrzCodeLanguage.lcl);
      expect(mapMarkdownLanguage(' LML '), LayrzCodeLanguage.lml);
    });
  });

  group('mapMarkdownLanguage — falls back to plain', () {
    test('maps an unrecognized language to plain', () {
      expect(mapMarkdownLanguage('json'), LayrzCodeLanguage.plain);
      expect(mapMarkdownLanguage('dart'), LayrzCodeLanguage.plain);
      expect(mapMarkdownLanguage('js'), LayrzCodeLanguage.plain);
      expect(mapMarkdownLanguage('yaml'), LayrzCodeLanguage.plain);
    });

    test('maps an empty string to plain', () {
      expect(mapMarkdownLanguage(''), LayrzCodeLanguage.plain);
    });

    test('maps a whitespace-only string to plain', () {
      expect(mapMarkdownLanguage('   '), LayrzCodeLanguage.plain);
    });

    test('maps null to plain', () {
      expect(mapMarkdownLanguage(null), LayrzCodeLanguage.plain);
    });

    test('never returns null for any input', () {
      for (final input in [null, '', '   ', 'python', 'py', 'lcl', 'lml', 'json', 'unknown-lang']) {
        expect(mapMarkdownLanguage(input), isNotNull);
      }
    });
  });
}
