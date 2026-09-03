import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Proof coverage for the maintainer's device-reported defect (confirmed on
/// iOS iPhone 17 Pro and Android): the drag handle used to be the first child
/// of the `SafeArea` inside the sheet's surface, so the SafeArea's top inset
/// pushed the handle DOWN, leaving a band of bare sheet surface above it. On
/// an iPhone with a Dynamic Island that inset is ~59dp, clearly visible
/// whenever the sheet is expanded close to the top of the screen.
///
/// The fix moves the handle OUTSIDE the SafeArea, as the first child of the
/// outer `Column`, so it sits flush with the sheet surface's own top edge
/// regardless of the system inset. The content below it stays inside a
/// SafeArea, but that SafeArea's `top` is only applied when there is no
/// handle above it to already occupy that strip -- see the long comment in
/// `bottom_sheet.dart` above the surface `Column`.
///
/// `tester.view.padding`/`viewPadding` default to ZERO, so a test that never
/// injects a non-zero top inset cannot distinguish "flush" from "pushed
/// down" -- this file exists specifically to inject one.
void main() {
  /// Pumps a modal [LayrzBottomSheet] with a non-zero top system-bar inset
  /// (simulating a notch/Dynamic Island), expanded close to the top of the
  /// screen so the inset genuinely has room to misplace the handle.
  Future<void> pumpSheetWithTopInset(
    WidgetTester tester, {
    required bool showDragHandle,
    double topInset = 59,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.padding = FakeViewPadding(top: topInset, bottom: 24);
    tester.view.viewPadding = FakeViewPadding(top: topInset, bottom: 24);
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
        initialSize: 0.95,
        minSize: 0.25,
        maxSize: 0.95,
        showDragHandle: showDragHandle,
        builder: (context) => const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Sheet content', key: ValueKey('sheetContent')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Finds the sheet's own decorated surface -- the [DecoratedBox] built
  /// directly inside [DraggableScrollableSheet]'s builder, distinguished from
  /// the drag handle's own pill decoration by requiring a [BoxShadow].
  Finder sheetSurfaceFinder() {
    return find.byWidgetPredicate(
      (w) => w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).boxShadow != null,
    );
  }

  group('LayrzBottomSheet drag handle sits flush with the top edge (device-reported defect)', () {
    testWidgets('the handle top edge is flush with the surface top edge under a non-zero top inset', (tester) async {
      await pumpSheetWithTopInset(tester, showDragHandle: true);

      final surfaceRect = tester.getRect(sheetSurfaceFinder());

      final candidateHandles = find
          .byWidgetPredicate((w) => w is GestureDetector)
          .evaluate()
          .map((e) => tester.getRect(find.byWidgetPredicate((w) => w == e.widget)))
          .where((r) => r.height < 100)
          .toList();
      expect(candidateHandles, isNotEmpty, reason: 'the drag handle must be present');
      final handleRect = candidateHandles.first;

      // This is the assertion that fails against the pre-fix code: with the
      // handle as the SafeArea's first child, handleRect.top would sit at
      // surfaceRect.top + topInset (~59px lower), not flush with it.
      expect(
        handleRect.top,
        closeTo(surfaceRect.top, 0.5),
        reason:
            'the drag handle (top=${handleRect.top}) must be flush with the sheet surface\'s own top edge '
            '(top=${surfaceRect.top}), not pushed down by the system top inset',
      );
    });

    testWidgets('the content below the handle still clears the full top inset, not just the handle', (tester) async {
      const topInset = 59.0;
      await pumpSheetWithTopInset(tester, showDragHandle: true, topInset: topInset);

      final surfaceRect = tester.getRect(sheetSurfaceFinder());
      final contentRect = tester.getRect(find.byKey(const ValueKey('sheetContent')));

      // The handle's own footprint (pill + padding, ~32px at default tokens)
      // is SMALLER than a real notch/Dynamic-Island inset (59px here) -- the
      // regression this test guards against is content clearing only the
      // handle's height and still landing inside the unsafe strip. The
      // content must clear the FULL top inset measured from the surface's
      // own top edge, exactly like the no-handle case below, regardless of
      // whether the handle is also covering part of that same strip.
      expect(
        contentRect.top - surfaceRect.top,
        greaterThanOrEqualTo(topInset - 0.5),
        reason:
            'content (top=${contentRect.top}) must clear the full ${topInset}px top system inset measured from '
            'the surface top (${surfaceRect.top}), not just the drag handle\'s own smaller footprint',
      );
    });

    testWidgets('with showDragHandle: false, the content SafeArea still insets the top itself', (tester) async {
      await pumpSheetWithTopInset(tester, showDragHandle: false);

      final surfaceRect = tester.getRect(sheetSurfaceFinder());
      final contentRect = tester.getRect(find.byKey(const ValueKey('sheetContent')));

      // With no handle to occupy the top strip, the content SafeArea must
      // fall back to inseting the top itself -- otherwise content would sit
      // directly under the notch with nothing at all protecting it.
      expect(
        contentRect.top - surfaceRect.top,
        greaterThanOrEqualTo(59.0),
        reason: 'without a drag handle, the content itself must be inset clear of the ~59px top system inset',
      );
    });

    // The handle's own footprint (DragHandle.pillHeight + 2 * tokens.spacing.sp3
    // = 4.0 + 2 * 14.0) at the design system's default tokens. Computed here,
    // not imported, so these tests fail loudly (not silently pass with a wrong
    // number) if the tokens this footprint is built from ever change -- the
    // point of these tests is to pin _topContentInset's math against a value
    // computed the same way production code computes it, from the same
    // constants, independent of this file.
    const handleFootprint = 32.0;

    // pumpSheetWithTopInset's own builder wraps 'Sheet content' in
    // `Padding(padding: EdgeInsets.all(16))` (see above) -- that 16px is the
    // fixture's own content chrome, entirely below _topContentInset's Padding
    // in the tree, so it adds a further 16px between the SafeArea's own top
    // and the ValueKey('sheetContent') text on every test in this file. The
    // exact-clearance assertions below (unlike the two existing
    // greaterThanOrEqualTo checks above, which are insensitive to it) must
    // account for this fixture padding to assert a tight tolerance without
    // being thrown off by content chrome that has nothing to do with the
    // sheet's own top-inset computation.
    const fixtureContentPadding = 16.0;

    guardedTestWidgets(
      'zero top inset (no notch): content sits immediately below the handle footprint, no extra gap',
      (tester) async {
        await pumpSheetWithTopInset(tester, showDragHandle: true, topInset: 0);

        final surfaceRect = tester.getRect(sheetSurfaceFinder());
        final contentRect = tester.getRect(find.byKey(const ValueKey('sheetContent')));

        // Handle still flush with a zero inset -- the branch that clamped a
        // negative footprint to zero must not have also pushed the handle
        // itself down.
        final candidateHandles = find
            .byWidgetPredicate((w) => w is GestureDetector)
            .evaluate()
            .map((e) => tester.getRect(find.byWidgetPredicate((w) => w == e.widget)))
            .where((r) => r.height < 100)
            .toList();
        expect(candidateHandles, isNotEmpty, reason: 'the drag handle must be present');
        final handleRect = candidateHandles.first;
        expect(
          handleRect.top,
          closeTo(surfaceRect.top, 0.5),
          reason:
              'with zero top inset, the drag handle (top=${handleRect.top}) must still be flush with the '
              'surface top edge (top=${surfaceRect.top})',
        );

        // This is the assertion that pins the "no phantom gap" regression:
        // most devices carry no top inset at all in landscape, and this is
        // also the ordinary Android-without-notch case in portrait. With
        // topPadding == 0, _topContentInset's math.max(0.0, 0 - 32.0) must
        // clamp to exactly 0.0, not leave the raw negative -32.0 subtracted
        // anywhere -- so content clearance must equal the handle's own
        // footprint (~32px) exactly, not 32 plus some additional gap that a
        // future change to the clamp could silently reintroduce.
        expect(
          contentRect.top - surfaceRect.top,
          closeTo(handleFootprint + fixtureContentPadding, 0.5),
          reason:
              'with zero top inset, content (top=${contentRect.top}) must clear exactly the handle\'s own '
              'footprint (~${handleFootprint}px) plus the fixture\'s own ${fixtureContentPadding}px content '
              'padding, measured from the surface top (${surfaceRect.top}), with no extra phantom gap from a '
              'mis-clamped topContentInset',
        );
      },
    );

    guardedTestWidgets(
      'top inset smaller than the handle footprint clamps to zero extra inset, not a negative or doubled gap',
      (tester) async {
        const topInset = 20.0; // below the ~32px handle footprint
        await pumpSheetWithTopInset(tester, showDragHandle: true, topInset: topInset);

        final surfaceRect = tester.getRect(sheetSurfaceFinder());
        final contentRect = tester.getRect(find.byKey(const ValueKey('sheetContent')));

        // This is the exact branch math.max(0.0, topPadding - handleFootprint)
        // exists for: topPadding (20) - handleFootprint (32) is negative
        // (-12), and nothing currently exercises that arithmetic. If the
        // clamp were removed or inverted, content would land ABOVE the
        // handle's own footprint (a negative extra inset) instead of
        // clamping to zero -- this asserts the clamped value, not the raw
        // subtraction.
        expect(
          contentRect.top - surfaceRect.top,
          closeTo(handleFootprint + fixtureContentPadding, 0.5),
          reason:
              'with a ${topInset}px top inset (smaller than the ~${handleFootprint}px handle footprint), '
              'content (top=${contentRect.top}) must still sit at exactly the handle footprint plus the '
              'fixture\'s own ${fixtureContentPadding}px content padding, measured from the surface top '
              '(${surfaceRect.top}) -- the extra inset must clamp to zero, not go negative',
        );
      },
    );

    guardedTestWidgets(
      'keyboard open together with a top inset: handle stays flush and content still clears the full top inset',
      (tester) async {
        const topInset = 59.0;
        const keyboardInset = 300.0;
        await pumpSheetWithTopInset(tester, showDragHandle: true, topInset: topInset);

        // Mirrors bottom_sheet_keyboard_insets_test.dart's own injection: set
        // viewInsets.bottom on the existing view AFTER the sheet is already
        // open and settled, then re-settle -- this is the maintainer's exact
        // device-reported configuration, a select sheet with the keyboard at
        // full height while a Dynamic-Island-sized top inset is also present.
        tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final surfaceRect = tester.getRect(sheetSurfaceFinder());
        final contentRect = tester.getRect(find.byKey(const ValueKey('sheetContent')));

        final candidateHandles = find
            .byWidgetPredicate((w) => w is GestureDetector)
            .evaluate()
            .map((e) => tester.getRect(find.byWidgetPredicate((w) => w == e.widget)))
            .where((r) => r.height < 100)
            .toList();
        expect(candidateHandles, isNotEmpty, reason: 'the drag handle must still be present with the keyboard open');
        final handleRect = candidateHandles.first;
        expect(
          handleRect.top,
          closeTo(surfaceRect.top, 0.5),
          reason:
              'with the keyboard open, the drag handle (top=${handleRect.top}) must still be flush with the '
              'sheet surface\'s own top edge (top=${surfaceRect.top}), unaffected by the bottom viewInsets',
        );
        expect(
          contentRect.top - surfaceRect.top,
          greaterThanOrEqualTo(topInset - 0.5),
          reason:
              'with the keyboard open, content (top=${contentRect.top}) must still clear the full '
              '${topInset}px top system inset measured from the surface top (${surfaceRect.top}), exactly as '
              'it does with no keyboard present',
        );
      },
    );

    guardedTestWidgets(
      'a large top inset scales content clearance to the full inset, not a hardcoded 59 or 32',
      (tester) async {
        const topInset = 100.0;
        await pumpSheetWithTopInset(tester, showDragHandle: true, topInset: topInset);

        final surfaceRect = tester.getRect(sheetSurfaceFinder());
        final contentRect = tester.getRect(find.byKey(const ValueKey('sheetContent')));

        expect(
          contentRect.top - surfaceRect.top,
          closeTo(topInset + fixtureContentPadding, 0.5),
          reason:
              'with a ${topInset}px top inset, content (top=${contentRect.top}) must clear exactly that full '
              'inset plus the fixture\'s own ${fixtureContentPadding}px content padding, measured from the '
              'surface top (${surfaceRect.top}), proving the computation scales with the actual inset rather '
              'than being hardcoded to a specific device value',
        );
      },
    );
  });
}
