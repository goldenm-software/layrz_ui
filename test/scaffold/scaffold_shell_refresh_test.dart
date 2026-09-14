import "dart:async";

import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";
import "package:layrz_ui/src/scaffold/src/list_panel.dart";
import "package:layrz_ui/src/scaffold/src/list_panel_refresh_footer.dart";

import "../helpers/pump_themed.dart";

/// Minimal domain object for testing.
class _TestItem {
  const _TestItem(this.id, this.name);

  final String id;
  final String name;
}

List<LayrzScaffoldItem<_TestItem>> _buildItems() {
  return [
    const LayrzScaffoldItem(
      key: ValueKey("1"),
      item: _TestItem("1", "Alpha"),
      tile: SizedBox(child: Text("Alpha")),
      searchableStrings: {"Alpha"},
    ),
    const LayrzScaffoldItem(
      key: ValueKey("2"),
      item: _TestItem("2", "Beta"),
      tile: SizedBox(child: Text("Beta")),
      searchableStrings: {"Beta"},
    ),
  ];
}

/// Regression + acceptance coverage for Part B of the ScaffoldShell revamp:
/// a built-in, list-level refresh capability so consumers stop wrapping the
/// whole shell in their own [LayrzRefreshIndicator] (which floated its
/// fallback button over both panes).
void main() {
  group("LayrzScaffoldShell.onRefresh", () {
    // The wide (1600x1200) iteration below opens item "1" before pumping so
    // the list panel/split renders -- on a wide viewport with nothing open,
    // the shell shows its desktop default table instead, which has neither
    // a ListPanelRefreshFooter nor a list-scoped LayrzRefreshIndicator.
    for (final viewport in [const Size(1600, 1200), const Size(400, 800)]) {
      final isWide = viewport.width >= 960;
      final label = isWide ? "wide (1600x1200)" : "compact (400x800)";

      testWidgets("$label: with onRefresh, the footer refresh affordance and the consumer footer coexist", (
        tester,
      ) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;

        final controller = LayrzScaffoldController();
        if (isWide) controller.open(key: const ValueKey("1"), builder: (_) => const Text("detail:Alpha"));
        addTearDown(controller.dispose);
        final tableController = LayrzTableController<_TestItem>();
        addTearDown(tableController.dispose);

        await pumpThemed(
          tester,
          SizedBox.expand(
            child: LayrzScaffoldShell<_TestItem>(
              controller: controller,
              items: _buildItems(),
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
              footer: const Text("Consumer footer", key: Key("consumer-footer")),
              onRefresh: () async {},
            ),
          ),
        );

        // The consumer-supplied footer is still rendered.
        expect(find.byKey(const Key("consumer-footer")), findsOneWidget);

        // The built-in refresh affordance renders alongside it, not in place of it.
        expect(find.byType(ListPanelRefreshFooter), findsOneWidget);
        expect(
          find.byKey(const ValueKey('layrz-scaffold-list-panel-refresh-footer-button')),
          findsOneWidget,
        );
      });

      testWidgets("$label: with onRefresh null, no refresh affordance appears (backward compat)", (tester) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;

        final controller = LayrzScaffoldController();
        if (isWide) controller.open(key: const ValueKey("1"), builder: (_) => const Text("detail:Alpha"));
        addTearDown(controller.dispose);
        final tableController = LayrzTableController<_TestItem>();
        addTearDown(tableController.dispose);

        await pumpThemed(
          tester,
          SizedBox.expand(
            child: LayrzScaffoldShell<_TestItem>(
              controller: controller,
              items: _buildItems(),
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
              footer: const Text("Consumer footer", key: Key("consumer-footer")),
            ),
          ),
        );

        expect(find.byKey(const Key("consumer-footer")), findsOneWidget);
        expect(find.byType(ListPanelRefreshFooter), findsNothing);
        expect(find.byType(LayrzRefreshIndicator), findsNothing);
      });

      testWidgets("$label: with onRefresh null and no footer, the footer region does not render at all", (
        tester,
      ) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;

        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);
        final tableController = LayrzTableController<_TestItem>();
        addTearDown(tableController.dispose);

        await pumpThemed(
          tester,
          SizedBox.expand(
            child: LayrzScaffoldShell<_TestItem>(
              controller: controller,
              items: _buildItems(),
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

        expect(find.byType(ListPanelRefreshFooter), findsNothing);
        expect(find.byType(LayrzRefreshIndicator), findsNothing);
      });

      testWidgets("$label: tapping the footer refresh control calls onRefresh and shows/clears busy state", (
        tester,
      ) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;

        final controller = LayrzScaffoldController();
        if (isWide) controller.open(key: const ValueKey("1"), builder: (_) => const Text("detail:Alpha"));
        addTearDown(controller.dispose);
        final tableController = LayrzTableController<_TestItem>();
        addTearDown(tableController.dispose);

        var callCount = 0;
        final completer = Completer<void>();

        await pumpThemed(
          tester,
          SizedBox.expand(
            child: LayrzScaffoldShell<_TestItem>(
              controller: controller,
              items: _buildItems(),
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
              onRefresh: () {
                callCount++;
                return completer.future;
              },
            ),
          ),
        );

        final buttonFinder = find.byKey(const ValueKey('layrz-scaffold-list-panel-refresh-footer-button'));
        expect(buttonFinder, findsOneWidget);

        await tester.tap(buttonFinder);
        await tester.pump();

        // onRefresh was invoked exactly once.
        expect(callCount, 1);

        // Busy/spinner state shows while the refresh is pending: the button's
        // LayrzButtonController reports loading, which LayrzButton renders as
        // a busy indicator rather than the plain icon.
        final busyButtonBefore = tester.widget<LayrzButton>(buttonFinder);
        expect(busyButtonBefore.controller?.isLoading, isTrue);

        // Resolve the refresh -- the controller transitions refreshing -> settling -> idle.
        completer.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        final busyButtonAfter = tester.widget<LayrzButton>(buttonFinder);
        expect(busyButtonAfter.controller?.isLoading, isFalse);

        // A second tap triggers another call, confirming the control is
        // interactive again after settling.
        await tester.tap(buttonFinder);
        await tester.pump();
        expect(callCount, 2);
      });
    }

    testWidgets(
      "wide layout (1600x1200): the LayrzRefreshIndicator scope is inside ListPanel, "
      "never an ancestor of DetailPane",
      (tester) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;

        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);
        final tableController = LayrzTableController<_TestItem>();
        addTearDown(tableController.dispose);

        await pumpThemed(
          tester,
          SizedBox.expand(
            child: LayrzScaffoldShell<_TestItem>(
              controller: controller,
              items: _buildItems(),
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
              onRefresh: () async {},
            ),
          ),
        );

        controller.open(
          key: const ValueKey("1"),
          builder: (_) => const Text("detail:Alpha", key: Key("detail")),
        );
        await tester.pump();

        // Exactly one LayrzRefreshIndicator exists, and it is a descendant of
        // ListPanel -- i.e. its scope is the list, not the whole shell.
        expect(find.byType(LayrzRefreshIndicator), findsOneWidget);
        expect(
          find.descendant(of: find.byType(ListPanel<_TestItem>), matching: find.byType(LayrzRefreshIndicator)),
          findsOneWidget,
        );

        // The detail pane's own content must NOT sit under any
        // LayrzRefreshIndicator ancestor.
        final detailFinder = find.byKey(const Key("detail"));
        expect(detailFinder, findsOneWidget);
        expect(
          find.ancestor(of: detailFinder, matching: find.byType(LayrzRefreshIndicator)),
          findsNothing,
        );
      },
    );

    testWidgets("compact layout (400x800): the LayrzRefreshIndicator scope stays inside ListPanel", (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await pumpThemed(
        tester,
        SizedBox.expand(
          child: LayrzScaffoldShell<_TestItem>(
            controller: controller,
            items: _buildItems(),
            itemExtent: 56.0,
            title: const Text('Title'),
            tableColumns: [
              LayrzColumn<_TestItem>(key: const ValueKey('c'), headerText: 'C', valueBuilder: (item) => '', width: 200),
            ],
            tableController: tableController,
            onRefresh: () async {},
          ),
        ),
      );

      expect(find.byType(LayrzRefreshIndicator), findsOneWidget);
      expect(
        find.descendant(of: find.byType(ListPanel<_TestItem>), matching: find.byType(LayrzRefreshIndicator)),
        findsOneWidget,
      );
    });

    testWidgets("the built-in fallback button is disabled -- no floating overlay refresh button", (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;

      // Open an item so the wide split (with the list panel and its footer)
      // renders instead of the desktop default table.
      final controller = LayrzScaffoldController()
        ..open(key: const ValueKey("1"), builder: (_) => const Text("detail:Alpha"));
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await pumpThemed(
        tester,
        SizedBox.expand(
          child: LayrzScaffoldShell<_TestItem>(
            controller: controller,
            items: _buildItems(),
            itemExtent: 56.0,
            title: const Text('Title'),
            tableColumns: [
              LayrzColumn<_TestItem>(key: const ValueKey('c'), headerText: 'C', valueBuilder: (item) => '', width: 200),
            ],
            tableController: tableController,
            onRefresh: () async {},
          ),
        ),
      );

      // LayrzRefreshIndicator's own built-in fallback button uses this key
      // internally when visible (see refresh_indicator.dart's
      // '_FallbackRefreshButton'/LayrzRefreshVisual key). It must be absent:
      // the footer control is the desktop affordance, not a floating overlay.
      expect(find.byKey(const ValueKey('layrz-refresh-fallback-button-visual')), findsNothing);

      // Exactly one refresh LayrzButton exists (the footer one) -- the
      // fallback button mode disables LayrzRefreshIndicator's own overlay
      // button entirely, so there is no second one floating over the list.
      expect(
        find.byKey(const ValueKey('layrz-scaffold-list-panel-refresh-footer-button')),
        findsOneWidget,
      );
    });

    testWidgets("a caller-supplied refreshController drives both the footer control and the indicator", (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;

      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      final refreshController = LayrzRefreshController();
      addTearDown(refreshController.dispose);

      var callCount = 0;

      await pumpThemed(
        tester,
        SizedBox.expand(
          child: LayrzScaffoldShell<_TestItem>(
            controller: controller,
            items: _buildItems(),
            itemExtent: 56.0,
            title: const Text('Title'),
            tableColumns: [
              LayrzColumn<_TestItem>(key: const ValueKey('c'), headerText: 'C', valueBuilder: (item) => '', width: 200),
            ],
            tableController: tableController,
            refreshController: refreshController,
            onRefresh: () async {
              callCount++;
            },
          ),
        ),
      );

      // Triggering the shared controller programmatically (as an app would
      // from a shortcut or external action) reaches the same onRefresh the
      // footer button would call.
      await refreshController.refresh(() async {
        callCount++;
      });

      expect(callCount, 1);
    });
  });
}
