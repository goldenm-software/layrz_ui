import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzNavigatorLabel', () {
    test('creates with label text', () {
      final label = LayrzNavigatorLabel('MAIN');
      expect(label.labelText, 'MAIN');
    });

    test('equals two identical labels', () {
      final label1 = LayrzNavigatorLabel('MAIN');
      final label2 = LayrzNavigatorLabel('MAIN');
      expect(label1, equals(label2));
    });

    test('not equals labels with different text', () {
      final label1 = LayrzNavigatorLabel('MAIN');
      final label2 = LayrzNavigatorLabel('REFERENCE');
      expect(label1, isNot(equals(label2)));
    });

    test('copyWith replaces label text', () {
      final label1 = LayrzNavigatorLabel('MAIN');
      final label2 = label1.copyWith(labelText: 'REFERENCE');
      expect(label2.labelText, 'REFERENCE');
    });
  });
}
