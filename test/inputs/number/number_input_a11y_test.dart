import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

/// Returns the semantics nodes whose label contains [needle], walking the full tree.
///
/// Unlike [countSemanticsWithLabel], this hands back the matched node itself, so a caller
/// can inspect e.g. [SemanticsNode.childrenCount] to confirm *which* node in the tree owns
/// the label — a plain occurrence count cannot distinguish a label sitting on its own leaf
/// node from the same label having been absorbed into an unrelated grouping node, and a
/// test asserting only the count would stay green either way.
List<SemanticsNode> findSemanticsWithLabel(WidgetTester tester, String needle) {
  // ignore: deprecated_member_use
  final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
  final matches = <SemanticsNode>[];
  void walk(SemanticsNode node) {
    if (node.getSemanticsData().label.contains(needle)) matches.add(node);
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(root);
  return matches;
}

void main() {
  group('LayrzNumberInput Accessibility', () {
    testWidgets('plain-chrome field exposes label, text-field role and enabled state on one node', (tester) async {
      // Phase 0 dump 5 (`hideStepButtons: true`, not disabled) pinned Branch A's flag set:
      //   flags: isTextField, hasEnabledState, isEnabled, isFocusable
      // The flag set does not depend on whether hintText is set — only on disabled/read-only
      // state (compare dump 2, the same branch with `disabled: true`, which trades
      // isEnabled for isReadOnly). The hint-merge shape itself is pinned separately by
      // the "hint text is exposed…" test below.
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzNumberInput(labelText: 'Amount', value: 42, hideStepButtons: true),
        );

        // Guards against a re-introduced duplicate label — the exact regression DESIGN-142
        // fixed — which a single-node flag assertion below cannot detect on its own.
        expect(countSemanticsWithLabel(tester, 'Amount'), 1);
        expect(
          tester.getSemantics(find.byType(EditableText)),
          matchesSemantics(
            label: 'Amount',
            isTextField: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('disabled field is announced disabled and read-only', (tester) async {
      // dump 2 (labelText + disabled: true, Branch A): the single merged node carries
      // isTextField, hasEnabledState, isReadOnly, isFocusable, and drops isEnabled
      // (i.e. isEnabled: false) — `disabled` forces Branch A regardless of
      // hideStepButtons (number_input.dart:511). Absorbs the former "disabled field is
      // announced as disabled" test, which asserted only widget existence.
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzNumberInput(labelText: 'Quantity', disabled: true),
        );

        final semanticsNodes = find.descendant(
          of: find.byType(LayrzNumberInput),
          matching: find.byType(Semantics),
        );
        expect(semanticsNodes, findsWidgets);

        // Guards against a re-introduced duplicate label — the exact regression DESIGN-142
        // fixed — which a single-node flag assertion below cannot detect on its own.
        expect(countSemanticsWithLabel(tester, 'Quantity'), 1);
        expect(
          tester.getSemantics(semanticsNodes.first),
          matchesSemantics(
            label: 'Quantity',
            hasEnabledState: true,
            isEnabled: false,
            isTextField: true,
            isReadOnly: true,
            isFocusable: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets(
      "numeric field label is exposed to screen readers on the field's own node, exactly once",
      (tester) async {
        // On the step-buttons branch, the outer Row splits the semantics tree into three
        // separately focusable/actionable children (decrement cap / field / increment cap
        // — see decision D-F). That outer node has no actions and is not itself focusable
        // ([enabled, hasEnabledState] only) — it is a pure grouping node the user never
        // lands on — so it must stay unlabelled: a label there would be announced once for
        // a node the user cannot act on, then announced again once focus reaches the field.
        //
        // dump 1 (labelText: 'Amount', value: 42, Branch B) confirms the field's own node:
        //   flags: isTextField, hasEnabledState, isEnabled, isFocusable
        //   label: "Amount", value: "42"
        // and both caps keep their own distinct labels, unaffected by the outer group
        // staying unlabelled.
        //
        // This is the opposite of LayrzComboBoxInput, whose outer node keeps the label:
        // ComboBox's outer node IS the focusable, actionable control ([button, focusable],
        // actions=[tap, focus]) — the trigger the user actually lands on — so the label
        // belongs there, and its inner (read-only) text field correctly carries `label: ""`.
        // Same principle both times: the label lives on the one node the user focuses;
        // Number's and ComboBox's outer nodes just aren't the same kind of node.
        final handle = tester.ensureSemantics();
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;

        try {
          await pumpThemedApp(
            tester,
            const LayrzNumberInput(
              labelText: 'Amount',
              value: 42,
            ),
          );

          expect(countSemanticsWithLabel(tester, 'Amount'), 1);

          // The label lives on the field's own (focusable) node, not the outer group.
          expect(
            tester.getSemantics(find.byType(EditableText)),
            matchesSemantics(
              label: 'Amount',
              isTextField: true,
              hasEnabledState: true,
              isEnabled: true,
              isFocusable: true,
            ),
          );

          // The step caps must keep their own distinct labels, unaffected by the outer
          // group losing its label — proves the fix removed one line, not a cap's node.
          expect(countSemanticsWithLabel(tester, 'Decrease value'), 1);
          expect(countSemanticsWithLabel(tester, 'Increase value'), 1);
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets('step caps expose localized labels exactly once', (tester) async {
      // dump 1: both caps carry their localized labels on exactly one node each.
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzNumberInput(labelText: 'Qty', value: 5),
        );

        expect(countSemanticsWithLabel(tester, 'Decrease value'), 1);
        expect(countSemanticsWithLabel(tester, 'Increase value'), 1);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('step caps are tap-actionable buttons', (tester) async {
      // dump 1: each cap resolves to a SINGLE node carrying both the button role and the
      // tap action — `actions: tap`, `flags: isButton, hasEnabledState, isEnabled` — which
      // settles dossier §11 unknown 3: NumberFieldControl's `Semantics(button: true)`
      // (number_field_edge.dart:158) merges with LayrzTappable's bare GestureDetector tap
      // fragment (tappable.dart:240-241) into one node, not two.
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzNumberInput(labelText: 'Amount', value: 42),
        );

        expect(
          tester.getSemantics(find.bySemanticsLabel('Decrease value')),
          matchesSemantics(
            label: 'Decrease value',
            isButton: true,
            hasTapAction: true,
            hasEnabledState: true,
            isEnabled: true,
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Increase value')),
          matchesSemantics(
            label: 'Increase value',
            isButton: true,
            hasTapAction: true,
            hasEnabledState: true,
            isEnabled: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('step caps report disabled at bounds', (tester) async {
      // dump 8 (value: 10, maximum: 10, minimum: 0): the increment cap, at its bound,
      // loses both `isEnabled` and `actions: tap` (flags: isButton, hasEnabledState
      // only); the decrement cap, not at its bound, keeps both.
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzNumberInput(
            labelText: 'Quantity',
            value: 10,
            maximum: 10,
            minimum: 0,
          ),
        );

        expect(
          tester.getSemantics(find.bySemanticsLabel('Increase value')),
          matchesSemantics(
            label: 'Increase value',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Decrease value')),
          matchesSemantics(
            label: 'Decrease value',
            isButton: true,
            hasTapAction: true,
            hasEnabledState: true,
            isEnabled: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('increment cap semantics go stale-correct immediately after a tap reaches maximum '
        '(DESIGN-150, door 2)', (tester) async {
      // Unlike "step caps report disabled at bounds" above (which pins the shape for a
      // widget already constructed at its bound), this proves the semantics update
      // *after* a change made post-render -- the exact staleness this row fixes. No
      // `onChanged` is supplied, so nothing but the fix's own listener can update this.
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzNumberInput(labelText: 'Quantity', value: 9, minimum: 0, maximum: 10, step: 1),
        );

        await tester.tap(find.bySemanticsLabel('Increase value'));
        await tester.pumpAndSettle();

        expect(
          tester.getSemantics(find.bySemanticsLabel('Increase value')),
          matchesSemantics(label: 'Increase value', isButton: true, hasEnabledState: true, isEnabled: false),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Decrease value')),
          matchesSemantics(
            label: 'Decrease value',
            isButton: true,
            hasTapAction: true,
            hasEnabledState: true,
            isEnabled: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets(
      'increment cap semantics go stale-correct after the controller text changes directly '
      '(DESIGN-150, door 3, typing)',
      (tester) async {
        final handle = tester.ensureSemantics();
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        final controller = TextEditingController(text: '9');
        addTearDown(controller.dispose);

        try {
          await pumpThemedApp(
            tester,
            LayrzNumberInput(labelText: 'Quantity', value: 9, minimum: 0, maximum: 10, controller: controller),
          );

          controller.text = '10';
          await tester.pump();

          expect(
            tester.getSemantics(find.bySemanticsLabel('Increase value')),
            matchesSemantics(label: 'Increase value', isButton: true, hasEnabledState: true, isEnabled: false),
          );
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets(
      'step controls are reachable by arrow/page keys on the field, clamp at the minimum '
      'bound, and are tap targets rather than focus stops',
      (tester) async {
        // number_input.dart:611-618 documents that the field is the only focus stop this
        // widget contributes (the ancestor Focus that intercepts stepping keys never
        // requests focus itself), and LayrzTappable — the caps' gesture surface — owns no
        // focus either (tappable.dart:27-28). Dump 1 confirms neither cap carries
        // `isFocusable`/`hasFocusAction`. So the real keyboard contract lives entirely on
        // the field via Focus.onKeyEvent (number_input.dart:445-487), and this test proves
        // that contract directly rather than asserting the caps are focusable, which they
        // deliberately are not (decision 1, dossier §10). The caps remain reachable by
        // gesture, asserted here as `isButton` + `hasTapAction` from dump 1/8.
        //
        // Deliberately ONE pumped widget for this entire test, and deliberately does not
        // exercise `readOnly`/`disabled` by sending a live key: two separate Flutter
        // framework quirks were found while writing this test, neither of which is this
        // widget's fault or this row's to fix —
        //   1. tapping to focus (`tester.tap(find.byType(EditableText))`) also positions
        //      the text caret, and on this field's centered, short text that triggers an
        //      unrelated `VerticalCaretMovementRun` assertion on the next
        //      vertical-caret-movement key; worked around by focusing via
        //      `focusNode.requestFocus()` instead (the same pattern already used
        //      successfully in number_input_lifecycle_test.dart).
        //   2. sending ANY vertical-caret-movement key (Arrow/Page) to a `readOnly`
        //      `EditableText` reproducibly trips the SAME `VerticalCaretMovementRun`
        //      assertion, even as the very first key of a brand-new, isolated test — with
        //      or without semantics enabled. There is no key-based way found to prove
        //      "inert when readOnly" live in this test environment; the guard is instead
        //      established by direct citation of number_input.dart:453/458/463/473
        //      (`!widget.readOnly && !widget.disabled` on every branch) plus the semantics
        //      dump 3 already pins for readOnly (both caps disabled — see "read-only field
        //      keeps the step-button chrome…" above). `disabled` is the same `||` clause,
        //      exercised identically, and routes to the no-caps plain-chrome branch anyway
        //      (nothing left to send a key to or check a cap on).
        final handle = tester.ensureSemantics();

        try {
          final focusNode = FocusNode(debugLabel: 'step-test-main');
          addTearDown(focusNode.dispose);

          num? lastValue = 5;
          await pumpThemedApp(
            tester,
            LayrzNumberInput(
              focusNode: focusNode,
              labelText: 'Quantity',
              value: 5,
              step: 10,
              minimum: 0,
              maximum: 1000,
              onChanged: (v) => lastValue = v,
            ),
          );

          focusNode.requestFocus();
          await tester.pumpAndSettle();

          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pumpAndSettle();
          expect(lastValue, 15, reason: 'ArrowUp steps by `step`');

          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
          expect(lastValue, 5, reason: 'ArrowDown steps by `step`');

          await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
          await tester.pumpAndSettle();
          expect(lastValue, 105, reason: 'PageUp steps by `step * 10`');

          await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
          await tester.pumpAndSettle();
          expect(lastValue, 5, reason: 'PageDown steps by `step * 10`');

          // Asserted HERE — at value 5, with neither cap at a bound — as a mid-sequence
          // checkpoint proving the dump-1 shape (button role, tap action, enabled) holds
          // while stepping via the keyboard, independent of the at-bound assertion added
          // below. This is not a workaround for missing coverage: it pins a distinct point
          // in the sequence that the final at-bound assertion does not.
          expect(
            tester.getSemantics(find.bySemanticsLabel('Decrease value')),
            matchesSemantics(isButton: true, hasTapAction: true, hasEnabledState: true, isEnabled: true),
          );
          expect(
            tester.getSemantics(find.bySemanticsLabel('Increase value')),
            matchesSemantics(isButton: true, hasTapAction: true, hasEnabledState: true, isEnabled: true),
          );

          await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
          await tester.pumpAndSettle();
          expect(lastValue, 0, reason: 'PageDown clamps at `minimum`, never goes negative');

          // The real at-bound assertion (DESIGN-150): before the controller-value listener
          // was added, `_handleKeyEvent`'s stepping branches (unlike `_handleIncrement`/
          // `_handleDecrement`) never called `setState`, so the decrement cap's own
          // semantics node went stale and kept reporting `isEnabled: true`/`hasTapAction:
          // true` after this very PageDown drove the value to `minimum`. This is a semantics
          // read only — no further key is sent (see the note below on why).
          expect(
            tester.getSemantics(find.bySemanticsLabel('Decrease value')),
            matchesSemantics(label: 'Decrease value', isButton: true, hasEnabledState: true, isEnabled: false),
          );
          expect(
            tester.getSemantics(find.bySemanticsLabel('Increase value')),
            matchesSemantics(
              label: 'Increase value',
              isButton: true,
              hasTapAction: true,
              hasEnabledState: true,
              isEnabled: true,
            ),
          );

          // A further key at the bound is guarded by number_input.dart:463/473
          // (`!_isIncrementDisabled()`/`!_isDecrementDisabled()`) — not re-sent here: a
          // 6th consecutive vertical-movement key in this same test was found to trip an
          // unrelated `VerticalCaretMovementRun` framework assertion documented above
          // (reproduced independent of this row's changes, both with and without semantics
          // enabled). "step caps report disabled at bounds" above already pins the guard's
          // effect on the caps' semantics end-to-end, for a widget constructed already at
          // its bound.
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets(
      'required field announces the required indicator in its accessible name (step buttons)',
      (tester) async {
        // dump 9 (isRequired: true, Branch B): the field's own node label becomes
        // "Amount, required" — built from `l10n.inputsRequiredIndicator` ('required'),
        // copied verbatim from LayrzTextAreaInput (textarea_input.dart:371-374). The outer
        // group and both caps are unaffected.
        final handle = tester.ensureSemantics();
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;

        try {
          await pumpThemedApp(
            tester,
            const LayrzNumberInput(labelText: 'Amount', isRequired: true),
          );

          expect(countSemanticsWithLabel(tester, 'Amount, required'), 1);
          expect(
            tester.getSemantics(find.byType(EditableText)),
            matchesSemantics(
              label: 'Amount, required',
              isTextField: true,
              hasEnabledState: true,
              isEnabled: true,
              isFocusable: true,
            ),
          );
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets(
      'required field announces the required indicator in its accessible name (plain chrome)',
      (tester) async {
        // dump 10 (isRequired: true, hideStepButtons: true, Branch A): the merged node's
        // label becomes "Amount, required", proving the `:586` (Branch A) node also picks
        // up `semanticLabel`, not just the field node at `:756`.
        final handle = tester.ensureSemantics();
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;

        try {
          await pumpThemedApp(
            tester,
            const LayrzNumberInput(labelText: 'Amount', isRequired: true, hideStepButtons: true),
          );

          expect(
            tester.getSemantics(find.byType(EditableText)),
            matchesSemantics(
              label: 'Amount, required',
              isTextField: true,
              hasEnabledState: true,
              isEnabled: true,
              isFocusable: true,
            ),
          );
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets('help affordance is exposed as a semantics tooltip (step buttons)', (tester) async {
      // dump 11 (helpTitleText + helpContentText, Branch B): the field node carries
      // `tooltip: "Help. Enter a positive number"` distinct from its `label: "Price"` — the
      // tooltip is NOT swallowed by any merge, resolving dossier §6.8 ("least sure").
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzNumberInput(
            labelText: 'Price',
            helpTitleText: 'Help',
            helpContentText: 'Enter a positive number',
          ),
        );

        expect(
          tester.getSemantics(find.byType(EditableText)),
          matchesSemantics(
            label: 'Price',
            tooltip: 'Help. Enter a positive number',
            isTextField: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('help affordance is exposed as a semantics tooltip (plain chrome)', (tester) async {
      // dump 12: same tooltip shape on the `:586` (Branch A) node.
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzNumberInput(
            labelText: 'Price',
            helpTitleText: 'Help',
            helpContentText: 'Enter a positive number',
            hideStepButtons: true,
          ),
        );

        expect(
          tester.getSemantics(find.byType(EditableText)),
          matchesSemantics(
            label: 'Price',
            tooltip: 'Help. Enter a positive number',
            isTextField: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('hint text is exposed to screen readers exactly once, merged into the label', (tester) async {
      // dump 4/5 settled DESIGN-116's Phase 0 gate (dossier §11 unknown 2): LayrzInputChrome
      // renders hintText as a plain, non-excluded Text (input_chrome.dart:417/:436) that
      // Flutter merges directly into the field's own label on BOTH branches — a single
      // two-line label "Amount\nEnter price", not two separate nodes. Adding
      // `hint: widget.hintText` on top of that (as LayrzTextAreaInput does) would announce
      // it twice, so number_input.dart deliberately does not set `hint:` (see the comment
      // above `semanticTooltip` in build()). This test pins the merged shape rather than a
      // `hint:` flag, and the name says "exposed…exactly once" rather than "hint text is
      // accessible" for exactly that reason.
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzNumberInput(labelText: 'Amount', hintText: 'Enter price'),
        );

        expect(countSemanticsWithLabel(tester, 'Amount'), 1);
        expect(countSemanticsWithLabel(tester, 'Enter price'), 1);
        expect(
          tester.getSemantics(find.byType(EditableText)),
          matchesSemantics(
            label: 'Amount\nEnter price',
            isTextField: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('read-only field keeps the step-button chrome and reports both caps disabled', (tester) async {
      // dump 3 (value: 42, readOnly: true, Branch B): `readOnly` does NOT switch to the
      // plain-chrome branch (only `disabled`/`hideStepButtons` do, number_input.dart:511)
      // — both caps stay rendered but lose `isEnabled`/`actions: tap`, and the field node
      // keeps isTextField/isReadOnly/isFocusable while losing isEnabled.
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzNumberInput(labelText: 'Amount', value: 42, readOnly: true),
        );

        expect(
          tester.getSemantics(find.byType(EditableText)),
          matchesSemantics(
            label: 'Amount',
            value: '42',
            isTextField: true,
            hasEnabledState: true,
            isEnabled: false,
            isReadOnly: true,
            isFocusable: true,
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Decrease value')),
          matchesSemantics(label: 'Decrease value', isButton: true, hasEnabledState: true, isEnabled: false),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Increase value')),
          matchesSemantics(label: 'Increase value', isButton: true, hasEnabledState: true, isEnabled: false),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('field is focusable and takes focus on tap', (tester) async {
      // Name trimmed from the original ("...and text selected with keyboard"): nothing
      // about text *selection* is asserted here, so the name must not promise it.
      //
      // This was the last of the 16 tests still asserting a widget fact
      // (`focusNode.hasFocus`) instead of the accessibility tree — exactly what this suite
      // exists to replace. Dump (2026-08-24, labelText: 'Number', controller text '42',
      // after tapping the field) pins the full flag/action set `matchesSemantics` requires
      // (it fails on a true flag/action left out just as readily as on a false one wrongly
      // asserted true):
      //   actions: setSelection, setText
      //   flags: isTextField, isFocused, hasEnabledState, isEnabled, isFocusable
      //   label: "Number"
      final handle = tester.ensureSemantics();
      final controller = TextEditingController(text: '42');
      addTearDown(controller.dispose);

      try {
        await pumpThemedApp(
          tester,
          LayrzNumberInput(
            labelText: 'Number',
            controller: controller,
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        expect(
          tester.getSemantics(find.byType(EditableText)),
          matchesSemantics(
            label: 'Number',
            isTextField: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            isFocused: true,
            hasSetSelectionAction: true,
            hasSetTextAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('error text merges into the grouping node on the step-buttons branch (DESIGN-145)', (tester) async {
      // dump 6 (labelText: 'Price', errors: ['Too small'], Branch B): removing the outer
      // label in 4892de2 made the outer grouping node compatible with
      // LayrzInputFooterSlot's error fragment — they are siblings in the same Column — so
      // the error text is absorbed into the outer node's own label instead of remaining a
      // separate node. "Too small" appears exactly once (on the outer group), "Price"
      // appears exactly once (on the field); nothing is duplicated or lost. This reproduces
      // DESIGN-145's node-count claim by dump rather than taking it on faith (dossier §11).
      //
      // A re-dump (2026-08-24, confirming DESIGN-116 review finding 1) shows the tree is
      // exactly 7 nodes deep, with the merged "Too small" label sitting on the grouping
      // node that has the three step-row children as its own children:
      //   #0 view -> #1 -> #2 -> #3 [label: "Too small", 3 children]
      //                              ├─ #4 "Decrease value"
      //                              ├─ #5 "Price" (the field)
      //                              └─ #6 "Increase value"
      // Asserting only the label *count* cannot tell this shape apart from the pre-fix
      // shape (error text as its own 8th leaf, "Price" still labelled once) — both would
      // satisfy "each string appears on exactly one node". Pinning `childrenCount == 3` on
      // the matched node is what actually proves the text moved into the grouping node
      // rather than merely existing somewhere once.
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzNumberInput(labelText: 'Price', errors: ['Too small']),
        );

        final groupingNodes = findSemanticsWithLabel(tester, 'Too small');
        expect(groupingNodes, hasLength(1));
        expect(
          groupingNodes.single.childrenCount,
          3,
          reason:
              'the error text must be absorbed into the outer grouping node (decrement '
              'cap / field / increment cap as its three children), not left as its own '
              'sibling leaf node',
        );
        expect(countSemanticsWithLabel(tester, 'Price'), 1);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('helper text merges the same way as error text', (tester) async {
      // dump 7 (labelText: 'Price', helperText: 'Some help', Branch B): helperText, also
      // rendered through LayrzInputFooterSlot, merges into the outer grouping node
      // identically to errors (see the test above) — "Some help" once, "Price" once.
      //
      // Re-dump (2026-08-24) confirms the identical 7-node shape as the errors test, with
      // "Some help" on the grouping node (`childrenCount == 3`) rather than its own leaf —
      // see that test's comment for the full tree and why the count alone doesn't pin it.
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzNumberInput(labelText: 'Price', helperText: 'Some help'),
        );

        final groupingNodes = findSemanticsWithLabel(tester, 'Some help');
        expect(groupingNodes, hasLength(1));
        expect(
          groupingNodes.single.childrenCount,
          3,
          reason:
              'the helper text must be absorbed into the outer grouping node, not left '
              'as its own sibling leaf node',
        );
        expect(countSemanticsWithLabel(tester, 'Price'), 1);
      } finally {
        handle.dispose();
      }
    });
  });
}
