import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

/// Regression coverage for [LayrzDurationInput]'s field failing to style
/// itself as errored.
///
/// **Root cause:** [LayrzDurationInput]'s summary field always passed
/// `readOnly: true` to both [LayrzInputStyleSpec.resolve] and the inner
/// [LayrzInputChrome] it builds -- an internal implementation fact (the field
/// never accepts typed input, it opens a picker on tap), not something a
/// caller ever set (`LayrzDurationInput` exposes no `readOnly` parameter at
/// all). [LayrzInputStyleSpec.resolve]'s own documented precedence --
/// "disabled > readOnly > error > pressed > hover/focused > default" --
/// ranks readOnly above error, so the field's border and background silently
/// stayed in their neutral resting colors even when [LayrzDurationInput.errors]
/// was non-empty. Reported by the maintainer from a device screenshot: label,
/// error icon, and footer text all rendered correctly, but the field's own
/// border stayed grey instead of red.
///
/// These tests assert on the RENDERED decoration -- the actual resolved
/// [BoxDecoration.border] color on the field's bordered [Container] -- not on
/// whether `errors` was merely passed as a parameter. A parameter-presence
/// assertion is exactly the class of test that let a blank field pass 111
/// green tests elsewhere in this repo.
void main() {
  group('LayrzDurationInput error border rendering', () {
    guardedTestWidgets('the field border resolves to the danger color when errors is non-empty', (tester) async {
      late LayrzTokens tokens;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            tokens = context.tokens;
            return LayrzDurationInput(
              labelText: 'Required Duration',
              isRequired: true,
              errors: const ['Duration is required'],
            );
          },
        ),
      );

      final borderedContainers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.decoration is BoxDecoration && (c.decoration! as BoxDecoration).border != null)
          .toList();

      expect(borderedContainers, isNotEmpty, reason: 'the field must render at least one bordered container');

      final fieldContainer = borderedContainers.firstWhere(
        (c) => ((c.decoration! as BoxDecoration).border! as Border).top.color == tokens.colors.danger,
        orElse: () => borderedContainers.first,
      );
      final resolvedColor = ((fieldContainer.decoration! as BoxDecoration).border! as Border).top.color;

      expect(
        resolvedColor,
        tokens.colors.danger,
        reason:
            'the field border must resolve to the danger color when errors is non-empty, not the neutral resting color',
      );
    });

    guardedTestWidgets('the field border resolves to the neutral color when errors is empty', (tester) async {
      late LayrzTokens tokens;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            tokens = context.tokens;
            return LayrzDurationInput(
              labelText: 'Optional Duration',
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
