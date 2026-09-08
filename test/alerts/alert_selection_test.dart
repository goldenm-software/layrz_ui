import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_selection_registrar.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzAlert title/description selection boundary', () {
    testWidgets(
      'title: a disabled selection registrar shadows an enabled ancestor',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: const SizedBox(
              width: 320,
              child: LayrzAlert(
                title: 'Chrome title',
                description: 'Selectable description content',
              ),
            ),
          ),
        );

        final titleContext = tester.element(find.text('Chrome title'));

        // The alert's own SelectionContainer.disabled around the title
        // shadows the enabled ancestor registrar above.
        expect(SelectionContainer.maybeOf(titleContext), isNull);
      },
    );

    testWidgets(
      'regression: the description stays selectable -- no disabled boundary from the alert itself',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final delegate = TestSelectionContainerDelegate();

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: delegate,
            child: const SizedBox(
              width: 320,
              child: LayrzAlert(
                title: 'Chrome title',
                description: 'Selectable description content',
              ),
            ),
          ),
        );

        final descriptionContext = tester.element(find.text('Selectable description content'));

        // Unlike the title above, the description carries no
        // SelectionContainer.disabled boundary of its own -- it resolves to
        // the SAME enabled ancestor's delegate-as-registrar constructed
        // above, proving the title-only decision (DESIGN-135) is honoured.
        final resolved = SelectionContainer.maybeOf(descriptionContext);
        expect(resolved, isNotNull);
        expect(resolved, same(delegate));
      },
    );

    testWidgets(
      'structural: the title Text has a SelectionContainer ancestor, the description does not gain one',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          const SizedBox(
            width: 320,
            child: LayrzAlert(
              title: 'Structural title',
              description: 'Structural description',
            ),
          ),
        );

        expect(
          find.ancestor(of: find.text('Structural title'), matching: find.byType(SelectionContainer)),
          findsOneWidget,
        );
        expect(
          find.ancestor(of: find.text('Structural description'), matching: find.byType(SelectionContainer)),
          findsNothing,
        );
      },
    );
  });
}
