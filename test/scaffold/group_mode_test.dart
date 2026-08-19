import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzScaffoldGroupMode', () {
    test('has grouped value', () {
      expect(LayrzScaffoldGroupMode.grouped, LayrzScaffoldGroupMode.grouped);
    });

    test('has flat value', () {
      expect(LayrzScaffoldGroupMode.flat, LayrzScaffoldGroupMode.flat);
    });

    test('grouped and flat are not equal', () {
      expect(
        LayrzScaffoldGroupMode.grouped,
        isNot(LayrzScaffoldGroupMode.flat),
      );
    });

    test('enum values are distinct', () {
      final values = LayrzScaffoldGroupMode.values;
      expect(values.length, 2);
      expect(values, contains(LayrzScaffoldGroupMode.grouped));
      expect(values, contains(LayrzScaffoldGroupMode.flat));
    });
  });
}
