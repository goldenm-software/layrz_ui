import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

/// Hosts a [LayrzSwitchInput] whose `focusNode` can be swapped between an
/// externally-owned [FocusNode] and `null`, to exercise `didUpdateWidget`'s
/// focus-node-change branch.
class _SwappableSwitchInput extends StatefulWidget {
  const _SwappableSwitchInput({super.key, required this.external});

  /// The externally-owned focus node under test.
  final FocusNode external;

  @override
  State<_SwappableSwitchInput> createState() => _SwappableSwitchInputState();
}

class _SwappableSwitchInputState extends State<_SwappableSwitchInput> {
  bool _useExternal = true;

  /// Swaps the widget's `focusNode` prop from [_SwappableSwitchInput.external] to `null`.
  void swapToNull() => setState(() => _useExternal = false);

  @override
  Widget build(BuildContext context) {
    return LayrzSwitchInput(
      value: false,
      onChanged: (_) {},
      focusNode: _useExternal ? widget.external : null,
    );
  }
}

void main() {
  group('LayrzSwitchInput focus node lifecycle', () {
    testWidgets('does not dispose an externally-supplied focusNode after it is swapped for null', (tester) async {
      final external = FocusNode();
      final key = GlobalKey<_SwappableSwitchInputState>();

      await pumpThemedApp(tester, _SwappableSwitchInput(key: key, external: external));

      // Swap the focusNode prop from external to null, exercising
      // didUpdateWidget's focus-node-change branch.
      key.currentState!.swapToNull();
      await tester.pump();

      // Unmount entirely, triggering State.dispose().
      await tester.pumpWidget(const SizedBox());

      // The externally-supplied node must survive: before the fix,
      // LayrzSwitchInput never updated its internal `_focusNode` reference on
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
}
