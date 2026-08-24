import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

/// Lifecycle/security regression coverage for [LayrzNumberInput]'s keyboard
/// stepping handler (DESIGN-142, finding 1).
///
/// Historically, `_handleKeyEvent` (an instance method closing over the
/// [State]) was assigned directly onto the field's [FocusNode] in `initState`
/// (`_focusNode.onKeyEvent = _handleKeyEvent;`) and never cleared. When the
/// [FocusNode] was hoisted by the caller via [LayrzNumberInput.focusNode], the
/// widget's disposal contract correctly left that node undisposed -- but the
/// stale [FocusNode.onKeyEvent] reference to a now-defunct [State] survived
/// the widget's own unmount. If the caller then reused the node elsewhere,
/// a stepping key would run [State] methods that read and write an already
/// disposed [TextEditingController], and would steal the key from whichever
/// widget legitimately owned the node afterwards. A second path meant
/// [LayrzNumberInput.focusNode] being swapped (via `didUpdateWidget`) silently
/// broke keyboard stepping altogether, since the handler was never installed
/// on the incoming node.
///
/// The fix moves `_handleKeyEvent` onto the `onKeyEvent` of an ancestor
/// [Focus] widget built fresh on every [State.build] call, instead of
/// mutating the field's own (possibly caller-owned) [FocusNode]. Being part
/// of the normal widget tree, that [Focus] widget -- and its handler -- is
/// torn down automatically and deterministically with [State.dispose], and
/// it keeps working across a [LayrzNumberInput.focusNode] swap because it
/// never depended on which specific node is currently focused underneath it.
void main() {
  group('LayrzNumberInput keyboard handler lifecycle', () {
    testWidgets(
      'external focusNode does not retain a stale key handler after the widget unmounts',
      (tester) async {
        final focusNode = FocusNode(debugLabel: 'hoisted');
        addTearDown(focusNode.dispose);
        var onChangedCallCount = 0;

        await pumpThemedApp(
          tester,
          LayrzNumberInput(
            focusNode: focusNode,
            value: 5,
            onChanged: (_) => onChangedCallCount++,
          ),
        );

        // Give the field focus while the widget (and its internal controller)
        // are alive.
        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        expect(focusNode.hasFocus, isTrue);

        // Unmount LayrzNumberInput. Per its documented disposal contract, the
        // caller-supplied focusNode is NOT disposed -- it survives.
        await pumpThemedApp(tester, const SizedBox.shrink());

        // The caller reuses the still-alive node on a completely unrelated
        // focusable widget, exactly as the public `focusNode` parameter's
        // contract invites.
        await pumpThemedApp(
          tester,
          Focus(
            focusNode: focusNode,
            child: const SizedBox(width: 10, height: 10),
          ),
        );
        focusNode.requestFocus();
        await tester.pumpAndSettle();
        expect(focusNode.hasFocus, isTrue);

        // Deliver a stepping key through the reused node. Before the fix,
        // this ran `_handleKeyEvent` on the defunct LayrzNumberInput state,
        // reading/writing its already-disposed TextEditingController.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(onChangedCallCount, 0);
      },
    );

    testWidgets(
      'keyboard stepping keeps working after didUpdateWidget swaps the focus node',
      (tester) async {
        final nodeA = FocusNode(debugLabel: 'node-a');
        final nodeB = FocusNode(debugLabel: 'node-b');
        addTearDown(nodeA.dispose);
        addTearDown(nodeB.dispose);
        num? lastValue;

        await pumpThemedApp(
          tester,
          LayrzNumberInput(
            focusNode: nodeA,
            value: 5,
            onChanged: (v) => lastValue = v,
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        expect(nodeA.hasFocus, isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        expect(lastValue, 6);

        // Swap to a different externally-owned focus node via
        // didUpdateWidget, keeping the field itself mounted.
        await pumpThemedApp(
          tester,
          LayrzNumberInput(
            focusNode: nodeB,
            value: lastValue,
            onChanged: (v) => lastValue = v,
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        expect(nodeB.hasFocus, isTrue);
        expect(nodeA.hasFocus, isFalse);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(lastValue, 7);
      },
    );

    testWidgets(
      'the ancestor Focus wrapper contributes no extra stop to Tab traversal',
      (tester) async {
        final before = FocusNode(debugLabel: 'before');
        final after = FocusNode(debugLabel: 'after');
        addTearDown(before.dispose);
        addTearDown(after.dispose);

        await pumpThemedApp(
          tester,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(focusNode: before, child: const SizedBox(width: 10, height: 10)),
              const LayrzNumberInput(value: 5),
              Focus(focusNode: after, child: const SizedBox(width: 10, height: 10)),
            ],
          ),
        );

        before.requestFocus();
        await tester.pumpAndSettle();
        expect(before.hasFocus, isTrue);

        // One Tab hop must land exactly on the field's own EditableText node
        // -- never on an intermediate node contributed by the ancestor Focus.
        before.nextFocus();
        await tester.pumpAndSettle();
        final editableTextState = tester.state<EditableTextState>(find.byType(EditableText));
        expect(editableTextState.widget.focusNode.hasFocus, isTrue);

        // The very next hop must reach `after` directly.
        editableTextState.widget.focusNode.nextFocus();
        await tester.pumpAndSettle();
        expect(after.hasFocus, isTrue);
      },
    );
  });
}
