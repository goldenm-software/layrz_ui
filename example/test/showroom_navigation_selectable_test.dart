import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Navigation smoke test against the real showroom app and its real
/// go_router `ShellRoute` + fade `CustomTransitionPage` routing, covering
/// the exact sequence reported live on Flutter web as breaking the content
/// pane with:
///   Assertion failed: .../selectable_region.dart:1919:12
///   _selectable == null   is not true
///
/// **Coverage note:** the assertion's actual trigger --
/// `BrowserContextMenu.enabled` flipping mid page-transition, read by
/// `SelectableRegionState.build()` (see
/// `lib/src/context_menu/src/browser_context_menu_suppressor.dart` for the
/// full mechanism and the fix) -- is gated behind `kIsWeb`, which is always
/// `false` under `flutter test`'s VM/DDC test runner. This test therefore
/// cannot reproduce the crash itself; it exists to catch any OTHER
/// exception this navigation sequence might throw, and to document the
/// exact repro steps. The real regression coverage for the fix lives in
/// `test/context_menu/browser_context_menu_suppressor_test.dart` and
/// `test/context_menu/context_menu_suppression_test.dart`, which verify the
/// shared reference count that prevents the flag from flapping.
void main() {
  testWidgets(
    'navigating Tab View -> Table -> Text -> Table does not crash the SelectableRegion',
    (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const ProviderScope(child: ShowroomApp(font: LayrzRobotoFont())),
      );
      await tester.pumpAndSettle();

      Future<void> navigateTo(String label) async {
        // Rail item labels render as RichText with a leading icon
        // WidgetSpan, so their plain text is "<icon glyphs><label>" rather
        // than the bare label -- match by substring instead of exact text.
        final finder = find.textContaining(label, findRichText: true);
        expect(finder, findsWidgets, reason: 'nav item "$label" must be present to tap it');
        await tester.ensureVisible(finder.first);
        await tester.pumpAndSettle();
        await tester.tap(finder.first);
        // Pump partway through the 300ms fade transition so the outgoing
        // and incoming pages are both mounted at once, then continue
        // pumping in small steps through the whole transition window --
        // the crash fires while the framework is mid-rebuild, not
        // necessarily on the very first frame after the tap.
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.pumpAndSettle();
      }

      await navigateTo('Tab View');
      expect(tester.takeException(), isNull);

      await navigateTo('Table');
      expect(tester.takeException(), isNull);

      await navigateTo('Text');
      expect(tester.takeException(), isNull);

      await navigateTo('Table');
      expect(tester.takeException(), isNull);

      // The layout's SelectableRegion must have survived the whole
      // sequence -- exactly one instance, no crash loop.
      expect(find.byType(SelectableRegion), findsOneWidget);
    },
  );
}
