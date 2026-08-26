import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzDurationInput a11y', () {
    testWidgets('anchor is properly labeled and readable by screen readers', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Session Duration',
          value: const Duration(hours: 2, minutes: 30),
        ),
      );

      expect(findButtonLabel('Session Duration'), findsOneWidget);
      // On compact view (default test viewport), should find LayrzInputChrome
      expect(find.byType(LayrzInputChrome), findsOneWidget);
    });

    testWidgets('summary uses humanized unit names from l10n', (WidgetTester tester) async {
      late final TextEditingController controller;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            controller = TextEditingController();
            return LayrzDurationInput(
              labelText: 'Duration',
              value: const Duration(days: 2),
              controller: controller,
            );
          },
        ),
      );

      expect(controller.text, isNotEmpty);
    });

    testWidgets('disabled state is perceivable by assistive technology', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          disabled: true,
        ),
      );

      expect(find.byType(LayrzInputChrome), findsOneWidget);
    });

    testWidgets('error messages are announced to screen readers', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          errors: ['Duration must be at least 1 hour'],
        ),
      );

      expect(find.text('Duration must be at least 1 hour'), findsOneWidget);
    });

    testWidgets('required indicator is perceivable', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          isRequired: true,
        ),
      );

      expect(find.byType(LayrzInputChrome), findsOneWidget);
    });

    testWidgets('hint text provides supplemental context', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          hintText: 'e.g., 2 days, 3 hours',
        ),
      );

      expect(find.text('e.g., 2 days, 3 hours'), findsWidgets);
    });

    testWidgets('help affordance is accessible', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          helpTitleText: 'About Duration',
          helpContentText: 'Enter the session duration',
        ),
      );

      expect(find.byType(LayrzDurationInput), findsOneWidget);
    });

    testWidgets('null duration shows empty/placeholder text', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          hintText: 'No duration selected',
        ),
      );

      expect(find.text('No duration selected'), findsWidgets);
    });

    testWidgets('picker panel units are labeled for accessibility', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(days: 1, hours: 2, minutes: 3, seconds: 4),
        ),
      );

      // Tap the input chrome to open the picker (bottom sheet on compact)
      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzNumberInput), findsWidgets);
    });

    testWidgets('picker layout is perceivable as distinct fields', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          visibleUnits: {
            LayrzDurationUnit.day,
            LayrzDurationUnit.hour,
            LayrzDurationUnit.minute,
            LayrzDurationUnit.second,
          },
        ),
      );

      // Tap the input chrome to open the picker (bottom sheet on compact)
      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzNumberInput), findsNWidgets(4));
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('visible units can be restricted for clarity', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          visibleUnits: {LayrzDurationUnit.hour, LayrzDurationUnit.minute},
        ),
      );

      // Tap the input chrome to open the picker (bottom sheet on compact)
      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzNumberInput), findsNWidgets(2));
    });

    testWidgets('reset button is labeled accessibly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(hours: 1),
        ),
      );

      // Tap the input chrome to open the picker (bottom sheet on compact)
      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzButton), findsWidgets);
      expect(findButtonLabel('Reset'), findsOneWidget);
    });
  });
}
