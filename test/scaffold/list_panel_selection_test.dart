import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_selection_registrar.dart';
import '../helpers/pump_themed.dart';

/// Minimal domain object used to drive [LayrzScaffoldShell]'s empty state.
class _TestItem {
  const _TestItem(this.id, this.name);

  final String id;
  final String name;
}

void main() {
  group('LayrzScaffoldShell list panel empty-state caption selection boundary', () {
    testWidgets(
      'the default empty-state caption sees a disabled selection registrar, not the ancestor\'s own',
      (tester) async {
        tester.view.physicalSize = const Size(1500, 950);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Open an item (keyless -- there are no items to key against) so the
        // wide split (with the list panel, and this test's empty-state
        // caption) renders instead of the desktop default table.
        final controller = LayrzScaffoldController()..open(builder: (_) => const Text('detail'));
        addTearDown(controller.dispose);
        final tableController = LayrzTableController<_TestItem>();
        addTearDown(tableController.dispose);

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: SizedBox.expand(
              child: LayrzScaffoldShell<_TestItem>(
                controller: controller,
                items: const <LayrzScaffoldItem<_TestItem>>[],
                itemExtent: 56.0,
                title: const Text('Title'),
                tableColumns: [
                  LayrzColumn<_TestItem>(
                    key: const ValueKey('c'),
                    headerText: 'C',
                    valueBuilder: (item) => '',
                    width: 200,
                  ),
                ],
                tableController: tableController,
              ),
            ),
          ),
        );

        final captionContext = tester.element(find.text('No items'));

        expect(SelectionContainer.maybeOf(captionContext), isNull);
      },
    );

    testWidgets(
      'structural: the empty-state caption has a SelectionContainer ancestor',
      (tester) async {
        tester.view.physicalSize = const Size(1500, 950);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Open an item (keyless -- there are no items to key against) so the
        // wide split (with the list panel, and this test's empty-state
        // caption) renders instead of the desktop default table.
        final controller = LayrzScaffoldController()..open(builder: (_) => const Text('detail'));
        addTearDown(controller.dispose);
        final tableController = LayrzTableController<_TestItem>();
        addTearDown(tableController.dispose);

        await pumpThemed(
          tester,
          SizedBox.expand(
            child: LayrzScaffoldShell<_TestItem>(
              controller: controller,
              items: const <LayrzScaffoldItem<_TestItem>>[],
              itemExtent: 56.0,
              title: const Text('Title'),
              tableColumns: [
                LayrzColumn<_TestItem>(
                  key: const ValueKey('c'),
                  headerText: 'C',
                  valueBuilder: (item) => '',
                  width: 200,
                ),
              ],
              tableController: tableController,
            ),
          ),
        );

        expect(
          find.ancestor(of: find.text('No items'), matching: find.byType(SelectionContainer)),
          findsOneWidget,
        );
      },
    );
  });
}
