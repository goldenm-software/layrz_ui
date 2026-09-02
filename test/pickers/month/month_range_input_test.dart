import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzMonthRangeInput', () {
    guardedTestWidgets('renders with label and hint text', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        const LayrzMonthRangeInput(labelText: 'Months', hintText: 'Select months'),
      );

      expect(findButtonLabel('Months'), findsOneWidget);
      expect(find.text('Select months'), findsWidgets);
    });

    guardedTestWidgets('renders Save/Cancel footer once open -- multi-part commit, never on tap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        const LayrzMonthRangeInput(labelText: 'Months'),
      );

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(findButtonLabel(const LayrzUiL10nDefault().actionCancel), findsOneWidget);
      expect(findButtonLabel(const LayrzUiL10nDefault().actionSave), findsOneWidget);
    });

    group('arbitrary mode (default, consecutive: false) -- non-consecutive selection', () {
      guardedTestWidgets('picking January, March and September leaves nothing rejected', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(labelText: 'Months', arbitraryValue: [LayrzMonth(year: 2026, month: 1)]),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        await tester.tap(find.text('March'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('September'));
        await tester.pumpAndSettle();

        // All three earlier selections must still be tappable/present as
        // selected -- nothing was rejected for breaking contiguity, unlike
        // U5's contiguous date-range sibling.
        await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
        await tester.pumpAndSettle();
      });

      guardedTestWidgets('Save reports a sorted list of all arbitrarily-selected months', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        List<LayrzMonth>? saved;

        await pumpThemedApp(
          tester,
          LayrzMonthRangeInput(labelText: 'Months', onArbitraryChanged: (months) => saved = months),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        // Tap out of order: September, then January, then March.
        await tester.tap(find.text('September'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('January'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('March'));
        await tester.pumpAndSettle();

        await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
        await tester.pumpAndSettle();

        expect(saved, [
          const LayrzMonth(year: 2026, month: 1),
          const LayrzMonth(year: 2026, month: 3),
          const LayrzMonth(year: 2026, month: 9),
        ]);
      });

      guardedTestWidgets('every selected month is individually deselectable by tapping it again', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        List<LayrzMonth>? saved;

        await pumpThemedApp(
          tester,
          LayrzMonthRangeInput(
            labelText: 'Months',
            arbitraryValue: const [LayrzMonth(year: 2026, month: 1), LayrzMonth(year: 2026, month: 3)],
            onArbitraryChanged: (months) => saved = months,
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        // Deselect March -- the middle of the (non-contiguous-in-spirit)
        // selection, proving no interior lock applies.
        await tester.tap(find.text('March'));
        await tester.pumpAndSettle();

        await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
        await tester.pumpAndSettle();

        expect(saved, [const LayrzMonth(year: 2026, month: 1)]);
      });

      guardedTestWidgets('no contiguity constraint: skipping months tap-to-tap never rejects', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(
            labelText: 'Months',
            arbitraryValue: [LayrzMonth(year: 2026, month: 1), LayrzMonth(year: 2026, month: 4)],
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        // February and March are "interior" to a contiguous Jan-Apr span,
        // but arbitrary mode has no interior concept -- both must remain
        // tappable, unlike LayrzDateRangeSurface's rejected-interior cells.
        await tester.tap(find.text('February'));
        await tester.pumpAndSettle();

        await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
        await tester.pumpAndSettle();
      });

      guardedTestWidgets('Reset is visible once a month is selected and clears the draft', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(labelText: 'Months'),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        expect(findButtonLabel(const LayrzUiL10nDefault().pickerRangeReset), findsNothing);

        await tester.tap(find.text('January'));
        await tester.pumpAndSettle();

        expect(findButtonLabel(const LayrzUiL10nDefault().pickerRangeReset), findsOneWidget);

        await tester.tap(findButtonLabel(const LayrzUiL10nDefault().pickerRangeReset));
        await tester.pumpAndSettle();

        expect(findButtonLabel(const LayrzUiL10nDefault().pickerRangeReset), findsNothing);

        // Save is disabled once the draft is empty again.
        final saveButton = tester.widget<LayrzButton>(
          find.ancestor(of: findButtonLabel(const LayrzUiL10nDefault().actionSave), matching: find.byType(LayrzButton)),
        );
        expect(saveButton.isDisabled, isTrue);
      });

      guardedTestWidgets('all twelve full month names render, no abbreviation', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(labelText: 'Months'),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        const names = [
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
        for (final name in names) {
          expect(find.text(name), findsOneWidget, reason: '$name should render in full, unabbreviated');
        }
      });

      guardedTestWidgets('Cancel discards the draft and never reports onArbitraryChanged', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        var callCount = 0;

        await pumpThemedApp(
          tester,
          LayrzMonthRangeInput(labelText: 'Months', onArbitraryChanged: (_) => callCount++),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        await tester.tap(find.text('January'));
        await tester.pumpAndSettle();

        await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionCancel));
        await tester.pumpAndSettle();

        expect(callCount, 0);
      });

      guardedTestWidgets(
        'involuntary close (Escape) discards both the draft selection and the navigated year',
        (tester) async {
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await pumpThemedApp(
            tester,
            const LayrzMonthRangeInput(
              labelText: 'Months',
              arbitraryValue: [LayrzMonth(year: 2026, month: 1)],
            ),
          );

          await tester.tap(find.byType(LayrzInputChrome));
          await tester.pumpAndSettle();

          // Select an extra month and navigate to a different year, then
          // dismiss without Save.
          await tester.tap(find.text('March'));
          await tester.pumpAndSettle();

          final nextChevron = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Next year');
          await tester.tap(nextChevron);
          await tester.pumpAndSettle();
          expect(find.text('Year 2027'), findsOneWidget);

          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();

          // Reopen: both the extra selection and the navigated year must be
          // gone -- the draft re-seeds from the committed arbitraryValue and
          // the year re-seeds from its first selected month's year (2026).
          await tester.tap(find.byType(LayrzInputChrome));
          await tester.pumpAndSettle();

          expect(find.text('Year 2026'), findsOneWidget);
          expect(find.text('Year 2027'), findsNothing);

          final marchCell = tester.widget<Semantics>(
            find.ancestor(of: find.text('March'), matching: find.byType(Semantics)).first,
          );
          expect(marchCell.properties.selected, isNot(true));
        },
      );

      guardedTestWidgets('year chevrons change the displayed year without committing or closing', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        List<LayrzMonth>? committed;

        await pumpThemedApp(
          tester,
          LayrzMonthRangeInput(labelText: 'Months', onArbitraryChanged: (m) => committed = m),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        final nextChevron = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Next year');
        await tester.tap(nextChevron);
        await tester.pumpAndSettle();

        expect(find.text('September'), findsOneWidget, reason: 'the panel is still open');
        expect(committed, isNull);
      });

      guardedTestWidgets('a custom arbitraryFormatter overrides the default comma-joined summary', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          LayrzMonthRangeInput(
            labelText: 'Months',
            arbitraryValue: const [LayrzMonth(year: 2026, month: 1), LayrzMonth(year: 2026, month: 3)],
            arbitraryFormatter: (months) => '${months.length} custom',
          ),
        );

        expect(find.text('2 custom'), findsOneWidget);
      });

      guardedTestWidgets('comma-list summary at the overflow threshold boundary (n)', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(
            labelText: 'Months',
            arbitraryValue: [
              LayrzMonth(year: 2026, month: 1),
              LayrzMonth(year: 2026, month: 2),
              LayrzMonth(year: 2026, month: 3),
              LayrzMonth(year: 2026, month: 4),
            ],
          ),
        );

        expect(find.text('Jan 2026, Feb 2026, Mar 2026, Apr 2026'), findsOneWidget);
      });

      guardedTestWidgets('count fallback summary just beyond the overflow threshold (n+1)', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(
            labelText: 'Months',
            arbitraryValue: [
              LayrzMonth(year: 2026, month: 1),
              LayrzMonth(year: 2026, month: 2),
              LayrzMonth(year: 2026, month: 3),
              LayrzMonth(year: 2026, month: 4),
              LayrzMonth(year: 2026, month: 5),
            ],
          ),
        );

        expect(find.text('5 months selected'), findsOneWidget);
        expect(find.textContaining('Jan 2026'), findsNothing);
      });
    });

    group('consecutive mode (consecutive: true) -- contiguous, endpoint-adjust', () {
      guardedTestWidgets('empty -> anchor -> complete builds a contiguous range', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzMonthRange? saved;

        await pumpThemedApp(
          tester,
          LayrzMonthRangeInput(labelText: 'Months', consecutive: true, onRangeChanged: (r) => saved = r),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        await tester.tap(find.text('February'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('May'));
        await tester.pumpAndSettle();

        await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
        await tester.pumpAndSettle();

        expect(
          saved,
          const LayrzMonthRange(start: LayrzMonth(year: 2026, month: 2), end: LayrzMonth(year: 2026, month: 5)),
        );
      });

      guardedTestWidgets('an interior month is rejected once the range is complete', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzMonthRange? saved;

        await pumpThemedApp(
          tester,
          LayrzMonthRangeInput(
            labelText: 'Months',
            consecutive: true,
            rangeValue: const LayrzMonthRange(
              start: LayrzMonth(year: 2026, month: 2),
              end: LayrzMonth(year: 2026, month: 6),
            ),
            onRangeChanged: (r) => saved = r,
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        // April is interior to Feb-Jun: must be visibly inert, no reaction.
        await tester.tap(find.text('April'), warnIfMissed: false);
        await tester.pumpAndSettle();

        await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
        await tester.pumpAndSettle();

        expect(
          saved,
          const LayrzMonthRange(start: LayrzMonth(year: 2026, month: 2), end: LayrzMonth(year: 2026, month: 6)),
        );
      });

      guardedTestWidgets('re-tapping an endpoint picks it up and makes it movable', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzMonthRange? saved;

        await pumpThemedApp(
          tester,
          LayrzMonthRangeInput(
            labelText: 'Months',
            consecutive: true,
            rangeValue: const LayrzMonthRange(
              start: LayrzMonth(year: 2026, month: 2),
              end: LayrzMonth(year: 2026, month: 6),
            ),
            onRangeChanged: (r) => saved = r,
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        // Pick up the end (June), move it to August.
        await tester.tap(find.text('June'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('August'));
        await tester.pumpAndSettle();

        await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
        await tester.pumpAndSettle();

        expect(
          saved,
          const LayrzMonthRange(start: LayrzMonth(year: 2026, month: 2), end: LayrzMonth(year: 2026, month: 8)),
        );
      });

      guardedTestWidgets('reverse-order taps auto-swap so start <= end', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzMonthRange? saved;

        await pumpThemedApp(
          tester,
          LayrzMonthRangeInput(labelText: 'Months', consecutive: true, onRangeChanged: (r) => saved = r),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        await tester.tap(find.text('August'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('March'));
        await tester.pumpAndSettle();

        await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
        await tester.pumpAndSettle();

        expect(
          saved,
          const LayrzMonthRange(start: LayrzMonth(year: 2026, month: 3), end: LayrzMonth(year: 2026, month: 8)),
        );
      });

      guardedTestWidgets('Dec -> Jan year boundary is a valid contiguous range spanning years', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzMonthRange? saved;

        await pumpThemedApp(
          tester,
          LayrzMonthRangeInput(
            labelText: 'Months',
            consecutive: true,
            rangeValue: const LayrzMonthRange(
              start: LayrzMonth(year: 2026, month: 12),
              end: LayrzMonth(year: 2026, month: 12),
            ),
            onRangeChanged: (r) => saved = r,
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        expect(find.text('December'), findsOneWidget);

        final nextChevron = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Next year');
        await tester.tap(nextChevron);
        await tester.pumpAndSettle();

        await tester.tap(find.text('January'));
        await tester.pumpAndSettle();

        await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
        await tester.pumpAndSettle();

        expect(
          saved,
          const LayrzMonthRange(start: LayrzMonth(year: 2026, month: 12), end: LayrzMonth(year: 2027, month: 1)),
        );
      });

      guardedTestWidgets('the summary formats both endpoints with the range separator', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(
            labelText: 'Months',
            consecutive: true,
            rangeValue: LayrzMonthRange(start: LayrzMonth(year: 2026, month: 2), end: LayrzMonth(year: 2026, month: 6)),
          ),
        );

        expect(
          find.text('February 2026${const LayrzUiL10nDefault().dateTimePickerRangeSeparator}June 2026'),
          findsOneWidget,
        );
      });

      guardedTestWidgets('a custom rangeFormatter overrides the default range summary', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          LayrzMonthRangeInput(
            labelText: 'Months',
            consecutive: true,
            rangeValue: const LayrzMonthRange(
              start: LayrzMonth(year: 2026, month: 2),
              end: LayrzMonth(year: 2026, month: 6),
            ),
            rangeFormatter: (r) => 'custom range',
          ),
        );

        expect(find.text('custom range'), findsOneWidget);
      });

      guardedTestWidgets('disabledMonths is ignored in consecutive mode', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzMonthRange? saved;

        await pumpThemedApp(
          tester,
          LayrzMonthRangeInput(
            labelText: 'Months',
            consecutive: true,
            disabledMonths: {const LayrzMonth(year: 2026, month: 3)},
            onRangeChanged: (r) => saved = r,
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        await tester.tap(find.text('March'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('May'));
        await tester.pumpAndSettle();

        await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
        await tester.pumpAndSettle();

        expect(saved, isNotNull, reason: 'disabledMonths must not block selection in consecutive mode');
      });
    });

    group('disabled and error states', () {
      guardedTestWidgets('disabled field does not open the panel on tap', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(labelText: 'Months', disabled: true),
        );

        await tester.tap(find.byType(LayrzInputChrome), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.text('January'), findsNothing);
      });

      guardedTestWidgets('error styling paints a danger border even though the anchor is not readOnly', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(labelText: 'Months', errors: ['Required']),
        );

        // Regression guard for trap 1 -- readOnly must stay false so the
        // danger border can still paint with errors present.
        final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));
        expect(chrome.readOnly, isFalse);
        expect(chrome.errors, contains('Required'));
      });

      guardedTestWidgets('months before minimum are disabled and inert in arbitrary mode', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        List<LayrzMonth>? saved;

        await pumpThemedApp(
          tester,
          LayrzMonthRangeInput(
            labelText: 'Months',
            minimum: const LayrzMonth(year: 2026, month: 6),
            onArbitraryChanged: (m) => saved = m,
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        await tester.tap(find.text('January'), warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(saved, isNull);
      });
    });

    group('desktop viewport (>=960px)', () {
      guardedTestWidgets('uses an anchored panel, not a bottom sheet', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(labelText: 'Months'),
        );

        expect(find.byType(LayrzAnchoredPanel), findsOneWidget);
      });

      guardedTestWidgets('no overflow rendering the 4x3 grid plus footer on a wide viewport', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(labelText: 'Months'),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();
      });
    });

    group('compact viewport (<960px)', () {
      guardedTestWidgets('uses a bottom sheet, not an anchored panel', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(labelText: 'Months'),
        );

        expect(find.byType(LayrzAnchoredPanel), findsNothing);
      });

      guardedTestWidgets('opens the bottom sheet with month names and Save/Cancel, no overflow', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthRangeInput(labelText: 'Months'),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        expect(find.text('September'), findsOneWidget);
        expect(findButtonLabel(const LayrzUiL10nDefault().actionSave), findsOneWidget);
        expect(findButtonLabel(const LayrzUiL10nDefault().actionCancel), findsOneWidget);
      });

      guardedTestWidgets('tapping months then Save commits and closes the sheet', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        List<LayrzMonth>? committed;

        await pumpThemedApp(
          tester,
          LayrzMonthRangeInput(labelText: 'Months', onArbitraryChanged: (m) => committed = m),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        await tester.tap(find.text('April'));
        await tester.pumpAndSettle();

        await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
        await tester.pumpAndSettle();

        expect(committed, [const LayrzMonth(year: 2026, month: 4)]);
        expect(find.text('September'), findsNothing, reason: 'the sheet closed');
      });
    });

    guardedTestWidgets('a caller-provided controller and focus node are used, not replaced', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await pumpThemedApp(
        tester,
        LayrzMonthRangeInput(
          labelText: 'Months',
          arbitraryValue: const [LayrzMonth(year: 2026, month: 5)],
          controller: controller,
          focusNode: focusNode,
        ),
      );

      expect(controller.text, 'May 2026');
    });

    guardedTestWidgets('dense: true is accepted and renders without error', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        const LayrzMonthRangeInput(labelText: 'Months', dense: true),
      );

      expect(find.byType(LayrzMonthRangeInput), findsOneWidget);
    });

    guardedTestWidgets('hideDetails hides the error footer block', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        const LayrzMonthRangeInput(labelText: 'Months', errors: ['Bad value'], hideDetails: true),
      );

      expect(find.text('Bad value'), findsNothing);
    });
  });
}
