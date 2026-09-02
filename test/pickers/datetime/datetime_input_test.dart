import 'package:flutter/services.dart';
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

  void setWide(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  void setCompact(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('LayrzDateTimeInput — construction', () {
    guardedTestWidgets('asserts at least one of labelText/hintText is provided', (tester) async {
      expect(() => LayrzDateTimeInput(), throwsAssertionError);
    });

    guardedTestWidgets('asserts firstDayOfWeek is within DateTime.monday..DateTime.sunday', (tester) async {
      expect(() => LayrzDateTimeInput(labelText: 'When', firstDayOfWeek: 0), throwsAssertionError);
      expect(() => LayrzDateTimeInput(labelText: 'When', firstDayOfWeek: 8), throwsAssertionError);
    });

    guardedTestWidgets('defaults presentation to tabbed and firstDayOfWeek to DateTime.monday', (tester) async {
      const widget = LayrzDateTimeInput(labelText: 'When');
      // presentation is deprecated and ignored as of DESIGN-49 (see
      // LayrzDateTimeInputPresentation's own doc) -- this only pins the
      // default value has not silently changed, not that it does anything.
      expect(widget.presentation, LayrzDateTimeInputPresentation.tabbed);
      expect(widget.firstDayOfWeek, DateTime.monday);
    });

    // Regression test for the scaffold's `initState` crash: `_updateSummary`
    // reads `context.l10n` (an inherited-widget dependency not established
    // until after `initState` completes), so constructing with a non-null
    // `value` must not throw "dependOnInheritedWidgetOfExactType() ...
    // called before initState() completed."
    guardedTestWidgets('constructing with a non-null value does not throw', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(labelText: 'When', value: DateTime(2026, 9, 5, 14, 30)),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(LayrzDateTimeInput), findsOneWidget);
    });
  });

  group('LayrzDateTimeInput — rendering', () {
    guardedTestWidgets('renders the label', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, LayrzDateTimeInput(labelText: 'When'));
      expect(findButtonLabel('When'), findsOneWidget);
    });

    guardedTestWidgets('shows hint text when value is null', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, LayrzDateTimeInput(labelText: 'When', hintText: 'Pick a datetime'));
      expect(find.text('Pick a datetime'), findsWidgets);
    });

    guardedTestWidgets('formats value using the default pattern', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(labelText: 'When', value: DateTime(2026, 9, 5, 14, 30)),
      );
      expect(find.text('2026-09-05 14:30'), findsOneWidget);
    });

    guardedTestWidgets('formats value using a custom pattern', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(labelText: 'When', value: DateTime(2026, 9, 5, 14, 30), pattern: '%d/%m/%Y %H:%M'),
      );
      expect(find.text('05/09/2026 14:30'), findsOneWidget);
    });

    guardedTestWidgets('formatter override takes precedence over pattern', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(
          labelText: 'When',
          value: DateTime(2026, 9, 5, 14, 30),
          pattern: '%Y-%m-%d %H:%M',
          formatter: (dt) => 'custom-${dt.year}',
        ),
      );
      expect(find.text('custom-2026'), findsOneWidget);
    });

    guardedTestWidgets('opens in the drawer at wide viewport, showing the calendar and time fields together', (
      tester,
    ) async {
      setWide(tester);
      await pumpThemedApp(tester, LayrzDateTimeInput(labelText: 'When'));
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      // The calendar's month header and the time fields are both visible at
      // once -- DESIGN-49 removed the tab strip, so there is no separate
      // "Time" tab to select.
      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
      expect(find.byType(EditableText), findsWidgets);
      // Finding 5: the drawer now also renders `labelText` as its visible
      // title (see LayrzDateTimeInput._openDesktopDrawer), so "When" appears
      // twice while the drawer is open -- once on the anchor field behind
      // it, once as the drawer's own title. `findsWidgets` (not
      // `findsOneWidget`) reflects that intentionally.
      expect(findButtonLabel('When'), findsWidgets);
    });
  });

  group('LayrzDateTimeInput — save/cancel footer', () {
    guardedTestWidgets('shows Cancel/Save from the first frame the drawer opens', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, LayrzDateTimeInput(labelText: 'When'));
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      expect(findButtonLabel('Save'), findsOneWidget);
      expect(findButtonLabel('Cancel'), findsOneWidget);
    });

    guardedTestWidgets('Save is disabled until both date and time are chosen', (tester) async {
      setWide(tester);
      DateTime? changed;
      await pumpThemedApp(tester, LayrzDateTimeInput(labelText: 'When', onChanged: (v) => changed = v));
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // Save with nothing chosen: tapping must not report anything.
      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();
      expect(changed, isNull);
      // The drawer should still be open (Save was a no-op).
      expect(findButtonLabel('Save'), findsOneWidget);
    });

    guardedTestWidgets('picking a date alone does not commit or close', (tester) async {
      setWide(tester);
      DateTime? changed;
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(labelText: 'When', value: DateTime(2026, 9, 1), onChanged: (v) => changed = v),
      );
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('15').first);
      await tester.pumpAndSettle();

      expect(changed, isNull);
      expect(findButtonLabel('Save'), findsOneWidget);
    });

    guardedTestWidgets('no midnight default: a never-touched time half is not silently committed', (tester) async {
      setWide(tester);
      DateTime? changed;
      await pumpThemedApp(tester, LayrzDateTimeInput(labelText: 'When', onChanged: (v) => changed = v));
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // Pick only a date; never touch a time field.
      await tester.tap(find.text('15').first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      // Save must be a no-op: the time half was never chosen.
      expect(changed, isNull);
    });

    guardedTestWidgets('Save commits the combined datetime and closes the drawer', (tester) async {
      setWide(tester);
      DateTime? changed;
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(labelText: 'When', value: DateTime(2026, 9, 1, 8, 0), onChanged: (v) => changed = v),
      );
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('15').first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(changed, DateTime(2026, 9, 15, 8, 0));
      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);
    });

    // DESIGN-98 regression: the maintainer reported Save rendering DISABLED
    // on reopen even though a datetime was already visibly selected --
    // "pressing save didn't update anything, I was forced to re-open to
    // set." Every Save-commits test above builds date+time fresh via taps;
    // none reopens on an already-complete `value` and presses Save with zero
    // interaction. This is that missing case.
    guardedTestWidgets('Save is already enabled on open when value is already complete, with zero interaction', (
      tester,
    ) async {
      setWide(tester);
      DateTime? changed;
      var changeCount = 0;
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(
          labelText: 'When',
          value: DateTime(2026, 9, 1, 8, 0),
          onChanged: (v) {
            changed = v;
            changeCount++;
          },
        ),
      );
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final saveButton = findButtonLabel('Save');
      expect(saveButton, findsOneWidget);
      final saveWidget = tester.widget<LayrzButton>(
        find.ancestor(of: saveButton, matching: find.byType(LayrzButton)).first,
      );
      expect(saveWidget.onTap, isNotNull, reason: 'Save must already be enabled -- no tap has happened yet.');

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(changeCount, 1);
      expect(changed, DateTime(2026, 9, 1, 8, 0));
    });

    guardedTestWidgets('Cancel reverts and closes without reporting anything', (tester) async {
      setWide(tester);
      DateTime? changed;
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(labelText: 'When', value: DateTime(2026, 9, 1, 8, 0), onChanged: (v) => changed = v),
      );
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Cancel'));
      await tester.pumpAndSettle();

      expect(changed, isNull);
      expect(find.text('2026-09-01 08:00'), findsOneWidget);
    });

    guardedTestWidgets('typing in a time field never closes the drawer (trap 4)', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, LayrzDateTimeInput(labelText: 'When'));
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsWidgets);

      await tester.enterText(find.byType(EditableText).first, '9');
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsWidgets);
      expect(findButtonLabel('Save'), findsOneWidget);
    });
  });

  group('LayrzDateTimeInput — presentation is deprecated and ignored (DESIGN-49)', () {
    guardedTestWidgets('tabbed and stepped render an identical calendar+time-fields surface', (tester) async {
      setWide(tester);

      Future<void> exerciseAndAssertNoTabStrip({required LayrzDateTimeInputPresentation presentation}) async {
        await pumpThemedApp(
          tester,
          LayrzDateTimeInput(labelText: 'When', presentation: presentation),
        );
        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        // No tab strip and no step-back affordance exist any longer -- both
        // parts are always visible together.
        expect(findButtonLabel('Time'), findsNothing);
        expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
        expect(find.byType(EditableText), findsWidgets);

        await tester.tap(findButtonLabel('Cancel'));
        await tester.pumpAndSettle();
      }

      await exerciseAndAssertNoTabStrip(presentation: LayrzDateTimeInputPresentation.tabbed);
      await exerciseAndAssertNoTabStrip(presentation: LayrzDateTimeInputPresentation.stepped);
    });

    guardedTestWidgets('onChanged fires at the identical commit moment (on Save) for both presentations', (
      tester,
    ) async {
      setWide(tester);

      Future<void> exerciseAndAssertCommitOnSaveOnly({required LayrzDateTimeInputPresentation presentation}) async {
        DateTime? changed;
        await pumpThemedApp(
          tester,
          LayrzDateTimeInput(
            labelText: 'When',
            presentation: presentation,
            value: DateTime(2026, 1, 1, 6, 0),
            onChanged: (v) => changed = v,
          ),
        );
        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('10').first);
        await tester.pumpAndSettle();

        // Not yet committed after picking the date alone.
        expect(changed, isNull);

        await tester.tap(findButtonLabel('Save'));
        await tester.pumpAndSettle();
        expect(changed, isNotNull);
      }

      await exerciseAndAssertCommitOnSaveOnly(presentation: LayrzDateTimeInputPresentation.tabbed);
      await exerciseAndAssertCommitOnSaveOnly(presentation: LayrzDateTimeInputPresentation.stepped);
    });
  });

  group('LayrzDateTimeInput — involuntary close discards draft state', () {
    guardedTestWidgets('Cancel closes the drawer without reporting or retaining the draft', (tester) async {
      setWide(tester);
      DateTime? changed;
      await pumpThemedApp(
        tester,
        Center(
          child: LayrzDateTimeInput(
            labelText: 'When',
            value: DateTime(2026, 9, 1, 8, 0),
            onChanged: (v) => changed = v,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // Pick a different date and edit a time field, but never Save.
      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, '5');
      await tester.pumpAndSettle();

      // DESIGN-98: LayrzEndDrawer's canDismiss infers false while actions is
      // present, so a barrier tap no longer closes it -- Cancel is now the
      // involuntary-close route this test exercises.
      await tester.tap(findButtonLabel('Cancel'));
      await tester.pumpAndSettle();

      expect(changed, isNull);
      expect(find.text('2026-09-01 08:00'), findsOneWidget);

      // Reopen: the draft must be gone -- the hour field must read back the
      // originally-seeded value (8), not the abandoned edit (5).
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText).first).controller.text,
        '8',
      );
    });

    guardedTestWidgets('Escape closes the drawer and reverts a pending Save', (tester) async {
      setWide(tester);
      DateTime? changed;
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(
          labelText: 'When',
          value: DateTime(2026, 9, 1, 8, 0),
          onChanged: (v) => changed = v,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(changed, isNull);
      expect(findButtonLabel('Save'), findsNothing);
    });
  });

  group('LayrzDateTimeInput — month navigation', () {
    guardedTestWidgets('chevrons navigate months without committing anything', (tester) async {
      setWide(tester);
      DateTime? changed;
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(labelText: 'When', value: DateTime(2026, 9, 1), onChanged: (v) => changed = v),
      );
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);
      await tester.tap(find.byIcon(MdiIcons.chevronRight));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);

      expect(changed, isNull);
    });
  });

  group('LayrzDateTimeInput — disabled / readOnly', () {
    guardedTestWidgets('disabled field does not open the drawer', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, LayrzDateTimeInput(labelText: 'When', disabled: true));
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);
    });

    // Regression guard for trap 1: the anchor must never hardcode
    // `readOnly: true`, since `LayrzInputStyleSpec.resolve` ranks `readOnly`
    // above `error` and would silently suppress the danger border.
    guardedTestWidgets('errors still paint a danger border when not disabled', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(labelText: 'When', errors: const ['Required']),
      );
      final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome).first);
      expect(chrome.readOnly, isFalse);
      expect(chrome.errors, contains('Required'));
    });
  });

  group('LayrzDateTimeInput — error styling', () {
    guardedTestWidgets('renders error text below the field when errors is non-empty', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(labelText: 'When', errors: const ['Please pick a datetime']),
      );
      expect(find.text('Please pick a datetime'), findsOneWidget);
    });
  });

  group('LayrzDateTimeInput — TZDateTime zone preservation', () {
    guardedTestWidgets('committed value keeps the same TZDateTime zone as the seeded value', (tester) async {
      setWide(tester);
      final location = tz.getLocation('America/New_York');
      final seed = tz.TZDateTime(location, 2026, 9, 1, 8, 0);

      DateTime? changed;
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(labelText: 'When', value: seed, onChanged: (v) => changed = v),
      );
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('15').first);
      await tester.pumpAndSettle();
      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(changed, isA<tz.TZDateTime>());
      expect((changed as tz.TZDateTime).location, location);
      expect(changed!.day, 15);
    });
  });

  group('LayrzDateTimeInput — leap years and month boundaries', () {
    guardedTestWidgets('February in a leap year renders 29 days and can be selected', (tester) async {
      setWide(tester);
      DateTime? changed;
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(labelText: 'When', value: DateTime(2028, 2, 1, 6, 0), onChanged: (v) => changed = v),
      );
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.text('29'), findsWidgets);
      await tester.tap(find.text('29').last);
      await tester.pumpAndSettle();
      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(changed, DateTime(2028, 2, 29, 6, 0));
    });
  });

  group('LayrzDateTimeInput — compact viewport', () {
    guardedTestWidgets('opens as a bottom sheet below isCompact, not the drawer', (tester) async {
      setCompact(tester);
      await pumpThemedApp(tester, LayrzDateTimeInput(labelText: 'When'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
      expect(findButtonLabel('Save'), findsOneWidget);
      expect(findButtonLabel('Cancel'), findsOneWidget);
    });

    guardedTestWidgets('no layout overflow at a narrow width with the calendar and time fields both visible', (
      tester,
    ) async {
      setCompact(tester);
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(labelText: 'When', showSeconds: true, use24HourFormat: false),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
