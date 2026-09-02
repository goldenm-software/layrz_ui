import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/date/date_surface.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  tzdata.initializeTimeZones();

  group('LayrzDateSurface — rendering', () {
    guardedTestWidgets('renders the month/year header for the seeded month', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateSurface(value: DateTime(2026, 9, 15), onDateSelected: (_) {}),
      );

      expect(find.text('September 2026'), findsOneWidget);
    });

    guardedTestWidgets('seeds the displayed month from the current month when value is null', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final now = DateTime.now();

      await pumpThemed(
        tester,
        LayrzDateSurface(value: null, onDateSelected: (_) {}),
      );

      expect(find.byType(LayrzDateSurface), findsOneWidget);
      // Header renders the current month/year label since no value seeds it.
      expect(find.textContaining('${now.year}'), findsWidgets);
    });

    guardedTestWidgets('renders without overflow at a narrow (compact) viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateSurface(value: DateTime(2026, 9, 15), onDateSelected: (_) {}),
      );

      expect(find.byType(LayrzDateSurface), findsOneWidget);
    });
  });

  group('LayrzDateSurface — commit on tap', () {
    guardedTestWidgets('tapping a day cell fires onDateSelected exactly once, with the tapped date', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? selected;
      var count = 0;

      await pumpThemed(
        tester,
        LayrzDateSurface(
          value: DateTime(2026, 9, 1),
          onDateSelected: (d) {
            selected = d;
            count++;
          },
        ),
      );

      await tester.tap(find.text('15').first);
      await tester.pump();

      expect(count, 1);
      expect(selected!.day, 15);
      expect(selected!.month, 9);
      expect(selected!.year, 2026);
    });

    guardedTestWidgets('this widget never renders a Cancel/Save footer', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateSurface(value: DateTime(2026, 9, 1), onDateSelected: (_) {}),
      );

      expect(find.text('Save'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });
  });

  group('LayrzDateSurface — month navigation', () {
    guardedTestWidgets('tapping the next-month chevron advances the header label by one month', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateSurface(value: DateTime(2026, 9, 1), onDateSelected: (_) {}),
      );

      expect(find.text('September 2026'), findsOneWidget);

      await tester.tap(find.byIcon(MdiIcons.chevronRight));
      await tester.pump();

      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('September 2026'), findsNothing);
    });

    guardedTestWidgets('tapping the previous-month chevron steps the header label back one month', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateSurface(value: DateTime(2026, 9, 1), onDateSelected: (_) {}),
      );

      await tester.tap(find.byIcon(MdiIcons.chevronLeft));
      await tester.pump();

      expect(find.text('August 2026'), findsOneWidget);
    });

    guardedTestWidgets('navigating away from the seeded month does not fire onDateSelected', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var count = 0;
      await pumpThemed(
        tester,
        LayrzDateSurface(value: DateTime(2026, 9, 1), onDateSelected: (_) => count++),
      );

      await tester.tap(find.byIcon(MdiIcons.chevronRight));
      await tester.pump();
      await tester.tap(find.byIcon(MdiIcons.chevronLeft));
      await tester.pump();

      expect(count, 0);
    });

    guardedTestWidgets('stepping past December wraps the header label into January of the next year', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateSurface(value: DateTime(2026, 12, 1), onDateSelected: (_) {}),
      );

      expect(find.text('December 2026'), findsOneWidget);

      await tester.tap(find.byIcon(MdiIcons.chevronRight));
      await tester.pump();

      expect(find.text('January 2027'), findsOneWidget);
    });

    guardedTestWidgets('stepping before January wraps the header label into December of the previous year', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateSurface(value: DateTime(2027, 1, 1), onDateSelected: (_) {}),
      );

      await tester.tap(find.byIcon(MdiIcons.chevronLeft));
      await tester.pump();

      expect(find.text('December 2026'), findsOneWidget);
    });
  });

  group('LayrzDateSurface — re-seeding (involuntary-close discipline)', () {
    guardedTestWidgets('rebuilding with a changed value re-seeds the displayed month', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var value = DateTime(2026, 9, 1);
      late StateSetter setState;

      // A StatefulBuilder inside one stable pumpThemed tree, rather than a
      // second pumpThemed call: LayrzBottomSheet's mobile route push aside,
      // `pumpThemed`'s own Overlay(initialEntries: ...) is only consulted at
      // its own construction, so a second top-level pumpThemed call does
      // not reconcile into the first mounted Overlay's entry -- it needs a
      // rebuild *within* an already-mounted tree to exercise
      // `didUpdateWidget`, which this StatefulBuilder provides.
      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setter) {
            setState = setter;
            return LayrzDateSurface(value: value, onDateSelected: (_) {});
          },
        ),
      );
      expect(find.text('September 2026'), findsOneWidget);

      // Browse forward without selecting -- draft month state moves.
      await tester.tap(find.byIcon(MdiIcons.chevronRight));
      await tester.pump();
      expect(find.text('October 2026'), findsOneWidget);

      // Rebuild the SAME element with a different `value`, exercising
      // `didUpdateWidget`'s re-seed path directly.
      setState(() => value = DateTime(2027, 3, 1));
      await tester.pump();

      expect(find.text('March 2027'), findsOneWidget);
      expect(find.text('October 2026'), findsNothing);
    });

    guardedTestWidgets('a fresh State (new key) always seeds from the current value, ignoring any prior browsing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var generation = 0;
      late StateSetter setState;

      // Simulates LayrzDateInput's own `_surfaceGeneration`-keyed
      // reconstruction on every desktop panel open.
      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setter) {
            setState = setter;
            return LayrzDateSurface(
              key: ValueKey(generation),
              value: DateTime(2026, 9, 1),
              onDateSelected: (_) {},
            );
          },
        ),
      );
      expect(find.text('September 2026'), findsOneWidget);

      await tester.tap(find.byIcon(MdiIcons.chevronRight));
      await tester.pump();
      expect(find.text('October 2026'), findsOneWidget);

      // A different key forces a brand-new State/initState, discarding the
      // browsed-to month entirely and re-seeding from `value` alone.
      setState(() => generation++);
      await tester.pump();

      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('October 2026'), findsNothing);
    });
  });

  group('LayrzDateSurface — bounds and disabled days', () {
    guardedTestWidgets('a disabledDays entry does not fire onDateSelected', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var count = 0;
      await pumpThemed(
        tester,
        LayrzDateSurface(
          value: DateTime(2026, 9, 1),
          disabledDays: {DateTime(2026, 9, 15)},
          onDateSelected: (_) => count++,
        ),
      );

      await tester.tap(find.text('15').first);
      await tester.pump();

      expect(count, 0);
    });

    guardedTestWidgets('a date outside firstDay/lastDay does not fire onDateSelected', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var count = 0;
      await pumpThemed(
        tester,
        LayrzDateSurface(
          value: DateTime(2026, 9, 15),
          firstDay: DateTime(2026, 9, 10),
          onDateSelected: (_) => count++,
        ),
      );

      await tester.tap(find.text('5').first);
      await tester.pump();

      expect(count, 0);
    });
  });

  group('LayrzDateSurface — firstDayOfWeek and showWeekNumbers', () {
    guardedTestWidgets('renders correctly with a Sunday-first week', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateSurface(
          value: DateTime(2026, 9, 1),
          firstDayOfWeek: DateTime.sunday,
          onDateSelected: (_) {},
        ),
      );

      expect(find.byType(LayrzDateSurface), findsOneWidget);
    });

    guardedTestWidgets('renders correctly with showWeekNumbers false', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateSurface(
          value: DateTime(2026, 9, 1),
          showWeekNumbers: false,
          onDateSelected: (_) {},
        ),
      );

      expect(find.byType(LayrzDateSurface), findsOneWidget);
    });
  });

  group('LayrzDateSurface — TZDateTime zone preservation', () {
    guardedTestWidgets('stepping months preserves the TZDateTime zone on the header label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final location = tz.getLocation('America/New_York');
      final value = tz.TZDateTime(location, 2026, 9, 1);

      DateTime? selected;
      await pumpThemed(
        tester,
        LayrzDateSurface(value: value, onDateSelected: (d) => selected = d),
      );

      await tester.tap(find.byIcon(MdiIcons.chevronRight));
      await tester.pump();
      expect(find.text('October 2026'), findsOneWidget);

      await tester.tap(find.text('15').first);
      await tester.pump();

      expect(selected, isA<tz.TZDateTime>());
      expect((selected! as tz.TZDateTime).location, location);
    });
  });
}
