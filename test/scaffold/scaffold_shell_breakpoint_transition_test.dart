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

/// Builds a single-item list keyed by `"1"`, using a fresh list *instance*
/// each call so [LayrzScaffoldShell.didUpdateWidget] observes a non-identical
/// `items` reference across rebuilds (mirroring a real refetch).
List<LayrzScaffoldItem<_TestItem>> _buildItems() {
  return [
    const LayrzScaffoldItem(
      key: ValueKey("1"),
      item: _TestItem("1", "Alpha"),
      tile: SizedBox(child: Text("Alpha")),
      searchableStrings: {"Alpha"},
    ),
  ];
}

void main() {
  group("LayrzScaffoldShell breakpoint transition (setState-during-build regression)", () {
    // REGRESSION: a mobile -> desktop resize that lands in the same pump as a
    // new `items` list instance must not crash with "setState() or
    // markNeedsBuild() called during build."
    //
    // Mechanism: with the narrow detail sheet open, its `ListenableBuilder`
    // (merging the controller and the shell's internal items-change notifier)
    // stays mounted for the sheet's exit animation. `didUpdateWidget` used to
    // bump that notifier unconditionally and synchronously, which fired
    // `notifyListeners()` -> `setState()` on that still-mounted
    // `ListenableBuilder` while the enclosing `LayoutBuilder` was itself
    // mid-rebuild from the breakpoint change. That is an illegal cross-widget
    // setState-during-build.
    testWidgets(
      "mobile -> desktop resize with a new items instance and an open sheet does not throw",
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);

        // Pin DPR before physicalSize: ambient DPR is 3.0, so a 1200-wide
        // physical size would resolve to a 400-logical (compact) surface
        // rather than the desktop band this test needs to start in.
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(500, 900); // narrow (< 960 logical)

        await tester.pumpWidget(
          LayrzApp(
            theme: LayrzThemeData.light(),
            debugShowCheckedModeBanner: false,
            home: SizedBox.expand(
              child: LayrzScaffoldShell<_TestItem>(
                controller: controller,
                items: _buildItems(),
                onDetailsBuild: (item) => Text("detail:${item.name}"),
                itemExtent: 56.0,
              ),
            ),
          ),
        );
        await tester.pump();

        // Open the detail sheet on the narrow layout.
        controller.open(const ValueKey("1"));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.text("detail:Alpha"), findsOneWidget);

        // Cross the breakpoint to desktop AND hand the shell a new `items`
        // instance in the same rebuild, while the sheet is still open/mounted.
        tester.view.physicalSize = const Size(1200, 900); // wide (>= 960 logical)
        await tester.pumpWidget(
          LayrzApp(
            theme: LayrzThemeData.light(),
            debugShowCheckedModeBanner: false,
            home: SizedBox.expand(
              child: LayrzScaffoldShell<_TestItem>(
                controller: controller,
                items: _buildItems(), // new instance, same keys
                onDetailsBuild: (item) => Text("detail:${item.name}"),
                itemExtent: 56.0,
              ),
            ),
          ),
        );

        // The offending assignment happens synchronously inside this pump's
        // build phase; a bare `pump()` is enough to surface it via
        // `tester.takeException()` without needing `pumpAndSettle()`.
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: "resizing across the breakpoint must not trigger setState-during-build",
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      "desktop -> mobile resize with a new items instance does not throw",
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);

        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1200, 900); // wide (>= 960 logical)

        await tester.pumpWidget(
          LayrzApp(
            theme: LayrzThemeData.light(),
            debugShowCheckedModeBanner: false,
            home: SizedBox.expand(
              child: LayrzScaffoldShell<_TestItem>(
                controller: controller,
                items: _buildItems(),
                onDetailsBuild: (item) => Text("detail:${item.name}"),
                itemExtent: 56.0,
              ),
            ),
          ),
        );
        await tester.pump();

        controller.open(const ValueKey("1"));
        await tester.pump();
        expect(find.text("detail:Alpha"), findsOneWidget);

        tester.view.physicalSize = const Size(500, 900); // narrow (< 960 logical)
        await tester.pumpWidget(
          LayrzApp(
            theme: LayrzThemeData.light(),
            debugShowCheckedModeBanner: false,
            home: SizedBox.expand(
              child: LayrzScaffoldShell<_TestItem>(
                controller: controller,
                items: _buildItems(), // new instance, same keys
                onDetailsBuild: (item) => Text("detail:${item.name}"),
                itemExtent: 56.0,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
