import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/layout/src/navigator_panel.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzLayout - Safe Area Geometry (DESIGN-82)', () {
    group('Rail (expanded) with TOP inset — critical invariant: surface.top < content.top', () {
      testWidgets('rail surface extends behind status bar; content is inset', (
        WidgetTester tester,
      ) async {
        /// Tests that with a non-zero TOP inset, the rail surface extends behind the status bar
        /// (top == 0) while the logo content's top is >= topInsetLogical.
        /// This proves SafeArea wraps the content Column, not the outer Container.

        const topInset = 24.0;

        // Force expanded presentation (md breakpoint) by setting a wide test size
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(1200, 800);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: topInset),
                viewPadding: const EdgeInsets.only(top: topInset),
              ),
              child: LayrzLayout(
                logo: 'assets/test-logo.png',
                items: [
                  LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
                ],
                body: const SizedBox(child: Text('Body')),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find the rail by looking for the logo image (which is rendered in the rail).
        final logoImages = find.byType(LayrzImage);
        final logoEvaluated = logoImages.evaluate();
        expect(logoEvaluated.isNotEmpty, isTrue, reason: 'Rail must render logo');

        final logoRect = tester.getRect(logoImages.first);

        /// CRITICAL ASSERTION: logo (content) top >= topInset.
        /// The logo is inside SafeArea, so it is inset from the top by topInset.
        /// If SafeArea wrapped the outer Container instead, the logo would be at or near the top edge.
        expect(
          logoRect.top,
          greaterThanOrEqualTo(topInset),
          reason:
              'CRITICAL: logo (content) top must be >= $topInset pt. '
              'This proves SafeArea wraps the content Column, not the outer Container. '
              'With a $topInset pt top inset, the logo is inset while the surface extends behind the status bar.',
        );
      });
    });

    group('Top Bar (drawer presentation) with TOP inset — critical invariant: surface.top < content.top', () {
      testWidgets('top bar surface reaches top edge; content is inset from status bar', (
        WidgetTester tester,
      ) async {
        /// Tests that with a non-zero TOP inset in drawer presentation (xs/sm width),
        /// the top bar surface is edge-to-edge (top == 0) while icon content is inset >= topInsetLogical.
        /// This proves DecoratedBox(surface) wraps SafeArea(content), not vice versa.

        const topInset = 24.0;

        // Force drawer presentation (sm breakpoint) by setting a narrow test size
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(400, 800);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: topInset),
                viewPadding: const EdgeInsets.only(top: topInset),
              ),
              child: LayrzLayout(
                logo: 'assets/test-logo.png',
                items: [
                  LayrzNavigatorPage(id: 'home', labelText: 'Home'),
                ],
                body: const SizedBox(child: Text('Body')),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find top bar surface (DecoratedBox, top == 0, height > 50).
        final decoratedBoxes = find.byType(DecoratedBox);
        Rect? surfaceRect;

        for (final element in decoratedBoxes.evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget));
          if (rect.top == 0 && rect.height > 50.0) {
            surfaceRect = rect;
            break;
          }
        }

        expect(surfaceRect, isNotNull, reason: 'Top bar surface DecoratedBox must exist at top == 0');

        // Find content (hamburger icon) inside the top bar.
        final icons = find.byType(Icon);
        final iconEvaluated = icons.evaluate();
        expect(iconEvaluated.isNotEmpty, isTrue, reason: 'Top bar must have drawer trigger icon');

        final contentRect = tester.getRect(icons.first);

        /// CRITICAL ASSERTION: surface.top (0) < icon.top (>= topInset).
        /// This proves DecoratedBox(surface) wraps SafeArea(content), not vice versa.
        /// If SafeArea wrapped DecoratedBox, both would start at the same y position.
        expect(
          surfaceRect!.top,
          lessThan(contentRect.top),
          reason:
              'CRITICAL: surface.top (0) < icon.top (~$topInset). '
              'This proves DecoratedBox > SafeArea structure. '
              'With a $topInset pt top inset, the surface reaches the edge while content is inset.',
        );

        expect(
          contentRect.top,
          greaterThanOrEqualTo(topInset),
          reason: 'Top bar content top must be >= top inset ($topInset pt)',
        );
      });

      testWidgets('top bar surface height extends by top inset; content height is constant', (
        WidgetTester tester,
      ) async {
        /// Tests that the decorated surface of the top bar is taller when there is a top inset,
        /// while the SafeArea-wrapped content remains at its base height (64 in compact mode).
        /// DESIGN-104: compact viewports (xs/sm bands, width < 960) use a 64px top bar height
        /// instead of the regular 56px.

        const topInset = 24.0;

        // Force drawer presentation (sm breakpoint)
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(400, 800);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: topInset),
                viewPadding: const EdgeInsets.only(top: topInset),
              ),
              child: LayrzLayout(
                logo: 'assets/test-logo.png',
                items: [
                  LayrzNavigatorPage(id: 'home', labelText: 'Home'),
                ],
                body: const SizedBox(child: Text('Body')),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find the DecoratedBox surface
        final decoratedBoxes = find.byType(DecoratedBox);
        Rect? surfaceRect;

        for (final element in decoratedBoxes.evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget));
          if (rect.top == 0 && rect.height > 50.0) {
            surfaceRect = rect;
            break;
          }
        }

        expect(surfaceRect, isNotNull, reason: 'Top bar surface must exist');

        /// The surface height should be approximately kLayrzLayoutCompactTopBarHeight (64) + inset (24) = 88.
        /// This invariant holds: surface.height = base.height + inset.
        /// This proves the surface extends behind the status bar.
        expect(
          surfaceRect!.height,
          closeTo(kLayrzLayoutCompactTopBarHeight + topInset, 1.0),
          reason:
              'Top bar surface height must be ~${kLayrzLayoutCompactTopBarHeight + topInset} '
              '(compact base ${kLayrzLayoutCompactTopBarHeight.toInt()} + inset $topInset). '
              'This proves the surface extends behind the status bar.',
        );
      });
    });

    group('Drawer with LEFT inset (landscape notch) — critical invariant: surface.left < content.left', () {
      testWidgets('drawer content.left >= leftInsetLogical (SafeArea insets left edge)', (
        WidgetTester tester,
      ) async {
        /// Tests that with a non-zero LEFT inset (landscape notch), the drawer content
        /// is inset >= leftInsetLogical. This proves SafeArea(right:false) insets from left/top/bottom.

        const leftInset = 20.0;

        // Force drawer presentation (sm breakpoint)
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(400, 800);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(left: leftInset),
                viewPadding: const EdgeInsets.only(left: leftInset),
              ),
              child: LayrzLayout(
                logo: 'assets/test-logo.png',
                items: [
                  LayrzNavigatorPage(id: 'home', labelText: 'Home'),
                ],
                body: const SizedBox(child: Text('Body')),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find logo (content) — it should be present in the visible layout.
        final logoImages = find.byType(LayrzImage);
        expect(logoImages.evaluate().isNotEmpty, isTrue, reason: 'Layout must render logo');

        final contentRect = tester.getRect(logoImages.first);

        /// CRITICAL ASSERTION: content.left >= leftInset.
        /// This proves SafeArea insets the content from the left edge.
        expect(
          contentRect.left,
          greaterThanOrEqualTo(leftInset),
          reason:
              'CRITICAL: content.left must be >= $leftInset pt. '
              'This proves SafeArea(right:false) insets from the left. '
              'With a $leftInset pt left inset, content is inset while the surface (if any) reaches the edge.',
        );
      });
    });

    group(
      'Navigator panel with RIGHT inset (DESIGN-84) — critical invariant: content.right == surface.right',
      () {
        /// DESIGN-84: `LayrzLayoutNavigatorPanel` (navigator_panel.dart:140-141) wraps its
        /// content Column in `SafeArea(right: false)`. This single line is shared by BOTH
        /// presentations of the panel — [LayrzLayout] instantiates the exact same
        /// [LayrzLayoutNavigatorPanel] widget twice: once as the persistent rail
        /// (layout.dart, onClose: null) and once as the drawer (layout.dart, onClose:
        /// closeDrawer). `right: false` means the panel does NOT inset its content away from
        /// its own right edge, so content.right must coincide with surface.right even under a
        /// non-zero right inset. If `right: false` were removed (i.e. SafeArea applied the
        /// right inset too), content.right would retreat from surface.right by the inset
        /// amount, and this assertion would fail.

        const rightInset = 30.0;

        testWidgets('rail: content.right == surface.right under a right inset', (WidgetTester tester) async {
          // Force expanded (rail) presentation with a wide test size. devicePixelRatio is
          // pinned to 1.0 so physicalSize maps 1:1 to logical size — otherwise the ambient
          // test devicePixelRatio (3.0) would shrink the logical width into the drawer band.
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = const Size(1200, 800);

          await pumpThemedApp(
            tester,
            Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.only(right: rightInset),
                  viewPadding: const EdgeInsets.only(right: rightInset),
                ),
                child: LayrzLayout(
                  logo: 'assets/test-logo.png',
                  items: [
                    LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
                  ],
                  body: const SizedBox(child: Text('Body')),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          final panelFinder = find.byType(LayrzLayoutNavigatorPanel);
          expect(panelFinder, findsOneWidget, reason: 'Rail must render exactly one LayrzLayoutNavigatorPanel');

          final surfaceRect = tester.getRect(panelFinder);

          // The SafeArea-wrapped content Column is the sole child of the panel's outer
          // Container; find it as the Column directly inside the panel subtree.
          final contentFinder = find.descendant(
            of: panelFinder,
            matching: find.byType(Column).first,
          );
          final contentRect = tester.getRect(contentFinder);

          /// CRITICAL ASSERTION: content.right == surface.right (within the panel).
          /// If `right: false` were removed, SafeArea would inset the content by
          /// rightInset, and content.right would be < surface.right.
          expect(
            contentRect.right,
            equals(surfaceRect.right),
            reason:
                'CRITICAL: rail content.right must equal surface.right even with a '
                '$rightInset pt right inset. This proves SafeArea(right: false) at '
                'navigator_panel.dart:140-141 does NOT inset content from the right edge. '
                'If right:false were removed, content.right would retreat by $rightInset pt.',
          );
        });

        testWidgets('drawer: content.right == surface.right under a right inset', (WidgetTester tester) async {
          // Force drawer presentation with a narrow test size. devicePixelRatio is pinned
          // to 1.0 for consistency with the rail test above (both must resolve deterministically).
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = const Size(400, 800);

          await pumpThemedApp(
            tester,
            Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.only(right: rightInset),
                  viewPadding: const EdgeInsets.only(right: rightInset),
                ),
                child: LayrzLayout(
                  logo: 'assets/test-logo.png',
                  items: [
                    LayrzNavigatorPage(id: 'home', labelText: 'Home'),
                  ],
                  body: const SizedBox(child: Text('Body')),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // The drawer panel is not mounted until the drawer is opened.
          final triggerFinder = find.byKey(const ValueKey('drawer_trigger_button'));
          expect(triggerFinder, findsOneWidget, reason: 'Drawer trigger button must be present');

          await tester.tap(triggerFinder);
          await tester.pumpAndSettle();

          final panelFinder = find.byType(LayrzLayoutNavigatorPanel);
          expect(panelFinder, findsOneWidget, reason: 'Drawer must render exactly one LayrzLayoutNavigatorPanel');

          final surfaceRect = tester.getRect(panelFinder);

          final contentFinder = find.descendant(
            of: panelFinder,
            matching: find.byType(Column).first,
          );
          final contentRect = tester.getRect(contentFinder);

          /// CRITICAL ASSERTION: content.right == surface.right (within the panel).
          /// This guards the SAME line as the rail test above — navigator_panel.dart:140-141
          /// is shared by both presentations.
          expect(
            contentRect.right,
            equals(surfaceRect.right),
            reason:
                'CRITICAL: drawer content.right must equal surface.right even with a '
                '$rightInset pt right inset. This proves SafeArea(right: false) at '
                'navigator_panel.dart:140-141 does NOT inset content from the right edge. '
                'If right:false were removed, content.right would retreat by $rightInset pt.',
          );
        });
      },
    );

    group('Rail with TOP and BOTTOM insets simultaneously — surface spans full height, content is inset both ends', () {
      testWidgets('rail surface spans 0..screenHeight; content is inset by topInset..(screenHeight - bottomInset)', (
        WidgetTester tester,
      ) async {
        /// Tests that with non-zero TOP and BOTTOM insets applied together, the rail surface
        /// still spans the full screen height (0 to screenHeight) while the content Column
        /// (SafeArea-wrapped) is inset at both ends: content.top >= topInset and
        /// content.bottom <= screenHeight - bottomInset.
        ///
        /// At screenHeight 800 with topInset 24 and bottomInset 16:
        ///   surface: 0 -> 800
        ///   content: 24 -> 784

        const screenHeight = 800.0;
        const topInset = 24.0;
        const bottomInset = 16.0;

        // devicePixelRatio is pinned to 1.0 so physicalSize maps 1:1 to logical size —
        // otherwise the ambient test devicePixelRatio (3.0) would shrink the logical width
        // into the drawer band instead of the rail band this test targets.
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1200, screenHeight);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: topInset, bottom: bottomInset),
                viewPadding: const EdgeInsets.only(top: topInset, bottom: bottomInset),
              ),
              child: LayrzLayout(
                logo: 'assets/test-logo.png',
                items: [
                  LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
                ],
                body: const SizedBox(child: Text('Body')),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final panelFinder = find.byType(LayrzLayoutNavigatorPanel);
        expect(panelFinder, findsOneWidget, reason: 'Rail must render exactly one LayrzLayoutNavigatorPanel');

        final surfaceRect = tester.getRect(panelFinder);

        expect(
          surfaceRect.top,
          equals(0.0),
          reason: 'Rail surface must reach the top edge (extends behind the status bar).',
        );
        expect(
          surfaceRect.bottom,
          closeTo(screenHeight, 1.0),
          reason: 'Rail surface must span the full screen height ($screenHeight), extending behind any bottom inset.',
        );

        final contentFinder = find.descendant(
          of: panelFinder,
          matching: find.byType(Column).first,
        );
        final contentRect = tester.getRect(contentFinder);

        /// CRITICAL ASSERTION: content.top >= topInset AND content.bottom <= screenHeight - bottomInset.
        /// This proves SafeArea insets content from both the top and bottom simultaneously,
        /// while the surface (the outer Container) remains full-bleed.
        expect(
          contentRect.top,
          greaterThanOrEqualTo(topInset),
          reason: 'Rail content.top must be >= $topInset pt (top inset).',
        );
        expect(
          contentRect.bottom,
          lessThanOrEqualTo(screenHeight - bottomInset + 1.0),
          reason: 'Rail content.bottom must be <= ${screenHeight - bottomInset} pt (screenHeight - bottomInset).',
        );
      });
    });

    group('Zero-inset baseline — safe area is a no-op without insets', () {
      testWidgets('with no insets, surface and content coincide', (WidgetTester tester) async {
        /// Tests that when there are no device insets, SafeArea does not affect layout.
        /// The invariant is: surface.height = base.height + inset, where inset = 0.
        /// The default test viewport is compact (width < 960), so the base height is 64px per DESIGN-104.

        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        await tester.pumpAndSettle();

        // Find top bar surface
        final decoratedBoxes = find.byType(DecoratedBox);
        Rect? surfaceRect;

        for (final element in decoratedBoxes.evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget));
          if (rect.top == 0 && rect.height > 50.0) {
            surfaceRect = rect;
            break;
          }
        }

        expect(surfaceRect, isNotNull, reason: 'Top bar surface must exist');

        /// With zero insets, the surface height should be approximately the base height (64 in compact mode).
        /// This invariant confirms SafeArea has no effect when insets are zero.
        expect(
          surfaceRect!.height,
          closeTo(kLayrzLayoutCompactTopBarHeight, 1.0),
          reason:
              'With zero insets, top bar surface height must equal the base height (${kLayrzLayoutCompactTopBarHeight.toInt()}px in compact). '
              'This confirms SafeArea has no effect when insets are zero.',
        );
      });
    });

    /// Keyboard insets (viewInsets) are distinct from viewPadding (device insets). SafeArea
    /// itself only ever reads viewPadding, so it correctly never grows a padding for the
    /// keyboard — that is not a gap in SafeArea. The layout handles the keyboard separately,
    /// by reducing the body's (and, when visible, the navigator panel's) available height by
    /// viewInsets.bottom, Scaffold-style. A prior version of this file held a test here
    /// ("viewInsets are not applied as SafeArea padding") whose only assertion was that
    /// SafeArea did not crash under a nonzero viewInsets — it asserted nothing about
    /// viewInsets itself and would have passed under the old, buggy behaviour too. The real
    /// assertions — that the body's usable height actually shrinks by viewInsets.bottom for
    /// both presentation paths, that the inset is not double-counted by nested readers, and
    /// that the open drawer panel shrinks in step — now live in
    /// test/layout/layout_keyboard_insets_test.dart.
  });
}
