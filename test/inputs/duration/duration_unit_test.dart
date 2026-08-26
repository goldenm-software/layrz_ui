import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzDurationUnit', () {
    test('declares exactly four units', () {
      expect(LayrzDurationUnit.values, hasLength(4));
    });

    test('declares day, hour, minute, second and nothing else', () {
      expect(
        LayrzDurationUnit.values,
        containsAll(<LayrzDurationUnit>[
          LayrzDurationUnit.day,
          LayrzDurationUnit.hour,
          LayrzDurationUnit.minute,
          LayrzDurationUnit.second,
        ]),
      );
    });

    test('orders units from largest to smallest by enum index', () {
      // Downstream code (LayrzDurationInput's zero-duration fallback) walks
      // LayrzDurationUnit.values and keeps the last visible match to find the
      // "smallest" unit — that only works if declaration order is largest to
      // smallest. Pin the order explicitly so a reordering is caught here,
      // not as a silent behavior change in the widget that depends on it.
      expect(LayrzDurationUnit.day.index, 0);
      expect(LayrzDurationUnit.hour.index, 1);
      expect(LayrzDurationUnit.minute.index, 2);
      expect(LayrzDurationUnit.second.index, 3);
    });

    test('each unit has a distinct index', () {
      final indexes = LayrzDurationUnit.values.map((unit) => unit.index).toSet();
      expect(indexes, hasLength(LayrzDurationUnit.values.length));
    });

    test('unit names match their declaration', () {
      expect(LayrzDurationUnit.day.name, 'day');
      expect(LayrzDurationUnit.hour.name, 'hour');
      expect(LayrzDurationUnit.minute.name, 'minute');
      expect(LayrzDurationUnit.second.name, 'second');
    });
  });
}
