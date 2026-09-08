import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_selection_registrar.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzChip label selection boundary', () {
    testWidgets(
      'a BuildContext below the chip label sees a disabled selection registrar, not the ancestor\'s own',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: const LayrzChip(labelText: 'Active'),
          ),
        );

        final labelContext = tester.element(find.text('Active'));

        expect(SelectionContainer.maybeOf(labelContext), isNull);
      },
    );

    testWidgets(
      'structural: the label Text has a SelectionContainer ancestor',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          const LayrzChip(labelText: 'Structural'),
        );

        final labelFinder = find.text('Structural');

        expect(
          find.ancestor(of: labelFinder, matching: find.byType(SelectionContainer)),
          findsOneWidget,
        );
      },
    );
  });
}
