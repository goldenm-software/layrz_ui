import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/number/number_input.dart';
import 'package:layrz_ui/src/pickers/src/models/time_of_day.dart';
import 'package:layrz_ui/src/pickers/src/shared/time_fields_panel.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

/// Every real caller (`*_surface.dart` files) hosts this panel inside a
/// bounded-width ancestor ([LayrzAnchoredPanel] or [LayrzBottomSheet]'s
/// `Padding`) -- `pumpThemed` alone gives its child unbounded width via
/// `Center`, which the panel's own `Row`-of-`Expanded` layout cannot resolve.
/// This wrapper reproduces the bounded-width context every real usage
/// already provides.
Widget _bounded(Widget child) => SizedBox(width: 700, child: child);

/// Same as [_bounded] but with a caller-chosen [width], for the narrow-width
/// regressions below that need widths other than the suite's usual 700px.
Widget _boundedWidth(Widget child, double width) => SizedBox(width: width, child: child);

void main() {
  group('LayrzPickersTimeFieldsPanel — zero clock/dial affordance', () {
    guardedTestWidgets('the tree contains no clock or dial widget of any kind', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(LayrzPickersTimeFieldsPanel(value: const LayrzTimeOfDay(hour: 9, minute: 30), onChanged: (_) {})),
      );

      // Fields are text inputs; there is no dedicated clock-face/dial type
      // in this library at all, so this asserts on the field count instead.
      // Three EditableText fields exist (hour, minute, seconds -- the
      // seconds field stays mounted but hidden via
      // Visibility(maintainState: true) per D15's no-reflow rule, see the
      // showSeconds group below) and nothing else interactive besides them.
      expect(find.byType(EditableText), findsNWidgets(3));
    });
  });

  group('LayrzPickersTimeFieldsPanel — showSeconds toggling without reflow', () {
    guardedTestWidgets('showSeconds true renders three fields', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30, second: 15),
            showSeconds: true,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(EditableText), findsNWidgets(3));
    });

    guardedTestWidgets('showSeconds false renders two visible fields but the row height is unchanged', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(LayrzPickersTimeFieldsPanel(value: const LayrzTimeOfDay(hour: 9, minute: 30), onChanged: (_) {})),
      );

      final withoutSecondsSize = tester.getSize(find.byType(LayrzPickersTimeFieldsPanel));

      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            showSeconds: true,
            onChanged: (_) {},
          ),
        ),
      );

      final withSecondsSize = tester.getSize(find.byType(LayrzPickersTimeFieldsPanel));

      // D15: toggling showSeconds must never reflow (change the panel's own
      // height) -- the seconds field is always present in the layout,
      // merely hidden via Visibility(maintainSize: true) when not shown.
      expect(withoutSecondsSize.height, withSecondsSize.height);
    });
  });

  group('LayrzPickersTimeFieldsPanel — trap 4: fields never close the hosting surface', () {
    guardedTestWidgets('typing into the hour field reports via onChanged only, panel stays mounted', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzTimeOfDay? reported;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onChanged: (t) => reported = t,
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText).first, '14');
      await tester.pump();

      expect(reported, isNotNull);
      expect(reported!.hour, 14);
      // The widget itself never disappears from the tree as a result of a
      // field edit -- there is no close/dismiss mechanism reachable from
      // this widget at all, which is the trap-4 contract this test proves.
      expect(find.byType(LayrzPickersTimeFieldsPanel), findsOneWidget);
    });
  });

  group('LayrzPickersTimeFieldsPanel — clamping', () {
    guardedTestWidgets('typing an out-of-range hour is clamped, not dropped', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzTimeOfDay? reported;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onChanged: (t) => reported = t,
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText).first, '99');
      await tester.pump();

      expect(reported, isNotNull);
      expect(reported!.hour, 23);
    });

    guardedTestWidgets('typing an out-of-range minute is clamped, not dropped', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzTimeOfDay? reported;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onChanged: (t) => reported = t,
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText).at(1), '99');
      await tester.pump();

      expect(reported, isNotNull);
      expect(reported!.minute, 59);
    });
  });

  group('LayrzPickersTimeFieldsPanel — 12h/24h', () {
    guardedTestWidgets('use24HourFormat true (default) hides the meridiem control', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(LayrzPickersTimeFieldsPanel(value: const LayrzTimeOfDay(hour: 9, minute: 30), onChanged: (_) {})),
      );

      expect(find.text('AM'), findsNothing);
      expect(find.text('PM'), findsNothing);
    });

    guardedTestWidgets('use24HourFormat false shows an AM/PM meridiem control', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            use24HourFormat: false,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('AM'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
    });

    guardedTestWidgets('tapping PM in 12h mode shifts the hour into the afternoon', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzTimeOfDay? reported;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            use24HourFormat: false,
            onChanged: (t) => reported = t,
          ),
        ),
      );

      await tester.tap(find.text('PM'));
      await tester.pump();

      expect(reported, isNotNull);
      expect(reported!.hour, 21);
    });
  });

  group('LayrzPickersTimeFieldsPanel — narrow-width label switch (no overflow)', () {
    guardedTestWidgets(
      'a real 400px phone width with showSeconds true does not overflow LayrzNumberInput chrome',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          _boundedWidth(
            LayrzPickersTimeFieldsPanel(
              value: const LayrzTimeOfDay(hour: 9, minute: 30, second: 15),
              showSeconds: true,
              onChanged: (_) {},
            ),
            400,
          ),
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'the panel must fall back to the short-form unit labels below '
              'LayrzPickersTimeField.kNarrowWidth per field so a real 400px phone '
              'width (the mobile bottom-sheet path on virtually every real device) '
              'never overflows LayrzNumberInput\'s chrome, mirroring '
              'duration_picker_panel_test.dart\'s identical 400px regression',
        );
      },
    );

    // At a real 400px phone width, hour/minute/second/meridiem cannot all
    // share one row even with 1-character labels (see _kFieldFloorWidth's
    // doc comment in time_fields_panel.dart for the LayrzNumberInput probe
    // this is based on: overflow persists up to 118px, clean from 120px, and
    // 400px leaves each of the three time fields only ~113px once the
    // meridiem control and spacing are reserved). LayrzPickersTimeFieldsPanel
    // resolves this by wrapping the meridiem control onto its own row below
    // the three time fields -- this test proves BOTH that nothing overflows
    // AND that the wrap actually happened (a widget below the row, not just
    // the absence of an exception), so a regression that silently reintroduces
    // the overflow some other way would still fail this test.
    guardedTestWidgets(
      'a real 400px phone width with showSeconds true and use24HourFormat false wraps the meridiem control '
      'onto its own row instead of overflowing',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          _boundedWidth(
            LayrzPickersTimeFieldsPanel(
              value: const LayrzTimeOfDay(hour: 9, minute: 30, second: 15),
              showSeconds: true,
              use24HourFormat: false,
              onChanged: (_) {},
            ),
            400,
          ),
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'wrapping the meridiem control onto its own row must give the three time fields the full '
              'available width, clearing _kFieldFloorWidth even at a real 400px phone width',
        );

        // The meridiem control (found via its "AM"/"PM" text) must sit BELOW
        // the three time fields (found via the hour field's EditableText),
        // not to their right -- proving the wrap actually happened, not just
        // that nothing threw.
        final hourFieldTop = tester.getTopLeft(find.byType(EditableText).first).dy;
        final meridiemTop = tester.getTopLeft(find.text('AM')).dy;
        expect(
          meridiemTop,
          greaterThan(hourFieldTop),
          reason: 'the meridiem control must be wrapped onto a row below the time fields, not beside them',
        );
      },
    );

    guardedTestWidgets(
      'a comfortable width with showSeconds true and use24HourFormat false keeps the meridiem control on the '
      'same row as the time fields (the wrap must not become the default)',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          _boundedWidth(
            LayrzPickersTimeFieldsPanel(
              value: const LayrzTimeOfDay(hour: 9, minute: 30, second: 15),
              showSeconds: true,
              use24HourFormat: false,
              onChanged: (_) {},
            ),
            900,
          ),
        );

        expect(tester.takeException(), isNull);

        final hourFieldTop = tester.getTopLeft(find.byType(EditableText).first).dy;
        final meridiemTop = tester.getTopLeft(find.text('AM')).dy;
        expect(
          meridiemTop,
          closeTo(hourFieldTop, 20),
          reason:
              'at a comfortable width the meridiem control must stay on the same row as the time fields '
              '(a small delta is expected from differing intrinsic content heights within the row; the '
              'wrapped case above puts it a full row -- tens of pixels -- further down)',
        );
      },
    );

    // CHANGED (Finding 3, DESIGN-98): this test previously pumped at 800px
    // and expected short-form labels, on the assumption that the three time
    // fields always share a single row (perFieldWidth = (800 - 6*2)/3 ~=
    // 262.7px, below kNarrowWidth). That assumption no longer holds: `build`
    // now derives `fieldsPerRow` FROM kNarrowWidth itself (see the class
    // doc's "Fields wrap across rows" section and the `fieldsPerRow` local
    // in `build`), so fieldsPerRow can never resolve to a count whose
    // resulting perFieldWidth falls below kNarrowWidth -- at 800px this now
    // solves to 2 fields per row at ~397px each, comfortably long-form. The
    // narrow-label switch is only reachable when the PANEL ITSELF is
    // narrower than kNarrowWidth (280.0): fieldsPerRow is already clamped to
    // its floor of 1 at that point, so a lone field still cannot clear the
    // threshold no matter how few fields share its row. This test now
    // exercises that genuinely narrow case instead of the retired
    // three-fields-forced-onto-one-row scenario.
    guardedTestWidgets('below the narrow-width threshold, fields show the short-form unit labels', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // fieldsPerRow floors to 1 at any width (fields wrap one per row well
      // before this point), so a 250px panel gives the lone field the full
      // 250px -- below LayrzPickersTimeField.kNarrowWidth (280.0).
      await pumpThemed(
        tester,
        _boundedWidth(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30, second: 15),
            showSeconds: true,
            onChanged: (_) {},
          ),
          250,
        ),
      );

      expect(find.text('Hours'), findsNothing);
      expect(find.text('Minutes'), findsNothing);
      expect(find.text('Seconds'), findsNothing);
      expect(
        find.text('h'),
        findsOneWidget,
        reason: 'hour is 9 (plural form), and singular/plural short forms are both "h" in English',
      );
      expect(find.text('m'), findsOneWidget);
      expect(find.text('s'), findsOneWidget);
    });

    // CHANGED (Finding 3, DESIGN-98): 900px trivially stays long-form under
    // the new arithmetic too (fieldsPerRow=3, perField=296px, same as
    // before) -- kept at 900px specifically so this test's own comment
    // continues to double as a sanity check that _kMaxRowWidth (900.0) does
    // not regress the case it was originally measured against.
    guardedTestWidgets('at or above the narrow-width threshold, fields show the unabridged unit labels', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // use24HourFormat: true (no meridiem reservation): fieldsPerRow solves
      // to 3 at 900px (900 capped by _kMaxRowWidth), perFieldWidth =
      // (900 - 6*2)/3 = 296px, at or above LayrzPickersTimeField.kNarrowWidth
      // (280.0).
      await pumpThemed(
        tester,
        _boundedWidth(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30, second: 15),
            showSeconds: true,
            onChanged: (_) {},
          ),
          900,
        ),
      );

      expect(find.text('Hours'), findsOneWidget);
      expect(find.text('Minutes'), findsOneWidget);
      expect(find.text('Seconds'), findsOneWidget);
      expect(find.text('h'), findsNothing);
      expect(find.text('m'), findsNothing);
      expect(find.text('s'), findsNothing);
    });

    // NEW (Finding 3, DESIGN-98): the actual regression this whole change
    // targets -- inside the real LayrzEndDrawer's ~372px, the three time
    // fields must stack one per row, each spanning the panel's own full
    // width, with the long-form labels restored (the maintainer's own
    // words: "it should look like the number input").
    guardedTestWidgets('at drawer width (372px), fields stack one per row with unabridged labels restored', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _boundedWidth(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30, second: 15),
            showSeconds: true,
            onChanged: (_) {},
          ),
          372,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Hours'), findsOneWidget);
      expect(find.text('Minutes'), findsOneWidget);
      expect(find.text('Seconds'), findsOneWidget);

      // Each field occupies its own row: the minute field's top sits below
      // the hour field's bottom edge, and the second field's top sits below
      // the minute field's bottom edge -- proving three stacked rows, not
      // one row of three fields side by side.
      final hourRect = tester.getRect(find.byType(EditableText).at(0));
      final minuteRect = tester.getRect(find.byType(EditableText).at(1));
      final secondRect = tester.getRect(find.byType(EditableText).at(2));
      expect(minuteRect.top, greaterThanOrEqualTo(hourRect.bottom));
      expect(secondRect.top, greaterThanOrEqualTo(minuteRect.bottom));

      // Each field's own LayrzNumberInput chrome spans (approximately) the
      // panel's own full width -- the "look like the number input"
      // full-width row shape, not a narrow field stranded in a wide row.
      // Measured via LayrzNumberInput's own outer box, not its innermost
      // EditableText (which does not itself stretch to fill the chrome
      // around it).
      final panelWidth = tester.getSize(find.byType(LayrzPickersTimeFieldsPanel)).width;
      final hourFieldWidth = tester.getSize(find.byType(LayrzNumberInput).first).width;
      expect(hourFieldWidth, greaterThan(panelWidth * 0.8));
    });
  });

  group('LayrzPickersTimeFieldsPanel — no interval snapping', () {
    guardedTestWidgets('an arbitrary minute value like 37 is representable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzTimeOfDay? reported;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onChanged: (t) => reported = t,
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText).at(1), '37');
      await tester.pump();

      expect(reported, isNotNull);
      expect(reported!.minute, 37);
    });
  });
}
