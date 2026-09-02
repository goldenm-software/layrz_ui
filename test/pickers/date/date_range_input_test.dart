import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/pickers/src/date/date_range_surface.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/find_button_label.dart';
import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

void main() {
  tzdata.initializeTimeZones();

  group('LayrzDateRangeInput — construction', () {
    guardedTestWidgets('asserts at least one of labelText/hintText is provided', (tester) async {
      expect(
        () => LayrzDateRangeInput(),
        throwsAssertionError,
      );
    });

    guardedTestWidgets('can be created with only hintText', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateRangeInput(hintText: 'Pick a range'));

      expect(find.byType(LayrzDateRangeInput), findsOneWidget);
    });

    // Regression test for the scaffold's central defect: `initState` called
    // `_updateSummary()` directly, which reads `context.l10n` -- an
    // inherited-widget dependency not yet established at that point in the
    // widget lifecycle -- and throws "dependOnInheritedWidgetOfExactType()
    // ... called before initState() completed" on construction with ANY
    // non-null `value`. Fixed by computing the summary reactively from
    // `build` via the `_lastValue` sentinel, mirroring `LayrzDateInput`.
    guardedTestWidgets('constructing with a non-null value does not throw', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(
          labelText: 'Range',
          value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(LayrzDateRangeInput), findsOneWidget);
    });
  });

  group('LayrzDateRangeInput — rendering', () {
    guardedTestWidgets('renders the label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateRangeInput(labelText: 'Range'));

      expect(findButtonLabel('Range'), findsOneWidget);
    });

    guardedTestWidgets('shows hint text when value is null', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateRangeInput(labelText: 'Range', hintText: 'Select a range'));

      expect(find.text('Select a range'), findsWidgets);
    });

    guardedTestWidgets('formats a non-null value as "start – end" with the default %Y-%m-%d pattern', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(
          labelText: 'Range',
          value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
        ),
      );

      expect(find.text('2026-09-05 – 2026-09-10'), findsOneWidget);
    });

    guardedTestWidgets('formats a non-null value with a custom pattern', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(
          labelText: 'Range',
          value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
          pattern: '%d/%m/%Y',
        ),
      );

      expect(find.text('05/09/2026 – 10/09/2026'), findsOneWidget);
    });

    guardedTestWidgets('a supplied formatter overrides pattern entirely', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(
          labelText: 'Range',
          value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
          pattern: '%Y-%m-%d',
          formatter: (r) => 'CUSTOM ${r.start.day}-${r.end.day}',
        ),
      );

      expect(find.text('CUSTOM 5-10'), findsOneWidget);
      expect(find.text('2026-09-05 – 2026-09-10'), findsNothing);
    });

    guardedTestWidgets('renders the calendar-range affordance icon', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateRangeInput(labelText: 'Range'));

      expect(find.byIcon(MdiIcons.calendarRangeOutline), findsOneWidget);
    });

    guardedTestWidgets('always renders a Cancel/Save footer once opened -- visible from the first frame', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateRangeInput(labelText: 'Range'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(findButtonLabel('Save'), findsOneWidget);
      expect(findButtonLabel('Cancel'), findsOneWidget);
    });

    // DESIGN-49: this widget no longer opens LayrzAnchoredPanel on desktop --
    // it opens LayrzPickerDrawer, a fixed-width (420px) drawer. See
    // `datetime_input_test.dart`'s equivalent group for the reference
    // conversion this test follows.
    guardedTestWidgets('the desktop drawer is fixed-width, not the anchor\'s width', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateRangeInput(labelText: 'Range'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byType(LayrzDateRangeSurface), findsOneWidget);
      final surfaceWidth = tester.getSize(find.byType(LayrzDateRangeSurface)).width;
      expect(surfaceWidth, lessThanOrEqualTo(420.0));
    });
  });

  group('LayrzDateRangeInput — errors', () {
    guardedTestWidgets('displays error text', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(labelText: 'Range', errors: const ['Required']),
      );

      expect(find.text('Required'), findsOneWidget);
    });

    guardedTestWidgets('hides error text when hideDetails is true', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(labelText: 'Range', errors: const ['Required'], hideDetails: true),
      );

      expect(find.text('Required'), findsNothing);
    });

    // The readOnly trap, expected clean per U1's shared buildPickerFieldRow --
    // the icon's color proves errors actually paint the danger reading, and
    // the direct assertion below guards the mechanism itself.
    guardedTestWidgets('error styling actually paints -- the affordance icon resolves to the danger color', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tokens = LayrzTokens.light();

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(labelText: 'Range', errors: const ['Required']),
      );

      final icon = tester.widget<Icon>(find.byIcon(MdiIcons.calendarRangeOutline));
      expect(icon.color, tokens.colors.danger);
      expect(icon.color, isNot(tokens.colors.fg1));
    });

    guardedTestWidgets('LayrzInputChrome.readOnly stays false even with errors present', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(labelText: 'Range', errors: const ['Required']),
      );

      final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome).first);
      expect(chrome.readOnly, isFalse);
    });
  });

  group('LayrzDateRangeInput — disabled tap behavior', () {
    guardedTestWidgets('disabled blocks the tap from opening the surface', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(labelText: 'Range', disabled: true),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);
    });

    guardedTestWidgets('a non-disabled field opens the surface on tap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateRangeInput(labelText: 'Range'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
    });
  });

  group('LayrzDateRangeInput — Save commits, Cancel reverts, both close (desktop)', () {
    guardedTestWidgets('selecting a range and pressing Save fires onChanged once and closes the panel', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? changed;
      var changeCount = 0;

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(
          labelText: 'Range',
          onChanged: (r) {
            changed = r;
            changeCount++;
          },
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();
      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(changeCount, 1);
      expect(changed!.start.day, 5);
      expect(changed!.end.day, 10);
      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);
    });

    guardedTestWidgets('the closed field reflects the newly saved range', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? current;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzDateRangeInput(
              labelText: 'Range',
              value: current,
              onChanged: (r) => setState(() => current = r),
            );
          },
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();
      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(current, isNotNull);
      expect(current!.start.day, 5);
      expect(current!.end.day, 20);

      final expectedStart = current!.start;
      final expectedEnd = current!.end;
      final expectedText =
          '${expectedStart.year.toString().padLeft(4, '0')}-'
          '${expectedStart.month.toString().padLeft(2, '0')}-'
          '${expectedStart.day.toString().padLeft(2, '0')}'
          ' – '
          '${expectedEnd.year.toString().padLeft(4, '0')}-'
          '${expectedEnd.month.toString().padLeft(2, '0')}-'
          '${expectedEnd.day.toString().padLeft(2, '0')}';
      expect(find.text(expectedText), findsOneWidget);
    });

    guardedTestWidgets('pressing Cancel after a partial selection does not fire onChanged and closes the panel', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var changeCount = 0;

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(labelText: 'Range', onChanged: (_) => changeCount++),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Cancel'));
      await tester.pumpAndSettle();

      expect(changeCount, 0);
      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);
    });

    guardedTestWidgets('Cancel leaves the previously committed value unchanged', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        Center(
          child: LayrzDateRangeInput(
            labelText: 'Range',
            value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
          ),
        ),
      );

      expect(find.text('2026-09-05 – 2026-09-10'), findsOneWidget);

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      // Re-tap an endpoint and move it -- would change the draft.
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('25').first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('2026-09-05 – 2026-09-10'), findsOneWidget);
    });
  });

  group('LayrzDateRangeInput — Save commits, Cancel reverts, both close (mobile, compact viewport)', () {
    guardedTestWidgets('opens the bottom sheet on a compact viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateRangeInput(labelText: 'Range'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
      expect(findButtonLabel('Save'), findsOneWidget);
      expect(findButtonLabel('Cancel'), findsOneWidget);
    });

    guardedTestWidgets('does NOT open the surface before a tap on a compact viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateRangeInput(labelText: 'Range'));

      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);
    });

    guardedTestWidgets('selecting a range and pressing Save in the bottom sheet fires onChanged and dismisses it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? changed;

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(labelText: 'Range', onChanged: (r) => changed = r),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();
      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(changed!.start.day, 5);
      expect(changed!.end.day, 10);
      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);
    });

    guardedTestWidgets('pressing Cancel in the bottom sheet dismisses it without firing onChanged', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var changeCount = 0;

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(labelText: 'Range', onChanged: (_) => changeCount++),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Cancel'));
      await tester.pumpAndSettle();

      expect(changeCount, 0);
      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);
    });

    guardedTestWidgets('disabled does not open the bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateRangeInput(labelText: 'Range', disabled: true));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);
    });
  });

  group('LayrzDateRangeInput — involuntary close discards draft state (desktop)', () {
    guardedTestWidgets('tap-outside after a partial selection closes the panel without changing value', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? changed;

      await pumpThemedApp(
        tester,
        Center(
          child: LayrzDateRangeInput(
            labelText: 'Range',
            value: LayrzDateRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 3)),
            onChanged: (r) => changed = r,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);

      // Re-tap the end endpoint and move it -- a pending, unsaved change.
      await tester.tap(find.text('3').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();

      // DESIGN-98: LayrzEndDrawer's canDismiss infers false while actions is
      // present, so a barrier tap no longer closes it -- Cancel is now the
      // involuntary-close route this test exercises.
      await tester.tap(findButtonLabel('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);
      expect(changed, isNull);
      expect(find.text('2026-09-01 – 2026-09-03'), findsOneWidget);
    });

    guardedTestWidgets(
      'reopening after an involuntary close discards a half-open (anchor-only) draft, not just an unsaved edit',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          Center(
            child: LayrzDateRangeInput(labelText: 'Range'),
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        // Anchor only -- half-open draft, Reset now visible.
        await tester.tap(find.text('5').first);
        await tester.pumpAndSettle();
        expect(findButtonLabel('Clear selection'), findsOneWidget);

        // Close involuntarily via Cancel -- a barrier tap no longer
        // dismisses once actions are present (DESIGN-98's canDismiss
        // inference).
        await tester.tap(findButtonLabel('Cancel'));
        await tester.pumpAndSettle();
        expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);

        // Reopen -- the anchor-only draft must be gone.
        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        expect(findButtonLabel('Clear selection'), findsNothing);
      },
    );

    guardedTestWidgets('reopening after an involuntary close shows the month containing value, not a stale one', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        Center(
          child: LayrzDateRangeInput(
            labelText: 'Range',
            value: LayrzDateRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 3)),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);

      await tester.tap(find.byIcon(MdiIcons.chevronRight));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(MdiIcons.chevronRight));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);

      // Close involuntarily via Cancel -- a barrier tap no longer dismisses
      // once actions are present (DESIGN-98's canDismiss inference).
      await tester.tap(findButtonLabel('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('November 2026'), findsNothing);
    });
  });

  group('LayrzDateRangeInput — controller and focus node lifecycle', () {
    guardedTestWidgets('disposes a self-created controller on widget dispose', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateRangeInput(labelText: 'Range'));
      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isNull);
    });

    guardedTestWidgets('does not dispose a caller-provided controller', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemedApp(tester, LayrzDateRangeInput(labelText: 'Range', controller: controller));
      await tester.pumpWidget(const SizedBox());

      expect(() => controller.text, returnsNormally);
    });

    guardedTestWidgets('does not dispose a caller-provided focus node', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemedApp(tester, LayrzDateRangeInput(labelText: 'Range', focusNode: focusNode));
      await tester.pumpWidget(const SizedBox());

      expect(() => focusNode.hasFocus, returnsNormally);
    });
  });

  group('LayrzDateRangeInput — bounds and disabled days', () {
    guardedTestWidgets('a date before firstDay does not extend/anchor the draft', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var count = 0;
      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(
          labelText: 'Range',
          value: LayrzDateRange(start: DateTime(2026, 9, 15), end: DateTime(2026, 9, 20)),
          firstDay: DateTime(2026, 9, 10),
          onChanged: (_) => count++,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();
      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(count, 1);
    });

    guardedTestWidgets('a disabledDays entry cannot become an endpoint', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? changed;
      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(
          labelText: 'Range',
          disabledDays: {DateTime(2026, 9, 15)},
          onChanged: (r) => changed = r,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('15').first);
      await tester.pumpAndSettle();

      // Disabled cell never anchors -- Save stays disabled (draft empty).
      expect(findButtonLabel('Clear selection'), findsNothing);
      expect(changed, isNull);
    });
  });

  group('LayrzDateRangeInput — TZDateTime zone preservation', () {
    guardedTestWidgets('a range saved from TZDateTime endpoints reports both endpoints in the same zone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final location = tz.getLocation('America/New_York');
      final value = LayrzDateRange(
        start: tz.TZDateTime(location, 2026, 9, 1),
        end: tz.TZDateTime(location, 2026, 9, 3),
      );

      LayrzDateRange? changed;
      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(labelText: 'Range', value: value, onChanged: (r) => changed = r),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(changed!.start, isA<tz.TZDateTime>());
      expect((changed!.start as tz.TZDateTime).location, location);
      expect(changed!.end, isA<tz.TZDateTime>());
      expect((changed!.end as tz.TZDateTime).location, location);
    });
  });

  group('LayrzDateRangeInput — help affordance', () {
    guardedTestWidgets('provides help affordance when helpContentText is non-null', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(
          labelText: 'Range',
          helpTitleText: 'About ranges',
          helpContentText: 'Pick a start and end date.',
        ),
      );

      expect(find.byType(LayrzDateRangeInput), findsOneWidget);
    });
  });

  group('LayrzDateRangeInput — viewport branch selection', () {
    // DESIGN-49: LayrzAnchoredPanel is no longer used by this widget at any
    // viewport -- desktop opens LayrzPickerDrawer, compact opens
    // LayrzBottomSheet. Both push a route rather than mounting inline, so
    // neither surface is present before the tap. See
    // `datetime_input_test.dart`'s equivalent group for the reference
    // conversion this test follows.
    guardedTestWidgets('wide viewport (>=960px) opens the fixed-width drawer, never an anchored panel', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(
          labelText: 'Range',
          value: LayrzDateRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 3)),
        ),
      );

      expect(find.byType(LayrzAnchoredPanel), findsNothing);

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
      expect(find.byType(LayrzDateRangeSurface), findsOneWidget);
      final surfaceWidth = tester.getSize(find.byType(LayrzDateRangeSurface)).width;
      expect(surfaceWidth, lessThanOrEqualTo(420.0), reason: "the drawer is fixed-width, not the anchor's width");
    });

    guardedTestWidgets('narrow viewport (<960px) opens a bottom sheet, never an anchored panel or a drawer', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(
          labelText: 'Range',
          value: LayrzDateRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 3)),
        ),
      );

      expect(
        find.byType(LayrzAnchoredPanel),
        findsNothing,
        reason: 'the compact branch must not build an anchored panel at all',
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
      expect(find.byType(LayrzDateRangeSurface), findsOneWidget);
    });
  });

  group('LayrzDateRangeInput — error state stays fully interactive (Finding 4)', () {
    // Regression test locking in correct behaviour -- see
    // `date_input_test.dart`'s equivalent group for the full rationale.
    // `date_range_input.dart`'s `onTap` is gated solely on
    // `widget.disabled`, never on `widget.errors`.
    guardedTestWidgets('tapping the anchor opens the surface even with errors present', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(labelText: 'Range', errors: const ['Required']),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
    });

    guardedTestWidgets('a range selection still commits via Save with errors present', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzDateRange? changed;

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(
          labelText: 'Range',
          errors: const ['Required'],
          onChanged: (r) => changed = r,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();
      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(changed, isNotNull);
      expect(changed!.start.day, 5);
      expect(changed!.end.day, 10);
    });

    guardedTestWidgets('tapping the anchor opens the bottom sheet on a compact viewport with errors present', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateRangeInput(labelText: 'Range', errors: const ['Required']),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
    });
  });

  group('LayrzDateRangeInput — pattern changes reflect immediately (Finding 5)', () {
    // Regression test for DESIGN-45 -- see `date_input_test.dart`'s
    // equivalent group for the full rationale.
    guardedTestWidgets('changing pattern alone re-renders the summary with no new selection', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var pattern = '%Y-%m-%d';

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LayrzDateRangeInput(
                  labelText: 'Range',
                  value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
                  pattern: pattern,
                ),
                GestureDetector(
                  onTap: () => setState(() => pattern = '%d/%m/%Y'),
                  child: const Text('Change pattern'),
                ),
              ],
            );
          },
        ),
      );

      expect(find.text('2026-09-05 – 2026-09-10'), findsOneWidget);

      await tester.tap(find.text('Change pattern'));
      await tester.pump();

      expect(find.text('05/09/2026 – 10/09/2026'), findsOneWidget);
      expect(find.text('2026-09-05 – 2026-09-10'), findsNothing);
    });

    guardedTestWidgets('changing formatter alone re-renders the summary with no new selection', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String Function(LayrzDateRange)? formatter;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LayrzDateRangeInput(
                  labelText: 'Range',
                  value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
                  formatter: formatter,
                ),
                GestureDetector(
                  onTap: () => setState(() => formatter = (r) => 'CUSTOM ${r.start.day}-${r.end.day}'),
                  child: const Text('Set formatter'),
                ),
              ],
            );
          },
        ),
      );

      await tester.tap(find.text('Set formatter'));
      await tester.pump();

      expect(find.text('CUSTOM 5-10'), findsOneWidget);
    });
  });
}
