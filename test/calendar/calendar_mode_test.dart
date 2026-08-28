import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzCalendarMode', () {
    test('ships exactly three values: month, week, day', () {
      expect(LayrzCalendarMode.values, [
        LayrzCalendarMode.month,
        LayrzCalendarMode.week,
        LayrzCalendarMode.day,
      ]);
    });

    test('values are stable and index-ordered', () {
      expect(LayrzCalendarMode.month.index, 0);
      expect(LayrzCalendarMode.week.index, 1);
      expect(LayrzCalendarMode.day.index, 2);
    });
  });
}
