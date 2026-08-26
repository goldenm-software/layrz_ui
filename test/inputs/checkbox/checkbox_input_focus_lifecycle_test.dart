import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

/// Hosts a [LayrzCheckboxInput] whose `focusNode` can be swapped between an
/// externally-owned [FocusNode] and `null`, to exercise `didUpdateWidget`'s
/// focus-node-change branch.
class _SwappableCheckboxInput extends StatefulWidget {
  const _SwappableCheckboxInput({super.key, required this.external});

  /// The externally-owned focus node under test.
  final FocusNode external;

  @override
  State<_SwappableCheckboxInput> createState() => _SwappableCheckboxInputState();
}

class _SwappableCheckboxInputState extends State<_SwappableCheckboxInput> {
  bool _useExternal = true;

  /// Swaps the widget's `focusNode` prop from [_SwappableCheckboxInput.external] to `null`.
  void swapToNull() => setState(() => _useExternal = false);

  @override
  Widget build(BuildContext context) {
    return LayrzCheckboxInput(
      value: false,
      onChanged: (_) {},
      focusNode: _useExternal ? widget.external : null,
    );
  }
}

void main() {
  group('LayrzCheckboxInput focus node lifecycle', () {
    testWidgets('does not dispose an externally-supplied focusNode after it is swapped for null', (tester) async {
      final external = FocusNode();
      final key = GlobalKey<_SwappableCheckboxInputState>();

      await pumpThemedApp(tester, _SwappableCheckboxInput(key: key, external: external));

      // Swap the focusNode prop from external to null, exercising
      // didUpdateWidget's focus-node-change branch.
      key.currentState!.swapToNull();
      await tester.pump();

      // Unmount entirely, triggering State.dispose().
      await tester.pumpWidget(const SizedBox());

      // The externally-supplied node must survive: before the fix,
      // LayrzCheckboxInput never updated its internal `_focusNode` reference
      // on a focusNode swap, so `dispose()` (which checks the *final*
      // `widget.focusNode`, now null) disposed the node the widget was
      // actually still holding -- the caller's external node.
      expect(() => external.dispose(), returnsNormally);
    });
  });
}
