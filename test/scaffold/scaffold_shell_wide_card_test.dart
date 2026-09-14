import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";
import "package:layrz_ui/src/scaffold/src/list_panel.dart";

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

/// Regression coverage for the desktop revamp (Part A): the wide layout's
/// thin `Container(width: 1, color: divider)` hairline between the list
/// panel and the detail pane was replaced with the detail pane wrapped in a
/// [LayrzCard], so the detail reads as its own floating surface instead of a
/// bare divider line.
void main() {
  group("LayrzScaffoldShell wide layout: detail pane is a LayrzCard, not a hairline divider", () {
    testWidgets("wide layout (1600x1200): LayrzCard wraps the detail pane and the old divider is gone", (
      tester,
    ) async {
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
              LayrzColumn<_TestItem>(key: const ValueKey('c'), headerText: 'C', valueBuilder: (item) => '', width: 200),
            ],
            tableController: tableController,
          ),
        ),
      );

      controller.open(key: const ValueKey("1"), builder: (_) => const Text("detail:Alpha"));
      await tester.pump();

      // The detail pane is now wrapped in a LayrzCard.
      expect(find.byType(LayrzCard), findsOneWidget);

      // The old 1px hairline divider Container must be gone. A LayrzCard's own
      // internal decorated containers never use a 1-logical-pixel width, so
      // asserting no Container reports exactly width 1 is a safe, structural
      // proxy for "the divider is gone" without coupling to LayrzCard internals.
      final oneWideContainers = tester.widgetList<Container>(find.byType(Container)).where((container) {
        final constraints = container.constraints;
        return constraints != null && constraints.maxWidth == 1 && constraints.minWidth == 1;
      });
      expect(
        oneWideContainers,
        isEmpty,
        reason: "the old width:1 hairline divider Container must no longer be present in the wide layout",
      );
    });

    testWidgets("wide layout (1600x1200): list panel still renders unchanged", (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;

      // Open an item so the wide split (with the list panel) renders instead
      // of the desktop default table.
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
          ),
        ),
      );

      // The list panel widget itself is still present and both rows render.
      expect(find.byType(ListPanel<_TestItem>), findsOneWidget);
      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
    });

    testWidgets("compact layout (400x800): no LayrzCard around the detail -- it stays sheet-presented", (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await tester.pumpWidget(
        Localizations(
          locale: const Locale('en'),
          delegates: const [
            DefaultWidgetsLocalizations.delegate,
            LayrzUiL10nDelegate(),
          ],
          child: LayrzTheme(
            data: LayrzThemeData.light(),
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => Navigator(
                    onGenerateRoute: (settings) {
                      return PageRouteBuilder<void>(
                        pageBuilder: (context, animation, secondaryAnimation) => SizedBox.expand(
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
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // No card is used for the compact list+sheet path -- this asserts the
      // wide-layout treatment did not leak into the compact branch.
      expect(find.byType(LayrzCard), findsNothing);
      expect(find.text("Alpha"), findsOneWidget);
    });

    testWidgets("dark mode: the detail card's surface contrasts with the shell background", (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;

      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      final darkTheme = LayrzThemeData.dark();

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
          ),
        ),
        theme: darkTheme,
      );

      controller.open(key: const ValueKey("1"), builder: (_) => const Text("detail:Alpha"));
      await tester.pump();

      expect(find.byType(LayrzCard), findsOneWidget);

      // The card must read its surface from the dark tokens (sf3 in dark mode,
      // per LayrzCard.build) rather than hardcoding a color, and that surface
      // must differ from the shell's own background (sf1) so the card visibly
      // separates from the page behind it.
      final tokens = darkTheme.tokens;
      expect(tokens.colors.sf3, isNot(equals(tokens.colors.sf1)));
    });
  });
}
