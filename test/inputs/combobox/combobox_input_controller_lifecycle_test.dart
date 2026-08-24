import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

/// A [TextEditingController] that counts net `addListener`/`removeListener`
/// calls, to prove a listener was actually detached rather than merely
/// inferring it from the absence of a crash.
class _CountingController extends TextEditingController {
  /// The current number of listeners registered via [addListener] that have
  /// not yet been removed via [removeListener].
  int listenerCount = 0;

  @override
  void addListener(VoidCallback listener) {
    listenerCount++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listenerCount--;
    super.removeListener(listener);
  }
}

/// Hosts a [LayrzComboBoxInput] whose `controller` can be swapped between two
/// externally-owned controllers, to exercise `didUpdateWidget`'s
/// controller-change branch.
class _SwappableComboBox extends StatefulWidget {
  const _SwappableComboBox({super.key, required this.controllerA, required this.controllerB});

  final TextEditingController controllerA;
  final TextEditingController controllerB;

  @override
  State<_SwappableComboBox> createState() => _SwappableComboBoxState();
}

class _SwappableComboBoxState extends State<_SwappableComboBox> {
  bool _useA = true;

  void swapToB() => setState(() => _useA = false);

  @override
  Widget build(BuildContext context) {
    return LayrzComboBoxInput(
      options: const ['Option 1', 'Option 2'],
      controller: _useA ? widget.controllerA : widget.controllerB,
    );
  }
}

void main() {
  group('LayrzComboBoxInput controller lifecycle', () {
    testWidgets('detaches its text listener from an outgoing externally-supplied controller on swap', (
      tester,
    ) async {
      final controllerA = _CountingController();
      final controllerB = _CountingController();
      addTearDown(() {
        controllerA.dispose();
        controllerB.dispose();
      });

      final key = GlobalKey<_SwappableComboBoxState>();

      await pumpThemedApp(
        tester,
        _SwappableComboBox(key: key, controllerA: controllerA, controllerB: controllerB),
      );

      final mountedListenerCount = controllerA.listenerCount;
      expect(mountedListenerCount, greaterThan(0));
      expect(controllerB.listenerCount, 0);

      // Swap the controller prop, exercising didUpdateWidget's
      // controller-change branch while both controllers remain alive and
      // externally owned.
      key.currentState!.swapToB();
      await tester.pump();

      // The outgoing controller must have its listener fully removed: before
      // the fix, LayrzComboBoxInput never called removeListener on the
      // controller it was swapping away from, leaking a listener onto a
      // controller the widget no longer tracks.
      expect(controllerA.listenerCount, 0);
      expect(controllerB.listenerCount, mountedListenerCount);
    });
  });
}
