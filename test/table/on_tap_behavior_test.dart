import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/table/src/on_tap_behavior.dart';

void main() {
  group('LayrzTableOnTapBehavior', () {
    test('has exactly the two documented values in order', () {
      expect(LayrzTableOnTapBehavior.values, [
        LayrzTableOnTapBehavior.none,
        LayrzTableOnTapBehavior.copyToClipboard,
      ]);
    });

    test('each value is distinct', () {
      expect(LayrzTableOnTapBehavior.values.toSet().length, LayrzTableOnTapBehavior.values.length);
    });

    test('values are addressable by name', () {
      expect(LayrzTableOnTapBehavior.none.name, 'none');
      expect(LayrzTableOnTapBehavior.copyToClipboard.name, 'copyToClipboard');
    });
  });
}
