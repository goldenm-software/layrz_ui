import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzLayout - Body MediaQuery.padding.top is removed (drawer presentation)', () {
    /// A bare ListView.builder with no explicit `padding:` falls back to
    /// MediaQuery.padding for its scroll axis (SDK's ScrollView.buildSlivers,
    /// scroll_view.dart:897-925), unconditional whenever an ancestor MediaQuery exists. In
    /// the drawer presentation, the top bar consumes padding.top for itself via its own
    /// SafeArea(bottom: false) (top_bar.dart:60) — but that SafeArea only affects the top
    /// bar's own subtree, not the MediaQuery the body (a sibling) receives. Without
    /// LayrzLayoutDrawerScaffold removing padding.top from the body's MediaQuery, a bare
    /// ListView in the body double-insets by the same status-bar height the top bar already
    /// physically occupies.
    ///
    /// This only reproduces with a non-zero tester.view.padding/viewPadding — the ambient
    /// test default is zero, which is the "desktop" condition where this bug cannot occur.
    testWidgets('bare ListView body has no phantom leading inset, but keeps its trailing padding', (
      WidgetTester tester,
    ) async {
      const topInset = 40.0;
      const bottomInset = 16.0;
      const itemExtent = 50.0;
      const itemCount = 30;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      // devicePixelRatio must be pinned BEFORE physicalSize — otherwise the ambient test
      // devicePixelRatio (3.0) skews the physical->logical mapping and the forced width no
      // longer lands in the drawer/compact presentation band this test targets.
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800);
      tester.view.padding = const FakeViewPadding(top: topInset, bottom: bottomInset);
      tester.view.viewPadding = const FakeViewPadding(top: topInset, bottom: bottomInset);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: ListView.builder(
            key: const ValueKey('body_list'),
            itemCount: itemCount,
            itemBuilder: (context, index) => SizedBox(
              key: ValueKey('item_$index'),
              height: itemExtent,
              child: Text('Item $index'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listFinder = find.byKey(const ValueKey('body_list'));
      final listRect = tester.getRect(listFinder);

      final firstItemRect = tester.getRect(find.byKey(const ValueKey('item_0')));

      /// CRITICAL ASSERTION: the first item starts at the very top of the ListView's own
      /// viewport (no phantom leading inset from a double-applied padding.top). If
      /// removePadding(removeTop: true) were missing, the first item would start topInset
      /// pixels further down than this, because ListView.buildSlivers would apply the
      /// ambient MediaQuery.padding.top as a SliverPadding on top of the list's content —
      /// on top of the status-bar height the top bar already visually occupies.
      expect(
        firstItemRect.top,
        closeTo(listRect.top, 1.0),
        reason:
            'CRITICAL: the ListView\'s first item must start at the top of its own viewport '
            'with no phantom leading inset. A non-zero gap here means MediaQuery.padding.top '
            'is leaking into the body and being auto-applied by ListView.buildSlivers, '
            'double-insetting on top of the space the top bar already consumes.',
      );

      // Scroll to the bottom to verify the trailing (bottom) padding IS still delivered —
      // it must NOT be removed, since nothing upstream double-consumes it.
      await tester.drag(listFinder, const Offset(0, -10000));
      await tester.pumpAndSettle();

      final lastItemRect = tester.getRect(find.byKey(ValueKey('item_${itemCount - 1}')));

      /// CRITICAL ASSERTION: the bottom inset is still respected — the last item's bottom
      /// edge does not run flush to (or past) the ListView's own viewport bottom; the
      /// scrollable's auto-applied bottom padding from MediaQuery.padding.bottom must
      /// survive, since removePadding here only ever removes the TOP.
      expect(
        lastItemRect.bottom,
        lessThanOrEqualTo(listRect.bottom - bottomInset + 1.0),
        reason:
            'CRITICAL: MediaQuery.padding.bottom must still be delivered to the body — only '
            'padding.top is removed. The last item\'s bottom edge must clear the viewport '
            'bottom by at least the bottom inset ($bottomInset pt).',
      );
    });

    /// Guards the specific mechanism that regressed D65 during this fix: composing
    /// removeViewInsets and removePadding as two NESTED MediaQuery.removeXxx(context:
    /// context, ...) widgets is broken, because each factory independently re-reads
    /// MediaQuery.of(context) from the same outer context (neither widget is in the tree
    /// yet when that context is captured) — so the inner call silently discards whatever
    /// the outer call already removed. This asserts BOTH removals hold simultaneously:
    /// padding.top is gone (this test's own concern) AND viewInsets is zeroed (D65's
    /// concern, see layout_keyboard_insets_test.dart) at the same time, with the keyboard
    /// open. A regression to the nested-context form would fail this even though each
    /// removal passes fine on its own with viewInsets == 0 (see the test above).
    testWidgets('padding.top removal and viewInsets zeroing both hold when keyboard is open', (
      WidgetTester tester,
    ) async {
      const topInset = 40.0;
      const keyboardInset = 300.0;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      addTearDown(tester.view.resetViewInsets);

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800);
      tester.view.padding = const FakeViewPadding(top: topInset);
      tester.view.viewPadding = const FakeViewPadding(top: topInset);
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);

      EdgeInsets? observedPadding;
      EdgeInsets? observedViewInsets;

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: Builder(
            builder: (context) {
              observedPadding = MediaQuery.paddingOf(context);
              observedViewInsets = MediaQuery.viewInsetsOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        observedPadding!.top,
        equals(0.0),
        reason: 'padding.top must still be removed from the body\'s MediaQuery when the keyboard is also open.',
      );
      expect(
        observedViewInsets,
        equals(EdgeInsets.zero),
        reason:
            'viewInsets must still be zeroed for the body when padding.top is also being '
            'removed at the same time — this is the exact combination the nested-context '
            'form silently breaks.',
      );
    });
  });

  group('LayrzLayout - Body MediaQuery.padding.top is removed (expanded/rail presentation)', () {
    /// The expanded presentation arranges body and rail panel as sibling Positioned
    /// widgets in a Stack (layout.dart:_buildExpanded), not a Column with a shared top bar
    /// like the drawer presentation — but the same bug applies. The rail panel consumes
    /// its OWN padding.top via navigator_panel.dart's SafeArea(right: false), and that
    /// only affects the panel's own subtree; the body Positioned has no SafeArea or other
    /// chrome above it, so its MediaQuery.padding.top must be explicitly removed or a bare
    /// ListView.builder in the body double-insets by the same status-bar height, exactly
    /// as in the drawer presentation. Confirmed empirically: witnessed a 40.0px gap
    /// (== topInset) here before this fix, at width 1200 (expanded/rail band).
    testWidgets('bare ListView body has no phantom leading inset, but keeps its trailing padding', (
      WidgetTester tester,
    ) async {
      const topInset = 40.0;
      const bottomInset = 16.0;
      const itemExtent = 50.0;
      const itemCount = 30;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      // devicePixelRatio must be pinned BEFORE physicalSize — otherwise the ambient test
      // devicePixelRatio (3.0) skews the physical->logical mapping and the forced width no
      // longer lands in the expanded/rail presentation band this test targets.
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.padding = const FakeViewPadding(top: topInset, bottom: bottomInset);
      tester.view.viewPadding = const FakeViewPadding(top: topInset, bottom: bottomInset);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
          ],
          body: ListView.builder(
            key: const ValueKey('body_list'),
            itemCount: itemCount,
            itemBuilder: (context, index) => SizedBox(
              key: ValueKey('item_$index'),
              height: itemExtent,
              child: Text('Item $index'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listFinder = find.byKey(const ValueKey('body_list'));
      final listRect = tester.getRect(listFinder);

      final firstItemRect = tester.getRect(find.byKey(const ValueKey('item_0')));

      /// CRITICAL ASSERTION: mirrors the drawer-presentation test above, for the
      /// Stack-based expanded layout.
      expect(
        firstItemRect.top,
        closeTo(listRect.top, 1.0),
        reason:
            'CRITICAL: the ListView\'s first item must start at the top of its own viewport '
            'with no phantom leading inset, in the expanded/rail presentation too. A '
            'non-zero gap here means MediaQuery.padding.top is leaking into the body '
            'Positioned and being auto-applied by ListView.buildSlivers.',
      );

      await tester.drag(listFinder, const Offset(0, -10000));
      await tester.pumpAndSettle();

      final lastItemRect = tester.getRect(find.byKey(ValueKey('item_${itemCount - 1}')));

      /// CRITICAL ASSERTION: the bottom inset is still respected — only padding.top is
      /// removed from the body's MediaQuery.
      expect(
        lastItemRect.bottom,
        lessThanOrEqualTo(listRect.bottom - bottomInset + 1.0),
        reason:
            'CRITICAL: MediaQuery.padding.bottom must still be delivered to the body in the '
            'expanded presentation — only padding.top is removed.',
      );
    });

    /// Mirrors the combined padding+keyboard regression guard above, for the expanded
    /// presentation's body Positioned (layout.dart:265-276), which also composes
    /// removeViewInsets and removePadding via MediaQueryData chaining rather than nested
    /// context-reading factories.
    testWidgets('padding.top removal and viewInsets zeroing both hold when keyboard is open', (
      WidgetTester tester,
    ) async {
      const topInset = 40.0;
      const keyboardInset = 300.0;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      addTearDown(tester.view.resetViewInsets);

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.padding = const FakeViewPadding(top: topInset);
      tester.view.viewPadding = const FakeViewPadding(top: topInset);
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);

      EdgeInsets? observedPadding;
      EdgeInsets? observedViewInsets;

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
          ],
          body: Builder(
            builder: (context) {
              observedPadding = MediaQuery.paddingOf(context);
              observedViewInsets = MediaQuery.viewInsetsOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        observedPadding!.top,
        equals(0.0),
        reason:
            'padding.top must still be removed from the expanded body\'s MediaQuery when '
            'the keyboard is also open.',
      );
      expect(
        observedViewInsets,
        equals(EdgeInsets.zero),
        reason: 'viewInsets must still be zeroed for the expanded body when padding.top is also being removed.',
      );
    });
  });
}
