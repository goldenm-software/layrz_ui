import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzMonthInput', () {
    guardedTestWidgets('renders with label and hint text', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        const LayrzMonthInput(labelText: 'Month', hintText: 'Select a month'),
      );

      expect(findButtonLabel('Month'), findsOneWidget);
      expect(find.text('Select a month'), findsWidgets);
    });

    guardedTestWidgets('shows empty text when value is null', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        const LayrzMonthInput(labelText: 'Month', hintText: 'Pick one'),
      );

      expect(find.text('Pick one'), findsWidgets);
    });

    guardedTestWidgets('formats a non-null value as "Month Year" by default', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        const LayrzMonthInput(labelText: 'Month', value: LayrzMonth(year: 2026, month: 9)),
      );

      expect(find.text('September 2026'), findsOneWidget);
    });

    guardedTestWidgets('a custom formatter overrides the default "Month Year" text', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzMonthInput(
          labelText: 'Month',
          value: const LayrzMonth(year: 2026, month: 9),
          formatter: (m) => '${m.month.toString().padLeft(2, '0')}/${m.year}',
        ),
      );

      expect(find.text('09/2026'), findsOneWidget);
      expect(find.text('September 2026'), findsNothing);
    });

    guardedTestWidgets('December to January year boundary formats correctly', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        const LayrzMonthInput(labelText: 'Month', value: LayrzMonth(year: 2025, month: 12)),
      );

      expect(find.text('December 2025'), findsOneWidget);
    });

    guardedTestWidgets('renders a Cancel/Save footer inside the drawer (DESIGN-98)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        const LayrzMonthInput(labelText: 'Month'),
      );

      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      expect(findButtonLabel('Save'), findsOneWidget);
      expect(findButtonLabel('Cancel'), findsOneWidget);
    });

    group('desktop viewport (>=960px)', () {
      guardedTestWidgets('opens the drawer (fixed-width, not a bottom sheet) at a wide viewport', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthInput(labelText: 'Month'),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        expect(
          findButtonLabel('Save'),
          findsOneWidget,
          reason: 'the drawer carries an actions row, unlike a bare anchored panel',
        );
      });

      guardedTestWidgets('tapping the field opens the panel with all twelve month names', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthInput(labelText: 'Month', value: LayrzMonth(year: 2026, month: 1)),
        );

        final field = find.byType(LayrzInputChrome);
        await tester.tap(field);
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
          expect(find.text(name), findsOneWidget, reason: '$name should render as a grid cell');
        }
      });

      guardedTestWidgets('a tap only drafts -- Save commits once and closes the drawer', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzMonth? committed;
        var callCount = 0;

        await pumpThemedApp(
          tester,
          StatefulBuilder(
            builder: (context, setState) {
              return LayrzMonthInput(
                labelText: 'Month',
                value: const LayrzMonth(year: 2026, month: 1),
                onChanged: (m) {
                  callCount++;
                  committed = m;
                },
              );
            },
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        await tester.tap(find.text('September'));
        await tester.pumpAndSettle();

        expect(callCount, 0, reason: 'DESIGN-98: a tap alone must no longer commit');
        expect(find.text('October'), findsOneWidget, reason: 'the drawer must stay open after a mere tap');

        await tester.tap(findButtonLabel('Save'));
        await tester.pumpAndSettle();

        expect(callCount, 1);
        expect(committed, const LayrzMonth(year: 2026, month: 9));
        // The drawer closed: the grid's month cells are no longer present.
        expect(find.text('October'), findsNothing);
      });

      // DESIGN-98 regression (see LayrzDateTimeInput's identical test for
      // the maintainer's report this guards against). Save must already be
      // enabled the moment the drawer opens on a pre-existing value, with
      // zero interaction -- not just after a fresh in-drawer tap.
      guardedTestWidgets('Save is already enabled on open when value is already set, with zero interaction', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzMonth? committed;
        var callCount = 0;

        await pumpThemedApp(
          tester,
          LayrzMonthInput(
            labelText: 'Month',
            value: const LayrzMonth(year: 2026, month: 1),
            onChanged: (m) {
              callCount++;
              committed = m;
            },
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
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
        expect(committed, const LayrzMonth(year: 2026, month: 1));
      });

      guardedTestWidgets('year chevrons change the displayed year without committing or closing', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzMonth? committed;

        await pumpThemedApp(
          tester,
          LayrzMonthInput(
            labelText: 'Month',
            value: const LayrzMonth(year: 2026, month: 1),
            onChanged: (m) => committed = m,
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        expect(find.text('Year 2026'), findsOneWidget);

        final nextChevron = find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Next year',
        );
        await tester.tap(nextChevron);
        await tester.pumpAndSettle();

        // The year advanced...
        expect(find.text('Year 2027'), findsOneWidget);
        // ...and the panel is still open (month cells are still present)...
        expect(find.text('September'), findsOneWidget);
        // ...and nothing committed as a side effect of navigation.
        expect(committed, isNull);
      });

      guardedTestWidgets(
        'reopening after involuntary close resets the displayed year to the committed value',
        (tester) async {
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await pumpThemedApp(
            tester,
            const LayrzMonthInput(labelText: 'Month', value: LayrzMonth(year: 2026, month: 1)),
          );

          // Open, navigate to a different year, then dismiss involuntarily
          // (Escape) without tapping a month.
          await tester.tap(find.byType(LayrzInputChrome));
          await tester.pumpAndSettle();

          final nextChevron = find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == 'Next year',
          );
          for (var i = 0; i < 4; i++) {
            await tester.tap(nextChevron);
            await tester.pumpAndSettle();
          }
          expect(find.text('Year 2030'), findsOneWidget);

          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();

          // Reopen: the year must be re-seeded from the committed value
          // (2026), not left at the navigated-to 2030.
          await tester.tap(find.byType(LayrzInputChrome));
          await tester.pumpAndSettle();

          expect(find.text('Year 2026'), findsOneWidget);
          expect(find.text('Year 2030'), findsNothing);
        },
      );

      guardedTestWidgets('escape key closes the panel without changing the value', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzMonth? committed;

        await pumpThemedApp(
          tester,
          LayrzMonthInput(
            labelText: 'Month',
            value: const LayrzMonth(year: 2026, month: 1),
            onChanged: (m) => committed = m,
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.text('January 2026'), findsOneWidget);
        expect(committed, isNull);
      });

      guardedTestWidgets('months before minimum are disabled and inert', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzMonth? committed;

        await pumpThemedApp(
          tester,
          LayrzMonthInput(
            labelText: 'Month',
            value: const LayrzMonth(year: 2026, month: 6),
            minimum: const LayrzMonth(year: 2026, month: 6),
            onChanged: (m) => committed = m,
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        await tester.tap(find.text('January'), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(committed, isNull);
      });

      guardedTestWidgets('individually disabled months are inert', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzMonth? committed;

        await pumpThemedApp(
          tester,
          LayrzMonthInput(
            labelText: 'Month',
            value: const LayrzMonth(year: 2026, month: 1),
            disabledMonths: {const LayrzMonth(year: 2026, month: 3)},
            onChanged: (m) => committed = m,
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        await tester.tap(find.text('March'), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(committed, isNull);
      });

      guardedTestWidgets('error styling paints a danger border even though the anchor is not readOnly', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthInput(labelText: 'Month', errors: ['Required']),
        );

        // Regression guard for trap 1: LayrzInputStyleSpec.resolve ranks
        // `readOnly` above `error`, so if this input ever hardcoded
        // `readOnly: true` on its chrome, the danger border below would
        // silently stop painting even with `errors` non-empty. The chrome is
        // always constructed with `readOnly: false`, so error styling must
        // still be visible.
        expect(find.byType(LayrzInputChrome), findsOneWidget);
        final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));
        expect(chrome.readOnly, isFalse);
        expect(chrome.errors, contains('Required'));
      });

      guardedTestWidgets('no overflow rendering the month grid (3 rows x 4 cols) on a wide viewport', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthInput(labelText: 'Month'),
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
          const LayrzMonthInput(labelText: 'Month'),
        );

        expect(find.byType(LayrzAnchoredPanel), findsNothing);
      });

      guardedTestWidgets('tapping the field opens the bottom sheet with month names, no overflow', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthInput(labelText: 'Month'),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        expect(find.text('September'), findsOneWidget);
      });

      guardedTestWidgets('a tap only drafts -- Save commits and closes the sheet on compact viewport', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzMonth? committed;

        await pumpThemedApp(
          tester,
          LayrzMonthInput(
            labelText: 'Month',
            value: const LayrzMonth(year: 2026, month: 1),
            onChanged: (m) => committed = m,
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        await tester.tap(find.text('April'));
        await tester.pumpAndSettle();
        expect(committed, isNull, reason: 'DESIGN-98: a tap alone must no longer commit, even on mobile');

        await tester.tap(findButtonLabel('Save'));
        await tester.pumpAndSettle();

        expect(committed, const LayrzMonth(year: 2026, month: 4));
        expect(find.text('May'), findsNothing);
      });

      guardedTestWidgets('disabled field does not open the sheet on tap', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthInput(labelText: 'Month', disabled: true),
        );

        await tester.tap(find.byType(LayrzInputChrome), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.text('September'), findsNothing);
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
        LayrzMonthInput(
          labelText: 'Month',
          value: const LayrzMonth(year: 2026, month: 5),
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
        const LayrzMonthInput(labelText: 'Month', dense: true),
      );

      expect(find.byType(LayrzMonthInput), findsOneWidget);
    });

    guardedTestWidgets('hideDetails hides the error footer block', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        const LayrzMonthInput(labelText: 'Month', errors: ['Bad value'], hideDetails: true),
      );

      expect(find.text('Bad value'), findsNothing);
    });

    group('error state stays fully interactive (Finding 4)', () {
      // Regression test locking in correct behaviour -- see
      // `date_input_test.dart`'s equivalent group for the full rationale.
      // `month_input.dart`'s `onTap` is gated solely on `widget.disabled`,
      // never on `widget.errors`.
      guardedTestWidgets('tapping the anchor opens the panel even with errors present', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthInput(labelText: 'Month', errors: ['Required']),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        expect(find.text('September'), findsOneWidget);
      });

      guardedTestWidgets('a selection still commits onChanged with errors present', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzMonth? committed;

        await pumpThemedApp(
          tester,
          LayrzMonthInput(
            labelText: 'Month',
            value: const LayrzMonth(year: 2026, month: 1),
            errors: const ['Required'],
            onChanged: (m) => committed = m,
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();
        await tester.tap(find.text('September'));
        await tester.pumpAndSettle();
        await tester.tap(findButtonLabel('Save'));
        await tester.pumpAndSettle();

        expect(committed, const LayrzMonth(year: 2026, month: 9));
      });

      guardedTestWidgets('tapping the anchor opens the bottom sheet on a compact viewport with errors present', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzMonthInput(labelText: 'Month', errors: ['Required']),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        expect(find.text('September'), findsOneWidget);
      });
    });

    group('pattern/formatter changes reflect immediately (Finding 5)', () {
      // Regression test for DESIGN-45 -- see `date_input_test.dart`'s
      // equivalent group for the full rationale. `LayrzMonthInput` has no
      // `pattern` field, only `formatter`, so only that is exercised here.
      guardedTestWidgets('changing formatter alone re-renders the summary with no new selection', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        String Function(LayrzMonth)? formatter;

        await pumpThemedApp(
          tester,
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LayrzMonthInput(
                    labelText: 'Month',
                    value: const LayrzMonth(year: 2026, month: 9),
                    formatter: formatter,
                  ),
                  GestureDetector(
                    onTap: () => setState(() => formatter = (m) => 'CUSTOM ${m.month}/${m.year}'),
                    child: const Text('Set formatter'),
                  ),
                ],
              );
            },
          ),
        );

        expect(find.text('September 2026'), findsOneWidget);

        await tester.tap(find.text('Set formatter'));
        await tester.pump();

        expect(find.text('CUSTOM 9/2026'), findsOneWidget);
        expect(find.text('September 2026'), findsNothing);
      });
    });
  });
}
