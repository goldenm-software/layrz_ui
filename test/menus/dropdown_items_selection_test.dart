import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_selection_registrar.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzDropdownLabel selection boundary', () {
    testWidgets(
      'the section header label sees a disabled selection registrar, not the ancestor\'s own',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: LayrzDropdownLabel(labelText: 'Section'),
          ),
        );

        final labelContext = tester.element(find.text('Section'));

        expect(SelectionContainer.maybeOf(labelContext), isNull);
      },
    );

    testWidgets(
      'structural: the section header label has a SelectionContainer ancestor',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzDropdownLabel(labelText: 'Structural Section'),
        );

        expect(
          find.ancestor(of: find.text('Structural Section'), matching: find.byType(SelectionContainer)),
          findsOneWidget,
        );
      },
    );
  });

  group('LayrzDropdownEntry selection boundary', () {
    testWidgets(
      'the entry label and shortcut see a disabled selection registrar, not the ancestor\'s own',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // The shortcut text is hidden on LayrzPlatform.isMobile, and
        // flutter_test's defaultTargetPlatform defaults to Android -- force
        // a desktop platform so the shortcut actually renders. Reset at the
        // end of the test body: debugAssertAllFoundationVarsUnset runs
        // before a tearDown callback registered mid-test would fire.
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: LayrzDropdownEntry(
              labelText: 'Entry label',
              onTap: () {},
              shortcut: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS},
            ),
          ),
        );

        final labelContext = tester.element(find.text('Entry label'));
        final shortcutFinder = find.byWidgetPredicate(
          (widget) => widget is Text && widget.data != null && widget.data != 'Entry label',
        );
        expect(shortcutFinder, findsOneWidget);
        final shortcutContext = tester.element(shortcutFinder);

        expect(SelectionContainer.maybeOf(labelContext), isNull);
        expect(SelectionContainer.maybeOf(shortcutContext), isNull);

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'structural: the entry label has a SelectionContainer ancestor',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzDropdownEntry(
            labelText: 'Structural entry',
            onTap: () {},
          ),
        );

        expect(
          find.ancestor(of: find.text('Structural entry'), matching: find.byType(SelectionContainer)),
          findsOneWidget,
        );
      },
    );
  });
}
