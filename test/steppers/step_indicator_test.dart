import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/steppers/src/step_indicator.dart';
import 'package:layrz_ui/src/steppers/src/stepper_state.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzStepIndicator', () {
    testWidgets('completed state always renders the checkmark, never a caller icon', (tester) async {
      await pumpThemed(
        tester,
        const LayrzStepIndicator(
          index: 0,
          state: LayrzStepperState.completed,
          icon: MdiIcons.creditCard,
        ),
      );

      expect(
        find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.check),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.creditCard),
        findsNothing,
      );
    });

    testWidgets('error state always renders the alert glyph, never a caller icon', (tester) async {
      await pumpThemed(
        tester,
        const LayrzStepIndicator(
          index: 0,
          state: LayrzStepperState.error,
          icon: MdiIcons.creditCard,
        ),
      );

      expect(
        find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.alertCircle),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.creditCard),
        findsNothing,
      );
    });

    testWidgets('completed state with no caller icon still renders the checkmark', (tester) async {
      await pumpThemed(
        tester,
        const LayrzStepIndicator(
          index: 2,
          state: LayrzStepperState.completed,
        ),
      );

      expect(
        find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.check),
        findsOneWidget,
      );
      // No step number text should appear for a completed step.
      expect(find.text('3'), findsNothing);
    });

    testWidgets('error state with no caller icon still renders the alert glyph', (tester) async {
      await pumpThemed(
        tester,
        const LayrzStepIndicator(
          index: 1,
          state: LayrzStepperState.error,
        ),
      );

      expect(
        find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.alertCircle),
        findsOneWidget,
      );
      expect(find.text('2'), findsNothing);
    });

    testWidgets('active state with a caller icon renders that icon, not the step number', (tester) async {
      await pumpThemed(
        tester,
        const LayrzStepIndicator(
          index: 0,
          state: LayrzStepperState.active,
          icon: MdiIcons.creditCard,
        ),
      );

      expect(
        find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.creditCard),
        findsOneWidget,
      );
      expect(find.text('1'), findsNothing);
    });

    testWidgets('upcoming state with a caller icon renders that icon, not the step number', (tester) async {
      await pumpThemed(
        tester,
        const LayrzStepIndicator(
          index: 3,
          state: LayrzStepperState.upcoming,
          icon: MdiIcons.truck,
        ),
      );

      expect(
        find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.truck),
        findsOneWidget,
      );
      expect(find.text('4'), findsNothing);
    });

    testWidgets('active state with null icon renders the 1-based step number', (tester) async {
      await pumpThemed(
        tester,
        const LayrzStepIndicator(
          index: 0,
          state: LayrzStepperState.active,
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('upcoming state with null icon renders the 1-based step number', (tester) async {
      await pumpThemed(
        tester,
        const LayrzStepIndicator(
          index: 4,
          state: LayrzStepperState.upcoming,
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('upcoming state renders a divider-coloured border', (tester) async {
      await pumpThemed(
        tester,
        const LayrzStepIndicator(
          index: 0,
          state: LayrzStepperState.upcoming,
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.border, isNotNull);
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('active, completed and error states render no border', (tester) async {
      for (final state in [
        LayrzStepperState.active,
        LayrzStepperState.completed,
        LayrzStepperState.error,
      ]) {
        await pumpThemed(
          tester,
          LayrzStepIndicator(index: 0, state: state),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration! as BoxDecoration;

        expect(decoration.border, isNull, reason: 'state $state should render no border');
      }
    });

    testWidgets('renders a fixed-size circle regardless of content', (tester) async {
      await pumpThemed(
        tester,
        const LayrzStepIndicator(
          index: 0,
          state: LayrzStepperState.active,
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));

      expect(container.constraints?.maxWidth ?? kLayrzStepIndicatorSize, kLayrzStepIndicatorSize);
      expect(container.constraints?.maxHeight ?? kLayrzStepIndicatorSize, kLayrzStepIndicatorSize);
    });
  });
}
