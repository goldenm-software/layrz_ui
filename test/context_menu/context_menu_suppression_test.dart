import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/context_menu/src/browser_context_menu_suppressor.dart';

import '../helpers/pump_themed.dart';

/// Regression coverage for the fix behind the "Tab View -> Table -> Text ->
/// Table" showroom crash (`SelectableRegionState.add()` asserting
/// `_selectable == null` -- see `test/layout/` for the mechanism). The fix
/// routes every [LayrzContextMenu]'s browser context-menu suppression
/// through the shared [LayrzBrowserContextMenuSuppressor] refcount instead
/// of each instance calling `BrowserContextMenu` directly, so that
/// `LayrzTable`'s many per-column [LayrzContextMenu] instances mounting and
/// disposing together (as they do on every navigation onto/off of a table
/// page) no longer flips the process-wide flag on every navigation.
void main() {
  group('LayrzContextMenu browser context-menu suppression', () {
    setUp(() {
      // The refcount is process-wide static state; start every test from a
      // known baseline regardless of what earlier tests in the suite left
      // behind.
      while (LayrzBrowserContextMenuSuppressor.debugRefCount > 0) {
        LayrzBrowserContextMenuSuppressor.release();
      }
    });

    testWidgets('mounting one instance acquires exactly one suppression', (tester) async {
      await pumpThemed(
        tester,
        const LayrzContextMenu(
          entries: [],
          child: SizedBox(width: 100, height: 40, child: Text('Header')),
        ),
      );

      expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 1);
    });

    testWidgets('disposing the only mounted instance releases the suppression', (tester) async {
      await pumpThemed(
        tester,
        const LayrzContextMenu(
          entries: [],
          child: SizedBox(width: 100, height: 40, child: Text('Header')),
        ),
      );
      expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 1);

      // Unmount by pumping an unrelated tree in its place.
      await tester.pumpWidget(const SizedBox.shrink());

      expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 0);
    });

    testWidgets(
      'many concurrent instances (LayrzTable header shape) share one suppression window',
      (tester) async {
        await pumpThemed(
          tester,
          Row(
            children: List.generate(
              7,
              (i) => LayrzContextMenu(
                entries: const [],
                child: SizedBox(width: 80, height: 40, child: Text('Column $i')),
              ),
            ),
          ),
        );

        // Seven header cells, each its own LayrzContextMenu -- the refcount
        // reflects all seven, not a flip-flopping single flag.
        expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 7);

        await tester.pumpWidget(const SizedBox.shrink());

        expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 0);
      },
    );

    testWidgets(
      'navigating between two suppressing pages never drops the count to zero mid-transition',
      (tester) async {
        // Mirrors two overlapping pages (e.g. Table and another
        // context-menu-bearing page) both mounted at once during a fade
        // transition -- the incoming page's LayrzContextMenu instances
        // mount before the outgoing page's dispose.
        await pumpThemed(
          tester,
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                LayrzContextMenu(entries: const [], child: SizedBox(key: ValueKey('old-$i'))),
            ],
          ),
        );
        expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 3);

        await pumpThemed(
          tester,
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                LayrzContextMenu(entries: const [], child: SizedBox(key: ValueKey('old-$i'))),
              for (var i = 0; i < 2; i++)
                LayrzContextMenu(entries: const [], child: SizedBox(key: ValueKey('new-$i'))),
            ],
          ),
        );
        // Old instances are still mounted (same keys, still present) and
        // new ones have joined -- count only grows, never dips to zero.
        expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 5);

        await pumpThemed(
          tester,
          Row(
            children: [
              for (var i = 0; i < 2; i++)
                LayrzContextMenu(entries: const [], child: SizedBox(key: ValueKey('new-$i'))),
            ],
          ),
        );
        // Old instances disposed -- count drops but never touched zero
        // while the new page's instances were live.
        expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 2);
        expect(LayrzBrowserContextMenuSuppressor.debugRefCount, greaterThan(0));

        await tester.pumpWidget(const SizedBox.shrink());
        expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 0);
      },
    );
  });
}
