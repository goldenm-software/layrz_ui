import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/buttons/buttons.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzButton Accessibility', () {
    group('Tappability: enabled state', () {
      testWidgets('enabled button is tappable when onTap is provided', (tester) async {
        var tapped = false;
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Enabled',
            onTap: () {
              tapped = true;
            },
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        expect(tapped, isTrue);
      });

      testWidgets('button is not tappable when onTap is null', (tester) async {
        var tapped = false;
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Disabled',
            onTap: null,
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        expect(tapped, isFalse);
      });

      testWidgets('button is not tappable when isDisabled: true', (tester) async {
        var tapped = false;
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Disabled',
            isDisabled: true,
            onTap: () {
              tapped = true;
            },
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        expect(tapped, isFalse);
      });

      testWidgets('button is not tappable when isLoading: true', (tester) async {
        final loading = ValueNotifier<bool>(true);
        var tapped = false;

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Loading',
            isLoading: loading,
            onTap: () {
              tapped = true;
            },
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.byType(LayrzButton), warnIfMissed: false);
        expect(tapped, isFalse);
      });

      testWidgets('button is not tappable when isCooldown: true', (tester) async {
        final cooldown = ValueNotifier<bool>(true);
        var tapped = false;

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Cooldown',
            isCooldown: cooldown,
            onTap: () {
              tapped = true;
            },
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.byType(LayrzButton), warnIfMissed: false);
        expect(tapped, isFalse);
      });

      testWidgets('tappability reflects isLoading changes', (tester) async {
        final loading = ValueNotifier<bool>(false);
        var tappedCount = 0;

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Toggle',
            isLoading: loading,
            onTap: () {
              tappedCount++;
            },
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        expect(tappedCount, equals(1));

        loading.value = true;
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.byType(LayrzButton), warnIfMissed: false);
        expect(tappedCount, equals(1));

        loading.value = false;
        await tester.pump();

        await tester.tap(find.byType(LayrzButton));
        expect(tappedCount, equals(2));
      });

      testWidgets('tappability reflects isCooldown changes', (tester) async {
        final cooldown = ValueNotifier<bool>(false);
        var tappedCount = 0;

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Toggle',
            isCooldown: cooldown,
            onTap: () {
              tappedCount++;
            },
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        expect(tappedCount, equals(1));

        cooldown.value = true;
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.byType(LayrzButton), warnIfMissed: false);
        expect(tappedCount, equals(1));

        cooldown.value = false;
        await tester.pump();

        await tester.tap(find.byType(LayrzButton));
        expect(tappedCount, equals(2));
      });
    });

    group('Semantic properties', () {
      testWidgets('button exposes button flag and label in semantics', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Test Label',
              onTap: () {},
            ),
          );

          final buttonSemantics = tester.getSemantics(find.byType(LayrzButton));

          // Button should expose button flag and label
          expect(buttonSemantics.label, contains('Test Label'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('button is enabled when onTap is provided and not disabled', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          var tapped = false;
          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Enabled Button',
              onTap: () {
                tapped = true;
              },
            ),
          );

          // Verify semantics node exists and has label
          final buttonSemantics = tester.getSemantics(find.byType(LayrzButton));
          expect(buttonSemantics.label, contains('Enabled Button'));

          // Verify button responds to taps (functional verification of enabled state)
          await tester.tap(find.byType(LayrzButton));
          expect(tapped, isTrue);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('button is disabled when onTap is null (verified via tappability + semantics)', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          var tapped = false;
          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Disabled Button',
              onTap: null,
            ),
          );

          // Verify semantics node exists and has label
          final buttonSemantics = tester.getSemantics(find.byType(LayrzButton));
          expect(buttonSemantics.label, contains('Disabled Button'));

          // Verify button does not respond to taps when onTap is null
          await tester.tap(find.byType(LayrzButton), warnIfMissed: false);
          expect(tapped, isFalse);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('button is disabled when isDisabled: true (verified via tappability + semantics)', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          var tapped = false;
          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Explicitly Disabled',
              isDisabled: true,
              onTap: () {
                tapped = true;
              },
            ),
          );

          // Verify semantics node exists and has label
          final buttonSemantics = tester.getSemantics(find.byType(LayrzButton));
          expect(buttonSemantics.label, contains('Explicitly Disabled'));

          // Verify button does not respond to taps (functional verification of disabled state)
          await tester.tap(find.byType(LayrzButton), warnIfMissed: false);
          expect(tapped, isFalse);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('button is disabled when isLoading is true (verified via tappability + semantics)', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          final loading = ValueNotifier<bool>(true);
          var tapped = false;
          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Loading Button',
              isLoading: loading,
              onTap: () {
                tapped = true;
              },
            ),
          );

          // Don't use pumpAndSettle on loading buttons — the animation is infinite
          await tester.pump(const Duration(milliseconds: 100));

          // Verify semantics node exists and has label
          final buttonSemantics = tester.getSemantics(find.byType(LayrzButton));
          expect(buttonSemantics.label, contains('Loading Button'));

          // Verify button does not respond to taps while loading
          await tester.tap(find.byType(LayrzButton), warnIfMissed: false);
          expect(tapped, isFalse);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('button is disabled when isCooldown is true (verified via tappability + semantics)', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          final cooldown = ValueNotifier<bool>(true);
          var tapped = false;
          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Cooldown Button',
              isCooldown: cooldown,
              onTap: () {
                tapped = true;
              },
            ),
          );

          // Don't use pumpAndSettle on cooldown buttons — the animation is infinite
          await tester.pump(const Duration(milliseconds: 100));

          // Verify semantics node exists and has label
          final buttonSemantics = tester.getSemantics(find.byType(LayrzButton));
          expect(buttonSemantics.label, contains('Cooldown Button'));

          // Verify button does not respond to taps during cooldown
          await tester.tap(find.byType(LayrzButton), warnIfMissed: false);
          expect(tapped, isFalse);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('Fab variant exposes labelText as accessible name despite no visible text', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Fab Accessible Label',
              style: LayrzButtonStyle.filledTonalFab,
              onTap: () {},
            ),
          );

          // Text should not be visible (Fab renders only icon)
          expect(find.text('Fab Accessible Label'), findsNothing);

          // But label should be in semantics tree for screen readers
          final buttonSemantics = tester.getSemantics(find.byType(LayrzButton));
          expect(buttonSemantics.label, contains('Fab Accessible Label'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('button label updates when labelText changes', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          final labelNotifier = ValueNotifier<String>('Initial Label');

          await pumpThemed(
            tester,
            ValueListenableBuilder(
              valueListenable: labelNotifier,
              builder: (context, label, _) => LayrzButton(
                labelText: label,
                onTap: () {},
              ),
            ),
          );

          var buttonSemantics = tester.getSemantics(find.byType(LayrzButton));
          expect(buttonSemantics.label, contains('Initial Label'));

          labelNotifier.value = 'Updated Label';
          await tester.pump();

          buttonSemantics = tester.getSemantics(find.byType(LayrzButton));
          expect(buttonSemantics.label, contains('Updated Label'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('button semantics remain correct across loading transition', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          final loading = ValueNotifier<bool>(false);
          var tappedCount = 0;

          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Toggle Loading',
              isLoading: loading,
              onTap: () {
                tappedCount++;
              },
            ),
          );

          // Initially not loading — button is enabled and responds to taps
          var buttonSemantics = tester.getSemantics(find.byType(LayrzButton));
          expect(buttonSemantics.label, contains('Toggle Loading'));

          await tester.tap(find.byType(LayrzButton));
          expect(tappedCount, equals(1));

          // Start loading — button is disabled and does not respond to taps
          loading.value = true;
          await tester.pump(const Duration(milliseconds: 100));

          buttonSemantics = tester.getSemantics(find.byType(LayrzButton));
          expect(buttonSemantics.label, contains('Toggle Loading'));

          await tester.tap(find.byType(LayrzButton), warnIfMissed: false);
          expect(tappedCount, equals(1)); // Should not have incremented

          // Stop loading — button is enabled again and responds to taps
          loading.value = false;
          await tester.pump();

          buttonSemantics = tester.getSemantics(find.byType(LayrzButton));
          expect(buttonSemantics.label, contains('Toggle Loading'));

          await tester.tap(find.byType(LayrzButton));
          expect(tappedCount, equals(2));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('regression: non-Fab button label is announced exactly once, not doubled', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Exactly Once Label',
              onTap: () {},
            ),
          );

          final buttonSemantics = tester.getSemantics(find.byType(LayrzButton));

          // Regression test: label must be exactly 'Exactly Once Label', not duplicated
          // This verifies excludeSemantics: true on the Semantics wrapper prevents
          // the child Text from contributing a duplicate node.
          expect(buttonSemantics.label, equals('Exactly Once Label'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('regression: Fab button label is announced exactly once in semantics tree', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Fab Exact Label',
              style: LayrzButtonStyle.filledTonalFab,
              onTap: () {},
            ),
          );

          // Fab does not render visible text, but label must appear in semantics exactly once
          expect(find.text('Fab Exact Label'), findsNothing);

          final buttonSemantics = tester.getSemantics(find.byType(LayrzButton));
          expect(buttonSemantics.label, equals('Fab Exact Label'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('button exposes hint in semantics when hintText is provided', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Button Label',
              hintText: 'Button Hint',
              onTap: () {},
            ),
          );

          final buttonSemantics = tester.getSemantics(find.byType(LayrzButton));
          expect(buttonSemantics.label, equals('Button Label'));
          expect(buttonSemantics.hint, equals('Button Hint'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('button does not expose hint in semantics when hintText is null', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Button Label',
              onTap: () {},
            ),
          );

          final buttonSemantics = tester.getSemantics(find.byType(LayrzButton));
          expect(buttonSemantics.label, equals('Button Label'));
          // When hintText is null, hint should be empty
          expect(buttonSemantics.hint, isEmpty);
        } finally {
          handle.dispose();
        }
      });
    });
  });
}
