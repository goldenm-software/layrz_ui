import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/pickers/src/datetime/datetime_range_surface.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/find_button_label.dart';
import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

/// A wide-enough anchor that the day grid (capped at `kDayGridMaxWidth` ==
/// 360.0) and two stacked [LayrzPickersTimeFieldsPanel] clusters (Start /
/// End) both stay clear of `LayrzPickersTimeField.kNarrowWidth` (280.0 per
/// field). `LayrzTimeRangeInput`'s own suite settled on 700.0 for a single
/// pair of clusters with no grid above them; this widget stacks the day grid
/// above the same two clusters rather than placing anything beside them, so
/// each cluster still only competes for width with itself, not with the
/// grid -- 700.0 remains sufficient and is reused verbatim.
const double _kSafeAnchorWidth = 700.0;

Widget _bounded(Widget child) => SizedBox(width: _kSafeAnchorWidth, child: child);

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

  group('LayrzDateTimeRangeInput — construction', () {
    guardedTestWidgets('asserts at least one of labelText/hintText is provided', (tester) async {
      expect(() => LayrzDateTimeRangeInput(), throwsAssertionError);
    });

    guardedTestWidgets('asserts firstDayOfWeek is within DateTime.monday..DateTime.sunday', (tester) async {
      expect(() => LayrzDateTimeRangeInput(labelText: 'Trip', firstDayOfWeek: 0), throwsAssertionError);
      expect(() => LayrzDateTimeRangeInput(labelText: 'Trip', firstDayOfWeek: 8), throwsAssertionError);
    });

    guardedTestWidgets('can be created with only hintText', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, _bounded(LayrzDateTimeRangeInput(hintText: 'Pick a datetime range')));
      expect(find.byType(LayrzDateTimeRangeInput), findsOneWidget);
    });

    // Regression test for the scaffold's central defect: `initState` called
    // `_updateSummary()` directly, which reads `context.l10n` -- an
    // inherited-widget dependency not yet established at that point in the
    // widget lifecycle -- and throws "dependOnInheritedWidgetOfExactType()
    // ... called before initState() completed" on construction with ANY
    // non-null startValue/endValue. Fixed by computing the summary reactively
    // from `build` via the `_summaryPrimed`/`_lastStartValue`/`_lastEndValue`
    // sentinel, mirroring `LayrzDateTimeInput`.
    guardedTestWidgets('constructing with non-null startValue/endValue does not throw', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: DateTime(2026, 9, 1, 9, 0),
            endValue: DateTime(2026, 9, 3, 17, 0),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(LayrzDateTimeRangeInput), findsOneWidget);
    });
  });

  group('LayrzDateTimeRangeInput — rendering', () {
    guardedTestWidgets('renders the label', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, _bounded(LayrzDateTimeRangeInput(labelText: 'Trip window')));
      // The hoisted label renders as a RichText, not a Text -- find.text
      // does not match it (see CLAUDE.md's picker test-conventions note).
      expect(findButtonLabel('Trip window'), findsOneWidget);
    });

    guardedTestWidgets('shows hint text when either endpoint is null', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, _bounded(LayrzDateTimeRangeInput(hintText: 'Choose a range')));
      expect(find.text('Choose a range'), findsWidgets);
    });

    guardedTestWidgets('formats a non-null pair with the default %Y-%m-%d %H:%M pattern joined by the range '
        'separator', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: DateTime(2026, 9, 1, 9, 0),
            endValue: DateTime(2026, 9, 3, 17, 30),
          ),
        ),
      );

      final l10n = const LayrzUiL10nDefault();
      expect(find.text('2026-09-01 09:00${l10n.dateTimePickerRangeSeparator}2026-09-03 17:30'), findsOneWidget);
    });

    guardedTestWidgets('formats a non-null pair with a custom pattern', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: DateTime(2026, 9, 1, 9, 0),
            endValue: DateTime(2026, 9, 3, 17, 30),
            pattern: '%d/%m/%Y',
          ),
        ),
      );

      final l10n = const LayrzUiL10nDefault();
      expect(find.text('01/09/2026${l10n.dateTimePickerRangeSeparator}03/09/2026'), findsOneWidget);
    });

    guardedTestWidgets('a supplied formatter overrides pattern entirely', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: DateTime(2026, 9, 1, 9, 0),
            endValue: DateTime(2026, 9, 3, 17, 30),
            formatter: (s, e) => 'CUSTOM ${s.day}->${e.day}',
          ),
        ),
      );

      expect(find.text('CUSTOM 1->3'), findsOneWidget);
    });

    guardedTestWidgets('always renders a Cancel/Save footer once opened -- visible from the first frame', (
      tester,
    ) async {
      setWide(tester);
      await pumpThemedApp(tester, _bounded(LayrzDateTimeRangeInput(labelText: 'Trip')));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(findButtonLabel('Cancel'), findsOneWidget);
      expect(findButtonLabel('Save'), findsOneWidget);
    });
  });

  group('LayrzDateTimeRangeInput — errors', () {
    guardedTestWidgets('displays error text', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        _bounded(LayrzDateTimeRangeInput(labelText: 'Trip', errors: const ['Required'])),
      );
      expect(find.text('Required'), findsOneWidget);
    });

    guardedTestWidgets('hides error text when hideDetails is true', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        _bounded(LayrzDateTimeRangeInput(labelText: 'Trip', errors: const ['Required'], hideDetails: true)),
      );
      expect(find.text('Required'), findsNothing);
    });

    guardedTestWidgets('LayrzInputChrome.readOnly stays false even with errors present (trap 1 regression)', (
      tester,
    ) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        _bounded(LayrzDateTimeRangeInput(labelText: 'Trip', errors: const ['Required'])),
      );

      final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome).first);
      expect(chrome.readOnly, isFalse);
      expect(chrome.errors, isNotEmpty);
    });
  });

  group('LayrzDateTimeRangeInput — disabled tap behavior', () {
    guardedTestWidgets('disabled blocks the tap from opening the surface', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, _bounded(LayrzDateTimeRangeInput(labelText: 'Trip', disabled: true)));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byType(LayrzDateTimeRangeSurface), findsNothing);
    });

    guardedTestWidgets('a non-disabled field opens the surface on tap', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, _bounded(LayrzDateTimeRangeInput(labelText: 'Trip')));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byType(LayrzDateTimeRangeSurface), findsOneWidget);
    });
  });

  group('LayrzDateTimeRangeInput — zero clock/dial affordance', () {
    guardedTestWidgets('opening the panel introduces no dial/clock widget, only day cells and text fields', (
      tester,
    ) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: DateTime(2026, 9, 1, 9, 0),
            endValue: DateTime(2026, 9, 3, 17, 0),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // Two clusters * (hour, minute, hidden-seconds) = 6 EditableText.
      expect(find.byType(EditableText), findsNWidgets(6));
      expect(find.byType(LayrzDateTimeRangeSurface), findsOneWidget);
    });
  });

  group('LayrzDateTimeRangeInput — trap 4: typing never closes the panel', () {
    guardedTestWidgets('typing in a time field fires no onChanged and keeps the panel open', (tester) async {
      setWide(tester);
      var callCount = 0;
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: DateTime(2026, 9, 1, 9, 0),
            endValue: DateTime(2026, 9, 3, 17, 0),
            onChanged: (_, _) => callCount++,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, '11');
      await tester.pump();

      expect(callCount, 0);
      expect(find.byType(LayrzDateTimeRangeSurface), findsOneWidget);
    });

    guardedTestWidgets('navigating months does not commit or close the panel', (tester) async {
      setWide(tester);
      var callCount = 0;
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: DateTime(2026, 9, 1, 9, 0),
            endValue: DateTime(2026, 9, 3, 17, 0),
            onChanged: (_, _) => callCount++,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final l10n = const LayrzUiL10nDefault();
      await tester.tap(find.bySemanticsLabel(l10n.calendarMonthNext));
      await tester.pumpAndSettle();

      expect(callCount, 0);
      expect(find.byType(LayrzDateTimeRangeSurface), findsOneWidget);
    });
  });

  group('LayrzDateTimeRangeInput — month navigation (bug: scaffold had none)', () {
    guardedTestWidgets('next/prev chevrons step the displayed month without committing', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: DateTime(2026, 9, 1, 9, 0),
            endValue: DateTime(2026, 9, 3, 17, 0),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('September 2026'), findsOneWidget);

      final l10n = const LayrzUiL10nDefault();
      await tester.tap(find.bySemanticsLabel(l10n.calendarMonthNext));
      await tester.pumpAndSettle();
      expect(find.textContaining('October 2026'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(l10n.calendarMonthBack));
      await tester.pumpAndSettle();
      expect(find.textContaining('September 2026'), findsOneWidget);
    });
  });

  group('LayrzDateTimeRangeInput — contiguous date state machine', () {
    guardedTestWidgets('empty -> anchor: first tap sets the anchor, Save stays disabled', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, _bounded(LayrzDateTimeRangeInput(labelText: 'Trip', onChanged: (_, _) {})));
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();

      final saveButton = tester.widget<LayrzButton>(
        find.ancestor(of: findButtonLabel('Save'), matching: find.byType(LayrzButton)).first,
      );
      expect(saveButton.isDisabled, isTrue);
    });

    guardedTestWidgets('anchor -> complete: second tap completes the range, auto-swapped if reversed', (
      tester,
    ) async {
      setWide(tester);
      DateTime? savedStart;
      DateTime? savedEnd;
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            onChanged: (s, e) {
              savedStart = s;
              savedEnd = e;
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // Tap the later date first, then the earlier one -- the policy must
      // auto-swap so the resulting anchor/end come out start <= end.
      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();

      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), '9');
      await tester.pump();
      await tester.enterText(fields.at(1), '0');
      await tester.pump();
      await tester.enterText(fields.at(3), '17');
      await tester.pump();
      await tester.enterText(fields.at(4), '0');
      await tester.pump();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(savedStart, isNotNull);
      expect(savedEnd, isNotNull);
      expect(savedStart!.day, 5);
      expect(savedEnd!.day, 20);
    });

    guardedTestWidgets('complete -> endpoint re-tap adjusts that edge, other edge fixed', (tester) async {
      setWide(tester);
      DateTime? savedStart;
      DateTime? savedEnd;
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: DateTime(2026, 9, 5, 9, 0),
            endValue: DateTime(2026, 9, 10, 17, 0),
            onChanged: (s, e) {
              savedStart = s;
              savedEnd = e;
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // Re-tap the start endpoint (5th) to pick it up, then move it to the 3rd.
      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('3').first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(savedStart!.day, 3);
      expect(savedEnd!.day, 10);
    });

    guardedTestWidgets('complete -> interior tap is rejected, range unchanged', (tester) async {
      setWide(tester);
      DateTime? savedStart;
      DateTime? savedEnd;
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: DateTime(2026, 9, 5, 9, 0),
            endValue: DateTime(2026, 9, 10, 17, 0),
            onChanged: (s, e) {
              savedStart = s;
              savedEnd = e;
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // Day 7 is strictly interior to [5, 10] -- tapping it must not move
      // either endpoint.
      await tester.tap(find.text('7').first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(savedStart!.day, 5);
      expect(savedEnd!.day, 10);
    });

    guardedTestWidgets('complete -> tap outside the range extends the nearer endpoint', (tester) async {
      setWide(tester);
      DateTime? savedStart;
      DateTime? savedEnd;
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: DateTime(2026, 9, 5, 9, 0),
            endValue: DateTime(2026, 9, 10, 17, 0),
            onChanged: (s, e) {
              savedStart = s;
              savedEnd = e;
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // Day 15 is outside [5, 10] and nearer the end -- it must extend the
      // end endpoint, not create a new disjoint anchor.
      await tester.tap(find.text('15').first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(savedStart!.day, 5);
      expect(savedEnd!.day, 15);
    });

    guardedTestWidgets('Reset control clears the draft back to empty', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: DateTime(2026, 9, 5, 9, 0),
            endValue: DateTime(2026, 9, 10, 17, 0),
            onChanged: (_, _) {},
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final l10n = const LayrzUiL10nDefault();
      expect(findButtonLabel(l10n.pickerRangeReset), findsOneWidget);
      await tester.tap(findButtonLabel(l10n.pickerRangeReset));
      await tester.pumpAndSettle();

      final saveButton = tester.widget<LayrzButton>(
        find.ancestor(of: findButtonLabel('Save'), matching: find.byType(LayrzButton)).first,
      );
      expect(saveButton.isDisabled, isTrue);
      expect(findButtonLabel(l10n.pickerRangeReset), findsNothing);
    });
  });

  group('LayrzDateTimeRangeInput — no midnight default, Save reachability', () {
    guardedTestWidgets('Save is disabled while the date range is incomplete even with times set', (
      tester,
    ) async {
      setWide(tester);
      await pumpThemedApp(tester, _bounded(LayrzDateTimeRangeInput(labelText: 'Trip', onChanged: (_, _) {})));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), '9');
      await tester.pump();

      final saveButton = tester.widget<LayrzButton>(
        find.ancestor(of: findButtonLabel('Save'), matching: find.byType(LayrzButton)).first,
      );
      expect(saveButton.isDisabled, isTrue);
    });

    guardedTestWidgets('Save is disabled when the date range is complete but a time part was never touched', (
      tester,
    ) async {
      setWide(tester);
      await pumpThemedApp(tester, _bounded(LayrzDateTimeRangeInput(labelText: 'Trip', onChanged: (_, _) {})));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();

      // Date range complete, but neither time cluster was ever edited.
      final saveButton = tester.widget<LayrzButton>(
        find.ancestor(of: findButtonLabel('Save'), matching: find.byType(LayrzButton)).first,
      );
      expect(saveButton.isDisabled, isTrue);
    });

    guardedTestWidgets('Save becomes enabled once the date range is complete and both times are set, and a '
        'never-touched time is never silently committed as midnight', (tester) async {
      setWide(tester);
      DateTime? savedStart;
      DateTime? savedEnd;
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            onChanged: (s, e) {
              savedStart = s;
              savedEnd = e;
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();

      final fields = find.byType(EditableText);
      // Start cluster: hour, minute. End cluster: hour, minute.
      await tester.enterText(fields.at(0), '9');
      await tester.pump();
      await tester.enterText(fields.at(1), '15');
      await tester.pump();
      await tester.enterText(fields.at(3), '17');
      await tester.pump();
      await tester.enterText(fields.at(4), '45');
      await tester.pump();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(savedStart, isNotNull);
      expect(savedEnd, isNotNull);
      expect(savedStart!.hour, 9);
      expect(savedStart!.minute, 15);
      expect(savedEnd!.hour, 17);
      expect(savedEnd!.minute, 45);
    });
  });

  group('LayrzDateTimeRangeInput — auto-swap including same-day time reversal', () {
    guardedTestWidgets('same calendar day for both endpoints with an earlier end time swaps the whole datetime '
        'pair, not just the times', (tester) async {
      setWide(tester);
      DateTime? savedStart;
      DateTime? savedEnd;
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            onChanged: (s, e) {
              savedStart = s;
              savedEnd = e;
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // Tap the same day twice: empty -> anchor -> complete (same day both
      // ends, per the contiguous policy's onTap when anchor == tapped it
      // still becomes complete with anchor == end).
      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();

      final fields = find.byType(EditableText);
      // Start time: 17:00 (later). End time: 09:00 (earlier). Same day.
      await tester.enterText(fields.at(0), '17');
      await tester.pump();
      await tester.enterText(fields.at(1), '0');
      await tester.pump();
      await tester.enterText(fields.at(3), '9');
      await tester.pump();
      await tester.enterText(fields.at(4), '0');
      await tester.pump();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(savedStart, isNotNull);
      expect(savedEnd, isNotNull);
      // The combined pair must come out non-reversed: the earlier
      // wall-clock instant reported as start, the later as end -- entire
      // datetimes swapped, not just the LayrzTimeOfDay values.
      expect(savedStart!.isBefore(savedEnd!) || savedStart!.isAtSameMomentAs(savedEnd!), isTrue);
      expect(savedStart!.hour, 9);
      expect(savedEnd!.hour, 17);
    });
  });

  group('LayrzDateTimeRangeInput — Save commits, Cancel reverts, both close (desktop)', () {
    guardedTestWidgets('selecting a full range and pressing Save fires onChanged once and closes the panel', (
      tester,
    ) async {
      setWide(tester);
      var callCount = 0;
      DateTime? savedStart;
      DateTime? savedEnd;
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            onChanged: (s, e) {
              callCount++;
              savedStart = s;
              savedEnd = e;
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();

      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), '9');
      await tester.pump();
      await tester.enterText(fields.at(1), '0');
      await tester.pump();
      await tester.enterText(fields.at(3), '17');
      await tester.pump();
      await tester.enterText(fields.at(4), '0');
      await tester.pump();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(callCount, 1);
      expect(savedStart!.day, 5);
      expect(savedEnd!.day, 10);
      expect(find.byType(LayrzDateTimeRangeSurface), findsNothing);
    });

    guardedTestWidgets('pressing Cancel after a partial selection does not fire onChanged and closes the panel', (
      tester,
    ) async {
      setWide(tester);
      var callCount = 0;
      await pumpThemedApp(
        tester,
        _bounded(LayrzDateTimeRangeInput(labelText: 'Trip', onChanged: (_, _) => callCount++)),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Cancel'));
      await tester.pumpAndSettle();

      expect(callCount, 0);
      expect(find.byType(LayrzDateTimeRangeSurface), findsNothing);
    });

    // DESIGN-98 regression: the maintainer reported the same "update value"
    // issue on this widget as on LayrzDateTimeInput -- Save not committing,
    // forcing a re-open. Every Save-commits test above builds the range and
    // both time clusters fresh via taps; none reopens on an
    // already-complete (startValue, endValue) pair and presses Save with
    // zero interaction. This is that missing case.
    guardedTestWidgets('Save is already enabled on open when value is already complete, with zero interaction', (
      tester,
    ) async {
      setWide(tester);
      var callCount = 0;
      DateTime? savedStart;
      DateTime? savedEnd;
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: DateTime(2026, 9, 5, 9, 0),
            endValue: DateTime(2026, 9, 10, 17, 0),
            onChanged: (s, e) {
              callCount++;
              savedStart = s;
              savedEnd = e;
            },
          ),
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

      expect(callCount, 1);
      expect(savedStart, DateTime(2026, 9, 5, 9, 0));
      expect(savedEnd, DateTime(2026, 9, 10, 17, 0));
      expect(find.byType(LayrzDateTimeRangeSurface), findsNothing);
    });
  });

  group('LayrzDateTimeRangeInput — Save commits, Cancel reverts, both close (mobile, compact viewport)', () {
    guardedTestWidgets('opens the bottom sheet on a compact viewport', (tester) async {
      setCompact(tester);
      await pumpThemedApp(tester, LayrzDateTimeRangeInput(labelText: 'Trip'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byType(LayrzDateTimeRangeSurface), findsOneWidget);
      expect(find.byType(LayrzAnchoredPanel), findsNothing);
    });

    guardedTestWidgets('selecting a range and pressing Save in the bottom sheet fires onChanged and dismisses it', (
      tester,
    ) async {
      setCompact(tester);
      var callCount = 0;
      await pumpThemedApp(tester, LayrzDateTimeRangeInput(labelText: 'Trip', onChanged: (_, _) => callCount++));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();

      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), '9');
      await tester.pump();
      await tester.enterText(fields.at(1), '0');
      await tester.pump();
      await tester.enterText(fields.at(3), '17');
      await tester.pump();
      await tester.enterText(fields.at(4), '0');
      await tester.pump();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(callCount, 1);
      expect(find.byType(LayrzDateTimeRangeSurface), findsNothing);
    });

    guardedTestWidgets('pressing Cancel in the bottom sheet dismisses it without firing onChanged', (tester) async {
      setCompact(tester);
      var callCount = 0;
      await pumpThemedApp(tester, LayrzDateTimeRangeInput(labelText: 'Trip', onChanged: (_, _) => callCount++));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Cancel'));
      await tester.pumpAndSettle();

      expect(callCount, 0);
      expect(find.byType(LayrzDateTimeRangeSurface), findsNothing);
    });

    guardedTestWidgets('disabled does not open the bottom sheet', (tester) async {
      setCompact(tester);
      await pumpThemedApp(tester, LayrzDateTimeRangeInput(labelText: 'Trip', disabled: true));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byType(LayrzDateTimeRangeSurface), findsNothing);
    });
  });

  group('LayrzDateTimeRangeInput — involuntary close discards draft state (desktop)', () {
    guardedTestWidgets('tap-outside after a partial selection closes the panel without changing value', (
      tester,
    ) async {
      setWide(tester);
      var callCount = 0;
      await pumpThemedApp(
        tester,
        _bounded(LayrzDateTimeRangeInput(labelText: 'Trip', onChanged: (_, _) => callCount++)),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();

      // Tap outside the panel to trigger an involuntary close.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(callCount, 0);
      expect(find.byType(LayrzDateTimeRangeSurface), findsNothing);
    });

    guardedTestWidgets('reopening after an involuntary close shows an empty draft, not the abandoned selection', (
      tester,
    ) async {
      setWide(tester);
      await pumpThemedApp(tester, _bounded(LayrzDateTimeRangeInput(labelText: 'Trip', onChanged: (_, _) {})));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').first);
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final saveButton = tester.widget<LayrzButton>(
        find.ancestor(of: findButtonLabel('Save'), matching: find.byType(LayrzButton)).first,
      );
      expect(saveButton.isDisabled, isTrue);
      final l10n = const LayrzUiL10nDefault();
      expect(findButtonLabel(l10n.pickerRangeReset), findsNothing);
    });
  });

  group('LayrzDateTimeRangeInput — controller and focus node lifecycle', () {
    guardedTestWidgets('disposes a self-created controller on widget dispose', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, _bounded(LayrzDateTimeRangeInput(labelText: 'Trip')));
      await pumpThemedApp(tester, const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });

    guardedTestWidgets('does not dispose a caller-provided controller', (tester) async {
      setWide(tester);
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemedApp(tester, _bounded(LayrzDateTimeRangeInput(labelText: 'Trip', controller: controller)));
      await pumpThemedApp(tester, const SizedBox.shrink());

      expect(() => controller.text, returnsNormally);
    });

    guardedTestWidgets('does not dispose a caller-provided focus node', (tester) async {
      setWide(tester);
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemedApp(tester, _bounded(LayrzDateTimeRangeInput(labelText: 'Trip', focusNode: focusNode)));
      await pumpThemedApp(tester, const SizedBox.shrink());

      expect(() => focusNode.hasFocus, returnsNormally);
    });
  });

  group('LayrzDateTimeRangeInput — bounds and disabled days', () {
    guardedTestWidgets('a disabledDays entry cannot become an endpoint', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            disabledDays: {DateTime(2026, 9, 15)},
            onChanged: (_, _) {},
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('15').first);
      await tester.pumpAndSettle();

      final saveButton = tester.widget<LayrzButton>(
        find.ancestor(of: findButtonLabel('Save'), matching: find.byType(LayrzButton)).first,
      );
      expect(saveButton.isDisabled, isTrue);
    });
  });

  group('LayrzDateTimeRangeInput — TZDateTime zone preservation', () {
    guardedTestWidgets('a range saved from TZDateTime endpoints round-trips both endpoints as TZDateTime in the '
        'same zone (not silently downgraded to plain DateTime)', (tester) async {
      setWide(tester);
      final location = tz.getLocation('America/New_York');
      final startValue = tz.TZDateTime(location, 2026, 9, 1, 9, 0);
      final endValue = tz.TZDateTime(location, 2026, 9, 3, 17, 0);

      DateTime? savedStart;
      DateTime? savedEnd;
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: startValue,
            endValue: endValue,
            onChanged: (s, e) {
              savedStart = s;
              savedEnd = e;
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(savedStart, isA<tz.TZDateTime>());
      expect((savedStart as tz.TZDateTime).location, location);
      expect(savedEnd, isA<tz.TZDateTime>());
      expect((savedEnd as tz.TZDateTime).location, location);
    });

    guardedTestWidgets('navigating months in a TZDateTime-seeded panel does not downgrade the endpoint types', (
      tester,
    ) async {
      setWide(tester);
      final location = tz.getLocation('America/New_York');
      final startValue = tz.TZDateTime(location, 2026, 9, 1, 9, 0);
      final endValue = tz.TZDateTime(location, 2026, 9, 3, 17, 0);

      DateTime? savedStart;
      DateTime? savedEnd;
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: startValue,
            endValue: endValue,
            onChanged: (s, e) {
              savedStart = s;
              savedEnd = e;
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final l10n = const LayrzUiL10nDefault();
      await tester.tap(find.bySemanticsLabel(l10n.calendarMonthNext));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(l10n.calendarMonthBack));
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(savedStart, isA<tz.TZDateTime>());
      expect(savedEnd, isA<tz.TZDateTime>());
    });
  });

  group('LayrzDateTimeRangeInput — help affordance', () {
    guardedTestWidgets('provides help affordance when helpContentText is non-null', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(labelText: 'Trip', helpTitleText: 'Help', helpContentText: 'Explanation'),
        ),
      );
      expect(find.byType(LayrzDateTimeRangeInput), findsOneWidget);
    });
  });

  group('LayrzDateTimeRangeInput — showSeconds', () {
    guardedTestWidgets('showSeconds true opens a panel with six EditableText fields per cluster (twelve total)', (
      tester,
    ) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: DateTime(2026, 9, 1, 9, 0, 0),
            endValue: DateTime(2026, 9, 3, 17, 0, 0),
            showSeconds: true,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsNWidgets(6));
    });

    guardedTestWidgets('anchor row height is identical with showSeconds true vs false (D15, no reflow)', (
      tester,
    ) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        _bounded(LayrzDateTimeRangeInput(labelText: 'Trip', showSeconds: false)),
      );
      final heightWithout = tester.getSize(find.byType(LayrzInputChrome).first).height;

      await pumpThemedApp(
        tester,
        _bounded(LayrzDateTimeRangeInput(labelText: 'Trip', showSeconds: true)),
      );
      final heightWith = tester.getSize(find.byType(LayrzInputChrome).first).height;

      expect(heightWith, heightWithout);
    });
  });

  group('LayrzDateTimeRangeInput — 24h / 12h and clamping', () {
    guardedTestWidgets('use24HourFormat defaults to true (no meridiem control rendered)', (tester) async {
      setWide(tester);
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: DateTime(2026, 9, 1, 9, 0),
            endValue: DateTime(2026, 9, 3, 17, 0),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('AM'), findsNothing);
      expect(find.textContaining('PM'), findsNothing);
    });

    guardedTestWidgets('37 minutes is representable and round-trips unchanged (no interval snapping)', (
      tester,
    ) async {
      setWide(tester);
      DateTime? savedStart;
      DateTime? savedEnd;
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: DateTime(2026, 9, 1, 9, 0),
            endValue: DateTime(2026, 9, 3, 17, 0),
            onChanged: (s, e) {
              savedStart = s;
              savedEnd = e;
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(1), '37');
      await tester.pump();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(savedStart!.minute, 37);
      expect(savedEnd!.minute, 0);
    });

    guardedTestWidgets('typing 25 into the 24h start-hour field clamps to 23 on the reported value', (
      tester,
    ) async {
      setWide(tester);
      DateTime? savedStart;
      DateTime? savedEnd;
      await pumpThemedApp(
        tester,
        _bounded(
          LayrzDateTimeRangeInput(
            labelText: 'Trip',
            startValue: DateTime(2026, 9, 1, 9, 0),
            endValue: DateTime(2026, 9, 3, 17, 0),
            onChanged: (s, e) {
              savedStart = s;
              savedEnd = e;
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), '25');
      await tester.pump();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(savedStart!.hour, 23);
      expect(savedEnd!.hour, 17);
    });
  });

  group('LayrzDateTimeRangeInput — viewport branch selection', () {
    // DESIGN-49: LayrzAnchoredPanel is no longer used by this widget at any
    // viewport -- desktop opens LayrzPickerDrawer, compact opens
    // LayrzBottomSheet. Both container types push a route rather than
    // mounting inline, so neither is present in the tree before the tap.
    guardedTestWidgets('opens the drawer (fixed-width, not a bottom sheet) at a wide viewport', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, _bounded(LayrzDateTimeRangeInput(labelText: 'Trip')));

      expect(find.byType(LayrzAnchoredPanel), findsNothing);
      expect(find.byType(LayrzDateTimeRangeSurface), findsNothing);

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byType(LayrzDateTimeRangeSurface), findsOneWidget);
      final surfaceWidth = tester.getSize(find.byType(LayrzDateTimeRangeSurface)).width;
      expect(surfaceWidth, lessThanOrEqualTo(420.0), reason: 'the drawer is fixed-width, not the anchor\'s width');
    });

    guardedTestWidgets('opens a bottom sheet route (not the drawer) below isCompact', (tester) async {
      setCompact(tester);
      await pumpThemedApp(tester, LayrzDateTimeRangeInput(labelText: 'Trip'));

      expect(find.byType(LayrzAnchoredPanel), findsNothing);

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      expect(find.byType(LayrzDateTimeRangeSurface), findsOneWidget);
    });
  });

  group('LayrzDateTimeRangeInput — the panel shows Start/End labels distinctly', () {
    guardedTestWidgets('the panel shows the start and end time cluster labels distinctly', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, _bounded(LayrzDateTimeRangeInput(labelText: 'Trip')));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final l10n = const LayrzUiL10nDefault();
      expect(find.text(l10n.timePickerStart), findsOneWidget);
      expect(find.text(l10n.timePickerEnd), findsOneWidget);
    });
  });

  group('LayrzDateTimeRangeInput — isRequired and dense', () {
    guardedTestWidgets('isRequired renders the required marker', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, _bounded(LayrzDateTimeRangeInput(labelText: 'Trip', isRequired: true)));
      // The label + '*' marker render as one RichText -- find.textContaining
      // does not match it (see the label test's identical note above).
      expect(findButtonLabel('Trip*'), findsOneWidget);
    });

    guardedTestWidgets('dense reduces the anchor field height without changing padding tokens', (tester) async {
      setWide(tester);
      await pumpThemedApp(tester, _bounded(LayrzDateTimeRangeInput(labelText: 'Trip')));
      final normalHeight = tester.getSize(find.byType(LayrzInputChrome).first).height;

      await pumpThemedApp(tester, _bounded(LayrzDateTimeRangeInput(labelText: 'Trip', dense: true)));
      final denseHeight = tester.getSize(find.byType(LayrzInputChrome).first).height;

      expect(denseHeight, lessThan(normalHeight));
    });
  });
}
