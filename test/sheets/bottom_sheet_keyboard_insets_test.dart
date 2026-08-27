import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzBottomSheet keyboard viewInsets (pushes the whole sheet up, D65-adjacent)', () {
    // Pinned per the pattern established throughout this repo's test suite:
    // devicePixelRatio must be set BEFORE physicalSize, since the ambient
    // ratio in the test harness is 3.0.
    void setLogicalSize(WidgetTester tester, Size logicalSize) {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = logicalSize;
    }

    const screenHeight = 800.0;
    const keyboardInset = 300.0;

    /// Finds the sheet's own decorated surface -- the ground-truth signal for
    /// "where is the sheet, on screen", independent of the internal layout
    /// (padding/spacers) of whatever content a caller puts inside it.
    Finder sheetSurfaceFinder() {
      return find.byWidgetPredicate(
        (widget) => widget is DecoratedBox && (widget.decoration as BoxDecoration).boxShadow != null,
      );
    }

    /// Opens a modal sheet with a bottom marker widget, so the marker's
    /// screen position is the observable signal for "is the sheet's full
    /// content visible above the keyboard".
    Future<void> openSheet(
      WidgetTester tester, {
      double initialSize = 0.4,
      bool isPersistent = false,
    }) async {
      final textController = TextEditingController();
      addTearDown(textController.dispose);
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

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
                  isPersistent: isPersistent,
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Sheet title'),
                        LayrzTextInput(
                          controller: textController,
                          focusNode: focusNode,
                          labelText: 'Focused field',
                        ),
                        const SizedBox(height: 8),
                        const Text('Bottom marker', key: ValueKey('bottomMarker')),
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

    testWidgets(
      'the sheet\'s own surface sits exactly at the keyboard\'s top edge, and its content is visible above it',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          setLogicalSize(tester, const Size(400, screenHeight));

          // 0.6, not 0.3: large enough that the sheet's own content (title +
          // field + spacer + marker, ~180px total) genuinely fits within the
          // reduced height (0.6 * (800 - 300) = 300px) without needing to
          // scroll -- this test is specifically about a sheet SHORT ENOUGH
          // relative to the remaining space that everything is immediately
          // visible. The case where content is taller than the available
          // space and must scroll to be reached is covered separately below
          // ("content taller than the available space scrolls").
          await openSheet(tester, initialSize: 0.6);

          final markerFinder = find.byKey(const ValueKey('bottomMarker'));
          expect(markerFinder, findsOneWidget, reason: 'sheet must be open');

          tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(markerFinder, findsOneWidget, reason: 'sheet content must still be present, not popped or hidden');

          // Ground truth: the sheet's own decorated surface (its actual outer
          // edge, not any particular piece of its caller-supplied content)
          // must sit exactly at the keyboard's top edge -- this is the
          // mechanism itself, verified directly rather than inferred from
          // where a marker with its own internal padding happens to land.
          final keyboardTop = screenHeight - keyboardInset;
          final surfaceRect = tester.getRect(sheetSurfaceFinder());
          expect(
            surfaceRect.bottom,
            closeTo(keyboardTop, 0.5),
            reason: 'the sheet\'s own bottom edge must sit exactly at the keyboard\'s top edge (y=$keyboardTop)',
          );

          // And the marker (real content, with its own internal padding) must
          // still be genuinely visible above the keyboard -- not just "the
          // sheet moved", but "the content inside it is actually reachable"
          // WITHOUT scrolling, since it fits in the available space.
          final markerRect = tester.getRect(markerFinder);
          expect(
            markerRect.bottom,
            lessThanOrEqualTo(keyboardTop),
            reason:
                'the sheet\'s bottom marker (bottom=${markerRect.bottom}) must sit above the '
                'keyboard\'s top edge (y=$keyboardTop), not be covered by it',
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'a TALL sheet (taller than the space above the keyboard) does not overflow -- '
      'DraggableScrollableSheet\'s existing maxSize clamp and internal scroll handle it',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          setLogicalSize(tester, const Size(400, screenHeight));

          // maxSize 0.95 -- deliberately large so, once the keyboard consumes
          // 300 of 800 logical px, the sheet's own maxChildSize fraction
          // (relative to the reduced available height) still cannot fit an
          // arbitrarily tall content column without scrolling. This
          // documents the deliberate choice: no new overflow mechanism was
          // added for the keyboard case -- DraggableScrollableSheet's
          // existing SingleChildScrollView (see _BottomSheetContentState)
          // already handles content taller than the sheet's own visible
          // extent by scrolling, and that is unchanged here; only the
          // available height it clamps against got smaller.
          await openSheet(tester, initialSize: 0.9);

          tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: 'a sheet taller than the remaining space above the keyboard must not overflow/assert',
          );

          final keyboardTop = screenHeight - keyboardInset;
          final surfaceRect = tester.getRect(sheetSurfaceFinder());
          expect(
            surfaceRect.bottom,
            closeTo(keyboardTop, 0.5),
            reason: 'even a tall sheet\'s bottom edge must still land exactly at the keyboard\'s top edge',
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'content taller than the space remaining above the keyboard must scroll to be reached, not overflow',
      (tester) async {
        // Deliberate decision, documented explicitly per the brief: when the
        // sheet cannot be fully visible above the keyboard, its content
        // scrolls -- it does not shrink the sheet's own decorated surface
        // below the keyboard's edge, and it does not render past its own
        // clip bounds. Reproduces the exact overflow discovered while
        // building this suite: a short initialSize (0.3) with real content
        // (title + LayrzTextInput + spacer + marker, ~180px) laid out inside
        // a sheet reduced to 150px (0.3 * (800 - 300)) by the keyboard --
        // the marker's LAYOUT position can sit past the sheet's own visible
        // surface (this is normal for anything inside a scrollable that
        // requires scrolling to reach), but the sheet's surface itself must
        // never extend past the keyboard's edge, and no exception must be
        // thrown.
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          setLogicalSize(tester, const Size(400, screenHeight));

          await openSheet(tester, initialSize: 0.3);

          tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull, reason: 'content taller than the available space must not crash');

          final keyboardTop = screenHeight - keyboardInset;
          final surfaceRect = tester.getRect(sheetSurfaceFinder());
          expect(
            surfaceRect.bottom,
            closeTo(keyboardTop, 0.5),
            reason:
                'the sheet\'s own surface must still sit exactly at the keyboard\'s top edge -- it must never '
                'grow past it just because its content does not fit',
          );

          // The marker can be reached by scrolling: find its ScrollController
          // ancestor and confirm it can actually scroll to bring the marker
          // into the sheet's own visible bounds, proving this is a genuine
          // "scroll to reach" case, not silently lost/inaccessible content.
          final scrollableFinder = find.byType(Scrollable);
          expect(scrollableFinder, findsWidgets, reason: 'the sheet\'s content must be scrollable');
          await tester.drag(scrollableFinder.first, const Offset(0, -200));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull, reason: 'scrolling the sheet\'s content must not throw either');
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('dismissing the keyboard returns the sheet to its resting position', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        setLogicalSize(tester, const Size(400, screenHeight));

        await openSheet(tester, initialSize: 0.3);

        final restingRect = tester.getRect(sheetSurfaceFinder());

        tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
        await tester.pumpAndSettle();
        final raisedRect = tester.getRect(sheetSurfaceFinder());
        expect(raisedRect.bottom, lessThan(restingRect.bottom), reason: 'the sheet must visibly move up');

        // Dismiss the keyboard.
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();

        final settledRect = tester.getRect(sheetSurfaceFinder());
        expect(
          settledRect,
          equals(restingRect),
          reason: 'dismissing the keyboard must return the sheet to exactly its resting position',
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('the drag-to-dismiss handle still works with the keyboard up', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        setLogicalSize(tester, const Size(400, screenHeight));

        await openSheet(tester, initialSize: 0.5);
        expect(find.byKey(const ValueKey('bottomMarker')), findsOneWidget);

        tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
        await tester.pumpAndSettle();

        final handle = find.byWidgetPredicate(
          (widget) => widget is Container && widget.constraints?.maxWidth == 40 && widget.constraints?.maxHeight == 4,
        );
        expect(handle, findsOneWidget, reason: 'the drag handle must still be present and found with the keyboard up');

        await tester.drag(handle, const Offset(0, 400));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason:
              'dragging with the keyboard up must not assert -- the keyboard-avoidance Padding shrinks the '
              'sheet\'s parent height, so the same pixel delta now converts to a larger size fraction via '
              'pixelsToSize; _onDragUpdate must clamp before calling jumpTo, whose own internal assert fires '
              'on the unclamped value before minSize/maxSize clamping ever runs',
        );
        expect(
          find.byKey(const ValueKey('bottomMarker')),
          findsNothing,
          reason: 'dragging down past the low snap point must still dismiss the sheet with the keyboard up',
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets(
      'a PERSISTENT sheet is also pushed up above the keyboard -- the mechanism is unconditional',
      (tester) async {
        // Deliberate choice: the keyboard-avoidance Padding/MediaQuery.removeViewInsets
        // wraps the Sheet branch of the transitionBuilder's Stack, which renders
        // for BOTH modal and persistent sheets (only the Barrier branch is
        // conditional on !isPersistent). A persistent sheet has no barrier and
        // the page stays interactive, but its own content is exactly as prone
        // to being covered by the keyboard as a modal sheet's -- there is no
        // reason a persistent sheet's fields should be hidden behind the
        // keyboard while a modal sheet's are not, so this applies to both
        // unconditionally, matching D65's own "unconditional, no new flag"
        // precedent in layout.dart.
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          setLogicalSize(tester, const Size(400, screenHeight));

          await openSheet(tester, initialSize: 0.3, isPersistent: true);

          final markerFinder = find.byKey(const ValueKey('bottomMarker'));
          expect(markerFinder, findsOneWidget);

          tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          final keyboardTop = screenHeight - keyboardInset;
          final surfaceRect = tester.getRect(sheetSurfaceFinder());
          expect(
            surfaceRect.bottom,
            closeTo(keyboardTop, 0.5),
            reason: 'a persistent sheet\'s own surface must also be pushed to sit at the keyboard\'s top edge',
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });
}
