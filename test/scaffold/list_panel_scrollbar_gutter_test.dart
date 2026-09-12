import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

import "../helpers/pump_themed.dart";

/// Minimal domain object for testing.
class _TestItem {
  const _TestItem(this.id, this.name);

  final String id;
  final String name;
}

/// Builds [count] plain (action-less) items, each named by its index.
List<LayrzScaffoldItem<_TestItem>> _plainItems(int count) {
  return List.generate(
    count,
    (i) => LayrzScaffoldItem<_TestItem>(
      key: ValueKey("$i"),
      item: _TestItem("$i", "Item $i"),
      tile: Text("Item $i"),
      searchableStrings: {"Item $i"},
    ),
  );
}

const _kWideSize = Size(1600, 1200);

void main() {
  group("ListPanel — scrollbar gutter (list_panel.dart padding placement)", () {
    testWidgets(
      "the ListView reserves the scrollbar gutter via its own padding, not an outer wrapper",
      (tester) async {
        addTearDown(tester.view.reset);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = _kWideSize;

        final controller = LayrzScaffoldController();
        final items = _plainItems(6);

        await pumpThemed(
          tester,
          SizedBox.expand(
            child: LayrzScaffoldShell<_TestItem>(
              controller: controller,
              items: items,
              itemExtent: 56.0,
            ),
          ),
        );
        expect(tester.takeException(), isNull);

        // The gutter must be reserved on the ListView's own `padding`, so the
        // Scrollable/Viewport (and thus the RawScrollbar LayrzScrollBehavior
        // installs inside it) keeps the panel's full content width -- only the
        // rows' sliver content is inset. Wrapping the ListView in an outer
        // Padding instead would shrink the Scrollable itself, collapsing the
        // gutter between the thumb and the row cards back to zero.
        final listView = tester.widget<ListView>(find.byType(ListView));
        expect(
          listView.padding,
          const EdgeInsets.only(right: kLayrzScrollbarThickness),
          reason: "ListView.padding must reserve the scrollbar gutter directly, inside the scroll view",
        );

        // Guard against the regression this fix corrects: no Padding ancestor
        // of the ListView may itself carry that same right inset -- that would
        // mean the gutter is (again) being reserved outside the Scrollable,
        // shrinking it and the row cards together instead of just the content.
        final listViewElement = tester.element(find.byType(ListView));
        final ancestorPaddings = <Padding>[];
        listViewElement.visitAncestorElements((ancestor) {
          if (ancestor.widget is Padding) {
            ancestorPaddings.add(ancestor.widget as Padding);
          }
          return true;
        });
        for (final padding in ancestorPaddings) {
          expect(
            padding.padding,
            isNot(const EdgeInsets.only(right: kLayrzScrollbarThickness)),
            reason: "the scrollbar gutter must not also be reserved by a Padding wrapped around the ListView",
          );
        }

        controller.dispose();
      },
    );

    testWidgets(
      "the empty state renders with no ListView and needs no scrollbar gutter",
      (tester) async {
        addTearDown(tester.view.reset);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = _kWideSize;

        final controller = LayrzScaffoldController();

        await pumpThemed(
          tester,
          SizedBox.expand(
            child: LayrzScaffoldShell<_TestItem>(
              controller: controller,
              items: const [],
              itemExtent: 56.0,
            ),
          ),
        );
        expect(tester.takeException(), isNull);

        expect(find.byType(ListView), findsNothing);

        controller.dispose();
      },
    );
  });
}
