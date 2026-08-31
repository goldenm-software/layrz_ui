import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

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

    testWidgets('the content below the handle still clears the top inset', (tester) async {
      await pumpSheetWithTopInset(tester, showDragHandle: true);

      final surfaceRect = tester.getRect(sheetSurfaceFinder());
      final contentRect = tester.getRect(find.byKey(const ValueKey('sheetContent')));

      // The handle itself (plus its own internal padding) already occupies
      // real height at the top of the sheet, so the content must still sit
      // strictly below the surface's own top edge -- it is not glued to y=0
      // just because the SafeArea stopped adding its own top inset.
      expect(
        contentRect.top,
        greaterThan(surfaceRect.top),
        reason: 'content must still be pushed clear of the surface\'s top edge by the handle above it',
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
  });
}
