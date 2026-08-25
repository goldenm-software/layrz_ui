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

/// Counts every `didPop` notification the navigator hosting the shell
/// receives, so the regression below can assert on the exact pop count
/// rather than on the sheet's own visibility (which is indistinguishable
/// before and after the fix — see the test file's doc comment).
class _PopCountingObserver extends NavigatorObserver {
  /// Number of `didPop` calls observed so far.
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
  }
}

/// Pumps a [LayrzScaffoldShell] inside a real [LayrzApp] (so the shell has a
/// genuine [Navigator] ancestor to push the narrow detail sheet onto), wired
/// to [observer] so pops on that navigator can be counted.
Future<void> _pumpShellApp(
  WidgetTester tester, {
  required LayrzScaffoldController controller,
  required List<LayrzScaffoldItem<_TestItem>> items,
  required NavigatorObserver observer,
  Size size = const Size(520, 900),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    LayrzApp(
      navigatorObservers: [observer],
      theme: LayrzThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: SizedBox.expand(
        child: LayrzScaffoldShell<_TestItem>(
          controller: controller,
          items: items,
          onDetailsBuild: (item) => Text("detail:${item.name}"),
          itemExtent: 56.0,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group("LayrzScaffoldShell narrow detail sheet dismissal (shell-double-pop)", () {
    // REGRESSION for the shell-double-pop defect: closing the narrow detail
    // sheet — by barrier tap or by dragging it down — must pop exactly once.
    //
    // A test that only asserts the sheet's content is gone would pass both
    // before and after the fix, because in both cases the sheet does
    // disappear (dismissing it is never in question). The actual defect is
    // an *extra* pop landing on the route underneath, which throws
    // "You have popped the last page off of the stack" once that route is
    // the app's only page. Counting pops via a NavigatorObserver is the only
    // way to see the difference.
    late LayrzScaffoldController controller;
    late _PopCountingObserver observer;
    late List<LayrzScaffoldItem<_TestItem>> items;

    setUp(() {
      controller = LayrzScaffoldController();
      observer = _PopCountingObserver();
      items = [
        const LayrzScaffoldItem(
          key: ValueKey("1"),
          item: _TestItem("1", "Alpha"),
          tile: SizedBox(child: Text("Alpha")),
          searchableStrings: {"Alpha"},
        ),
      ];
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets("barrier tap dismissal pops exactly once and throws nothing", (tester) async {
      await _pumpShellApp(tester, controller: controller, items: items, observer: observer);

      controller.open(const ValueKey("1"));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text("detail:Alpha"), findsOneWidget);

      // A point visibly above the sheet's own content, so it lands on the barrier.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text("detail:Alpha"), findsNothing);
      expect(
        observer.pops,
        equals(1),
        reason: "dismissing the sheet must pop only the sheet's own route, never the route underneath",
      );
    });

    testWidgets("drag-to-dismiss pops exactly once and throws nothing", (tester) async {
      await _pumpShellApp(tester, controller: controller, items: items, observer: observer);

      controller.open(const ValueKey("1"));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text("detail:Alpha"), findsOneWidget);

      final handle = find.byWidgetPredicate(
        (widget) => widget is Container && widget.constraints?.maxWidth == 40 && widget.constraints?.maxHeight == 4,
      );
      expect(handle, findsOneWidget);

      // The default snap points are [0.5, 0.95] with minSize 0.25. Dragging well
      // past the low end dismisses the sheet on release.
      await tester.drag(handle, const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text("detail:Alpha"), findsNothing);
      expect(
        observer.pops,
        equals(1),
        reason: "dismissing the sheet must pop only the sheet's own route, never the route underneath",
      );
    });
  });
}
