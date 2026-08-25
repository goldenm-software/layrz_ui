import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/number/number_field_edge.dart';

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
///
/// This file also covers the ownership of the `_controller` listener added for
/// DESIGN-150 (the step-cap staleness fix): it must move across all four
/// controller-ownership transitions in `didUpdateWidget`, exactly as the
/// [FocusNode]-facing key handler above does, and must never be left attached
/// to a controller this [State] no longer tracks after a swap or an unmount.
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

  group('LayrzNumberInput controller-value listener lifecycle (DESIGN-150)', () {
    // The sharp, non-vacuous test for a leaked listener: swap or unmount, then write to
    // the controller that should no longer be listened to, and assert no exception. A
    // leaked listener calls `setState` on a defunct [State]; `ChangeNotifier.notifyListeners`
    // reports that through `FlutterError.onError`, so it surfaces via
    // `tester.takeException()` after the pump. A leaked listener on a still-mounted state is
    // merely a redundant rebuild and is not observable -- which is why the unmount step is
    // required in every one of these tests, not decorative.

    testWidgets(
      'controller null -> external: the listener moves onto the caller\'s controller and the '
      'internal one is disposed',
      (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzNumberInput(value: 5, minimum: 0, maximum: 10),
        );

        final internal = tester.widget<EditableText>(find.byType(EditableText)).controller;

        final external = TextEditingController(text: '5');
        addTearDown(external.dispose);

        await pumpThemedApp(
          tester,
          LayrzNumberInput(value: 5, minimum: 0, maximum: 10, controller: external),
        );

        external.text = '10';
        await tester.pump();

        expect(
          tester.widget<NumberFieldControl>(find.byType(NumberFieldControl).last).isDisabled,
          isTrue,
          reason: 'the listener must now be driven by the caller\'s controller',
        );

        // The controller the widget owned before the swap must have been disposed, not
        // merely abandoned. A disposed ChangeNotifier throws on addListener -- the only
        // black-box way to observe this from outside the widget.
        expect(() => internal.addListener(() {}), throwsA(isA<FlutterError>()));
      },
    );

    testWidgets(
      'controller external -> null: nothing is left attached to the caller\'s controller after unmount',
      (tester) async {
        final first = TextEditingController(text: '5');
        addTearDown(first.dispose);

        await pumpThemedApp(
          tester,
          LayrzNumberInput(value: 5, minimum: 0, maximum: 10, controller: first),
        );

        await pumpThemedApp(
          tester,
          const LayrzNumberInput(value: 5, minimum: 0, maximum: 10),
        );

        await pumpThemedApp(tester, const SizedBox.shrink());

        first.text = '10';
        await tester.pump();

        expect(tester.takeException(), isNull);
        // `first` was never owned by the widget (it was externally supplied throughout),
        // so it must never have been disposed either.
        expect(() => first.addListener(() {}), returnsNormally);
      },
    );

    testWidgets(
      'controller external -> a different external: the listener moves on, then off, and '
      'neither controller is disposed',
      (tester) async {
        final first = TextEditingController(text: '5');
        final second = TextEditingController(text: '5');
        addTearDown(first.dispose);
        addTearDown(second.dispose);

        await pumpThemedApp(
          tester,
          LayrzNumberInput(value: 5, minimum: 0, maximum: 10, controller: first),
        );

        await pumpThemedApp(
          tester,
          LayrzNumberInput(value: 5, minimum: 0, maximum: 10, controller: second),
        );

        second.text = '10';
        await tester.pump();

        expect(
          tester.widget<NumberFieldControl>(find.byType(NumberFieldControl).last).isDisabled,
          isTrue,
          reason: 'the listener must have moved onto `second`',
        );

        await pumpThemedApp(tester, const SizedBox.shrink());

        first.text = '10';
        await tester.pump();

        expect(tester.takeException(), isNull, reason: 'the listener must have come off `first` on the swap');
        expect(() => first.addListener(() {}), returnsNormally);
        expect(() => second.addListener(() {}), returnsNormally);
      },
    );

    testWidgets(
      'plain disposal with an external controller leaves no listener behind',
      (tester) async {
        final external = TextEditingController(text: '5');
        addTearDown(external.dispose);

        await pumpThemedApp(
          tester,
          LayrzNumberInput(value: 5, minimum: 0, maximum: 10, controller: external),
        );

        await pumpThemedApp(tester, const SizedBox.shrink());

        external.text = '10';
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(() => external.addListener(() {}), returnsNormally);
      },
    );

    testWidgets(
      'controller swap does not leave the disabled-state comparison basis describing the '
      'outgoing controller (L5)',
      (tester) async {
        // The naive form of this test -- swap, then assert the render right after the swap
        // -- proves nothing: `didUpdateWidget` always forces a rebuild, and `build()`
        // recomputes both predicates fresh on every call and passes them straight into
        // `NumberFieldControl`, regardless of how (or whether) any cache is maintained. So
        // that first assertion below passes under a correct implementation AND under a
        // broken one -- it is here only as a sanity check, not the proof.
        //
        // The proof is the second step: `value` stays constant across the swap (so the
        // pre-existing, out-of-scope re-seed gap at didUpdateWidget's value block never
        // fires -- see the class-level doc comment), `second` starts already at `maximum`,
        // and only a write to `second` *after* the swap can flip the cap back to enabled.
        // A comparison basis that was refreshed only by the listener itself (mirroring
        // `_wasEmpty` in LayrzSearchInput verbatim, with no swap-time reseed) would still be
        // holding `first`'s pre-swap reading (not at the bound) when this write arrives.
        // Comparing the new, correct reading (`false`) against that stale basis (also
        // `false`, coincidentally) finds no flip, skips `setState`, and the cap is left
        // showing the wrong, stale-disabled state even though the widget already knows
        // better. The fix in this file computes and stores the comparison basis directly in
        // `build()` instead, so it is never anything other than what the most recent build
        // actually rendered -- see `_lastDecrementDisabled`/`_lastIncrementDisabled` in
        // number_input.dart.
        final first = TextEditingController(text: '5');
        final second = TextEditingController(text: '10');
        addTearDown(first.dispose);
        addTearDown(second.dispose);

        await pumpThemedApp(
          tester,
          LayrzNumberInput(value: 5, minimum: 0, maximum: 10, controller: first),
        );

        await pumpThemedApp(
          tester,
          LayrzNumberInput(value: 5, minimum: 0, maximum: 10, controller: second),
        );

        expect(
          tester.widget<NumberFieldControl>(find.byType(NumberFieldControl).last).isDisabled,
          isTrue,
          reason: 'sanity check only -- true under any implementation, correct or broken',
        );

        second.text = '9';
        await tester.pump();

        expect(
          tester.widget<NumberFieldControl>(find.byType(NumberFieldControl).last).isDisabled,
          isFalse,
          reason:
              'a comparison basis still describing `first`\'s pre-swap reading would '
              'wrongly suppress this rebuild',
        );
      },
    );
  });
}
