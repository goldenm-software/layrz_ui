import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTreeView', () {
    guardedTestWidgets('is self-scrolling: wraps the sliver form in its own CustomScrollView', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 400,
          height: 400,
          child: LayrzTreeView<String>(
            nodes: const [
              LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
              LayrzTreeNode<String>(id: 'b', content: 'Beta'),
            ],
          ),
        ),
      );

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(LayrzSliverTreeView<String>), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    guardedTestWidgets('forwards selectable and onSelectionChanged to the sliver form', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Set<Object> lastSelection = {};

      await pumpThemed(
        tester,
        SizedBox(
          width: 400,
          height: 400,
          child: LayrzTreeView<String>(
            nodes: const [LayrzTreeNode<String>(id: 'a', content: 'Alpha')],
            selectable: true,
            onSelectionChanged: (ids) => lastSelection = ids,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTappable));
      await tester.pump();

      expect(lastSelection, {'a'});
    });

    guardedTestWidgets('applies the supplied padding around the tree content', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 400,
          height: 400,
          child: LayrzTreeView<String>(
            nodes: const [LayrzTreeNode<String>(id: 'a', content: 'Alpha')],
            padding: const EdgeInsets.all(12),
          ),
        ),
      );

      final sliverPadding = tester.widget<SliverPadding>(find.byType(SliverPadding));
      expect(sliverPadding.padding, const EdgeInsets.all(12));
    });
  });
}
