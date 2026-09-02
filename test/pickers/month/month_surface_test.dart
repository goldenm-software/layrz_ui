import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/models/month.dart';
import 'package:layrz_ui/src/pickers/src/month/month_surface.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzMonthSurface', () {
    guardedTestWidgets('displays the year of the seeded value', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzMonthSurface(
          value: const LayrzMonth(year: 2019, month: 3),
          onMonthSelected: (_) {},
        ),
      );

      expect(find.text('Year 2019'), findsOneWidget);
    });

    guardedTestWidgets('defaults to the current year when value is null', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzMonthSurface(value: null, onMonthSelected: (_) {}),
      );

      expect(find.text('Year ${DateTime.now().year}'), findsOneWidget);
    });

    guardedTestWidgets('tapping a month cell invokes onMonthSelected with the tapped month', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzMonth? selected;

      await pumpThemed(
        tester,
        LayrzMonthSurface(
          value: const LayrzMonth(year: 2026, month: 1),
          onMonthSelected: (m) => selected = m,
        ),
      );

      await tester.tap(find.text('November'));
      await tester.pumpAndSettle();

      expect(selected, const LayrzMonth(year: 2026, month: 11));
    });

    guardedTestWidgets('year chevrons navigate without invoking onMonthSelected', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var callCount = 0;

      await pumpThemed(
        tester,
        LayrzMonthSurface(
          value: const LayrzMonth(year: 2026, month: 1),
          onMonthSelected: (_) => callCount++,
        ),
      );

      final nextChevron = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Next year',
      );
      await tester.tap(nextChevron);
      await tester.pumpAndSettle();

      expect(find.text('Year 2027'), findsOneWidget);
      expect(callCount, 0);

      final backChevron = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Previous year',
      );
      await tester.tap(backChevron);
      await tester.pumpAndSettle();
      await tester.tap(backChevron);
      await tester.pumpAndSettle();

      expect(find.text('Year 2025'), findsOneWidget);
      expect(callCount, 0);
    });

    guardedTestWidgets('didUpdateWidget re-seeds the displayed year when value changes', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var value = const LayrzMonth(year: 2020, month: 1);
      late StateSetter setState;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setter) {
            setState = setter;
            return LayrzMonthSurface(value: value, onMonthSelected: (_) {});
          },
        ),
      );

      expect(find.text('Year 2020'), findsOneWidget);

      setState(() => value = const LayrzMonth(year: 2031, month: 1));
      await tester.pump();

      expect(find.text('Year 2031'), findsOneWidget);
      expect(find.text('Year 2020'), findsNothing);
    });

    guardedTestWidgets('all twelve full month names render with no abbreviation', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzMonthSurface(
          value: const LayrzMonth(year: 2026, month: 1),
          onMonthSelected: (_) {},
        ),
      );

      const fullNames = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      for (final name in fullNames) {
        expect(find.text(name), findsOneWidget);
      }
      // No abbreviated three-letter forms leak through as separate labels.
      expect(find.text('Jan'), findsNothing);
      expect(find.text('Sep'), findsNothing);
    });

    guardedTestWidgets('renders without overflow on a compact (bottom-sheet-sized) width', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 360,
          child: LayrzMonthSurface(
            value: const LayrzMonth(year: 2026, month: 1),
            onMonthSelected: (_) {},
          ),
        ),
      );
    });

    guardedTestWidgets('renders no Save/Cancel footer', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzMonthSurface(
          value: const LayrzMonth(year: 2026, month: 1),
          onMonthSelected: (_) {},
        ),
      );

      expect(find.text('Save'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    guardedTestWidgets('disabledMonths render inert and do not invoke onMonthSelected', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var callCount = 0;

      await pumpThemed(
        tester,
        LayrzMonthSurface(
          value: const LayrzMonth(year: 2026, month: 1),
          disabledMonths: {const LayrzMonth(year: 2026, month: 7)},
          onMonthSelected: (_) => callCount++,
        ),
      );

      await tester.tap(find.text('July'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(callCount, 0);
    });

    guardedTestWidgets('minimum/maximum bound the selectable range', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var callCount = 0;

      await pumpThemed(
        tester,
        LayrzMonthSurface(
          value: const LayrzMonth(year: 2026, month: 6),
          minimum: const LayrzMonth(year: 2026, month: 3),
          maximum: const LayrzMonth(year: 2026, month: 9),
          onMonthSelected: (_) => callCount++,
        ),
      );

      await tester.tap(find.text('January'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(callCount, 0);

      await tester.tap(find.text('December'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(callCount, 0);

      await tester.tap(find.text('June'));
      await tester.pumpAndSettle();
      expect(callCount, 1);
    });
  });
}
