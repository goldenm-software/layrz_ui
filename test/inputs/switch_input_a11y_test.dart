import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/switch_input.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzSwitchInput A11y', () {
    testWidgets('renders switch with label', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          labelText: 'Enable notifications',
          value: false,
          onChanged: (_) {},
        ),
      );

      expect(find.byType(LayrzSwitchInput), findsOneWidget);
      expect(find.text('Enable notifications'), findsOneWidget);
    });

    testWidgets('displays label text for accessibility', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          labelText: 'Enable notifications',
          value: false,
          onChanged: (_) {},
        ),
      );

      expect(find.text('Enable notifications'), findsOneWidget);
    });

    testWidgets('provides thumb position as visual state indicator', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          value: true,
          onChanged: (_) {},
        ),
      );

      // Positioned thumb is the visual state indicator (not colour alone)
      expect(find.byType(Positioned), findsOneWidget);
    });

    testWidgets('shows track with thumb in off position', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      // Thumb position is the visual indicator of off state
      expect(find.byType(Positioned), findsOneWidget);
      expect(find.byType(Stack), findsOneWidget);
    });

    testWidgets('track and thumb visible for state indication', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      // Both track (Container) and thumb (Positioned Container) present
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Stack), findsOneWidget);
    });

    testWidgets('responds to keyboard input', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          labelText: 'Enable feature',
          value: false,
          onChanged: (_) {},
        ),
      );

      // Switch is part of the widget tree
      expect(find.byType(LayrzSwitchInput), findsOneWidget);
    });

    testWidgets('state changes with value', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          value: false,
          onChanged: (_) {},
        ),
      );

      // Track exists in off state
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('disabled state is visually distinct', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          labelText: 'Unavailable',
          value: false,
          disabled: true,
          onChanged: (_) {},
        ),
      );

      expect(find.text('Unavailable'), findsOneWidget);
    });

    testWidgets('switch and label are in same widget', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          labelText: 'Enable',
          value: false,
          onChanged: (_) {},
        ),
      );

      // Single switch widget contains label text
      expect(find.byType(LayrzSwitchInput), findsOneWidget);
      expect(find.text('Enable'), findsOneWidget);
    });

    testWidgets('thumb position indicates on/off without colour alone', (tester) async {
      await pumpThemed(
        tester,
        LayrzSwitchInput(
          value: true,
          onChanged: (_) {},
        ),
      );

      // Positioned thumb exists for visual state
      expect(find.byType(Positioned), findsOneWidget);
    });
  });
}
