import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

/// Minimal domain object used to exercise [LayrzScaffoldShell] in isolation.
class _TestItem {
  /// Creates a test item with the given [id] and [name].
  const _TestItem(this.id, this.name);

  /// Stable identifier, mirrored by the [LayrzScaffoldItem.key] used in tests.
  final String id;

  /// Display name rendered by the tile and detail builder.
  final String name;
}

/// Pumps a [LayrzScaffoldShell] inside a real [LayrzApp] (so the shell has a
/// genuine [Navigator] ancestor to push the narrow detail sheet onto), at a
/// narrow surface size so the shell picks the narrow/single-pane layout and
/// presents its detail via [LayrzBottomSheet].
Future<void> _pumpNarrowShellApp(
  WidgetTester tester, {
  required LayrzScaffoldController controller,
  required List<LayrzScaffoldItem<_TestItem>> items,
  Size size = const Size(400, 800),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final tableController = LayrzTableController<_TestItem>();
  addTearDown(tableController.dispose);

  await tester.pumpWidget(
    LayrzApp(
      theme: LayrzThemeData.light(),
      home: SizedBox.expand(
        child: LayrzScaffoldShell<_TestItem>(
          controller: controller,
          items: items,
          itemExtent: 56.0,
          title: const Text('Title'),
          tableColumns: [
            LayrzColumn<_TestItem>(key: const ValueKey('c'), headerText: 'C', valueBuilder: (item) => '', width: 200),
          ],
          tableController: tableController,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group("LayrzScaffoldShell narrow detail sheet (scrollable: false)", () {
    // END-TO-END REGRESSION for the mobile crash fixed by
    // `LayrzBottomSheet.show(..., scrollable: false, ...)` at
    // scaffold_shell.dart:709.
    //
    // Before that fix, the narrow detail sheet always wrapped its content in
    // its own SingleChildScrollView (unbounded height). A detail body using
    // `LayrzTabView(expandContent: true)` -- exactly what a real app_form
    // uses -- wraps its selected tab's content in an `Expanded`, which throws
    // "RenderFlex children have non-zero flex but incoming height
    // constraints are unbounded" under that unbounded ancestor.
    //
    // `scrollable: false` hands the sheet's content a BOUNDED height instead
    // (via the sheet's own Column(max) -> Expanded chain, using
    // PrimaryScrollController rather than wrapping in a scroll view), which
    // is what lets `LayrzTabView(expandContent: true)` lay out correctly
    // inside a detail form on mobile.
    late LayrzScaffoldController controller;

    setUp(() {
      controller = LayrzScaffoldController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets(
      "opening a detail with a LayrzTabView(expandContent: true) body does not throw an unbounded-height "
      "error, and the selected tab's content is laid out",
      (tester) async {
        addTearDown(tester.view.reset);

        const items = [
          LayrzScaffoldItem<_TestItem>(
            key: ValueKey("1"),
            item: _TestItem("1", "Alpha"),
            tile: SizedBox(child: Text("Alpha")),
            searchableStrings: {"Alpha"},
          ),
        ];

        await _pumpNarrowShellApp(tester, controller: controller, items: items);

        // Mirrors a real app_form detail builder: a LayrzDetailScaffold whose
        // body is a LayrzTabView with the default expandContent: true.
        controller.open(
          key: const ValueKey("1"),
          builder: (_) => LayrzDetailScaffold(
            title: const Text("Alpha detail", key: Key("detail-title")),
            body: LayrzTabView(
              expandContent: true,
              tabs: [
                LayrzTab(
                  labelText: "General",
                  child: const Text("General tab content", key: Key("general-tab-content")),
                ),
                LayrzTab(
                  labelText: "Advanced",
                  child: const Text("Advanced tab content", key: Key("advanced-tab-content")),
                ),
              ],
            ),
            actions: [
              LayrzButton(labelText: "Save", key: const Key("detail-save"), onTap: () {}),
            ],
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        // No "RenderFlex ... incoming height constraints are unbounded" (or
        // any other) exception was thrown while presenting the sheet.
        expect(tester.takeException(), isNull);

        // The sheet's content, including the pinned title and actions, is
        // present.
        expect(find.byKey(const Key("detail-title")), findsOneWidget);
        expect(find.byKey(const Key("detail-save")), findsOneWidget);

        // The substantive assertion: the selected tab's content is genuinely
        // laid out (not merely present in the widget tree without size) --
        // proof LayrzTabView's inner Expanded received a real bounded height
        // rather than throwing before ever reaching this point.
        expect(find.byKey(const Key("general-tab-content")), findsOneWidget);
        expect(find.text("General tab content"), findsOneWidget);
        final contentSize = tester.getSize(find.byKey(const Key("general-tab-content")));
        expect(contentSize.width, greaterThan(0));
        expect(contentSize.height, greaterThan(0));
      },
    );
  });
}
