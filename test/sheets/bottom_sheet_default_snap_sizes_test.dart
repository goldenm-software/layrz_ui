import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed_app.dart';

/// Regression coverage for the derived default `snapSizes`, exercised through
/// [LayrzBottomSheet.show]'s public surface rather than the private
/// `_defaultSnapSizes` helper: every test opens a real sheet and reads back
/// the actual [DraggableScrollableSheet] the SDK is handed, which is the same
/// widget whose internal assertion crashed before this fix.
///
/// Before this fix, `effectiveSnapSizes` was the hardcoded literal
/// `[0.5, 0.95]` regardless of the caller's own `minSize`/`maxSize` -- valid
/// only when `maxSize` stayed at its own default of `0.95`. Any caller who
/// narrowed `maxSize` below `0.95` (or above the top of that literal range on
/// the low end) and left `snapSizes` unset got a default snap point outside
/// their own `minSize..maxSize` range, and `DraggableScrollableSheet` asserts
/// `snapSize >= minChildSize && snapSize <= maxChildSize` for every entry.
void main() {
  group('LayrzBottomSheet default snapSizes derivation', () {
    guardedTestWidgets(
      'untouched defaults (minSize: 0.25, maxSize: 0.95) still produce exactly [0.5, 0.95]',
      (tester) async {
        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                LayrzBottomSheet.show<void>(
                  context,
                  builder: (context) => const SizedBox(height: 200),
                );
              },
              child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
            ),
          ),
        );

        await tester.tap(find.text('Tap'));
        await tester.pumpAndSettle();

        final sheet = tester.widget<DraggableScrollableSheet>(find.byType(DraggableScrollableSheet));
        expect(
          sheet.snapSizes,
          [0.5, 0.95],
          reason: 'no existing caller relying on the implicit default may see its snap points shift',
        );
        expect(sheet.minChildSize, 0.25);
        expect(sheet.maxChildSize, 0.95);
      },
    );

    guardedTestWidgets(
      'the exact failing combination (maxSize: 0.5, no snapSizes) no longer crashes and stays in-bounds',
      (tester) async {
        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                LayrzBottomSheet.show<void>(
                  context,
                  isPersistent: true,
                  canDismiss: false,
                  initialSize: 0.3,
                  maxSize: 0.5,
                  builder: (context) => const SizedBox(height: 200),
                );
              },
              child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
            ),
          ),
        );

        await tester.tap(find.text('Tap'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'opening must not throw the snapSize assertion');

        final sheet = tester.widget<DraggableScrollableSheet>(find.byType(DraggableScrollableSheet));
        expect(sheet.maxChildSize, 0.5);
        for (final size in sheet.snapSizes!) {
          expect(
            size,
            inInclusiveRange(sheet.minChildSize, sheet.maxChildSize),
            reason: 'every derived snap point must lie within minSize..maxSize by construction',
          );
        }
        expect(
          sheet.snapSizes,
          [0.375, 0.5],
          reason:
              'with minSize 0.25 (this method\'s own default) and maxSize 0.5, the historical 0.5 low '
              'snap point sits AT maxSize rather than strictly inside it, so the derivation falls back '
              'to the range midpoint (0.25 + (0.5 - 0.25) / 2 == 0.375) instead',
        );
      },
      // This test is itself the "before" proof: expectOverflow stays false, so any assertion
      // thrown while opening the sheet surfaces via tester.takeException() at the wrapper's own
      // check, in addition to the explicit assertion above.
    );

    guardedTestWidgets(
      'a narrowed minSize that still allows the historical 0.5 point keeps it as the low snap',
      (tester) async {
        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                LayrzBottomSheet.show<void>(
                  context,
                  minSize: 0.4,
                  maxSize: 0.95,
                  initialSize: 0.5,
                  builder: (context) => const SizedBox(height: 200),
                );
              },
              child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
            ),
          ),
        );

        await tester.tap(find.text('Tap'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final sheet = tester.widget<DraggableScrollableSheet>(find.byType(DraggableScrollableSheet));
        expect(
          sheet.snapSizes,
          [0.5, 0.95],
          reason: '0.5 still lies strictly inside (0.4, 0.95), so it is kept as-is',
        );
      },
    );

    guardedTestWidgets(
      'a narrowed minSize that excludes the historical 0.5 point falls back to the range midpoint',
      (tester) async {
        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                LayrzBottomSheet.show<void>(
                  context,
                  minSize: 0.6,
                  maxSize: 0.95,
                  initialSize: 0.7,
                  builder: (context) => const SizedBox(height: 200),
                );
              },
              child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
            ),
          ),
        );

        await tester.tap(find.text('Tap'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final sheet = tester.widget<DraggableScrollableSheet>(find.byType(DraggableScrollableSheet));
        expect(sheet.snapSizes, hasLength(2));
        expect(
          sheet.snapSizes![0],
          closeTo(0.775, 1e-9),
          reason:
              '0.5 is below minSize (0.6), so the low snap point falls back to the midpoint of '
              '0.6..0.95, which is 0.775',
        );
        expect(sheet.snapSizes![1], 0.95);
      },
    );

    guardedTestWidgets(
      'the degenerate minSize == maxSize collapses to a single-element, in-bounds snapSizes',
      (tester) async {
        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                LayrzBottomSheet.show<void>(
                  context,
                  minSize: 0.5,
                  maxSize: 0.5,
                  initialSize: 0.5,
                  builder: (context) => const SizedBox(height: 200),
                );
              },
              child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
            ),
          ),
        );

        await tester.tap(find.text('Tap'));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'a fixed-height sheet (minSize == maxSize) must not crash from a duplicated snap point',
        );

        final sheet = tester.widget<DraggableScrollableSheet>(find.byType(DraggableScrollableSheet));
        expect(
          sheet.snapSizes,
          [0.5],
          reason: 'no room for two ascending points when minSize == maxSize, so only one is kept',
        );
      },
    );
  });
}
