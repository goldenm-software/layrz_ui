import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTappable Accessibility', () {
    group('Semantic properties', () {
      testWidgets('inert tappable is not exposed as a button', (tester) async {
        // Arrange & Act
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            const LayrzTappable(
              child: Text('Inert'),
            ),
          );

          // Assert
          // An inert tappable should not be exposed as a button.
          final semantics = tester.getSemantics(find.text('Inert'));
          expect(semantics, isNot(matchesSemantics(isButton: true)));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('tappable with onTap exposes tap action to screen readers', (tester) async {
        // Arrange & Act
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzTappable(
              onTap: () {},
              child: const Text('Tappable'),
            ),
          );

          // Assert
          // The GestureDetector with onTap should expose hasTapAction in the semantics tree.
          // This is critical for assistive technology to detect the widget is tappable.
          final semantics = tester.getSemantics(find.text('Tappable'));
          expect(semantics, matchesSemantics(hasTapAction: true));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('tappable with onLongPress exposes long-press action to screen readers', (tester) async {
        // Arrange & Act
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzTappable(
              onLongPress: () {},
              child: const Text('Long Pressable'),
            ),
          );

          // Assert
          // The GestureDetector with onLongPress should expose hasLongPressAction.
          final semantics = tester.getSemantics(find.text('Long Pressable'));
          expect(semantics, matchesSemantics(hasLongPressAction: true));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('disabled tappable does not expose tap action (important boundary)', (tester) async {
        // Arrange & Act
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzTappable(
              disabled: true,
              onTap: () {},
              child: const Text('Disabled Widget'),
            ),
          );

          // Assert
          // When disabled, the interactive path is bypassed entirely (early return),
          // so the GestureDetector is not created and tap action should not be exposed.
          // This is a critical boundary: the disabled flag switches between inert and interactive paths.
          final semantics = tester.getSemantics(find.text('Disabled Widget'));
          expect(semantics, isNot(matchesSemantics(hasTapAction: true)));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('disabled tappable does not expose long-press action', (tester) async {
        // Arrange & Act
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzTappable(
              disabled: true,
              onLongPress: () {},
              child: const Text('Disabled Long Press'),
            ),
          );

          // Assert
          // When disabled, long-press action should not be exposed.
          final semantics = tester.getSemantics(find.text('Disabled Long Press'));
          expect(semantics, isNot(matchesSemantics(hasLongPressAction: true)));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('tappable does not expose focus action (no focus ownership)', (tester) async {
        // Arrange & Act
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzTappable(
              onTap: () {},
              child: const Text('Tappable'),
            ),
          );

          // Assert
          // LayrzTappable does NOT own focus, so it should not expose focus action.
          // This is a deliberate design decision: focus remains with whatever real control wraps it.
          final semantics = tester.getSemantics(find.text('Tappable'));
          expect(semantics, isNot(matchesSemantics(hasFocusAction: true)));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('tappable is not focusable (no focus ownership)', (tester) async {
        // Arrange & Act
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzTappable(
              onTap: () {},
              child: const Text('Tappable'),
            ),
          );

          // Assert
          // LayrzTappable does NOT own focus, so it should not be focusable.
          final semantics = tester.getSemantics(find.text('Tappable'));
          expect(semantics, isNot(matchesSemantics(isFocusable: true)));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('child content remains accessible within tappable', (tester) async {
        // Arrange & Act
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzTappable(
              onTap: () {},
              child: const Text('Accessible Content'),
            ),
          );

          // Assert
          // The child text should be accessible in the semantics tree.
          expect(find.text('Accessible Content'), findsOneWidget);
          final semantics = tester.getSemantics(find.text('Accessible Content'));
          expect(semantics.label, contains('Accessible Content'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('tappable with is not exposed as button (wrapper, not control)', (tester) async {
        // Arrange & Act
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzTappable(
              onTap: () {},
              child: const Text('Tappable'),
            ),
          );

          // Assert
          // LayrzTappable is a wrapper, not a control itself. It should not be exposed as a button.
          // The button role belongs to the actual control that owns focus (if any).
          final semantics = tester.getSemantics(find.text('Tappable'));
          expect(semantics, isNot(matchesSemantics(isButton: true)));
        } finally {
          handle.dispose();
        }
      });
    });
  });
}
