import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/context_menu/src/browser_context_menu_suppressor.dart';

void main() {
  group('LayrzBrowserContextMenuSuppressor', () {
    // The reference count is a static, process-wide value shared by every
    // test in this file (and, in a real app, every LayrzContextMenu
    // instance) -- reset it after each test so tests remain order-independent.
    tearDown(() {
      while (LayrzBrowserContextMenuSuppressor.debugRefCount > 0) {
        LayrzBrowserContextMenuSuppressor.release();
      }
    });

    test('starts at zero', () {
      expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 0);
    });

    test('acquire increments the shared count', () {
      LayrzBrowserContextMenuSuppressor.acquire();
      expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 1);

      LayrzBrowserContextMenuSuppressor.acquire();
      expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 2);
    });

    test('release decrements the shared count', () {
      LayrzBrowserContextMenuSuppressor.acquire();
      LayrzBrowserContextMenuSuppressor.acquire();
      LayrzBrowserContextMenuSuppressor.release();
      expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 1);

      LayrzBrowserContextMenuSuppressor.release();
      expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 0);
    });

    test(
      'the count never goes negative across many concurrent acquire/release pairs '
      '(the shape LayrzTable\'s per-column headers produce)',
      () {
        // Simulates LayrzTable mounting one LayrzContextMenu per visible
        // column (several concurrent acquisitions), then a page navigation
        // disposing them all.
        for (var i = 0; i < 7; i++) {
          LayrzBrowserContextMenuSuppressor.acquire();
        }
        expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 7);

        for (var i = 0; i < 7; i++) {
          LayrzBrowserContextMenuSuppressor.release();
        }
        expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 0);
      },
    );

    test(
      'the count stays above zero across an overlapping navigation, matching the fix\'s intent',
      () {
        // Outgoing page's suppressors (e.g. Table's header cells).
        for (var i = 0; i < 4; i++) {
          LayrzBrowserContextMenuSuppressor.acquire();
        }
        expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 4);

        // Incoming page's suppressors mount before the outgoing page's
        // dispose, exactly as two pages overlap during a fade transition.
        for (var i = 0; i < 3; i++) {
          LayrzBrowserContextMenuSuppressor.acquire();
        }
        expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 7);

        // Outgoing page disposes -- count never touches zero mid-transition,
        // so the shared BrowserContextMenu flag never actually flips value
        // while both pages are mounted.
        for (var i = 0; i < 4; i++) {
          LayrzBrowserContextMenuSuppressor.release();
        }
        expect(LayrzBrowserContextMenuSuppressor.debugRefCount, 3);
        expect(LayrzBrowserContextMenuSuppressor.debugRefCount, greaterThan(0));
      },
    );

    test('release without a matching acquire throws in debug mode', () {
      expect(() => LayrzBrowserContextMenuSuppressor.release(), throwsA(isA<AssertionError>()));
    });
  });
}
