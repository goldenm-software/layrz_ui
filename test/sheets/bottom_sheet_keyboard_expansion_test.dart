import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Proof coverage for the maintainer's superseding decision on the keyboard
/// defect, verbatim: "on open keyboard, just use the remaining space
/// available, disabling the expansion controls because, with an open
/// keyboard, there is not much space available there."
///
/// This supersedes the earlier "push the whole sheet up" mechanism
/// (`bottom_sheet_keyboard_insets_test.dart`, still valid as a geometry check
/// since the sheet's surface still ends up at the keyboard's top edge either
/// way) with two behaviours that file does not cover:
/// - the sheet is PINNED to fill the remaining space the moment the keyboard
///   opens, regardless of what fraction it was at before
/// - drag-to-EXPAND is suppressed while the keyboard is up (nothing to expand
///   into), while drag-to-DISMISS is deliberately preserved through a
///   separate path (see `_DragHandle.dismissOnly` in bottom_sheet.dart)
void main() {
  group('LayrzBottomSheet keyboard-driven expansion suppression', () {
    void setLogicalSize(WidgetTester tester, Size logicalSize) {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = logicalSize;
    }

    const screenHeight = 800.0;
    const keyboardInset = 300.0;

    Finder sheetSurfaceFinder() {
      return find.byWidgetPredicate(
        (widget) => widget is DecoratedBox && (widget.decoration as BoxDecoration).boxShadow != null,
      );
    }

    Finder dragHandleFinder() {
      return find.byWidgetPredicate(
        (widget) => widget is Container && widget.constraints?.maxWidth == 40 && widget.constraints?.maxHeight == 4,
      );
    }

    Future<void> openSheet(
      WidgetTester tester, {
      double initialSize = 0.3,
      double minSize = 0.25,
      double maxSize = 0.95,
      // Adds a tall spacer plus a keyed marker at the very bottom of the
      // sheet's content -- used by the safe-area/keyboard composition test
      // to check the gap between the sheet's own bottom edge and its
      // bottom-most content, which "Sheet title" alone (a single line near
      // the top) cannot exercise.
      bool withBottomMarker = false,
    }) async {
      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                LayrzBottomSheet.show<void>(
                  context,
                  initialSize: initialSize,
                  minSize: minSize,
                  maxSize: maxSize,
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sheet title'),
                        if (withBottomMarker) ...[
                          const SizedBox(height: 900),
                          const Text('Bottom marker', key: ValueKey('bottomMarker')),
                        ],
                      ],
                    ),
                  ),
                );
              },
              child: const SizedBox(width: 100, height: 100, child: Text('Open')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('opening the keyboard pins the sheet to fill the remaining space, regardless of prior size', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        setLogicalSize(tester, const Size(400, screenHeight));

        // Deliberately small -- 0.3 of the FULL screen, far short of filling
        // the remaining space above the keyboard. If the sheet merely kept
        // its current fraction (as it would without this fix), its top would
        // sit well below the top of the reduced 500px box once the keyboard
        // opens (500 - 0.3*500 = 350px of empty space above it) rather than
        // right at it.
        await openSheet(tester, initialSize: 0.3);

        tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
        await tester.pumpAndSettle();

        final availableHeight = screenHeight - keyboardInset;
        final surfaceRect = tester.getRect(sheetSurfaceFinder());

        // Pinned to 1.0 of the reduced box: the surface's top edge must sit
        // at y=0 (the very top of the screen), not partway down.
        expect(
          surfaceRect.top,
          closeTo(0.0, 0.5),
          reason:
              'the sheet must fill the ENTIRE remaining space above the keyboard once it opens, not stay at '
              'the fraction it was showing before',
        );
        expect(surfaceRect.bottom, closeTo(availableHeight, 0.5));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('while the keyboard is up, dragging the handle upward does not grow the sheet further', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        setLogicalSize(tester, const Size(400, screenHeight));

        await openSheet(tester, initialSize: 0.3);
        tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
        await tester.pumpAndSettle();

        final beforeRect = tester.getRect(sheetSurfaceFinder());
        expect(beforeRect.top, closeTo(0.0, 0.5), reason: 'sheet must already be pinned to fill the remaining space');

        // An upward drag would ordinarily grow the sheet (see the
        // pre-existing "dragging the handle upward grows the sheet" test in
        // bottom_sheet_test.dart) -- with expansion suppressed there is
        // nowhere further to grow, so the surface's geometry must not change.
        await tester.drag(dragHandleFinder(), const Offset(0, -150));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final afterRect = tester.getRect(sheetSurfaceFinder());
        expect(
          afterRect,
          equals(beforeRect),
          reason: 'dragging upward with the keyboard open must not resize the sheet -- expansion is suppressed',
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('while the keyboard is up, a small downward drag does not dismiss or resize the sheet', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        setLogicalSize(tester, const Size(400, screenHeight));

        await openSheet(tester, initialSize: 0.3);
        tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
        await tester.pumpAndSettle();

        expect(find.text('Sheet title'), findsOneWidget);
        final beforeRect = tester.getRect(sheetSurfaceFinder());

        // Below the dismiss-only threshold (80px, see bottom_sheet.dart) --
        // an incidental jitter while the user is typing must not dismiss the
        // sheet or visibly move it (the dismiss-only path never touches the
        // sheet's own size mid-drag, unlike the ordinary resize path).
        await tester.drag(dragHandleFinder(), const Offset(0, 40));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Sheet title'), findsOneWidget, reason: 'a small drag must not dismiss the sheet');
        expect(tester.getRect(sheetSurfaceFinder()), equals(beforeRect));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('while the keyboard is up, a deliberate downward drag past the threshold still dismisses the sheet', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        setLogicalSize(tester, const Size(400, screenHeight));

        await openSheet(tester, initialSize: 0.3);
        tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
        await tester.pumpAndSettle();

        expect(find.text('Sheet title'), findsOneWidget);

        // Past the 80px dismiss-only threshold: a user must still be able to
        // deliberately swipe the sheet away while the keyboard is up --
        // disabling EXPANSION was never meant to also disable dismissal.
        await tester.drag(dragHandleFinder(), const Offset(0, 200));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'dismissing via drag with the keyboard up must not throw or assert',
        );
        expect(
          find.text('Sheet title'),
          findsNothing,
          reason: 'a deliberate downward drag past the threshold must still dismiss the sheet with the keyboard up',
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('closing the keyboard restores normal expansion behaviour', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        setLogicalSize(tester, const Size(400, screenHeight));

        await openSheet(tester, initialSize: 0.3, minSize: 0.25, maxSize: 0.95);

        tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
        await tester.pumpAndSettle();
        final pinnedRect = tester.getRect(sheetSurfaceFinder());
        expect(pinnedRect.top, closeTo(0.0, 0.5), reason: 'sheet must be pinned while the keyboard is up');

        // Dismiss the keyboard.
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();

        // First proof of restoration: the sheet returns to EXACTLY the size
        // it had before the keyboard opened (initialSize 0.3 here), not just
        // clamped down to maxSize (0.95) -- the latter would still be a
        // visibly jarring jump from a small sheet to a near-full-screen one
        // the instant the keyboard closes. _sizeBeforeKeyboard in
        // bottom_sheet.dart records the pre-pin size specifically so the
        // sheet returns to REST, not merely to "somewhere unpinned".
        final restoredRect = tester.getRect(sheetSurfaceFinder());
        final expectedRestingTop = screenHeight - (0.3 * screenHeight);
        expect(
          restoredRect.top,
          closeTo(expectedRestingTop, 0.5),
          reason:
              'once the keyboard closes, the sheet must return to exactly its pre-keyboard size (0.3), not '
              'merely clamp down to maxSize (0.95)',
        );

        // Second, stronger proof: minSize must also be restored (not still
        // locked to 1.0) -- a large downward drag must dismiss the sheet
        // again, exactly as it would if the keyboard had never opened
        // (mirrors the pre-existing "dragging the handle down past the low
        // snap point dismisses the sheet" test in bottom_sheet_test.dart).
        await tester.drag(dragHandleFinder(), const Offset(0, 700));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.text('Sheet title'),
          findsNothing,
          reason:
              'once restored, a large downward drag must dismiss the sheet exactly as it would have before '
              'the keyboard ever opened -- minSize is no longer locked to 1.0',
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets(
      'keyboard up AND system bottom inset present: the bottom safe-area inset does not stack on top of the '
      'keyboard inset',
      (tester) async {
        // The case team-lead flagged as most likely to look subtly wrong on
        // device: with the keyboard open, the Android nav bar sits BEHIND the
        // keyboard, so SafeArea's bottom inset (which reads MediaQuery.padding,
        // not the permanent viewPadding) must already read as zero once the
        // keyboard covers that region -- applying both would leave a visible
        // gap between the sheet's usable content and the keyboard's own top
        // edge. See bottom_sheet.dart's SafeArea comment for the mechanism:
        // this composes for free because of how the engine (and this test's
        // own tester.view.padding, mirroring it) reports `padding` versus
        // `viewPadding` once the keyboard is up.
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          setLogicalSize(tester, const Size(400, screenHeight));
          addTearDown(tester.view.resetPadding);
          addTearDown(tester.view.resetViewPadding);

          // The device's permanent bottom system-bar inset (nav bar).
          const navBarInset = 24.0;
          tester.view.viewPadding = const FakeViewPadding(bottom: navBarInset);
          // Before the keyboard opens, `padding` reports the nav bar's own
          // inset -- nothing obscures it yet.
          tester.view.padding = const FakeViewPadding(bottom: navBarInset);

          await openSheet(tester, initialSize: 0.3, withBottomMarker: true);

          final availableHeightNoKeyboard = screenHeight;
          final surfaceBeforeKeyboard = tester.getRect(sheetSurfaceFinder());
          expect(surfaceBeforeKeyboard.bottom, closeTo(availableHeightNoKeyboard, 0.5));

          // Now the keyboard opens. On a real device, once the keyboard
          // covers the nav bar's own region, `padding.bottom` collapses to 0
          // (the engine's own computation -- padding is "the parts NOT
          // obscured"), even though `viewPadding.bottom` (the permanent
          // inset) stays at 24. This test sets both independently to mirror
          // that real composition rather than asserting it as an assumption.
          tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
          tester.view.padding = FakeViewPadding.zero;
          await tester.pumpAndSettle();

          final keyboardTop = screenHeight - keyboardInset;
          final surfaceRect = tester.getRect(sheetSurfaceFinder());
          // With the keyboard open, the sheet is PINNED to fill the entire
          // remaining space (Defect B) -- so the correct "no double-inset"
          // check is on the SURFACE's own bottom edge, not on where a single
          // piece of top-anchored content happens to land (which, once
          // pinned, sits near the TOP of the screen regardless of any
          // safe-area inset -- nowhere near the keyboard at all).
          expect(
            surfaceRect.bottom,
            closeTo(keyboardTop, 0.5),
            reason:
                'the sheet\'s surface must still land exactly at the keyboard\'s top edge, not further up as '
                'if an extra 24px of nav-bar inset were ALSO being reserved on top of it (i.e. must not land at '
                '${keyboardTop - navBarInset} instead)',
          );

          // Second, content-level proof: scroll to the bottom of the sheet's
          // content and confirm it reaches close to the sheet's OWN bottom
          // edge (SafeArea's normal ~sp3+content padding), not held back by
          // an extra ~24px gap that would appear if the nav-bar's own
          // permanent inset (viewPadding.bottom, still 24 regardless of the
          // keyboard) were mistakenly consulted here instead of the
          // keyboard-aware padding.bottom (already 0).
          await tester.scrollUntilVisible(find.byKey(const ValueKey('bottomMarker')), 200.0);
          await tester.pumpAndSettle();
          final markerRect = tester.getRect(find.byKey(const ValueKey('bottomMarker')));
          final gapFromSurfaceBottom = surfaceRect.bottom - markerRect.bottom;
          expect(
            gapFromSurfaceBottom,
            lessThan(navBarInset + 40),
            reason:
                'the sheet\'s own bottom-most content must sit close to its surface\'s bottom edge -- a gap of '
                '$gapFromSurfaceBottom is too large and suggests the permanent 24px nav-bar inset is being '
                'applied on top of the keyboard, rather than collapsing to zero once the keyboard covers it',
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });
}
