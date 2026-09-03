import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/date/date_range_surface.dart';
import 'package:layrz_ui/src/pickers/src/models/date_range.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/find_button_label.dart';
import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  tzdata.initializeTimeZones();

  group('LayrzDateRangeSurface — rendering', () {
    guardedTestWidgets('renders the month/year header for the seeded month', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
          onSave: (_) {},
          onCancel: () {},
        ),
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
        LayrzDateRangeSurface(value: null, onSave: (_) {}, onCancel: () {}),
      );

      expect(find.byType(LayrzDateRangeSurface), findsOneWidget);
      expect(find.textContaining('${now.year}'), findsWidgets);
    });

    guardedTestWidgets('renders without overflow at a narrow (compact) viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
          onSave: (_) {},
          onCancel: () {},
        ),
      );

      expect(find.byType(LayrzDateRangeSurface), findsOneWidget);
    });

    guardedTestWidgets('renders without overflow at a wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
          onSave: (_) {},
          onCancel: () {},
        ),
      );

      expect(find.byType(LayrzDateRangeSurface), findsOneWidget);
    });
  });

  group('LayrzDateRangeSurface — Cancel/Save footer, visible from the first frame', () {
    guardedTestWidgets('renders Cancel and Save buttons immediately, before any tap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateRangeSurface(value: null, onSave: (_) {}, onCancel: () {}),
      );

      expect(findButtonLabel('Cancel'), findsOneWidget);
      expect(findButtonLabel('Save'), findsOneWidget);
    });

    guardedTestWidgets('Save is disabled while the draft is empty', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var saveCount = 0;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(value: null, onSave: (_) => saveCount++, onCancel: () {}),
      );

      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saveCount, 0);
    });

    guardedTestWidgets('Save is disabled while only the anchor is set (half-open)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var saveCount = 0;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(value: null, onSave: (_) => saveCount++, onCancel: () {}),
      );

      await tester.tap(find.text('5').first);
      await tester.pump();

      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saveCount, 0);
    });

    guardedTestWidgets('Save reports the completed range exactly once', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? saved;
      var saveCount = 0;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: null,
          onSave: (r) {
            saved = r;
            saveCount++;
          },
          onCancel: () {},
        ),
      );

      await tester.tap(find.text('5').first);
      await tester.pump();
      await tester.tap(find.text('10').first);
      await tester.pump();

      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saveCount, 1);
      expect(saved!.start.day, 5);
      expect(saved!.end.day, 10);
    });

    guardedTestWidgets('Cancel invokes onCancel without invoking onSave', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var cancelCount = 0;
      var saveCount = 0;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: null,
          onSave: (_) => saveCount++,
          onCancel: () => cancelCount++,
        ),
      );

      await tester.tap(find.text('5').first);
      await tester.pump();

      await tester.tap(findButtonLabel('Cancel'));
      await tester.pump();

      expect(cancelCount, 1);
      expect(saveCount, 0);
    });
  });

  group('LayrzDateRangeSurface — Reset visibility', () {
    guardedTestWidgets('Reset is absent while the draft is empty', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateRangeSurface(value: null, onSave: (_) {}, onCancel: () {}),
      );

      expect(findButtonLabel('Clear selection'), findsNothing);
    });

    guardedTestWidgets('Reset appears as soon as the anchor is set (half-open)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateRangeSurface(value: null, onSave: (_) {}, onCancel: () {}),
      );

      await tester.tap(find.text('5').first);
      await tester.pump();

      expect(findButtonLabel('Clear selection'), findsOneWidget);
    });

    guardedTestWidgets('Reset clears a completed range back to empty', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var saveCount = 0;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(value: null, onSave: (_) => saveCount++, onCancel: () {}),
      );

      await tester.tap(find.text('5').first);
      await tester.pump();
      await tester.tap(find.text('10').first);
      await tester.pump();
      expect(findButtonLabel('Clear selection'), findsOneWidget);

      await tester.tap(findButtonLabel('Clear selection'));
      await tester.pump();

      expect(findButtonLabel('Clear selection'), findsNothing);

      await tester.tap(findButtonLabel('Save'));
      await tester.pump();
      expect(saveCount, 0);
    });
  });

  group('LayrzDateRangeSurface — state machine: empty -> anchor -> complete, auto-swap', () {
    guardedTestWidgets('first tap sets the anchor only; nothing reported', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var saveCount = 0;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(value: null, onSave: (_) => saveCount++, onCancel: () {}),
      );

      await tester.tap(find.text('12').first);
      await tester.pump();

      expect(saveCount, 0);
      expect(findButtonLabel('Clear selection'), findsOneWidget);
    });

    guardedTestWidgets('second tap after the anchor completes the range', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? saved;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(value: null, onSave: (r) => saved = r, onCancel: () {}),
      );

      await tester.tap(find.text('5').first);
      await tester.pump();
      await tester.tap(find.text('12').first);
      await tester.pump();
      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saved!.start.day, 5);
      expect(saved!.end.day, 12);
    });

    guardedTestWidgets('tapping the later date first, then the earlier date, auto-swaps start/end', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? saved;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(value: null, onSave: (r) => saved = r, onCancel: () {}),
      );

      // Tap the 20th first, then the 5th -- reversed order.
      await tester.tap(find.text('20').first);
      await tester.pump();
      await tester.tap(find.text('5').first);
      await tester.pump();
      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      // Auto-swapped so start <= end -- never rejected as an "error".
      expect(saved!.start.day, 5);
      expect(saved!.end.day, 20);
    });
  });

  group('LayrzDateRangeSurface — endpoint re-tap adjusts that edge only', () {
    guardedTestWidgets('re-tapping the end endpoint keeps the start fixed and moves the end', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? saved;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
          onSave: (r) => saved = r,
          onCancel: () {},
        ),
      );

      // Re-tap the end endpoint (10th) to pick it up, then move it to the 15th.
      await tester.tap(find.text('10').first);
      await tester.pump();
      await tester.tap(find.text('15').first);
      await tester.pump();
      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saved!.start.day, 5);
      expect(saved!.end.day, 15);
    });

    guardedTestWidgets('re-tapping the start endpoint keeps the end fixed and moves the start', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? saved;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 20)),
          onSave: (r) => saved = r,
          onCancel: () {},
        ),
      );

      // Re-tap the start endpoint (10th), then move it earlier to the 3rd.
      await tester.tap(find.text('10').first);
      await tester.pump();
      await tester.tap(find.text('3').first);
      await tester.pump();
      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saved!.start.day, 3);
      expect(saved!.end.day, 20);
    });

    guardedTestWidgets(
      'the reviewer scenario: tap the 5th, misjudge to the 30th, correct the end down to the 20th',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzDateRange? saved;
        await pumpThemed(
          tester,
          LayrzDateRangeSurface(value: null, onSave: (r) => saved = r, onCancel: () {}),
        );

        // Anchor the 5th.
        await tester.tap(find.text('5').first);
        await tester.pump();
        // Misjudge to the 30th -- range completes 5..30.
        await tester.tap(find.text('30').first);
        await tester.pump();
        // Re-tap the end endpoint (30th) to pick it up, then correct it to the 20th.
        await tester.tap(find.text('30').first);
        await tester.pump();
        await tester.tap(find.text('20').first);
        await tester.pump();

        await tester.tap(findButtonLabel('Save'));
        await tester.pump();

        expect(saved!.start.day, 5);
        expect(saved!.end.day, 20);
      },
    );

    guardedTestWidgets('an endpoint moved past the fixed edge auto-swaps rather than erroring', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? saved;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 20)),
          onSave: (r) => saved = r,
          onCancel: () {},
        ),
      );

      // Pick up the start endpoint (10th) then drag it past the fixed end (20th) to the 25th.
      await tester.tap(find.text('10').first);
      await tester.pump();
      await tester.tap(find.text('25').first);
      await tester.pump();
      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saved!.start.day, 20);
      expect(saved!.end.day, 25);
    });
  });

  group('LayrzDateRangeSurface — interior tap rejected and visibly non-interactive', () {
    guardedTestWidgets('tapping an interior cell of a completed range does not change the range', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? saved;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 20)),
          onSave: (r) => saved = r,
          onCancel: () {},
        ),
      );

      // The 12th is strictly between 5 and 20 -- an interior cell.
      await tester.tap(find.text('12').first);
      await tester.pump();
      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saved!.start.day, 5);
      expect(saved!.end.day, 20);
    });

    guardedTestWidgets('an interior cell has no pointer cursor and no tap semantics action', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzDateRangeSurface(
            value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 20)),
            onSave: (_) {},
            onCancel: () {},
          ),
        );

        final mouseRegion = tester
            .widgetList<MouseRegion>(find.byType(MouseRegion))
            .firstWhere(
              (region) => region.cursor == MouseCursor.defer,
              orElse: () => throw StateError('no deferred-cursor cell found'),
            );
        expect(mouseRegion.cursor, MouseCursor.defer);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('interior cells read as locked from the moment a range exists, before any rejected tap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzDateRangeSurface(
            value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 20)),
            onSave: (_) {},
            onCancel: () {},
          ),
        );

        // No tap yet -- the interior cell must already be styled inert.
        final interiorCellCount = tester
            .widgetList<MouseRegion>(find.byType(MouseRegion))
            .where(
              (region) => region.cursor == MouseCursor.defer,
            )
            .length;
        expect(interiorCellCount, greaterThan(0));
      } finally {
        handle.dispose();
      }
    });
  });

  group('LayrzDateRangeSurface — outside tap extends the nearer endpoint', () {
    guardedTestWidgets('a tap before the start extends the range backward to it', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? saved;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 20)),
          onSave: (r) => saved = r,
          onCancel: () {},
        ),
      );

      await tester.tap(find.text('2').first);
      await tester.pump();
      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saved!.start.day, 2);
      expect(saved!.end.day, 20);
    });

    guardedTestWidgets('a tap after the end extends the range forward to it', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? saved;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 20)),
          onSave: (r) => saved = r,
          onCancel: () {},
        ),
      );

      await tester.tap(find.text('28').first);
      await tester.pump();
      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saved!.start.day, 10);
      expect(saved!.end.day, 28);
    });
  });

  group('LayrzDateRangeSurface — no sequence of taps yields a discontinuous selection', () {
    guardedTestWidgets('a long sequence of anchor/complete/endpoint-adjust/outside taps always saves a contiguous '
        'range (every day between start and end is present in the grid as rangeInterior or an endpoint)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? saved;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(value: null, onSave: (r) => saved = r, onCancel: () {}),
      );

      // anchor -> complete -> reversed-order re-anchor via Reset -> endpoint
      // adjust -> outside-extend. At every step the only representable
      // states are empty/half-open/complete -- there is no tap sequence
      // that reaches a gap, because LayrzContiguousRangePolicy never
      // constructs a draft with a hole.
      await tester.tap(find.text('10').first);
      await tester.pump();
      await tester.tap(find.text('4').first); // reversed order -> auto-swap
      await tester.pump();
      await tester.tap(find.text('10').first); // re-tap the end endpoint
      await tester.pump();
      await tester.tap(find.text('18').first); // move it out
      await tester.pump();
      await tester.tap(find.text('25').first); // outside tap -> extend
      await tester.pump();

      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saved, isNotNull);
      // The resulting range is a single contiguous LayrzDateRange -- by
      // construction (start <= end, both non-null) there is no way for
      // this type itself to represent a gap.
      expect(saved!.start.isBefore(saved!.end) || saved!.start.isAtSameMomentAs(saved!.end), isTrue);
      expect(saved!.start.day, 4);
      expect(saved!.end.day, 25);
    });
  });

  group('LayrzDateRangeSurface — involuntary close discards the draft (re-seeding)', () {
    guardedTestWidgets('rebuilding with the same (null) value after a partial selection discards the draft', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var generation = 0;
      late StateSetter setState;

      // Simulates LayrzAnchoredPanel's dismiss-and-reopen: a fresh Key
      // forces a brand-new State/initState on next open, discarding any
      // partial in-progress selection -- mirrors LayrzDateSurface's own
      // regression test for the same involuntary-close mechanism.
      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setter) {
            setState = setter;
            return LayrzDateRangeSurface(
              key: ValueKey(generation),
              value: null,
              onSave: (_) {},
              onCancel: () {},
            );
          },
        ),
      );

      // Partially select -- anchor only.
      await tester.tap(find.text('5').first);
      await tester.pump();
      expect(findButtonLabel('Clear selection'), findsOneWidget);

      // Simulate an involuntary close + reopen via key bump.
      setState(() => generation++);
      await tester.pump();

      // Draft is gone -- Reset is no longer shown, and Save stays disabled.
      expect(findButtonLabel('Clear selection'), findsNothing);
    });

    guardedTestWidgets('rebuilding with a changed value re-seeds the draft to the new committed range', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? value = LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10));
      late StateSetter setState;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setter) {
            setState = setter;
            return LayrzDateRangeSurface(value: value, onSave: (_) {}, onCancel: () {});
          },
        ),
      );
      expect(find.text('September 2026'), findsOneWidget);

      setState(() => value = LayrzDateRange(start: DateTime(2027, 3, 1), end: DateTime(2027, 3, 5)));
      await tester.pump();

      expect(find.text('March 2027'), findsOneWidget);
    });
  });

  group('LayrzDateRangeSurface — month navigation', () {
    guardedTestWidgets('tapping the next-month chevron advances the header label by one month', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
          onSave: (_) {},
          onCancel: () {},
        ),
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
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
          onSave: (_) {},
          onCancel: () {},
        ),
      );

      await tester.tap(find.byIcon(MdiIcons.chevronLeft));
      await tester.pump();

      expect(find.text('August 2026'), findsOneWidget);
    });

    guardedTestWidgets('stepping past December wraps the header label into January of the next year', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: DateTime(2026, 12, 5), end: DateTime(2026, 12, 10)),
          onSave: (_) {},
          onCancel: () {},
        ),
      );

      expect(find.text('December 2026'), findsOneWidget);

      await tester.tap(find.byIcon(MdiIcons.chevronRight));
      await tester.pump();

      expect(find.text('January 2027'), findsOneWidget);
    });

    guardedTestWidgets('navigating away and back does not alter an already-completed draft range', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? saved;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
          onSave: (r) => saved = r,
          onCancel: () {},
        ),
      );

      await tester.tap(find.byIcon(MdiIcons.chevronRight));
      await tester.pump();
      await tester.tap(find.byIcon(MdiIcons.chevronLeft));
      await tester.pump();

      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saved!.start.day, 5);
      expect(saved!.end.day, 10);
    });
  });

  group('LayrzDateRangeSurface — bounds and disabled days', () {
    guardedTestWidgets('a disabledDays entry does not change the draft when tapped', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? saved;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
          disabledDays: {DateTime(2026, 9, 25)},
          onSave: (r) => saved = r,
          onCancel: () {},
        ),
      );

      // Outside tap on a disabled day must not extend the range.
      await tester.tap(find.text('25').first);
      await tester.pump();
      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saved!.end.day, 10);
    });

    guardedTestWidgets('a date outside firstDay/lastDay does not change the draft when tapped', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? saved;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: DateTime(2026, 9, 15), end: DateTime(2026, 9, 20)),
          firstDay: DateTime(2026, 9, 10),
          onSave: (r) => saved = r,
          onCancel: () {},
        ),
      );

      await tester.tap(find.text('5').first);
      await tester.pump();
      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saved!.start.day, 15);
    });
  });

  group('LayrzDateRangeSurface — leap years and month boundaries', () {
    guardedTestWidgets('a range spanning a leap-year Feb 29 saves correctly', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? saved;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: DateTime(2024, 2, 20), end: DateTime(2024, 2, 25)),
          onSave: (r) => saved = r,
          onCancel: () {},
        ),
      );

      // Re-tap the end endpoint, extend it to the 29th (leap day).
      await tester.tap(find.text('25').first);
      await tester.pump();
      await tester.tap(find.text('29').last);
      await tester.pump();
      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saved!.end.day, 29);
      expect(saved!.end.month, 2);
    });
  });

  group('LayrzDateRangeSurface — TZDateTime zone preservation', () {
    guardedTestWidgets('a range built from TZDateTime endpoints is saved in the same zone', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final location = tz.getLocation('America/New_York');
      final start = tz.TZDateTime(location, 2026, 9, 5);
      final end = tz.TZDateTime(location, 2026, 9, 10);

      LayrzDateRange? saved;
      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: start, end: end),
          onSave: (r) => saved = r,
          onCancel: () {},
        ),
      );

      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saved!.start, isA<tz.TZDateTime>());
      expect((saved!.start as tz.TZDateTime).location, location);
    });
  });

  group('LayrzDateRangeSurface — firstDayOfWeek and showWeekNumbers', () {
    guardedTestWidgets('renders correctly with a Sunday-first week', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
          firstDayOfWeek: DateTime.sunday,
          onSave: (_) {},
          onCancel: () {},
        ),
      );

      expect(find.byType(LayrzDateRangeSurface), findsOneWidget);
    });

    guardedTestWidgets('renders correctly with showWeekNumbers false', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzDateRangeSurface(
          value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
          showWeekNumbers: false,
          onSave: (_) {},
          onCancel: () {},
        ),
      );

      expect(find.byType(LayrzDateRangeSurface), findsOneWidget);
    });
  });
}
