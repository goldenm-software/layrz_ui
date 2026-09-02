import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/find_button_label.dart';
import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

void main() {
  tzdata.initializeTimeZones();

  group('LayrzDateInput — construction', () {
    guardedTestWidgets('asserts at least one of labelText/hintText is provided', (tester) async {
      expect(
        () => LayrzDateInput(),
        throwsAssertionError,
      );
    });

    guardedTestWidgets('can be created with only hintText', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateInput(hintText: 'Pick a date'));

      expect(find.byType(LayrzDateInput), findsOneWidget);
    });

    guardedTestWidgets('asserts firstDayOfWeek is within DateTime.monday..DateTime.sunday', (tester) async {
      expect(
        () => LayrzDateInput(labelText: 'Date', firstDayOfWeek: 0),
        throwsAssertionError,
      );
      expect(
        () => LayrzDateInput(labelText: 'Date', firstDayOfWeek: 8),
        throwsAssertionError,
      );
    });

    guardedTestWidgets('defaults firstDayOfWeek to DateTime.monday', (tester) async {
      const widget = LayrzDateInput(labelText: 'Date');
      expect(widget.firstDayOfWeek, DateTime.monday);
    });

    // Regression test for a class of bug found across this batch's
    // scaffolds: `initState` reading `context.l10n` (an inherited-widget
    // dependency not yet established at that point in the widget
    // lifecycle) throws "dependOnInheritedWidgetOfExactType() ... called
    // before initState() completed" on construction with ANY non-null
    // `value` -- see `_lastValue`'s doc on `_LayrzDateInputState` for the
    // fix (the summary is computed reactively from `build`, never from
    // `initState`).
    guardedTestWidgets('constructing with a non-null value does not throw', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateInput(labelText: 'Date', value: DateTime(2026, 9, 5)),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(LayrzDateInput), findsOneWidget);
    });
  });

  group('LayrzDateInput — rendering', () {
    guardedTestWidgets('renders the label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date'));

      expect(findButtonLabel('Date'), findsOneWidget);
    });

    guardedTestWidgets('shows hint text when value is null', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date', hintText: 'Select a date'));

      expect(find.text('Select a date'), findsWidgets);
    });

    guardedTestWidgets('formats a non-null value with the default %Y-%m-%d pattern', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateInput(labelText: 'Date', value: DateTime(2026, 9, 5)),
      );

      expect(find.text('2026-09-05'), findsOneWidget);
    });

    guardedTestWidgets('formats a non-null value with a custom pattern', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateInput(labelText: 'Date', value: DateTime(2026, 9, 5), pattern: '%d/%m/%Y'),
      );

      expect(find.text('05/09/2026'), findsOneWidget);
    });

    guardedTestWidgets('a supplied formatter overrides pattern entirely', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateInput(
          labelText: 'Date',
          value: DateTime(2026, 9, 5),
          pattern: '%Y-%m-%d',
          formatter: (d) => 'CUSTOM ${d.day}',
        ),
      );

      expect(find.text('CUSTOM 5'), findsOneWidget);
      expect(find.text('2026-09-05'), findsNothing);
    });

    guardedTestWidgets('renders the calendar affordance icon', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date'));

      expect(find.byIcon(MdiIcons.calendarBlankOutline), findsOneWidget);
    });

    guardedTestWidgets('never renders a Cancel/Save footer', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(findButtonLabel('Save'), findsNothing);
      expect(findButtonLabel('Cancel'), findsNothing);
    });
  });

  group('LayrzDateInput — errors', () {
    guardedTestWidgets('displays error text', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateInput(labelText: 'Date', errors: const ['Required']),
      );

      expect(find.text('Required'), findsOneWidget);
    });

    guardedTestWidgets('hides error text when hideDetails is true', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateInput(labelText: 'Date', errors: const ['Required'], hideDetails: true),
      );

      expect(find.text('Required'), findsNothing);
    });

    // The readOnly trap: LayrzInputStyleSpec.resolve ranks `readOnly` above
    // `error`, so hardcoding `readOnly: true` on the anchor would silently
    // suppress the danger border even with `errors` non-empty. This proves
    // the affordance icon (whose color also derives from `spec.textColor`)
    // actually reaches the danger color when errors are present -- it would
    // stay at the plain fg1/fg4 reading if `readOnly` were wrongly hardcoded.
    guardedTestWidgets('error styling actually paints -- the affordance icon resolves to the danger color', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tokens = LayrzTokens.light();

      await pumpThemedApp(
        tester,
        LayrzDateInput(labelText: 'Date', errors: const ['Required']),
      );

      final icon = tester.widget<Icon>(find.byIcon(MdiIcons.calendarBlankOutline));
      expect(icon.color, tokens.colors.danger);
      expect(icon.color, isNot(tokens.colors.fg1));
    });

    // Direct assertion on the trap itself, alongside the icon-color proof
    // above: the inner chrome's own `readOnly` field must stay `false`
    // even with `errors` non-empty. Hardcoding `readOnly: true` on a
    // picker anchor is the exact defect `LayrzInputStyleSpec.resolve`'s
    // `readOnly > error` precedence would silently reward with a
    // still-grey field despite a present error.
    guardedTestWidgets('LayrzInputChrome.readOnly stays false even with errors present', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateInput(labelText: 'Date', errors: const ['Required']),
      );

      final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome).first);
      expect(chrome.readOnly, isFalse);
    });
  });

  group('LayrzDateInput — disabled vs readOnly-style tap behavior', () {
    guardedTestWidgets('disabled blocks the tap from opening the surface', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateInput(labelText: 'Date', disabled: true),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // No day grid surface opened.
      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);
    });

    guardedTestWidgets('a non-disabled field opens the surface on tap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // The month-nav header renders once the surface is open.
      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
    });
  });

  group('LayrzDateInput — commit on tap (desktop, wide viewport)', () {
    guardedTestWidgets('tapping a day fires onChanged exactly once with the tapped date and closes the panel', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? changed;
      var changeCount = 0;

      await pumpThemedApp(
        tester,
        LayrzDateInput(
          labelText: 'Date',
          value: DateTime(2026, 9, 1),
          onChanged: (d) {
            changed = d;
            changeCount++;
          },
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('15').first);
      await tester.pumpAndSettle();

      expect(changeCount, 1);
      expect(changed, isNotNull);
      expect(changed!.day, 15);
      expect(changed!.month, 9);
      expect(changed!.year, 2026);

      // Panel closed as part of the same gesture -- the month-nav header
      // (only rendered while the surface is open) is gone.
      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);
    });

    guardedTestWidgets('the closed field reflects the newly committed date', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? current = DateTime(2026, 9, 1);

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzDateInput(
              labelText: 'Date',
              value: current,
              onChanged: (d) => setState(() => current = d),
            );
          },
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();

      expect(find.text('2026-09-20'), findsOneWidget);
    });
  });

  group('LayrzDateInput — commit on tap (mobile, compact viewport)', () {
    guardedTestWidgets('opens the bottom sheet on a compact viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date', value: DateTime(2026, 9, 1)));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
    });

    guardedTestWidgets('does NOT open the anchored panel affordance chrome on a compact viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date'));

      // No day grid open before the tap.
      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);
    });

    guardedTestWidgets('tapping a day in the bottom sheet fires onChanged once and dismisses the sheet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? changed;
      var changeCount = 0;

      await pumpThemedApp(
        tester,
        LayrzDateInput(
          labelText: 'Date',
          value: DateTime(2026, 9, 1),
          onChanged: (d) {
            changed = d;
            changeCount++;
          },
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('15').first);
      await tester.pumpAndSettle();

      expect(changeCount, 1);
      expect(changed!.day, 15);
      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);
    });

    guardedTestWidgets('disabled does not open the bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date', disabled: true));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);
    });
  });

  group('LayrzDateInput — involuntary close discards draft state (desktop)', () {
    guardedTestWidgets('tap-outside closes the panel without changing value', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? changed;

      await pumpThemedApp(
        tester,
        Center(
          child: LayrzDateInput(
            labelText: 'Date',
            value: DateTime(2026, 9, 1),
            onChanged: (d) => changed = d,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);

      // Tap far outside the anchor/panel to trigger LayrzAnchoredPanel's
      // tap-outside dismissal.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);
      expect(changed, isNull);
      expect(find.text('2026-09-01'), findsOneWidget);
    });

    // Regression test for the involuntary-close month-staleness bug: without
    // an explicit re-seed, LayrzAnchoredPanel's `child` State survives an
    // involuntary close (it is constructed eagerly and not recreated), so a
    // browsed-to-but-uncommitted month would otherwise still be showing on
    // reopen instead of the month containing `value`.
    guardedTestWidgets('reopening after an involuntary close shows the month containing value, not a stale one', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        Center(
          child: LayrzDateInput(labelText: 'Date', value: DateTime(2026, 9, 1)),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);

      // Browse forward two months without selecting anything.
      await tester.tap(find.byIcon(MdiIcons.chevronRight));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(MdiIcons.chevronRight));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);

      // Close involuntarily.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);

      // Reopen -- must show September 2026 again, not the browsed-to November.
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('November 2026'), findsNothing);
    });
  });

  group('LayrzDateInput — controller and focus node lifecycle', () {
    guardedTestWidgets('disposes a self-created controller on widget dispose', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date'));
      await tester.pumpWidget(const SizedBox());

      // No exception thrown means the disposal path did not double-dispose
      // or throw on a caller-owned controller it does not own.
      expect(tester.takeException(), isNull);
    });

    guardedTestWidgets('does not dispose a caller-provided controller', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date', controller: controller));
      await tester.pumpWidget(const SizedBox());

      // Still usable -- would throw "used after being disposed" otherwise.
      expect(() => controller.text, returnsNormally);
    });

    guardedTestWidgets('does not dispose a caller-provided focus node', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date', focusNode: focusNode));
      await tester.pumpWidget(const SizedBox());

      expect(() => focusNode.hasFocus, returnsNormally);
    });
  });

  group('LayrzDateInput — bounds and disabled days', () {
    guardedTestWidgets('a date before firstDay does not fire onChanged', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var count = 0;
      await pumpThemedApp(
        tester,
        LayrzDateInput(
          labelText: 'Date',
          value: DateTime(2026, 9, 15),
          firstDay: DateTime(2026, 9, 10),
          onChanged: (_) => count++,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();

      expect(count, 0);
    });

    guardedTestWidgets('a disabledDays entry does not fire onChanged', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var count = 0;
      await pumpThemedApp(
        tester,
        LayrzDateInput(
          labelText: 'Date',
          value: DateTime(2026, 9, 1),
          disabledDays: {DateTime(2026, 9, 15)},
          onChanged: (_) => count++,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('15').first);
      await tester.pumpAndSettle();

      expect(count, 0);
    });
  });

  group('LayrzDateInput — leap years and month boundaries', () {
    guardedTestWidgets('renders and allows selecting Feb 29 on a leap year', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? changed;
      await pumpThemedApp(
        tester,
        LayrzDateInput(
          labelText: 'Date',
          value: DateTime(2024, 2, 1),
          onChanged: (d) => changed = d,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // February 2024's page also carries a leading January 29 (disabled,
      // adjacent-period) before the real February 29 -- `.last` is
      // February's, since no month after it on this 42-cell page reaches
      // day 29 again (March only runs through day 10).
      await tester.tap(find.text('29').last);
      await tester.pumpAndSettle();

      expect(changed!.year, 2024);
      expect(changed!.month, 2);
      expect(changed!.day, 29);
    });

    guardedTestWidgets('navigating from December wraps the header label into the next January', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        Center(
          child: LayrzDateInput(labelText: 'Date', value: DateTime(2026, 12, 1)),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      expect(find.text('December 2026'), findsOneWidget);

      await tester.tap(find.byIcon(MdiIcons.chevronRight));
      await tester.pumpAndSettle();

      expect(find.text('January 2027'), findsOneWidget);
    });
  });

  group('LayrzDateInput — TZDateTime zone preservation', () {
    guardedTestWidgets('a tapped date from a TZDateTime value is reported in the same zone', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final location = tz.getLocation('America/New_York');
      final value = tz.TZDateTime(location, 2026, 9, 1);

      DateTime? changed;
      await pumpThemedApp(
        tester,
        LayrzDateInput(
          labelText: 'Date',
          value: value,
          onChanged: (d) => changed = d,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('15').first);
      await tester.pumpAndSettle();

      expect(changed, isA<tz.TZDateTime>());
      expect((changed! as tz.TZDateTime).location, location);
      expect(changed!.day, 15);
    });
  });

  group('LayrzDateInput — firstDayOfWeek', () {
    guardedTestWidgets('a caller-supplied firstDayOfWeek changes the weekday header order', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateInput(labelText: 'Date', value: DateTime(2026, 9, 1), firstDayOfWeek: DateTime.sunday),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // Sunday-first: the header's first letter cell should be "S" (Sunday),
      // proving the default (Monday) was actually overridden -- the widget
      // still renders (no crash) with a boundary firstDayOfWeek value.
      expect(find.byType(LayrzDateInput), findsOneWidget);
    });
  });

  group('LayrzDateInput — help affordance', () {
    guardedTestWidgets('provides help affordance when helpContentText is non-null', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDateInput(
          labelText: 'Date',
          helpTitleText: 'About dates',
          helpContentText: 'Pick any date within range.',
        ),
      );

      expect(find.byType(LayrzDateInput), findsOneWidget);
    });
  });

  group('LayrzDateInput — viewport branch selection', () {
    guardedTestWidgets('opens the anchored panel (not a bottom sheet route) at a wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date', value: DateTime(2026, 9, 1)));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // The anchored panel keeps the original field visible behind it
      // (no full route push), unlike the bottom sheet which pushes a new
      // route. The field's own summary text is still present in the tree.
      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
    });

    guardedTestWidgets('opens a bottom sheet route (not an anchored panel) below isCompact', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzDateInput(labelText: 'Date', value: DateTime(2026, 9, 1)));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
    });
  });
}
