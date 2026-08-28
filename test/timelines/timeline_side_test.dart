import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzTimelineSide', () {
    test('has exactly two values: start and end', () {
      expect(LayrzTimelineSide.values, [LayrzTimelineSide.start, LayrzTimelineSide.end]);
    });

    test('start and end are distinct', () {
      expect(LayrzTimelineSide.start, isNot(equals(LayrzTimelineSide.end)));
    });
  });
}
