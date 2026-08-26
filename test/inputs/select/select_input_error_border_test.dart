import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

/// Regression coverage for [LayrzSelectInput]'s field styling itself as
/// errored -- the same defect [LayrzDurationInput] had (see
/// duration_input_error_border_test.dart), verified by direct render here
/// rather than assumed from reading the source.
///
/// **Verified already correct.** Unlike [LayrzDurationInput],
/// [LayrzSelectInput] never passes `readOnly: true` to the
/// [LayrzInputStyleSpec.resolve] call that produces its outer field border --
/// [LayrzInputChrome] itself is explicitly constructed with `readOnly: false`
/// there. So the precedence trap ("disabled > readOnly > error > ...") never
/// triggers for Select. These tests exist as a forward-looking regression
/// guard, asserting on the RENDERED [BoxDecoration.border] color, not on
/// whether `errors` was merely passed as a parameter.
void main() {
  group('LayrzSelectInput error border rendering', () {
    final items = <LayrzSelectItem<String>>[
      const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
    ];

    testWidgets('the field border resolves to the danger color when errors is non-empty', (tester) async {
      late LayrzTokens tokens;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            tokens = context.tokens;
            return LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
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

    testWidgets('the field border resolves to the neutral color when errors is empty', (tester) async {
      late LayrzTokens tokens;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            tokens = context.tokens;
            return LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
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
