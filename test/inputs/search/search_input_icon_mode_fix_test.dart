import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/pump_themed_app.dart';

/// Regression coverage for four defects reported against [LayrzSearchInput]'s
/// icon mode after Linux desktop device testing:
///
/// 1. The panel border double-rounded-rectangle visual bug, and the
///    requirement that focused/error states remain visually distinct once
///    the chrome's own border is suppressed.
/// 2. Focus does not land on the field when the panel opens.
/// 3. Clearing the search does not (re)focus the field.
/// 4. Icon mode never renders a hint.
void main() {
  group('LayrzSearchInput icon mode fixes', () {
    testWidgets('focus lands on the field after the panel opens', (
      tester,
    ) async {
      final focusNode = FocusNode(debugLabel: 'search-field');
      addTearDown(focusNode.dispose);

      await pumpThemedApp(
        tester,
        LayrzSearchInput(mode: LayrzSearchInputMode.icon, focusNode: focusNode),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(
        focusNode.hasFocus,
        isTrue,
        reason: 'the field focus node should hold focus once the panel finishes opening',
      );
    });

    testWidgets('icon mode field shows the hint text', (tester) async {
      await pumpThemedApp(
        tester,
        const LayrzSearchInput(
          mode: LayrzSearchInputMode.icon,
          hintText: 'Search records',
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      final chrome = tester.widget<LayrzInputChrome>(
        find.byType(LayrzInputChrome),
      );
      expect(chrome.hintText, equals('Search records'));
      expect(find.text('Search records'), findsOneWidget);
    });

    testWidgets(
      'clearing in field mode (re)focuses the field even if it was unfocused',
      (tester) async {
        final focusNode = FocusNode(debugLabel: 'search-field');
        addTearDown(focusNode.dispose);
        final controller = TextEditingController(text: 'flutter');
        addTearDown(controller.dispose);

        await pumpThemedApp(
          tester,
          LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            controller: controller,
            focusNode: focusNode,
          ),
        );

        expect(focusNode.hasFocus, isFalse);

        await tester.tap(find.byIcon(MdiIcons.close));
        await tester.pumpAndSettle();

        expect(
          focusNode.hasFocus,
          isTrue,
          reason: 'clearing should focus the field so the user can keep typing',
        );
      },
    );

    testWidgets(
      'clearing in icon mode returns focus to the field after it was lost',
      (tester) async {
        final focusNode = FocusNode(debugLabel: 'search-field');
        addTearDown(focusNode.dispose);
        final controller = TextEditingController(text: 'flutter');
        addTearDown(controller.dispose);

        await pumpThemedApp(
          tester,
          LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
            controller: controller,
            focusNode: focusNode,
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        // Explicitly drop focus to simulate it having been lost.
        focusNode.unfocus();
        await tester.pumpAndSettle();
        expect(focusNode.hasFocus, isFalse);

        await tester.tap(find.byIcon(MdiIcons.close));
        await tester.pumpAndSettle();

        expect(
          focusNode.hasFocus,
          isTrue,
          reason: 'clearing should return focus to the panel field',
        );
      },
    );

    testWidgets(
      'focused state is visually distinct from resting state without a competing border',
      (tester) async {
        final focusNode = FocusNode(debugLabel: 'search-field');
        addTearDown(focusNode.dispose);

        await pumpThemedApp(
          tester,
          LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
            focusNode: focusNode,
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        // The chrome itself must not draw its own border in icon mode -- the panel
        // is the single visual container.
        final chrome = tester.widget<LayrzInputChrome>(
          find.byType(LayrzInputChrome),
        );
        expect(chrome.showBorder, isFalse);

        // Focus landed automatically (see the dedicated test above); the field
        // is focused right now. The panel itself -- not a hand-rolled wrapper
        // Container inside its scroll view -- must carry a visible focus
        // indicator distinct from the resting state. Since the elevate-overlay
        // redesign (DESIGN-145), that indicator is `LayrzAnchoredPanel.border`,
        // painted by the panel around its own capped viewport.
        expect(focusNode.hasFocus, isTrue);

        final panel = tester.widget<LayrzAnchoredPanel>(
          find.byType(LayrzAnchoredPanel),
        );
        expect(
          panel.border,
          isNotNull,
          reason: 'the focused state must remain visually distinct via the panel border',
        );

        // Now blur the field: the ring must disappear again (resting state).
        focusNode.unfocus();
        await tester.pumpAndSettle();

        final restingPanel = tester.widget<LayrzAnchoredPanel>(
          find.byType(LayrzAnchoredPanel),
        );
        expect(
          restingPanel.border,
          isNull,
          reason: 'resting state must not draw a panel border',
        );
      },
    );

    testWidgets(
      'error state remains visually distinct without a competing border',
      (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
            errors: ['Something went wrong'],
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        final panel = tester.widget<LayrzAnchoredPanel>(
          find.byType(LayrzAnchoredPanel),
        );
        expect(
          panel.border,
          isNotNull,
          reason: 'the error state must remain visually distinct via the panel border',
        );
      },
    );
  });
}
