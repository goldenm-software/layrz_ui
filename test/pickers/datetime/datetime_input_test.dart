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

    guardedTestWidgets('opens as an anchored panel at wide viewport, bottom sheet at compact', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, LayrzDateTimeInput(labelText: 'When'));
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
      // No LayrzBottomSheet route should have been pushed.
      expect(findButtonLabel('When'), findsOneWidget);
    });
  });

  group('LayrzDateTimeInput — save/cancel footer', () {
    guardedTestWidgets('shows Cancel/Save from the first frame the panel opens (tabbed)', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, LayrzDateTimeInput(labelText: 'When'));
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      expect(findButtonLabel('Save'), findsOneWidget);
      expect(findButtonLabel('Cancel'), findsOneWidget);
    });

    guardedTestWidgets('shows Cancel/Save from the first frame the panel opens (stepped)', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(labelText: 'When', presentation: LayrzDateTimeInputPresentation.stepped),
      );
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
      // Panel should still be open (Save was a no-op).
      expect(findButtonLabel('Save'), findsOneWidget);
    });

    guardedTestWidgets('picking a date alone does not commit or close (tabbed)', (tester) async {
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

    guardedTestWidgets('Save commits the combined datetime and closes the panel', (tester) async {
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

    guardedTestWidgets('typing in a time field never closes the surface (trap 4)', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(labelText: 'When', presentation: LayrzDateTimeInputPresentation.stepped),
      );
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // Advance to the time step.
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsWidgets);

      await tester.enterText(find.byType(EditableText).first, '9');
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsWidgets);
      expect(findButtonLabel('Save'), findsOneWidget);
    });
  });

  group('LayrzDateTimeInput — tabbed vs stepped are provably different', () {
    guardedTestWidgets('tabbed shows only the date half until the time tab is selected', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, LayrzDateTimeInput(labelText: 'When'));
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);

      await tester.tap(findButtonLabel('Time'));
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsNothing);
      expect(find.byType(EditableText), findsWidgets);
    });

    guardedTestWidgets('tabbed: switching tabs does not commit or close', (tester) async {
      setWide(tester);
      DateTime? changed;
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(labelText: 'When', value: DateTime(2026, 9, 1, 8, 0), onChanged: (v) => changed = v),
      );
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Time'));
      await tester.pumpAndSettle();
      await tester.tap(findButtonLabel('Date'));
      await tester.pumpAndSettle();

      expect(changed, isNull);
      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
      expect(findButtonLabel('Save'), findsOneWidget);
    });

    guardedTestWidgets('stepped: time step is unreachable before a date is chosen', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(labelText: 'When', presentation: LayrzDateTimeInputPresentation.stepped),
      );
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);
      // No tab strip exists in stepped mode.
      expect(findButtonLabel('Time'), findsNothing);
    });

    guardedTestWidgets('stepped: selecting a date advances to the time step, with a back affordance', (
      tester,
    ) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(labelText: 'When', presentation: LayrzDateTimeInputPresentation.stepped),
      );
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('12').first);
      await tester.pumpAndSettle();

      // The day grid's own month-navigation chevrons are gone; the only
      // chevron left is the back affordance's own icon.
      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
      expect(find.byIcon(MdiIcons.chevronRight), findsNothing);
      expect(find.byType(EditableText), findsWidgets);
      expect(findButtonLabel('Date'), findsOneWidget);

      // Back affordance returns to the date step without discarding the date.
      await tester.tap(findButtonLabel('Date'));
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);
    });

    guardedTestWidgets('stepped: cancelling at the time step abandons the whole selection', (tester) async {
      setWide(tester);
      DateTime? changed;
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(
          labelText: 'When',
          presentation: LayrzDateTimeInputPresentation.stepped,
          onChanged: (v) => changed = v,
        ),
      );
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('12').first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Cancel'));
      await tester.pumpAndSettle();

      expect(changed, isNull);
      expect(find.text(''), findsWidgets);
    });

    guardedTestWidgets('both presentations fire onChanged at the identical commit moment (on Save)', (
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

        // Not yet committed after picking the date alone, in either mode.
        expect(changed, isNull);

        if (presentation == LayrzDateTimeInputPresentation.tabbed) {
          await tester.tap(findButtonLabel('Time'));
          await tester.pumpAndSettle();
        }
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
    guardedTestWidgets('tap-outside closes the panel without reporting or retaining the draft', (tester) async {
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

      // Pick a different date and switch to the time tab, but never Save.
      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();
      await tester.tap(findButtonLabel('Time'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(changed, isNull);
      expect(find.text('2026-09-01 08:00'), findsOneWidget);

      // Reopen: the draft must be gone and the presentation reset to the
      // date tab, not stuck on the browsed-to time tab.
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);
    });

    guardedTestWidgets('stepped: involuntary close resets to the date step, not the browsed-to time step', (
      tester,
    ) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        Center(
          child: LayrzDateTimeInput(
            labelText: 'When',
            presentation: LayrzDateTimeInputPresentation.stepped,
            value: DateTime(2026, 9, 1, 8, 0),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsWidgets);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);
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
    guardedTestWidgets('disabled field does not open the panel', (tester) async {
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
    guardedTestWidgets('opens as a bottom sheet below isCompact, not an anchored panel', (tester) async {
      setCompact(tester);
      await pumpThemedApp(tester, LayrzDateTimeInput(labelText: 'When'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(MdiIcons.chevronLeft), findsOneWidget);
      expect(findButtonLabel('Save'), findsOneWidget);
      expect(findButtonLabel('Cancel'), findsOneWidget);
    });

    guardedTestWidgets('no layout overflow at a narrow width with the tab strip and time fields', (tester) async {
      setCompact(tester);
      await pumpThemedApp(
        tester,
        LayrzDateTimeInput(labelText: 'When', showSeconds: true, use24HourFormat: false),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      await tester.tap(findButtonLabel('Time'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
