import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

void main() {
  // Mirrors LayrzSelectInput's DESIGN-144 fix (select_input_focus_lifecycle_test.dart):
  // a caller-supplied focusNode was accepted, lifecycle-managed and disposed
  // correctly, but never attached to any Focus widget in the tree, so
  // `requestFocus()` on it was a silent no-op. These tests assert the node
  // actually gains focus, not merely that it survives disposal --
  // `returnsNormally` on `dispose()` cannot distinguish a wired node from an
  // inert one.
  group('LayrzDurationInput focus node wiring', () {
    testWidgets('caller-supplied focusNode is usable via requestFocus on desktop', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          focusNode: focusNode,
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('caller-supplied focusNode is usable via requestFocus on compact', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          focusNode: focusNode,
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
    });
  });
}
