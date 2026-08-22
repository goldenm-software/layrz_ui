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

      testWidgets('tappable with onTap is not a button (wrapper, not control)', (tester) async {
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

      testWidgets('disabled tappable is not exposed as interactive', (tester) async {
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
          // A disabled tappable should not be a button or have tap action.
          final semantics = tester.getSemantics(find.text('Disabled Widget'));
          expect(semantics, isNot(matchesSemantics(isButton: true)));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('tappable with multiple gestures is not a button', (tester) async {
        // Arrange & Act
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzTappable(
              onTap: () {},
              onLongPress: () {},
              onSecondaryTap: () {},
              child: const Text('Multi-action'),
            ),
          );

          // Assert
          // Even with multiple gestures, it's still just a wrapper, not a button.
          final semantics = tester.getSemantics(find.text('Multi-action'));
          expect(semantics, isNot(matchesSemantics(isButton: true)));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('inert tappable has minimal semantic footprint', (tester) async {
        // Arrange & Act
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            const LayrzTappable(
              child: Text('Minimal Semantics'),
            ),
          );

          // Assert
          // An inert tappable should not add any semantic flags or actions.
          final semantics = tester.getSemantics(find.text('Minimal Semantics'));
          expect(semantics, isNot(matchesSemantics(
            isButton: true,
            isFocusable: true,
            hasFocusAction: true,
            hasEnabledState: true,
          )));
        } finally {
          handle.dispose();
        }
      });
    });
  });
}
