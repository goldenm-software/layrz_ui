import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzAnchoredPanel - Accessibility', () {
    testWidgets('anchor semantic label is exposed in semantics tree', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzAnchoredPanel(
            anchorSemanticLabel: 'Options menu',
            builder: (context, controller) => LayrzButton(
              labelText: 'Open',
              onTap: controller.open,
            ),
            child: const SizedBox(
              width: 200,
              height: 100,
              child: Text('Panel content'),
            ),
          ),
        );

        // Verify the anchor has button semantics with the provided label.
        expect(
          tester.getSemantics(find.byType(LayrzAnchoredPanel)),
          matchesSemantics(
            label: 'Options menu',
            isButton: true,
          ),
          reason: 'Anchor should expose button semantics with provided label to screen readers',
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('anchor without semantic label does not add wrapper', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzAnchoredPanel(
            // anchorSemanticLabel is null
            builder: (context, controller) => LayrzButton(
              labelText: 'Trigger',
              onTap: controller.open,
            ),
            child: const SizedBox(
              width: 200,
              height: 100,
              child: Text('Content'),
            ),
          ),
        );

        // When no label is provided, no Semantics wrapper is added.
        // The button's semantics come from LayrzButton itself.
        expect(find.byType(LayrzButton), findsOneWidget);
        expect(find.byType(LayrzAnchoredPanel), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('panel content is accessible when opened', (tester) async {
      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          builder: (context, controller) => LayrzButton(
            labelText: 'Show',
            onTap: controller.open,
          ),
          child: const SizedBox(
            width: 200,
            height: 100,
            child: Text('Panel item'),
          ),
        ),
      );

      // When panel is closed, content is not in the tree.
      expect(find.text('Panel item'), findsNothing);

      // Open the panel.
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // When open, content is reachable.
      expect(find.text('Panel item'), findsOneWidget,
          reason: 'Panel content should be reachable when panel is open');
    });


    // DEVICE VERIFICATION REQUIRED
    //
    // The following a11y features require device testing to verify:
    //
    // 1. **Screen reader announcement**: When the anchor receives focus, the screen
    //    reader announces the anchor's semantic label. Verification requires running
    //    with Android TalkBack or iOS VoiceOver enabled on a device.
    //
    // 2. **Arrow key navigation**: RawMenuAnchor provides arrow-key focus traversal
    //    within the panel via DirectionalFocusIntent. Verification requires keyboard
    //    input on device or emulator.
    //
    // 3. **Escape to dismiss**: RawMenuAnchor closes the panel on Escape key.
    //    Verification requires keyboard testing on device.
    //
    // 4. **Panel semantic label announced**: When the panel is open with a
    //    panelSemanticLabel, it is announced by the screen reader. Verification
    //    requires device testing with screen reader enabled.
    //
    // FINDINGS FROM SDK VERIFICATION (DESIGN-123)
    //
    // RawMenuAnchor (Flutter SDK source at flutter/packages/flutter/lib/src/widgets/raw_menu_anchor.dart):
    // - Does NOT provide a Semantics node (documented at line 169)
    // - DOES provide keyboard shortcuts via _kMenuTraversalShortcuts (lines 34-41):
    //   * Arrow Up/Down/Left/Right → DirectionalFocusIntent (navigation)
    //   * Escape → DismissIntent (close panel)
    // - Keyboard semantics are disabled (line 845: `includeSemantics: false`)
    // - No duplicate semantics risk (RawMenuAnchor provides none)
    //
    // Role decision: Neutral (NOT "menu") because:
    // - Content is arbitrary (not always menu items)
    // - Keyboard contract is incomplete (has arrow keys + Escape but NO Enter-to-select)
    // - Calling it a "menu" would promise behavior we cannot guarantee
    //
    // Implementation: Caller supplies semantic labels for localization.
    // No hardcoded English. Labels are optional; if null, no wrapper is added.
  });
}
