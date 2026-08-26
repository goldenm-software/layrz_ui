import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

/// Controller-ownership regression coverage for [LayrzSearchInput]
/// (DESIGN-142, finding 2).
///
/// `_controller` used to be `late final`, with no handling at all for the
/// controller identity changing in `didUpdateWidget`. A caller rebuilding
/// from `controller: null` to a real, externally-owned instance therefore
/// kept the widget silently wired to its own internally-created controller
/// -- ignoring the caller's -- and `dispose` then declined to dispose the
/// internal one (since `widget.controller` was non-null by that point),
/// leaking it.
///
/// The fix mirrors [LayrzComboBoxInput]'s reference handling of all four
/// controller-ownership transitions in `didUpdateWidget`.
void main() {
  group('LayrzSearchInput controller ownership', () {
    testWidgets(
      'controller null -> external: the widget switches to the new controller and '
      'disposes the one it created internally',
      (tester) async {
        final external = TextEditingController(text: 'from external');
        addTearDown(external.dispose);

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(mode: LayrzSearchInputMode.field),
        );

        // Capture the controller the widget wired up on its own -- there is
        // no public accessor for the private `_controller` field, so this is
        // read back the same way any consumer would: via the EditableText
        // it ultimately configures.
        final internal = tester.widget<EditableText>(find.byType(EditableText)).controller;
        expect(internal, isNot(same(external)));

        await pumpThemedApp(
          tester,
          LayrzSearchInput(mode: LayrzSearchInputMode.field, controller: external),
        );

        final wired = tester.widget<EditableText>(find.byType(EditableText)).controller;
        expect(wired, same(external), reason: 'the field must now be driven by the caller\'s controller');
        expect(find.text('from external'), findsOneWidget);

        // The controller the widget owned before the swap must have been
        // disposed rather than kept alive unreferenced. A disposed
        // ChangeNotifier throws on addListener -- this is the only
        // black-box way to observe the leak from outside the widget.
        expect(
          () => internal.addListener(() {}),
          throwsA(isA<FlutterError>()),
        );
      },
    );

    testWidgets(
      'controller external -> null: the caller\'s controller is never disposed',
      (tester) async {
        final external = TextEditingController(text: 'kept alive');
        addTearDown(external.dispose);

        await pumpThemedApp(
          tester,
          LayrzSearchInput(mode: LayrzSearchInputMode.field, controller: external),
        );

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(mode: LayrzSearchInputMode.field),
        );

        final wired = tester.widget<EditableText>(find.byType(EditableText)).controller;
        expect(wired, isNot(same(external)));

        // Must still be usable -- proves the widget did not dispose the
        // controller it no longer owns once ownership reverted to it.
        expect(() => external.addListener(() {}), returnsNormally);
      },
    );

    testWidgets(
      'controller external -> a different external: only the listener moves, neither instance is disposed',
      (tester) async {
        final first = TextEditingController(text: 'first');
        final second = TextEditingController(text: 'second');
        addTearDown(first.dispose);
        addTearDown(second.dispose);

        await pumpThemedApp(
          tester,
          LayrzSearchInput(mode: LayrzSearchInputMode.field, controller: first),
        );

        await pumpThemedApp(
          tester,
          LayrzSearchInput(mode: LayrzSearchInputMode.field, controller: second),
        );

        final wired = tester.widget<EditableText>(find.byType(EditableText)).controller;
        expect(wired, same(second));
        expect(find.text('second'), findsOneWidget);
        expect(() => first.addListener(() {}), returnsNormally);
      },
    );
  });

  group('LayrzSearchInput focus node ownership', () {
    // `_focusNode` had the identical gap as `_controller` above: it was
    // `late final`, with no swap handling in `didUpdateWidget` at all, so a
    // caller rebuilding from `focusNode: null` to a real instance kept the
    // widget silently wired to its own internally-created node -- ignoring
    // the caller's -- and `dispose` then declined to dispose the internal
    // one, leaking it. Fixed the same way, mirroring
    // [LayrzComboBoxInput]'s ownership handling (minus the listener
    // move/reattach: this state never attaches its own listener to
    // `_focusNode`, so there is nothing to detach here).
    testWidgets(
      'focusNode null -> external: the widget switches to the new node and '
      'disposes the one it created internally',
      (tester) async {
        final external = FocusNode(debugLabel: 'external');
        addTearDown(external.dispose);

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(mode: LayrzSearchInputMode.field),
        );

        // Capture the node the widget wired up on its own -- there is no
        // public accessor for the private `_focusNode` field, so this is
        // read back the same way any consumer would: via the EditableText
        // it ultimately configures.
        final internal = tester.widget<EditableText>(find.byType(EditableText)).focusNode;
        expect(internal, isNot(same(external)));

        await pumpThemedApp(
          tester,
          LayrzSearchInput(mode: LayrzSearchInputMode.field, focusNode: external),
        );

        final wired = tester.widget<EditableText>(find.byType(EditableText)).focusNode;
        expect(wired, same(external), reason: 'the field must now be driven by the caller\'s focus node');

        external.requestFocus();
        await tester.pumpAndSettle();
        expect(external.hasFocus, isTrue);

        // The node the widget owned before the swap must have been disposed
        // rather than kept alive unreferenced. A disposed ChangeNotifier
        // throws on addListener -- this is the only black-box way to
        // observe the leak from outside the widget.
        expect(
          () => internal.addListener(() {}),
          throwsA(isA<FlutterError>()),
        );
      },
    );

    testWidgets(
      'focusNode external -> null: the caller\'s node is never disposed',
      (tester) async {
        final external = FocusNode(debugLabel: 'kept-alive');
        addTearDown(external.dispose);

        await pumpThemedApp(
          tester,
          LayrzSearchInput(mode: LayrzSearchInputMode.field, focusNode: external),
        );

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(mode: LayrzSearchInputMode.field),
        );

        final wired = tester.widget<EditableText>(find.byType(EditableText)).focusNode;
        expect(wired, isNot(same(external)));

        // Must still be usable -- proves the widget did not dispose the
        // node it no longer owns once ownership reverted to it.
        expect(() => external.addListener(() {}), returnsNormally);
      },
    );

    testWidgets(
      'focusNode external -> a different external: neither instance is disposed',
      (tester) async {
        final first = FocusNode(debugLabel: 'first');
        final second = FocusNode(debugLabel: 'second');
        addTearDown(first.dispose);
        addTearDown(second.dispose);

        await pumpThemedApp(
          tester,
          LayrzSearchInput(mode: LayrzSearchInputMode.field, focusNode: first),
        );

        await pumpThemedApp(
          tester,
          LayrzSearchInput(mode: LayrzSearchInputMode.field, focusNode: second),
        );

        final wired = tester.widget<EditableText>(find.byType(EditableText)).focusNode;
        expect(wired, same(second));
        expect(() => first.addListener(() {}), returnsNormally);
      },
    );
  });
}
