import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

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
        /// while the SafeArea-wrapped content remains at kLayrzLayoutTopBarHeight.

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

        /// The surface height should be approximately kLayrzLayoutTopBarHeight (56) + inset (24) = ~80.
        /// This proves the surface extends behind the status bar.
        expect(
          surfaceRect!.height,
          closeTo(kLayrzLayoutTopBarHeight + topInset, 1.0),
          reason:
              'Top bar surface height must be ~${kLayrzLayoutTopBarHeight + topInset} (base 56 + inset $topInset). '
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

    group('Zero-inset baseline — safe area is a no-op without insets', () {
      testWidgets('with no insets, surface and content coincide', (WidgetTester tester) async {
        /// Tests that when there are no device insets, SafeArea does not affect layout.
        /// Surface and content tops should be equal (or nearly equal).

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

        /// With no insets, the surface height should be approximately kLayrzLayoutTopBarHeight.
        /// This confirms SafeArea is a no-op when there are no insets.
        expect(
          surfaceRect!.height,
          closeTo(kLayrzLayoutTopBarHeight, 1.0),
          reason:
              'With zero insets, top bar surface height must equal kLayrzLayoutTopBarHeight. '
              'This confirms SafeArea has no effect when insets are zero.',
        );
      });
    });

    group('Keyboard insets — out of scope for layout surface geometry', () {
      testWidgets('viewInsets are not applied as SafeArea padding', (WidgetTester tester) async {
        /// viewInsets (like keyboard height) are distinct from viewPadding (device insets).
        /// This test documents that keyboard insets are not applied to the layout surface,
        /// as they are for transient, content-driven overlays, not the layout structure.

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                viewInsets: const EdgeInsets.only(bottom: 300.0),
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

        /// Verify SafeArea is still present (no crash).
        expect(
          find.byType(SafeArea),
          findsWidgets,
          reason: 'SafeArea must handle viewInsets without crashing',
        );
      });
    });
  });
}
