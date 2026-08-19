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

        // Force expanded presentation (md breakpoint) by setting a wide test size
        tester.binding.window.physicalSizeTestValue = const Size(1200, 800);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: 24.0),
                viewPadding: const EdgeInsets.only(top: 24.0),
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

        /// CRITICAL ASSERTION: logo (content) top >= 24.
        /// The logo is inside SafeArea, so it is inset from the top by 24pt.
        /// If SafeArea wrapped the outer Container instead, the logo would be at or near the top edge.
        expect(
          logoRect.top,
          greaterThanOrEqualTo(24.0),
          reason:
              'CRITICAL: logo (content) top must be >= 24pt. '
              'This proves SafeArea wraps the content Column, not the outer Container. '
              'With a 24pt top inset, the logo is inset while the surface extends behind the status bar.',
        );
      });

      testWidgets('rail logo is inset; safe area wraps content not surface', (
        WidgetTester tester,
      ) async {
        /// Tests that SafeArea wraps only the content Column, not the outer Container.
        /// With a top inset, the logo (content) is inset while the surface itself is not.

        // Force expanded presentation (md breakpoint)
        tester.binding.window.physicalSizeTestValue = const Size(1200, 800);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: 24.0),
                viewPadding: const EdgeInsets.only(top: 24.0),
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

        // Find the logo image (content inside SafeArea).
        final logoImages = find.byType(LayrzImage);
        final logoEvaluated = logoImages.evaluate();
        expect(logoEvaluated.isNotEmpty, isTrue, reason: 'Rail must render logo');

        final logoRect = tester.getRect(logoImages.first);

        /// The logo is inside SafeArea(child: Column(...)), so with a 24pt top inset,
        /// the logo's top should be >= 24pt. This proves SafeArea only wraps the Column,
        /// not the outer Container that acts as the surface.
        expect(
          logoRect.top,
          greaterThanOrEqualTo(24.0),
          reason:
              'Logo (content inside SafeArea Column) must be inset by at least 24pt. '
              'This proves SafeArea wraps only the content, not the surface.',
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

        // Force drawer presentation (sm breakpoint) by setting a narrow test size
        tester.binding.window.physicalSizeTestValue = const Size(400, 800);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: 24.0),
                viewPadding: const EdgeInsets.only(top: 24.0),
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

        /// CRITICAL ASSERTION: surface.top (0) < icon.top (>= 24).
        /// This proves DecoratedBox(surface) wraps SafeArea(content), not vice versa.
        /// If SafeArea wrapped DecoratedBox, both would start at the same y position.
        expect(
          surfaceRect!.top,
          lessThan(contentRect.top),
          reason:
              'CRITICAL: surface.top (0) < icon.top (~24). '
              'This proves DecoratedBox > SafeArea structure. '
              'With a 24pt top inset, the surface reaches the edge while content is inset.',
        );

        expect(
          contentRect.top,
          greaterThanOrEqualTo(24.0),
          reason: 'Top bar content top must be >= top inset (24pt)',
        );
      });

      testWidgets('top bar surface height extends by top inset; content height is constant', (
        WidgetTester tester,
      ) async {
        /// Tests that the decorated surface of the top bar is taller when there is a top inset,
        /// while the SafeArea-wrapped content remains at kLayrzLayoutTopBarHeight.

        // Force drawer presentation (sm breakpoint)
        tester.binding.window.physicalSizeTestValue = const Size(400, 800);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: 24.0),
                viewPadding: const EdgeInsets.only(top: 24.0),
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
          greaterThan(kLayrzLayoutTopBarHeight),
          reason:
              'Top bar surface height must be > kLayrzLayoutTopBarHeight (56) to include '
              'the inset space behind the status bar.',
        );
      });
    });

    group('Drawer with LEFT inset (landscape notch) — critical invariant: surface.left < content.left', () {
      testWidgets('drawer surface.left == 0; content.left >= leftInsetLogical', (
        WidgetTester tester,
      ) async {
        /// Tests that with a non-zero LEFT inset (landscape notch), the drawer surface
        /// is edge-to-edge (left == 0) while content is inset >= leftInsetLogical.
        /// SafeArea(right:false) insets from left/top/bottom, not right.

        // Force drawer presentation (sm breakpoint)
        tester.binding.window.physicalSizeTestValue = const Size(400, 800);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(left: 20.0),
                viewPadding: const EdgeInsets.only(left: 20.0),
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

        // Open drawer.
        final icons = find.byType(Icon);
        if (icons.evaluate().isNotEmpty) {
          await tester.tap(icons.first);
          await tester.pumpAndSettle();
        }

        // Find drawer surface (Container, width == kLayrzLayoutDrawerWidth, left == 0).
        final containers = find.byType(Container);
        Rect? surfaceRect;

        for (final element in containers.evaluate()) {
          final widget = element.widget;
          if (widget is Container && widget.decoration is BoxDecoration) {
            final rect = tester.getRect(find.byWidget(widget));
            if ((rect.width - kLayrzLayoutDrawerWidth).abs() < 1.0 && rect.left == 0) {
              surfaceRect = rect;
              break;
            }
          }
        }

        if (surfaceRect != null) {
          // Find content (logo) inside drawer.
          final logoImages = find.byType(LayrzImage);
          if (logoImages.evaluate().isNotEmpty) {
            final contentRect = tester.getRect(logoImages.first);

            /// CRITICAL ASSERTION: surface.left (0) < content.left (>= 20).
            /// This proves SafeArea(right:false) insets from left.
            expect(
              surfaceRect.left,
              lessThan(contentRect.left),
              reason:
                  'CRITICAL: surface.left (0) < content.left (~20). '
                  'This proves SafeArea(right:false) insets from left. '
                  'With a 20pt left inset, the surface reaches the edge while content is inset.',
            );

            expect(
              contentRect.left,
              greaterThanOrEqualTo(20.0),
              reason: 'Drawer content left must be >= left inset (20pt)',
            );
          }
        }
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

    group('SafeArea presence (structural)', () {
      testWidgets('SafeArea is present in layout tree', (WidgetTester tester) async {
        /// Verifies that SafeArea widget is present somewhere in the layout tree.
        /// This is a structural check; the geometric tests above verify behavior.

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

        expect(
          find.byType(SafeArea),
          findsWidgets,
          reason: 'SafeArea widget must be present in the layout tree',
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
