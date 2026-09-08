import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_selection_registrar.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTooltip content selection boundary', () {
    testWidgets(
      'a BuildContext below the tooltip title/content sees a disabled selection registrar, not the ancestor\'s own',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: LayrzTooltip(
              titleText: 'Tooltip title',
              contentText: 'Tooltip content',
              child: SizedBox(
                key: const ValueKey('anchor'),
                width: 50,
                height: 50,
                child: const Text('anchor'),
              ),
            ),
          ),
        );

        await tester.longPress(find.byKey(const ValueKey('anchor')));
        await tester.pumpAndSettle();

        final titleContext = tester.element(find.text('Tooltip title'));
        final contentContext = tester.element(find.text('Tooltip content'));

        // Each disabled scope shadows the enabled ancestor registrar above,
        // proving the boundary actually blocks selection sweep rather than
        // merely being absent because nothing else provides one.
        expect(SelectionContainer.maybeOf(titleContext), isNull);
        expect(SelectionContainer.maybeOf(contentContext), isNull);
      },
    );

    testWidgets(
      'structural: title and content Text widgets have a SelectionContainer ancestor',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzTooltip(
            titleText: 'Structural title',
            contentText: 'Structural content',
            child: SizedBox(
              key: const ValueKey('anchor-structural'),
              width: 50,
              height: 50,
              child: const Text('anchor'),
            ),
          ),
        );

        await tester.longPress(find.byKey(const ValueKey('anchor-structural')));
        await tester.pumpAndSettle();

        expect(
          find.ancestor(of: find.text('Structural title'), matching: find.byType(SelectionContainer)),
          findsOneWidget,
        );
        expect(
          find.ancestor(of: find.text('Structural content'), matching: find.byType(SelectionContainer)),
          findsOneWidget,
        );
      },
    );
  });
}
