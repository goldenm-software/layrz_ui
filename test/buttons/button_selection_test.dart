import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_selection_registrar.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzButton label selection boundary', () {
    testWidgets(
      'a BuildContext below the button label sees a disabled selection registrar, not the ancestor\'s own',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // A minimal stand-in for SelectionArea: a real, enabled
        // SelectionContainer ancestor whose registrar the button's own
        // disabled scope around its RichText label must shadow.
        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: LayrzButton(
              labelText: 'Save changes',
              onTap: () {},
            ),
          ),
        );

        final richTextFinder = find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText().contains('Save changes'),
        );
        expect(richTextFinder, findsOneWidget);

        final richTextContext = tester.element(richTextFinder);

        // The button content's own SelectionContainer.disabled shadows the
        // enabled ancestor registrar above -- proving the boundary actually
        // blocks selection sweep, not merely that no ancestor exists.
        expect(SelectionContainer.maybeOf(richTextContext), isNull);
      },
    );

    testWidgets(
      'structural: the label RichText has a SelectionContainer ancestor',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Cheap structural check',
            onTap: () {},
          ),
        );

        final richTextFinder = find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText().contains('Cheap structural check'),
        );

        expect(
          find.ancestor(of: richTextFinder, matching: find.byType(SelectionContainer)),
          findsOneWidget,
        );
      },
    );
  });
}
