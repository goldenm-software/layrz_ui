import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

/// Hosts a [LayrzSelectInput] whose `focusNode` can be swapped between an
/// externally-owned [FocusNode] and `null`, to exercise `didUpdateWidget`'s
/// focus-node-change branch.
class _SwappableSelectInput extends StatefulWidget {
  const _SwappableSelectInput({super.key, required this.external});

  /// The externally-owned focus node under test.
  final FocusNode external;

  @override
  State<_SwappableSelectInput> createState() => _SwappableSelectInputState();
}

class _SwappableSelectInputState extends State<_SwappableSelectInput> {
  bool _useExternal = true;

  /// Swaps the widget's `focusNode` prop from [_SwappableSelectInput.external] to `null`.
  void swapToNull() => setState(() => _useExternal = false);

  @override
  Widget build(BuildContext context) {
    return LayrzSelectInput<String>(
      itemExtent: 40,
      items: const [
        LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
      ],
      focusNode: _useExternal ? widget.external : null,
    );
  }
}

void main() {
  group('LayrzSelectInput focus node lifecycle', () {
    testWidgets('does not dispose an externally-supplied focusNode after it is swapped for null', (tester) async {
      final external = FocusNode();
      final key = GlobalKey<_SwappableSelectInputState>();

      await pumpThemedApp(tester, _SwappableSelectInput(key: key, external: external));

      // Swap the focusNode prop from external to null, exercising
      // didUpdateWidget's focus-node-change branch.
      key.currentState!.swapToNull();
      await tester.pump();

      // Unmount entirely, triggering State.dispose().
      await tester.pumpWidget(const SizedBox());

      // The externally-supplied node must survive: before the fix,
      // LayrzSelectInput never updated its internal `_focusNode` reference on
      // a focusNode swap, so `dispose()` (which checks the *final*
      // `widget.focusNode`, now null) disposed the node the widget was
      // actually still holding -- the caller's external node.
      //
      // addListener() on a disposed ChangeNotifier throws (debug assertion), so
      // it is the real liveness probe here -- unlike calling dispose() directly,
      // which both consumes the only chance to check liveness and would throw a
      // *different*, misleading error ("dispose() called twice") if the widget
      // had already disposed the node, rather than the intended "used after
      // being disposed" signal.
      expect(() => external.addListener(() {}), returnsNormally);
      external.dispose();
    });
  });

  // DESIGN-144: separated from the lifecycle group above on purpose -- this
  // run also touches the surface's height rule (DESIGN-40), and a red suite
  // must point unambiguously at which change broke it.
  group('LayrzSelectInput focus node wiring (DESIGN-144)', () {
    testWidgets('caller-supplied focusNode is usable via requestFocus on desktop', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: const [
            LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
          ],
          focusNode: focusNode,
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('caller-supplied focusNode is usable via requestFocus on mobile', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: const [
            LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
          ],
          focusNode: focusNode,
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
    });
  });
}
