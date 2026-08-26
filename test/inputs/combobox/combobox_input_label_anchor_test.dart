import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/combobox/combobox_surface.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/pump_themed_app.dart';

/// Regression coverage for label/error hoisting parity with
/// `LayrzSelectInput` (DESIGN-145's `_appendExtras` mechanism).
///
/// **Root cause:** [LayrzComboBoxInput]'s desktop overlay is a
/// [LayrzAnchoredPanel] with `coverAnchor: true` -- the opened panel
/// positions itself against the anchor widget's own rect. Before this fix,
/// the anchor was the inner [LayrzInputChrome], which rendered `labelText`
/// and the error footer INSIDE itself, so the anchor's rect included the
/// label. The panel then landed on the label's top-left rather than the
/// actual bordered field's top-left.
///
/// Measured directly before the fix, at this test's own viewport: the
/// opened panel's top matched the label's top exactly, 24.0 logical pixels
/// above the field's own bordered box.
void main() {
  group('LayrzComboBoxInput label/error anchor parity (Select mechanism)', () {
    testWidgets(
      "the opened desktop panel's top-left aligns with the FIELD's bordered box, not the label's",
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          LayrzComboBoxInput(
            options: const ['Option A', 'Option B'],
            labelText: 'Choose one',
            errors: const ['Something is wrong'],
          ),
        );

        // The actual bordered field box -- a Container whose BoxDecoration
        // carries a border. This is what the user perceives as "the field",
        // distinct from the label rendered above it.
        final fieldBoxRect = tester.getRect(
          find
              .byWidgetPredicate(
                (w) =>
                    w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).border != null,
              )
              .first,
        );

        // The label, rendered via RichText/TextSpan (not a plain Text widget).
        final labelRect = tester.getRect(
          find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().startsWith('Choose one'),
          ),
        );

        // Sanity: the label sits strictly above the field box before the panel
        // ever opens -- otherwise this test would not be exercising the defect
        // it targets.
        expect(labelRect.top, lessThan(fieldBoxRect.top));

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final panelRect = tester.getRect(find.byType(LayrzComboBoxPanelContent));

        // The opened panel must cover the FIELD, exactly like
        // `LayrzSelectInput`'s DESIGN-145 defect-1 regression (see
        // select_input_test.dart's "defect 1" test) -- tolerance 0.0.
        expect(panelRect.overlaps(fieldBoxRect), isTrue);
        expect(panelRect.top, closeTo(fieldBoxRect.top, 0.0));
        expect(panelRect.left, closeTo(fieldBoxRect.left, 0.0));

        // And must NOT land on the label -- it must sit strictly below it,
        // by more than a hairline, so a regression that re-includes the label
        // in the anchor's rect is caught even if some other adjustment
        // shrinks the gap without eliminating it.
        expect(panelRect.top, greaterThan(labelRect.top + 1.0));
      },
    );

    testWidgets('the LayrzAnchoredPanel widget itself also anchors to the field, not the label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          options: const ['Option A', 'Option B'],
          labelText: 'Choose one',
        ),
      );

      final fieldBoxRect = tester.getRect(
        find
            .byWidgetPredicate(
              (w) => w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).border != null,
            )
            .first,
      );

      final anchoredPanelRect = tester.getRect(find.byType(LayrzAnchoredPanel));

      expect(anchoredPanelRect.top, closeTo(fieldBoxRect.top, 0.0));
      expect(anchoredPanelRect.left, closeTo(fieldBoxRect.left, 0.0));
    });

    testWidgets('label and error text are still rendered when the panel is closed', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          options: const ['Option A', 'Option B'],
          labelText: 'Choose one',
          errors: const ['Something is wrong'],
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().startsWith('Choose one'),
        ),
        findsOneWidget,
      );
      expect(find.text('Something is wrong'), findsOneWidget);
    });
  });
}
