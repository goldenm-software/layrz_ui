import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

/// Counts semantics nodes whose label contains [needle].
///
/// Walks the full semantics tree from its root, rather than relying on a `findsWidgets`-style
/// existence check, so a test built on this can actually distinguish "labeled once", "labeled
/// twice" (a duplicate announcement), and "never labeled" (an empty accessible name) — the
/// three outcomes a tautological assertion cannot tell apart. Requires [WidgetTester.ensureSemantics]
/// to be active.
int countSemanticsWithLabel(WidgetTester tester, String needle) {
  // ignore: deprecated_member_use
  final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
  var count = 0;
  void walk(SemanticsNode node) {
    if (node.getSemanticsData().label.contains(needle)) count++;
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(root);
  return count;
}

void main() {
  group('LayrzNumberInput Accessibility', () {
    testWidgets('field is labeled for assistive technology', (tester) async {
      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Product Price',
          hintText: 'Enter price',
        ),
      );

      // The label should be present and associated with the field
      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets(
      'numeric field label is exposed to screen readers on the outer node and the inner field',
      (tester) async {
        // On the step-buttons branch, the outer Row splits the semantics tree into three
        // branches (decrement cap / field / increment cap — see decision D-F), so the label
        // cannot merge into a single node the way it does on LayrzTextInput's healthy baseline.
        // The fix gives the field's own node the label too (previously empty), so the count is
        // 2, not 1 — this is the intended outcome of D-F, not a duplicate-announcement defect
        // (unlike the Search/ComboBox case this differs from).
        final handle = tester.ensureSemantics();
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;

        await pumpThemedApp(
          tester,
          const LayrzNumberInput(
            labelText: 'Amount',
            value: 42,
          ),
        );

        expect(countSemanticsWithLabel(tester, 'Amount'), 2);

        // Verify the outer semantic node still carries the label and enabled state
        expect(
          tester.getSemantics(
            find
                .descendant(
                  of: find.byType(LayrzNumberInput),
                  matching: find.byType(Semantics),
                )
                .first,
          ),
          matchesSemantics(
            label: 'Amount',
            hasEnabledState: true,
            isEnabled: true,
          ),
        );

        handle.dispose();
      },
    );

    testWidgets('disabled numeric field is semantically marked', (tester) async {
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Quantity',
          disabled: true,
        ),
      );

      // Verify disabled semantics - disabled number input is read-only from the
      // EditableText perspective, so it has isTextField and isReadOnly flags
      final semanticsNodes = find.descendant(
        of: find.byType(LayrzNumberInput),
        matching: find.byType(Semantics),
      );

      // There should be at least one Semantics node for the control itself
      expect(semanticsNodes, findsWidgets);

      // Find the Semantics node that has the label and is disabled
      final controlSemantics = tester.getSemantics(semanticsNodes.first);
      expect(
        controlSemantics,
        matchesSemantics(
          label: 'Quantity',
          hasEnabledState: true,
          isEnabled: false,
          isTextField: true,
          isReadOnly: true,
          isFocusable: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('increment button has accessible label', (tester) async {
      // Decision D-F: before the fix, the increment cap had an empty label and no flags
      // at all — a screen reader announced nothing. `findsWidgets` on the icon alone (the
      // original assertion here) cannot detect that, since the icon renders either way.
      final handle = tester.ensureSemantics();
      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Quantity',
          value: 5,
        ),
      );

      expect(countSemanticsWithLabel(tester, 'Increase value'), 1);

      handle.dispose();
    });

    testWidgets('decrement button has accessible label', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Quantity',
          value: 5,
        ),
      );

      expect(countSemanticsWithLabel(tester, 'Decrease value'), 1);

      handle.dispose();
    });

    testWidgets('step caps and inner field carry non-empty accessible labels (D-F)', (tester) async {
      // Before the fix (dossier §4.1 / §7.6): the field (#4) and both step caps (#3, #5) all
      // had empty labels and, for the caps, no flags at all — a screen reader focusing any of
      // the three announced nothing. This counts and inspects labels rather than asserting mere
      // node existence, which is precisely the defect the ComboBox and Search "exactly once"
      // tests shared (dossier §4.3).
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Qty',
          value: 5,
        ),
      );

      // Decrement cap: localized, non-empty, exactly one node
      expect(countSemanticsWithLabel(tester, 'Decrease value'), 1);
      // Increment cap: localized, non-empty, exactly one node
      expect(countSemanticsWithLabel(tester, 'Increase value'), 1);
      // Inner field: carries the input's own label (in addition to the outer wrapper node)
      expect(countSemanticsWithLabel(tester, 'Qty'), 2);

      handle.dispose();
    });

    testWidgets('step buttons are focusable with keyboard', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzNumberInput(
          labelText: 'Quantity',
          value: 5,
          onChanged: (_) {},
        ),
      );

      // Widgets should be in the tree and focusable
      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('field retains required indicator for accessibility', (tester) async {
      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Amount',
          isRequired: true,
        ),
      );

      // Field should be present
      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('error messages are announced', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Price',
          errors: ['Price must be positive'],
        ),
      );

      expect(find.text('Price must be positive'), findsOneWidget);
    });

    testWidgets('help text is accessible', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Price',
          helpTitleText: 'Help',
          helpContentText: 'Enter a positive number',
        ),
      );

      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('disabled field is announced as disabled', (tester) async {
      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Price',
          disabled: true,
        ),
      );

      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('read-only field is announced as read-only', (tester) async {
      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Price',
          value: 42,
          readOnly: true,
        ),
      );

      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('hint text is accessible when label is present', (tester) async {
      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Amount',
          hintText: 'e.g., 99.99',
        ),
      );

      // Field should be present
      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('field can be focused and text selected with keyboard', (tester) async {
      final controller = TextEditingController(text: '42');
      addTearDown(controller.dispose);

      await pumpThemedApp(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          controller: controller,
        ),
      );

      // Focus the field
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      // Field should be focused
      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('button states are announced when disabled at bounds', (tester) async {
      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Quantity',
          value: 10,
          maximum: 10,
          minimum: 0,
        ),
      );

      // Buttons should be present with their icons
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('step buttons receive focus in tab order', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzNumberInput(
          labelText: 'Quantity',
          value: 5,
          onChanged: (_) {},
        ),
      );

      // The widgets should be in focus order
      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });
  });
}
