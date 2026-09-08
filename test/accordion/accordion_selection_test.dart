import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_selection_registrar.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzAccordion selection boundary (DESIGN-135 follow-up)', () {
    testWidgets(
      'the header title sees a disabled selection registrar, not the ancestor\'s own',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: LayrzAccordion(
              titleText: 'Accordion title',
              expanded: false,
              onExpansionChanged: (_) {},
              body: const Text('Body content'),
            ),
          ),
        );

        final titleContext = tester.element(find.text('Accordion title'));

        expect(SelectionContainer.maybeOf(titleContext), isNull);
      },
    );

    testWidgets(
      'structural: the header title has a SelectionContainer ancestor',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzAccordion(
            titleText: 'Structural title',
            expanded: false,
            onExpansionChanged: (_) {},
            body: const Text('Body content'),
          ),
        );

        expect(
          find.ancestor(of: find.text('Structural title'), matching: find.byType(SelectionContainer)),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'the body (consumer-supplied child) is left selectable, not wrapped',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: LayrzAccordion(
              titleText: 'Accordion title',
              expanded: true,
              onExpansionChanged: (_) {},
              body: const Text('Selectable body'),
            ),
          ),
        );

        final bodyContext = tester.element(find.text('Selectable body'));

        // The body is consumer content: it must still see the enabled
        // ancestor SelectionContainer, unlike the header title above.
        expect(SelectionContainer.maybeOf(bodyContext), isNotNull);
      },
    );
  });
}
