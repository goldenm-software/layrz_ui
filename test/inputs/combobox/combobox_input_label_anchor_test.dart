import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/combobox/combobox_surface.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/pump_themed_app.dart';

/// Regression coverage for label/error hoisting, previously about parity
/// with `LayrzAnchoredPanel.coverAnchor`'s anchor-rect computation
/// (DESIGN-145's `_appendExtras` mechanism).
///
/// **DESIGN-98 retired `coverAnchor` for this widget entirely.** The
/// maintainer's instruction moved the desktop overlay from
/// `LayrzAnchoredPanel` to [LayrzEndDrawer] -- a fixed-width right-edge
/// drawer that does not anchor to the field's rect at all, so "does the
/// panel land on the field or the label" is no longer a question this widget
/// can even ask: the drawer's position is independent of both. The two
/// anchor-rect tests this file used to carry are replaced with the DESIGN-98
/// equivalent -- the drawer must not overlap the field, mirroring
/// `LayrzSelectInput`'s identical DESIGN-98 rewrite in
/// `select_input_test.dart`. `_appendExtras` itself is unchanged and still
/// hoists the label/error footer outside the field's own chrome (see
/// `combobox_input.dart`), which is what the third test below still covers.
void main() {
  group('LayrzComboBoxInput label/error anchor parity', () {
    testWidgets(
      "the desktop drawer's rect does not overlap the field's own bordered box (DESIGN-98 retires coverAnchor)",
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

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final drawerRect = tester.getRect(find.byType(BottomSheetContent));

        expect(
          drawerRect.overlaps(fieldBoxRect),
          isFalse,
          reason: 'the drawer is a separate, fixed-width right-edge panel -- it must not cover the field in place',
        );
      },
    );

    testWidgets('the opened drawer does not depend on the label\'s position at all', (tester) async {
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

      final labelRect = tester.getRect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().startsWith('Choose one'),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final drawerRect = tester.getRect(find.byType(BottomSheetContent));

      // Post-DESIGN-98 the drawer is a fixed-width right-edge panel, never
      // positioned against the label (or the field) at all -- it must sit
      // clear of the label, not merely below it by a coincidental amount.
      expect(drawerRect.overlaps(labelRect), isFalse);
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
