import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_selection_registrar.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzStepIndicator step number selection boundary', () {
    testWidgets(
      'a BuildContext below the step number sees a disabled selection registrar, not the ancestor\'s own',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: const LayrzStepIndicator(
              index: 0,
              state: LayrzStepperState.upcoming,
            ),
          ),
        );

        final numberContext = tester.element(find.text('1'));

        expect(SelectionContainer.maybeOf(numberContext), isNull);
      },
    );
  });

  group('LayrzStepper (horizontal/wide) label selection boundary', () {
    final wideSteps = [
      const LayrzStep(labelText: 'Personal', body: SizedBox.shrink()),
      const LayrzStep(labelText: 'Shipping', body: SizedBox.shrink()),
    ];

    testWidgets(
      'the wide header step label sees a disabled selection registrar, not the ancestor\'s own',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: LayrzStepper(steps: wideSteps, direction: LayrzStepperDirection.horizontal),
          ),
        );

        final labelContext = tester.element(find.text('Personal').first);

        expect(SelectionContainer.maybeOf(labelContext), isNull);
      },
    );

    testWidgets(
      'structural: the wide label has a SelectionContainer ancestor',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzStepper(steps: wideSteps, direction: LayrzStepperDirection.horizontal),
        );

        expect(
          find.ancestor(of: find.text('Personal').first, matching: find.byType(SelectionContainer)),
          findsWidgets,
        );
      },
    );
  });

  group('LayrzStepper (vertical/compact) counter and label selection boundary', () {
    final compactSteps = [
      const LayrzStep(labelText: 'Personal', body: SizedBox.shrink()),
      const LayrzStep(labelText: 'Shipping', body: SizedBox.shrink()),
    ];

    testWidgets(
      'the persistent counter and the row label see a disabled selection registrar, not the ancestor\'s own',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: LayrzStepper(steps: compactSteps, direction: LayrzStepperDirection.vertical),
          ),
        );

        final counterContext = tester.element(find.text('Step 1 of 2'));
        final labelContext = tester.element(find.text('Personal'));

        expect(SelectionContainer.maybeOf(counterContext), isNull);
        expect(SelectionContainer.maybeOf(labelContext), isNull);
      },
    );

    testWidgets(
      'structural: the row label has a SelectionContainer ancestor',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzStepper(steps: compactSteps, direction: LayrzStepperDirection.vertical),
        );

        expect(
          find.ancestor(of: find.text('Personal'), matching: find.byType(SelectionContainer)),
          findsOneWidget,
        );
      },
    );
  });
}
