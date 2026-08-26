import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Proof coverage for the maintainer's device-reported defect: with `cfdf089`
/// pushing the sheet to the root Navigator (full-screen route), its own content
/// ran edge-to-edge with no protection from the status bar (content clipped at
/// the top) or the Android navigation bar (content, e.g. an error label and a
/// character counter, hidden behind it at the bottom).
///
/// His decision: the sheet's SURFACE stays edge-to-edge (the modern Android
/// full-bleed look) but its CONTENT is inset clear of both system bars. This is
/// `MediaQuery.padding`/`viewPadding` territory (device system-bar insets), not
/// `viewInsets` (keyboard) -- the composition between the two is covered
/// separately in `bottom_sheet_keyboard_insets_test.dart`.
void main() {
  /// Pumps a modal [LayrzBottomSheet] at the given system-bar [padding], with
  /// no keyboard inset, and returns the tester ready to inspect geometry.
  ///
  /// `initialSize`/`maxSize` default to `1.0` so the sheet's surface reaches
  /// the very top of the screen -- the only way to distinguish "the surface is
  /// short of the top bar because it simply isn't that tall yet" (nothing to do
  /// with safe areas) from "the surface is genuinely kept out from under the
  /// status bar" (which it must NOT be -- only content is inset).
  Future<void> pumpSheetWithSystemBars(
    WidgetTester tester, {
    required EdgeInsets padding,
    double initialSize = 1.0,
    double maxSize = 1.0,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.padding = FakeViewPadding(
      top: padding.top,
      bottom: padding.bottom,
      left: padding.left,
      right: padding.right,
    );
    tester.view.viewPadding = FakeViewPadding(
      top: padding.top,
      bottom: padding.bottom,
      left: padding.left,
      right: padding.right,
    );
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    late BuildContext capturedContext;

    await tester.pumpWidget(
      LayrzApp(
        theme: LayrzThemeData.light(),
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();

    unawaited(
      LayrzBottomSheet.show<void>(
        capturedContext,
        initialSize: initialSize,
        minSize: 0.25,
        maxSize: maxSize,
        // Content sized to fill almost the entire physical screen height with
        // a spacer, so "Username contains invalid characters" / "0/30" land
        // right at the bottom of the CONTENT area -- mirroring the
        // maintainer's screenshot where an error label and a character
        // counter sat at the bottom of a form and were hidden behind the nav
        // bar. Content lives inside a SingleChildScrollView with unbounded
        // height, so a fixed-height spacer (not mainAxisAlignment) is what
        // actually pushes the trailing text down near the screen's own
        // bottom edge -- without it, the defect is never in reach to observe.
        builder: (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Phone Number'),
              SizedBox(height: 760),
              Text('Username contains invalid characters'),
              Text('0/30'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Finds the sheet's own surface -- the [DecoratedBox] built directly inside
  /// [DraggableScrollableSheet]'s builder in `_BottomSheetContentState`, whose
  /// [BoxDecoration] paints the surface color, a shadow, and rounded TOP-ONLY
  /// corners (`topLeft`/`topRight`). This is deliberately distinguished from
  /// the drag handle's own pill -- also a [DecoratedBox], but with a fully
  /// circular [BorderRadius] and no shadow -- by requiring `boxShadow` to be
  /// present, which only the surface's decoration sets.
  Finder sheetSurfaceFinder() {
    return find.byWidgetPredicate(
      (w) => w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).boxShadow != null,
    );
  }

  group('LayrzBottomSheet safe area handling', () {
    testWidgets('content clears the status bar; the surface still extends under it', (tester) async {
      await pumpSheetWithSystemBars(
        tester,
        padding: const EdgeInsets.only(top: 40, bottom: 24),
      );

      final surfaceRect = tester.getRect(sheetSurfaceFinder());
      final contentTopRect = tester.getRect(find.text('Phone Number'));

      // At initialSize/maxSize 1.0 the surface reaches the very top of the
      // screen -- it is NOT itself inset by the status bar.
      expect(surfaceRect.top, closeTo(0.0, 0.5));

      // Without the fix, the content's own top sits at ~48px (the drag
      // handle's own ~48px header height plus nothing else) regardless of
      // the 40px status bar -- that baseline alone clears a naive ">= 40"
      // check without SafeArea doing anything. With the fix, SafeArea adds
      // the status bar's own 40px on TOP of that baseline, landing content
      // at ~88px. 70px sits strictly between the two, so this only passes
      // when the inset is genuinely applied.
      expect(contentTopRect.top, greaterThanOrEqualTo(70.0));
    });

    testWidgets('content clears the nav bar at the bottom; the surface still extends under it', (tester) async {
      await pumpSheetWithSystemBars(
        tester,
        padding: const EdgeInsets.only(top: 40, bottom: 24),
      );

      final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final navBarTop = screenHeight - 24;

      // Content is deliberately taller than the visible area (see
      // pumpSheetWithSystemBars) so the trailing text needs scrolling into
      // view -- exactly as the maintainer's real, tall form does.
      await tester.scrollUntilVisible(find.text('0/30'), 200.0);
      await tester.pumpAndSettle();

      final surfaceRect = tester.getRect(sheetSurfaceFinder());
      final errorRect = tester.getRect(find.text('Username contains invalid characters'));
      final counterRect = tester.getRect(find.text('0/30'));

      // The surface still reaches the true bottom edge of the screen.
      expect(surfaceRect.bottom, closeTo(screenHeight, 0.5));

      // Both pieces of content that were reported hidden behind the nav bar
      // must now sit fully above it once scrolled into view.
      expect(errorRect.bottom, lessThanOrEqualTo(navBarTop));
      expect(counterRect.bottom, lessThanOrEqualTo(navBarTop));
    });

    testWidgets('the drag handle does not end up under the status bar', (tester) async {
      await pumpSheetWithSystemBars(
        tester,
        padding: const EdgeInsets.only(top: 40, bottom: 24),
      );

      // The drag handle is the GestureDetector immediately below the sheet's
      // surface -- the barrier's own full-screen GestureDetector is excluded
      // by requiring a height far smaller than the screen.
      final handleFinder = find.byWidgetPredicate((w) {
        return w is GestureDetector;
      });
      final handleRect = handleFinder
          .evaluate()
          .map((e) => tester.getRect(find.byWidgetPredicate((w) => w == e.widget)))
          .firstWhere((r) => r.height < 100);

      expect(handleRect.top, greaterThanOrEqualTo(40.0));
    });

    testWidgets('with zero system-bar insets, SafeArea introduces no gratuitous padding', (tester) async {
      await pumpSheetWithSystemBars(
        tester,
        padding: EdgeInsets.zero,
      );

      final surfaceRect = tester.getRect(sheetSurfaceFinder());
      final contentTopRect = tester.getRect(find.text('Phone Number'));

      // Drag handle header is ~40px tall (sp3 padding + 4px pill), plus the
      // caller's own 16px Padding -- content should sit close to the surface's
      // own top, not pushed down by an inset SafeArea invents out of nothing.
      expect(contentTopRect.top - surfaceRect.top, lessThan(80.0));
    });
  });
}
