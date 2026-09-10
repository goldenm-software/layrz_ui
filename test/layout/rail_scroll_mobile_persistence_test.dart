import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

/// Regression tests for the DESIGN-213 follow-up: persisting the nav rail's
/// scroll offset on the MOBILE (drawer) presentation.
///
/// Unlike the expanded/rail presentation — where [LayrzLayoutController.railScrollController]
/// stays attached to one long-lived `SingleChildScrollView` for the whole
/// life of the layout — the drawer presentation's nav panel (and the
/// `SingleChildScrollView` inside it) is rebuilt from scratch on every
/// rebuild of `LayrzLayoutDrawerScaffold` (see that widget's `build`, which
/// invokes `drawerBuilder` directly rather than caching its result). A fresh
/// scrollable always reattaches the same [ScrollController] at offset
/// `0.0`, so without an explicit restore the drawer's nav rail would
/// silently reset to the top on every such rebuild.
///
/// [LayrzLayoutController.railScrollOffset] is the durable source of truth
/// (mirrored from the controller automatically as the user scrolls) and
/// [LayrzLayoutController.restoreRailScroll] is what jumps a freshly
/// attached scrollable back to it — `layout.dart` calls it in a post-frame
/// callback every time the drawer branch's `drawerBuilder` runs.
void main() {
  final drawerTrigger = find.byKey(const ValueKey('drawer_trigger_button'));

  group('LayrzLayoutController rail scroll offset — controller-level restore', () {
    test('railScrollOffset tracks the attached scrollable and restoreRailScroll re-jumps a new one', () {
      final controller = LayrzLayoutController();
      addTearDown(controller.dispose);

      // No client attached yet: offset defaults to 0 and restoring is a
      // harmless no-op.
      expect(controller.railScrollOffset, 0.0);
      expect(() => controller.restoreRailScroll(), returnsNormally);
    });

    testWidgets(
      'scrolling then simulating a fresh scrollable attach (as the drawer rebuild does) is restored',
      (WidgetTester tester) async {
        final controller = LayrzLayoutController();
        addTearDown(controller.dispose);

        Widget buildScrollable(Key scrollableKey) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: ListView.builder(
              key: scrollableKey,
              controller: controller.railScrollController,
              itemCount: 50,
              itemExtent: 50.0,
              itemBuilder: (context, index) => SizedBox(height: 50.0, child: Text('Item $index')),
            ),
          );
        }

        // First "attach": a scrollable standing in for the drawer's nav panel
        // scrollable on its first build.
        await tester.pumpWidget(buildScrollable(const ValueKey('scrollable_a')));
        expect(tester.takeException(), isNull);
        expect(controller.railScrollController.hasClients, isTrue);

        controller.railScrollController.jumpTo(350.0);
        await tester.pump();

        // The controller's own listener must have mirrored the scroll into
        // railScrollOffset without any explicit call.
        expect(controller.railScrollOffset, 350.0);

        // Tear down that scrollable entirely (unlike a route swap, a
        // different Key forces the old Scrollable's State — and its
        // ScrollPosition — to be disposed and a brand new one created, the
        // same way LayrzLayoutDrawerScaffold's build recreates the drawer's
        // SingleChildScrollView from scratch on every rebuild of the drawer
        // branch).
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        // Re-attach: a NEW scrollable, same ScrollController instance. A
        // fresh attach always starts at initialScrollOffset (0.0).
        await tester.pumpWidget(buildScrollable(const ValueKey('scrollable_b')));
        expect(tester.takeException(), isNull);
        expect(controller.railScrollController.hasClients, isTrue);
        expect(controller.railScrollController.offset, 0.0);

        // The saved offset must still read 350.0 -- it is independent of
        // whichever scrollable happens to be attached right now.
        expect(controller.railScrollOffset, 350.0);

        // This is exactly what layout.dart's post-frame callback does after
        // every drawer-branch rebuild.
        controller.restoreRailScroll();
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(controller.railScrollController.offset, 350.0);
      },
    );

    testWidgets('restoreRailScroll clamps to maxScrollExtent when the saved offset no longer fits', (
      WidgetTester tester,
    ) async {
      final controller = LayrzLayoutController();
      addTearDown(controller.dispose);

      Widget buildScrollable(Key scrollableKey, int itemCount) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: ListView.builder(
            key: scrollableKey,
            controller: controller.railScrollController,
            itemCount: itemCount,
            itemExtent: 50.0,
            itemBuilder: (context, index) => SizedBox(height: 50.0, child: Text('Item $index')),
          ),
        );
      }

      await tester.pumpWidget(buildScrollable(const ValueKey('long_list'), 50));
      controller.railScrollController.jumpTo(2000.0);
      await tester.pump();
      expect(controller.railScrollOffset, 2000.0);

      // Recreate with far fewer items -- the saved offset (2000.0) no
      // longer fits the new maxScrollExtent.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(buildScrollable(const ValueKey('short_list'), 3));

      expect(() => controller.restoreRailScroll(), returnsNormally);
      await tester.pump();

      final position = controller.railScrollController.position;
      expect(controller.railScrollController.offset, position.maxScrollExtent);
      expect(controller.railScrollController.offset, lessThan(2000.0));
      expect(tester.takeException(), isNull);
    });
  });

  group('LayrzLayout drawer (mobile) presentation — end-to-end rail scroll persistence', () {
    testWidgets(
      'scrolling the open drawer nav rail survives the drawer branch rebuilding',
      (WidgetTester tester) async {
        addTearDown(tester.view.reset);
        // Compact viewport (< 960px) so the layout resolves to the drawer
        // presentation.
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final controller = LayrzLayoutController();
        addTearDown(controller.dispose);

        // Enough nav items that the rail overflows the drawer's viewport
        // height and is actually scrollable.
        final items = List<LayrzNavigatorItem>.generate(
          40,
          (index) => LayrzNavigatorPage(id: 'page-$index', labelText: 'Page $index'),
        );

        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: items,
            controller: controller,
            body: const SizedBox(child: Text('Body')),
          ),
        );
        expect(tester.takeException(), isNull);

        // Open the drawer.
        await tester.tap(drawerTrigger);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        expect(controller.railScrollController.hasClients, isTrue);

        controller.railScrollController.jumpTo(150.0);
        await tester.pump();
        expect(controller.railScrollOffset, 150.0);

        // Force the drawer branch to rebuild without closing the drawer:
        // toggling the notifications-panel-adjacent controller state (a
        // setSearchQuery mutation) notifies LayrzLayout's listener, which
        // calls setState and rebuilds LayrzLayoutDrawerScaffold — and, per
        // that widget's build method, re-invokes drawerBuilder, producing a
        // brand-new LayrzLayoutNavigatorPanel/SingleChildScrollView while the
        // drawer stays open.
        controller.setSearchQuery('re-render me');
        await tester.pump();
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(controller.railScrollController.hasClients, isTrue);
        expect(controller.railScrollController.offset, 150.0);
      },
    );
  });
}
