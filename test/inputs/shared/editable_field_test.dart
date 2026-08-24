import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/shared/editable_field.dart';

import '../../helpers/pump_themed.dart';

/// A [FocusNode] that exposes [notify] to invoke [notifyListeners] directly.
///
/// The production crash this test guards against comes from
/// `FocusManager.applyFocusChangesIfNeeded` calling `FocusNode._notify`, which
/// in turn calls [ChangeNotifier.notifyListeners] on a node that may no
/// longer be attached to a live focus tree (e.g. it belonged to a field that
/// was just unmounted). Driving `requestFocus()` in a test does not
/// reliably reproduce that path once the node is detached, so this subclass
/// calls the protected [notifyListeners] directly to simulate exactly what
/// the focus manager does, independent of attachment state.
///
/// It also counts net `addListener`/`removeListener` calls, so a single node
/// type can back both the crash regression test and the listener-detachment
/// assertion below.
class _NotifiableFocusNode extends FocusNode {
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

  /// Invokes [notifyListeners], simulating a focus-change notification
  /// delivered by the focus manager.
  void notify() => notifyListeners();
}

/// Builds a minimal [LayrzEditableFieldConfig] wired to [controller] and
/// [focusNode], with every other option left at its simplest valid value.
LayrzEditableFieldConfig _buildConfig({
  required TextEditingController controller,
  required FocusNode focusNode,
}) {
  return LayrzEditableFieldConfig(
    labelText: null,
    hintText: null,
    disabled: false,
    readOnly: false,
    controller: controller,
    focusNode: focusNode,
    onChanged: null,
    onSubmit: null,
    onFocusChanged: null,
    onTap: null,
    keyboardType: TextInputType.text,
    textInputAction: null,
    inputFormatters: const [],
    maxLength: null,
    autofocus: false,
    textCapitalization: TextCapitalization.none,
    autofillHints: const [],
    obscureText: false,
    autocorrect: true,
    enableSuggestions: true,
    actions: null,
    minLines: 1,
    maxLines: 1,
    expands: false,
  );
}

void main() {
  group('LayrzEditableField focus node lifecycle', () {
    testWidgets(
      'does not crash when an externally-supplied FocusNode notifies after the field unmounts',
      (tester) async {
        final focusNode = _NotifiableFocusNode();
        final controller = TextEditingController();
        final showField = ValueNotifier<bool>(true);
        addTearDown(() {
          showField.dispose();
          controller.dispose();
          focusNode.dispose();
        });

        await pumpThemed(
          tester,
          ValueListenableBuilder<bool>(
            valueListenable: showField,
            builder: (context, show, _) {
              if (!show) {
                return const SizedBox.shrink();
              }
              return LayrzEditableField(
                config: _buildConfig(controller: controller, focusNode: focusNode),
              );
            },
          ),
        );

        // Unmount only the field. The focus node is owned by this test (as a
        // stand-in for a parent widget, e.g. LayrzSearchInput in icon mode)
        // and stays alive across the unmount.
        showField.value = false;
        await tester.pump();

        // Simulate the focus manager notifying this node of a focus change
        // elsewhere in the tree. Before the fix, LayrzEditableFieldState
        // never removed its listener from an externally-supplied node, so
        // this invoked setState on a disposed State and threw
        // "setState() called after dispose()".
        focusNode.notify();
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'removes its focus listener from an externally-supplied FocusNode on unmount',
      (tester) async {
        final focusNode = _NotifiableFocusNode();
        final controller = TextEditingController();
        final showField = ValueNotifier<bool>(true);
        addTearDown(() {
          showField.dispose();
          controller.dispose();
          focusNode.dispose();
        });

        await pumpThemed(
          tester,
          ValueListenableBuilder<bool>(
            valueListenable: showField,
            builder: (context, show, _) {
              if (!show) {
                return const SizedBox.shrink();
              }
              return LayrzEditableField(
                config: _buildConfig(controller: controller, focusNode: focusNode),
              );
            },
          ),
        );

        final mountedListenerCount = focusNode.listenerCount;
        expect(mountedListenerCount, greaterThan(0));

        showField.value = false;
        await tester.pump();

        // The net listener count must return all the way to zero (the
        // pre-mount baseline) once the field unmounts. Asserting merely
        // "less than mounted" is not enough: EditableText attaches its own
        // internal listener to the same node and correctly removes it on
        // its own dispose regardless of this bug, which alone produces a
        // decrease and would mask a leaked LayrzEditableFieldState listener.
        expect(focusNode.listenerCount, 0);
      },
    );
  });
}
