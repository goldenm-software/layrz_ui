import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzRadioInput — Accessibility', () {
    testWidgets('group label renders', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          labelText: 'Choose a department',
          items: [
            const LayrzSelectItem(value: 'sales', child: Text('Sales'), searchableStrings: {'Sales'}),
            const LayrzSelectItem(value: 'eng', child: Text('Engineering'), searchableStrings: {'Engineering'}),
          ],
        ),
      );

      expect(find.text('Choose a department'), findsOneWidget);
    });

    testWidgets('group announces label in semantics', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await pumpThemed(
          tester,
          LayrzRadioInput<String>(
            labelText: 'Department',
            items: [
              const LayrzSelectItem(value: 'sales', child: Text('Sales'), searchableStrings: {'Sales'}),
              const LayrzSelectItem(value: 'eng', child: Text('Engineering'), searchableStrings: {'Engineering'}),
            ],
          ),
        );

        // The group's label should be present in the semantic tree.
        expect(find.text('Department'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('option labels render for accessibility', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(value: 'marketing', child: Text('Marketing'), searchableStrings: {'Marketing'}),
            const LayrzSelectItem(value: 'sales', child: Text('Sales'), searchableStrings: {'Sales'}),
          ],
        ),
      );

      expect(find.text('Marketing'), findsOneWidget);
      expect(find.text('Sales'), findsOneWidget);
    });

    testWidgets('each option announces its role and checked state', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await pumpThemed(
          tester,
          LayrzRadioInput<String>(
            items: [
              const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
              const LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
            ],
          ),
        );

        // RawRadio widgets emit semantics with radio button properties.
        // Verify both options expose radio button semantics (hasCheckedState, inMutuallyExclusiveGroup).
        final radioFinder = find.byWidgetPredicate((w) => w is RawRadio);
        expect(radioFinder, findsWidgets);

        // First option should expose hasCheckedState and be in a mutually exclusive group
        expect(
          tester.getSemantics(radioFinder.at(0)),
          matchesSemantics(
            hasCheckedState: true,
            isChecked: false,
            hasEnabledState: true,
            isEnabled: true,
            isInMutuallyExclusiveGroup: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );

        // Second option should also expose the same semantics
        expect(
          tester.getSemantics(radioFinder.at(1)),
          matchesSemantics(
            hasCheckedState: true,
            isChecked: false,
            hasEnabledState: true,
            isEnabled: true,
            isInMutuallyExclusiveGroup: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('label and radio form one semantics node', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await pumpThemed(
          tester,
          LayrzRadioInput<String>(
            items: [
              const LayrzSelectItem(
                value: 'unified',
                child: Text('Unified Label'),
                searchableStrings: {'Unified Label'},
              ),
            ],
          ),
        );

        // The label and radio should be merged into one semantics node via the Semantics
        // wrapper. BREAKING (DESIGN-142): the outer `Semantics` no longer sets an explicit
        // `label` -- `child`'s own semantics (a plain `Text`, here) merge upward into it
        // instead, producing the same single-node result without a separate label string.
        final radioFinder = find.byWidgetPredicate((w) => w is RawRadio);
        expect(radioFinder, findsOneWidget);

        // The semantics node should include the label and be in a mutually exclusive group
        expect(
          tester.getSemantics(radioFinder),
          matchesSemantics(
            hasCheckedState: true,
            isChecked: false,
            isInMutuallyExclusiveGroup: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );

        // Verify the label text renders
        expect(find.text('Unified Label'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('enabled state renders with clickable options', (tester) async {
      String? selectedValue;

      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
          ],
          disabled: false,
          onChanged: (value) {
            selectedValue = value;
          },
        ),
      );

      await tester.tap(find.text('Option A'));
      await tester.pump();

      expect(selectedValue, 'a');
    });

    testWidgets('disabled state prevents selection', (tester) async {
      String? selectedValue;

      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          items: [
            const LayrzSelectItem(
              value: 'disabled',
              child: Text('Disabled Option'),
              searchableStrings: {'Disabled Option'},
            ),
          ],
          disabled: true,
          onChanged: (value) {
            selectedValue = value;
          },
        ),
      );

      await tester.tap(find.text('Disabled Option'));
      await tester.pump();

      expect(selectedValue, isNull);
    });

    testWidgets('required asterisk is perceivable by screen reader', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await pumpThemed(
          tester,
          LayrzRadioInput<String>(
            labelText: 'Choose',
            isRequired: true,
            items: [
              const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
            ],
          ),
        );

        expect(find.text('*'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('error text is perceivable by screen reader', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        const errorText = 'This field is required';

        await pumpThemed(
          tester,
          LayrzRadioInput<String>(
            items: [
              const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
            ],
            errors: [errorText],
          ),
        );

        expect(find.text(errorText), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('radio widgets render with built-in keyboard support', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await pumpThemed(
          tester,
          LayrzRadioInput<String>(
            items: [
              const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
              const LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
            ],
          ),
        );

        // Verify both options expose keyboard-accessible semantics
        final radioFinder = find.byWidgetPredicate((w) => w is RawRadio);
        expect(radioFinder, findsWidgets);

        // Both options should be focusable and have tap actions (keyboard-accessible)
        expect(
          tester.getSemantics(radioFinder.at(0)),
          matchesSemantics(
            hasCheckedState: true,
            isChecked: false,
            hasEnabledState: true,
            isEnabled: true,
            isInMutuallyExclusiveGroup: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );

        expect(
          tester.getSemantics(radioFinder.at(1)),
          matchesSemantics(
            hasCheckedState: true,
            isChecked: false,
            hasEnabledState: true,
            isEnabled: true,
            isInMutuallyExclusiveGroup: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );

        expect(find.text('Option A'), findsOneWidget);
        expect(find.text('Option B'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('selection state is exposed to semantics, not colour alone', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await pumpThemed(
          tester,
          LayrzRadioInput<String>(
            value: 'a',
            items: const [
              LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
              LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
            ],
          ),
        );

        // RawRadio exposes checked/unchecked state via semantics flags, not through colour alone.
        // This satisfies WCAG 1.4.1: information must not be conveyed by colour alone.
        final radioFinder = find.byWidgetPredicate((w) => w is RawRadio);
        expect(radioFinder, findsWidgets);

        // Verify the two options are in the semantics tree with their labels.
        expect(find.text('Option A'), findsOneWidget);
        expect(find.text('Option B'), findsOneWidget);

        // Verify the RawRadio widgets expose checked state via semantics.
        // The first radio (Option A, value='a') is selected.
        expect(
          tester.getSemantics(find.byWidgetPredicate((w) => w is RawRadio).at(0)),
          matchesSemantics(
            hasCheckedState: true,
            isChecked: true,
            hasEnabledState: true,
            isEnabled: true,
            isInMutuallyExclusiveGroup: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );

        // The second radio (Option B, value='b') is unselected.
        expect(
          tester.getSemantics(find.byWidgetPredicate((w) => w is RawRadio).at(1)),
          matchesSemantics(
            hasCheckedState: true,
            isChecked: false,
            hasEnabledState: true,
            isEnabled: true,
            isInMutuallyExclusiveGroup: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('selection visually indicated by filled radio', (tester) async {
      await pumpThemed(
        tester,
        LayrzRadioInput<String>(
          value: 'a',
          items: [
            const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
            const LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
          ],
        ),
      );

      // RadioGroup + RawRadio handle visual indication internally
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
    });

    testWidgets('option label is announced once, not twice', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await pumpThemed(
          tester,
          LayrzRadioInput<String>(
            items: const [
              LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
            ],
          ),
        );

        // Count semantics nodes that carry the label 'Option A'.
        // BREAKING (DESIGN-142): there is no separate `labelText` string anymore -- the
        // outer `Semantics` sets no explicit `label`, and `child` (here a plain `Text`) is
        // left un-excluded so its own semantics merge upward into that same node, rather
        // than contributing a second, sibling node. The label should still appear exactly
        // once in the semantics tree.
        // ignore: deprecated_member_use
        final semanticsOwner = tester.binding.pipelineOwner.semanticsOwner;
        expect(semanticsOwner, isNotNull);

        final rootNode = semanticsOwner!.rootSemanticsNode;
        expect(rootNode, isNotNull);

        int labelCount = 0;
        void countLabels(dynamic node) {
          if (node.label == 'Option A') {
            labelCount++;
          }
          node.visitChildren((child) {
            countLabels(child);
            return true;
          });
        }

        countLabels(rootNode!);

        // Merged into one node rather than two siblings -- announced only once.
        expect(
          labelCount,
          equals(1),
          reason: 'Label "Option A" should be announced exactly once in semantics tree',
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('in mutually exclusive group announced correctly', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await pumpThemed(
          tester,
          LayrzRadioInput<String>(
            items: const [
              LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
              LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
            ],
          ),
        );

        // Each radio should be marked as in a mutually exclusive group
        // Check the RawRadio's semantics node, which has the merged semantics from its parent Semantics widget
        expect(
          tester.getSemantics(find.byWidgetPredicate((w) => w is RawRadio).at(0)),
          matchesSemantics(
            hasCheckedState: true,
            isChecked: false,
            hasEnabledState: true,
            isEnabled: true,
            isInMutuallyExclusiveGroup: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );

        expect(
          tester.getSemantics(find.byWidgetPredicate((w) => w is RawRadio).at(1)),
          matchesSemantics(
            hasCheckedState: true,
            isChecked: false,
            hasEnabledState: true,
            isEnabled: true,
            isInMutuallyExclusiveGroup: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('disabled option reports not-enabled', (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await pumpThemed(
          tester,
          LayrzRadioInput<String>(
            disabled: true,
            items: const [
              LayrzSelectItem(
                value: 'disabled',
                child: Text('Disabled Option'),
                searchableStrings: {'Disabled Option'},
              ),
            ],
          ),
        );

        // The disabled radio should report isEnabled: false
        // Check the RawRadio's semantics node, which has the merged semantics from its parent Semantics widget
        expect(
          tester.getSemantics(find.byWidgetPredicate((w) => w is RawRadio)),
          matchesSemantics(
            hasCheckedState: true,
            isChecked: false,
            hasEnabledState: true,
            isEnabled: false,
            isInMutuallyExclusiveGroup: true,
            isFocusable: false,
          ),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
