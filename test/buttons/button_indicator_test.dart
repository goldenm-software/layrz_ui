import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/buttons/buttons.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('Loading and cooldown indicators', () {
    testWidgets('isLoading displays indicator', (tester) async {
      final loading = ValueNotifier<bool>(true);

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'Loading',
          isLoading: loading,
          onTap: () {},
        ),
      );

      // Use bounded pump() instead of pumpAndSettle() due to infinite animation.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LayrzButton), findsOneWidget);
    });

    testWidgets('isCooldown displays indicator', (tester) async {
      final cooldown = ValueNotifier<bool>(true);

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'Cooldown',
          isCooldown: cooldown,
          onTap: () {},
        ),
      );

      // Use bounded pump() instead of pumpAndSettle() due to infinite animation.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LayrzButton), findsOneWidget);
    });

    testWidgets('indicator animates', (tester) async {
      final loading = ValueNotifier<bool>(true);

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'Animating',
          isLoading: loading,
          onTap: () {},
        ),
      );

      // Run animation for a bit.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LayrzButton), findsOneWidget);

      // Run a full animation cycle.
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byType(LayrzButton), findsOneWidget);
    });

    testWidgets('indicator is disposed without throwing', (tester) async {
      final loading = ValueNotifier<bool>(true);

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'Dispose Test',
          isLoading: loading,
          onTap: () {},
        ),
      );

      // Pump a different tree.
      await tester.pumpWidget(const SizedBox.shrink());

      // No exception should be thrown.
      expect(find.byType(LayrzButton), findsNothing);
    });

    testWidgets('loading indicator suppresses taps', (tester) async {
      final loading = ValueNotifier<bool>(true);
      int tapCount = 0;

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'Button',
          isLoading: loading,
          onTap: () => tapCount++,
        ),
      );

      // Use bounded pump() instead of pumpAndSettle() due to infinite animation.
      await tester.tap(find.byType(LayrzButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tapCount, equals(0));

      // Disable loading.
      loading.value = false;
      await tester.pump();

      // Now taps should work.
      await tester.tap(find.byType(LayrzButton));
      await tester.pump();

      expect(tapCount, equals(1));
    });

    testWidgets('cooldown indicator suppresses taps', (tester) async {
      final cooldown = ValueNotifier<bool>(true);
      int tapCount = 0;

      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'Button',
          isCooldown: cooldown,
          onTap: () => tapCount++,
        ),
      );

      // Use bounded pump() instead of pumpAndSettle() due to infinite animation.
      await tester.tap(find.byType(LayrzButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tapCount, equals(0));

      // Disable cooldown.
      cooldown.value = false;
      await tester.pump();

      // Now taps should work.
      await tester.tap(find.byType(LayrzButton));
      await tester.pump();

      expect(tapCount, equals(1));
    });
  });
}
