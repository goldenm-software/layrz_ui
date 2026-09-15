import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

/// Counts semantics nodes whose label contains [needle].
///
/// Walks the full semantics tree from its root, rather than relying on a `findsWidgets`-style
/// existence check, so a test built on this can actually distinguish "labeled once", "labeled
/// twice" (a duplicate announcement), and "never labeled" (an empty accessible name) --
/// mirrors the identical helper in `number_input_a11y_test.dart`. Requires
/// [WidgetTester.ensureSemantics] to be active.
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

/// Finds the outer accessible [Semantics] node [LayrzOtpInput] builds around its hidden
/// field.
///
/// [LayrzOtpInput] wraps its `GestureDetector`/`Stack` in an explicit `Semantics(label:,
/// textField: true, enabled:, readOnly:, value:, ...)`, which produces its OWN semantics
/// node (carrying the real [LayrzOtpInput.labelText] and code [String] value) distinct from
/// the raw [EditableText]'s own semantics node underneath it -- the latter carries no
/// meaningful label of its own: the painted [OtpSlot] row on top of it is wrapped in
/// [ExcludeSemantics], so its digit [Text] widgets never leak a second, digit-per-line label
/// onto the hidden field's own node. The outer node -- found here as the first [Semantics]
/// descendant of [LayrzOtpInput] -- is the one a screen reader actually announces the field
/// by, so it is the one every assertion in this suite targets, never `find.byType(EditableText)`.
Finder findOtpSemantics() => find
    .descendant(
      of: find.byType(LayrzOtpInput),
      matching: find.byType(Semantics),
    )
    .first;

void main() {
  group('LayrzOtpInput Accessibility', () {
    testWidgets('exposes a text-field semantics node with label, value and enabled state', (tester) async {
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzOtpInput(labelText: 'Verification code', value: '123'),
        );

        expect(
          tester.getSemantics(findOtpSemantics()),
          matchesSemantics(
            label: 'Verification code',
            value: '123',
            isTextField: true,
            hasEnabledState: true,
            isEnabled: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('the label is present exactly once', (tester) async {
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzOtpInput(labelText: 'Verification code'),
        );

        // Guards against a duplicate-label regression: the outer node carries the label
        // once, and the inner EditableText node (empty value) contributes nothing.
        expect(countSemanticsWithLabel(tester, 'Verification code'), 1);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('the label is present exactly once even with a non-empty value', (tester) async {
      // Guards the ExcludeSemantics wrapper around the painted OtpSlot row: with digits
      // entered, the six OtpSlot Text widgets must not leak a "1\n2\n3"-style label onto
      // the inner EditableText node, which would otherwise sit alongside the real
      // "Verification code" label in the tree.
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzOtpInput(labelText: 'Verification code', value: '123456'),
        );

        expect(countSemanticsWithLabel(tester, 'Verification code'), 1);
        // Positively confirms the digit-leak is gone, not merely that it doesn't collide
        // with the real label string.
        expect(countSemanticsWithLabel(tester, '1\n2\n3'), 0);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('required field announces the required indicator exactly once', (tester) async {
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzOtpInput(labelText: 'Verification code', isRequired: true),
        );

        expect(countSemanticsWithLabel(tester, 'Verification code, required'), 1);
        expect(
          tester.getSemantics(findOtpSemantics()),
          matchesSemantics(
            label: 'Verification code, required',
            isTextField: true,
            hasEnabledState: true,
            isEnabled: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('disabled state reflects hasEnabledState/isEnabled false in semantics', (tester) async {
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzOtpInput(labelText: 'Verification code', disabled: true),
        );

        expect(
          tester.getSemantics(findOtpSemantics()),
          matchesSemantics(
            label: 'Verification code',
            isTextField: true,
            hasEnabledState: true,
            isEnabled: false,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('enabled (non-disabled) field reports hasEnabledState/isEnabled true', (tester) async {
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzOtpInput(labelText: 'Verification code'),
        );

        expect(
          tester.getSemantics(findOtpSemantics()),
          matchesSemantics(
            label: 'Verification code',
            isTextField: true,
            hasEnabledState: true,
            isEnabled: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('readOnly state is reflected in semantics, distinct from disabled', (tester) async {
      // Unlike `disabled`, `readOnly` keeps `isEnabled: true` alongside `isReadOnly: true` --
      // the field stays announced as enabled/focusable, just not editable.
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzOtpInput(labelText: 'Verification code', readOnly: true, value: '123456'),
        );

        expect(
          tester.getSemantics(findOtpSemantics()),
          matchesSemantics(
            label: 'Verification code',
            value: '123456',
            isTextField: true,
            hasEnabledState: true,
            isEnabled: true,
            isReadOnly: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('field carries no readOnly flag when readOnly is false', (tester) async {
      final handle = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      try {
        await pumpThemedApp(
          tester,
          const LayrzOtpInput(labelText: 'Verification code'),
        );

        expect(
          tester.getSemantics(findOtpSemantics()),
          matchesSemantics(
            label: 'Verification code',
            isTextField: true,
            hasEnabledState: true,
            isEnabled: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
