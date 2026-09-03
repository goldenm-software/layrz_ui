import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/pickers/src/datetime/datetime_range_surface.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/find_button_label.dart';
import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

/// Matches [LayrzDateTimeRangeInput]'s own test suite -- wide enough that
/// the day grid and both time clusters stay clear of
/// `LayrzPickersTimeField.kNarrowWidth` (280.0 per field).
const double _kSafeWidth = 700.0;

Widget _bounded(Widget child) => SizedBox(width: _kSafeWidth, child: child);

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

  group('LayrzDateTimeRangeSurface — rendering', () {
    guardedTestWidgets('renders the month/year header for the seeded value', (tester) async {
      setWide(tester);
      await pumpThemed(
        tester,
        _bounded(
          LayrzDateTimeRangeSurface(
            value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
            startTime: const LayrzTimeOfDay(hour: 9, minute: 0),
            endTime: const LayrzTimeOfDay(hour: 17, minute: 0),
            onSave: (_, _) {},
            onCancel: () {},
          ),
        ),
      );

      expect(find.text('September 2026'), findsOneWidget);
    });

    guardedTestWidgets('seeds the displayed month from the current month when value is null', (tester) async {
      setWide(tester);
      final now = DateTime.now();

      await pumpThemed(
        tester,
        _bounded(
          LayrzDateTimeRangeSurface(value: null, startTime: null, endTime: null, onSave: (_, _) {}, onCancel: () {}),
        ),
      );

      expect(find.byType(LayrzDateTimeRangeSurface), findsOneWidget);
      expect(find.textContaining('${now.year}'), findsWidgets);
    });

    guardedTestWidgets('renders without overflow at a narrow (compact) viewport', (tester) async {
      setCompact(tester);
      await pumpThemed(
        tester,
        LayrzDateTimeRangeSurface(
          value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
          startTime: const LayrzTimeOfDay(hour: 9, minute: 0),
          endTime: const LayrzTimeOfDay(hour: 17, minute: 0),
          onSave: (_, _) {},
          onCancel: () {},
        ),
      );

      expect(find.byType(LayrzDateTimeRangeSurface), findsOneWidget);
    });

    guardedTestWidgets('renders without overflow at a wide viewport, with showSeconds and 12h both on', (
      tester,
    ) async {
      setWide(tester);
      await pumpThemed(
        tester,
        _bounded(
          LayrzDateTimeRangeSurface(
            value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
            startTime: const LayrzTimeOfDay(hour: 9, minute: 0, second: 0),
            endTime: const LayrzTimeOfDay(hour: 17, minute: 0, second: 0),
            showSeconds: true,
            use24HourFormat: false,
            onSave: (_, _) {},
            onCancel: () {},
          ),
        ),
      );

      expect(find.byType(LayrzDateTimeRangeSurface), findsOneWidget);
    });
  });

  group('LayrzDateTimeRangeSurface — month navigation', () {
    guardedTestWidgets('the next/prev chevrons step the displayed month, without invoking onSave', (
      tester,
    ) async {
      setWide(tester);
      var saveCount = 0;
      await pumpThemed(
        tester,
        _bounded(
          LayrzDateTimeRangeSurface(
            value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
            startTime: const LayrzTimeOfDay(hour: 9, minute: 0),
            endTime: const LayrzTimeOfDay(hour: 17, minute: 0),
            onSave: (_, _) => saveCount++,
            onCancel: () {},
          ),
        ),
      );

      expect(find.text('September 2026'), findsOneWidget);

      final l10n = const LayrzUiL10nDefault();
      await tester.tap(find.bySemanticsLabel(l10n.calendarMonthNext));
      await tester.pump();
      expect(find.text('October 2026'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(l10n.calendarMonthBack));
      await tester.pump();
      expect(find.text('September 2026'), findsOneWidget);

      expect(saveCount, 0);
    });
  });

  group('LayrzDateTimeRangeSurface — Cancel/Save footer, visible from the first frame', () {
    guardedTestWidgets('renders Cancel and Save buttons immediately, before any tap', (tester) async {
      setWide(tester);
      await pumpThemed(
        tester,
        _bounded(
          LayrzDateTimeRangeSurface(value: null, startTime: null, endTime: null, onSave: (_, _) {}, onCancel: () {}),
        ),
      );

      expect(findButtonLabel('Cancel'), findsOneWidget);
      expect(findButtonLabel('Save'), findsOneWidget);
    });

    guardedTestWidgets('Save is disabled while the date draft is empty', (tester) async {
      setWide(tester);
      var saveCount = 0;
      await pumpThemed(
        tester,
        _bounded(
          LayrzDateTimeRangeSurface(
            value: null,
            startTime: null,
            endTime: null,
            onSave: (_, _) => saveCount++,
            onCancel: () {},
          ),
        ),
      );

      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saveCount, 0);
    });

    guardedTestWidgets('Save is disabled while only the date anchor is set (half-open)', (tester) async {
      setWide(tester);
      var saveCount = 0;
      await pumpThemed(
        tester,
        _bounded(
          LayrzDateTimeRangeSurface(
            value: null,
            startTime: null,
            endTime: null,
            onSave: (_, _) => saveCount++,
            onCancel: () {},
          ),
        ),
      );

      await tester.tap(find.text('5').first);
      await tester.pump();

      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saveCount, 0);
    });

    guardedTestWidgets(
      'Save commits once, with both time parts defaulted to midnight, when the date range is complete but '
      'the time parts were never touched (midnight is a valid default)',
      (tester) async {
        setWide(tester);
        DateTime? savedStart;
        DateTime? savedEnd;
        var saveCount = 0;
        await pumpThemed(
          tester,
          _bounded(
            LayrzDateTimeRangeSurface(
              value: null,
              startTime: null,
              endTime: null,
              onSave: (s, e) {
                savedStart = s;
                savedEnd = e;
                saveCount++;
              },
              onCancel: () {},
            ),
          ),
        );

        await tester.tap(find.text('5').first);
        await tester.pump();
        await tester.tap(find.text('10').first);
        await tester.pump();

        // `LayrzDateTimeRangeSurfaceState.canSave` (commit 83ba2e0) is
        // `_draft.isComplete` alone -- neither `_startTime` nor `_endTime`
        // gates it any longer, and both are `late` fields seeded to
        // midnight when the caller's `startTime`/`endTime` are null.
        await tester.tap(findButtonLabel('Save'));
        await tester.pump();

        expect(saveCount, 1, reason: 'the completed date range alone is enough to make Save committable');
        expect(savedStart!.day, 5);
        expect(savedStart!.hour, 0);
        expect(savedStart!.minute, 0);
        expect(savedEnd!.day, 10);
        expect(savedEnd!.hour, 0);
        expect(savedEnd!.minute, 0);
      },
    );

    guardedTestWidgets('Save reports the completed (start, end) datetime pair exactly once', (tester) async {
      setWide(tester);
      DateTime? savedStart;
      DateTime? savedEnd;
      var saveCount = 0;
      await pumpThemed(
        tester,
        _bounded(
          LayrzDateTimeRangeSurface(
            value: null,
            startTime: null,
            endTime: null,
            onSave: (s, e) {
              savedStart = s;
              savedEnd = e;
              saveCount++;
            },
            onCancel: () {},
          ),
        ),
      );

      await tester.tap(find.text('5').first);
      await tester.pump();
      await tester.tap(find.text('10').first);
      await tester.pump();

      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), '9');
      await tester.pump();
      await tester.enterText(fields.at(1), '15');
      await tester.pump();
      await tester.enterText(fields.at(3), '17');
      await tester.pump();
      await tester.enterText(fields.at(4), '45');
      await tester.pump();

      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(saveCount, 1);
      expect(savedStart!.day, 5);
      expect(savedStart!.hour, 9);
      expect(savedStart!.minute, 15);
      expect(savedEnd!.day, 10);
      expect(savedEnd!.hour, 17);
      expect(savedEnd!.minute, 45);
    });

    guardedTestWidgets('Cancel invokes onCancel without invoking onSave', (tester) async {
      setWide(tester);
      var cancelCount = 0;
      var saveCount = 0;
      await pumpThemed(
        tester,
        _bounded(
          LayrzDateTimeRangeSurface(
            value: null,
            startTime: null,
            endTime: null,
            onSave: (_, _) => saveCount++,
            onCancel: () => cancelCount++,
          ),
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

  group('LayrzDateTimeRangeSurface — auto-swap including same-day time reversal', () {
    guardedTestWidgets('same day for both endpoints with a reversed time pair swaps the whole datetimes', (
      tester,
    ) async {
      setWide(tester);
      DateTime? savedStart;
      DateTime? savedEnd;
      await pumpThemed(
        tester,
        _bounded(
          LayrzDateTimeRangeSurface(
            value: null,
            startTime: null,
            endTime: null,
            onSave: (s, e) {
              savedStart = s;
              savedEnd = e;
            },
            onCancel: () {},
          ),
        ),
      );

      await tester.tap(find.text('5').first);
      await tester.pump();
      await tester.tap(find.text('5').first);
      await tester.pump();

      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), '17');
      await tester.pump();
      await tester.enterText(fields.at(1), '0');
      await tester.pump();
      await tester.enterText(fields.at(3), '9');
      await tester.pump();
      await tester.enterText(fields.at(4), '0');
      await tester.pump();

      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(savedStart!.day, 5);
      expect(savedEnd!.day, 5);
      expect(savedStart!.hour, 9);
      expect(savedEnd!.hour, 17);
      expect(savedStart!.isBefore(savedEnd!), isTrue);
    });

    guardedTestWidgets('reverse-order date taps auto-swap so the saved pair is always start <= end', (
      tester,
    ) async {
      setWide(tester);
      DateTime? savedStart;
      DateTime? savedEnd;
      await pumpThemed(
        tester,
        _bounded(
          LayrzDateTimeRangeSurface(
            value: null,
            startTime: null,
            endTime: null,
            onSave: (s, e) {
              savedStart = s;
              savedEnd = e;
            },
            onCancel: () {},
          ),
        ),
      );

      await tester.tap(find.text('20').first);
      await tester.pump();
      await tester.tap(find.text('5').first);
      await tester.pump();

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
      await tester.pump();

      expect(savedStart!.day, 5);
      expect(savedEnd!.day, 20);
    });
  });

  group('LayrzDateTimeRangeSurface — Reset visibility', () {
    guardedTestWidgets('Reset is absent while the draft is empty', (tester) async {
      setWide(tester);
      await pumpThemed(
        tester,
        _bounded(
          LayrzDateTimeRangeSurface(value: null, startTime: null, endTime: null, onSave: (_, _) {}, onCancel: () {}),
        ),
      );

      final l10n = const LayrzUiL10nDefault();
      expect(findButtonLabel(l10n.pickerRangeReset), findsNothing);
    });

    guardedTestWidgets('Reset appears once an anchor is set and clears the draft back to empty', (tester) async {
      setWide(tester);
      await pumpThemed(
        tester,
        _bounded(
          LayrzDateTimeRangeSurface(value: null, startTime: null, endTime: null, onSave: (_, _) {}, onCancel: () {}),
        ),
      );

      final l10n = const LayrzUiL10nDefault();
      await tester.tap(find.text('5').first);
      await tester.pump();
      expect(findButtonLabel(l10n.pickerRangeReset), findsOneWidget);

      await tester.tap(findButtonLabel(l10n.pickerRangeReset));
      await tester.pump();

      expect(findButtonLabel(l10n.pickerRangeReset), findsNothing);
    });
  });

  group('LayrzDateTimeRangeSurface — involuntary close re-seeding', () {
    guardedTestWidgets('didUpdateWidget re-seeds the draft when value/startTime/endTime change externally', (
      tester,
    ) async {
      setWide(tester);
      LayrzDateRange? value = LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10));
      LayrzTimeOfDay? startTime = const LayrzTimeOfDay(hour: 9, minute: 0);
      LayrzTimeOfDay? endTime = const LayrzTimeOfDay(hour: 17, minute: 0);

      await tester.pumpWidget(
        Localizations(
          locale: const Locale('en'),
          delegates: const [DefaultWidgetsLocalizations.delegate, LayrzUiL10nDelegate()],
          child: LayrzTheme(
            data: LayrzThemeData.light(),
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => Center(
                    child: StatefulBuilder(
                      builder: (context, setState) => _bounded(
                        LayrzDateTimeRangeSurface(
                          value: value,
                          startTime: startTime,
                          endTime: endTime,
                          onSave: (_, _) {},
                          onCancel: () => setState(() {
                            value = null;
                            startTime = null;
                            endTime = null;
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('September 2026'), findsOneWidget);

      // Simulate an involuntary close: the caller (LayrzDateTimeRangeInput)
      // resets the widgets' own value/startTime/endTime to null after
      // dismissing the panel -- didUpdateWidget must re-seed the draft
      // rather than keep showing the previous month/selection.
      await tester.tap(findButtonLabel('Cancel'));
      await tester.pump();

      final l10n = const LayrzUiL10nDefault();
      final now = DateTime.now();
      expect(find.textContaining('${now.year}'), findsWidgets);
      expect(findButtonLabel(l10n.pickerRangeReset), findsNothing);
    });
  });

  group('LayrzDateTimeRangeSurface — TZDateTime zone preservation', () {
    guardedTestWidgets('a value seeded from TZDateTime endpoints reports both endpoints as TZDateTime on Save '
        '(not silently downgraded to plain DateTime)', (tester) async {
      setWide(tester);
      final location = tz.getLocation('America/New_York');
      final value = LayrzDateRange(
        start: tz.TZDateTime(location, 2026, 9, 1),
        end: tz.TZDateTime(location, 2026, 9, 3),
      );

      DateTime? savedStart;
      DateTime? savedEnd;
      await pumpThemed(
        tester,
        _bounded(
          LayrzDateTimeRangeSurface(
            value: value,
            startTime: const LayrzTimeOfDay(hour: 9, minute: 0),
            endTime: const LayrzTimeOfDay(hour: 17, minute: 0),
            onSave: (s, e) {
              savedStart = s;
              savedEnd = e;
            },
            onCancel: () {},
          ),
        ),
      );

      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(savedStart, isA<tz.TZDateTime>());
      expect((savedStart as tz.TZDateTime).location, location);
      expect(savedEnd, isA<tz.TZDateTime>());
      expect((savedEnd as tz.TZDateTime).location, location);
    });

    guardedTestWidgets('stepping months on a TZDateTime-seeded draft preserves the zone through _dayOnly', (
      tester,
    ) async {
      setWide(tester);
      final location = tz.getLocation('America/New_York');
      final value = LayrzDateRange(
        start: tz.TZDateTime(location, 2026, 9, 1),
        end: tz.TZDateTime(location, 2026, 9, 3),
      );

      DateTime? savedStart;
      DateTime? savedEnd;
      await pumpThemed(
        tester,
        _bounded(
          LayrzDateTimeRangeSurface(
            value: value,
            startTime: const LayrzTimeOfDay(hour: 9, minute: 0),
            endTime: const LayrzTimeOfDay(hour: 17, minute: 0),
            onSave: (s, e) {
              savedStart = s;
              savedEnd = e;
            },
            onCancel: () {},
          ),
        ),
      );

      final l10n = const LayrzUiL10nDefault();
      await tester.tap(find.bySemanticsLabel(l10n.calendarMonthNext));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(l10n.calendarMonthBack));
      await tester.pump();

      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(savedStart, isA<tz.TZDateTime>());
      expect(savedEnd, isA<tz.TZDateTime>());
    });
  });

  group('LayrzDateTimeRangeSurface — showSeconds and 24h/12h', () {
    guardedTestWidgets('showSeconds true renders three fields per cluster (six total)', (tester) async {
      setWide(tester);
      await pumpThemed(
        tester,
        _bounded(
          LayrzDateTimeRangeSurface(
            value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
            startTime: const LayrzTimeOfDay(hour: 9, minute: 0, second: 0),
            endTime: const LayrzTimeOfDay(hour: 17, minute: 0, second: 0),
            showSeconds: true,
            onSave: (_, _) {},
            onCancel: () {},
          ),
        ),
      );

      expect(find.byType(EditableText), findsNWidgets(6));
    });

    guardedTestWidgets('37 minutes is representable and round-trips unchanged through Save', (tester) async {
      setWide(tester);
      DateTime? savedStart;
      await pumpThemed(
        tester,
        _bounded(
          LayrzDateTimeRangeSurface(
            value: LayrzDateRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
            startTime: const LayrzTimeOfDay(hour: 9, minute: 0),
            endTime: const LayrzTimeOfDay(hour: 17, minute: 0),
            onSave: (s, _) => savedStart = s,
            onCancel: () {},
          ),
        ),
      );

      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(1), '37');
      await tester.pump();

      await tester.tap(findButtonLabel('Save'));
      await tester.pump();

      expect(savedStart!.minute, 37);
    });
  });
}
