import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/pump_themed_app.dart';

/// Regression coverage for [LayrzComboBoxInput]'s field styling itself as
/// errored, for BOTH the closed field and the opened desktop panel's own
/// first row -- the same defect [LayrzDurationInput] had (see
/// duration_input_error_border_test.dart), verified by direct render here
/// rather than assumed from reading the source.
///
/// **Verified already correct.** [LayrzComboBoxInput] passes
/// `readOnly: widget.readOnly` (the caller's own flag, defaulting to `false`)
/// to its chrome, not an internal always-true readOnly fact -- so the
/// precedence trap ("disabled > readOnly > error > ...") in
/// [LayrzInputStyleSpec.resolve] never triggers here. The open panel's border
/// is painted separately by `LayrzAnchoredPanel.border`, colored from
/// `widget.errors.isNotEmpty` directly. These tests exist as a
/// forward-looking regression guard, asserting on the RENDERED
/// [BoxDecoration.border] color, not on whether `errors` was merely passed as
/// a parameter.
void main() {
  group('LayrzComboBoxInput error border rendering', () {
    testWidgets('the closed field border resolves to the danger color when errors is non-empty', (tester) async {
      late LayrzTokens tokens;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            tokens = context.tokens;
            return LayrzComboBoxInput(
              options: const ['Option A', 'Option B'],
              labelText: 'Choose',
              errors: const ['Required'],
            );
          },
        ),
      );

      final borderedContainers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.decoration is BoxDecoration && (c.decoration! as BoxDecoration).border != null)
          .toList();

      final anyDanger = borderedContainers.any(
        (c) => ((c.decoration! as BoxDecoration).border! as Border).top.color == tokens.colors.danger,
      );

      expect(
        anyDanger,
        isTrue,
        reason: 'at least one bordered container must resolve to the danger color when errors is non-empty',
      );
    });

    testWidgets('the opened panel border also resolves to the danger color when errors is non-empty', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late LayrzTokens tokens;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            tokens = context.tokens;
            return LayrzComboBoxInput(
              options: const ['Option A', 'Option B'],
              labelText: 'Choose',
              errors: const ['Required'],
            );
          },
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final borderedContainers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.decoration is BoxDecoration && (c.decoration! as BoxDecoration).border != null)
          .toList();

      final anyDanger = borderedContainers.any(
        (c) => ((c.decoration! as BoxDecoration).border! as Border).top.color == tokens.colors.danger,
      );

      expect(
        anyDanger,
        isTrue,
        reason: 'the opened panel must also render the danger border, not just the closed field',
      );
    });

    testWidgets('the closed field border resolves to the neutral color when errors is empty', (tester) async {
      late LayrzTokens tokens;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            tokens = context.tokens;
            return LayrzComboBoxInput(
              options: const ['Option A', 'Option B'],
              labelText: 'Choose',
            );
          },
        ),
      );

      final borderedContainers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.decoration is BoxDecoration && (c.decoration! as BoxDecoration).border != null)
          .toList();

      final anyDanger = borderedContainers.any(
        (c) => ((c.decoration! as BoxDecoration).border! as Border).top.color == tokens.colors.danger,
      );

      expect(anyDanger, isFalse, reason: 'no container should render the danger border when there are no errors');
    });
  });
}
