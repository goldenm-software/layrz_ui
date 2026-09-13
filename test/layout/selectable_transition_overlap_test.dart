import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

/// A minimal stand-in for go_router's `CustomTransitionPage`, built the same
/// way: a [Page] whose [createRoute] returns a [PageRoute] that fades the
/// *incoming* child in via [Animation] alone, leaving [secondaryAnimation]
/// unused -- exactly [LayrzPageTransitions.fade]'s shape.
class _FadePage extends Page<void> {
  const _FadePage({required this.child, required LocalKey super.key});

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }
}

/// Structural regression test for the general shape behind the "Tab View ->
/// Table -> Text -> Table" showroom crash (`Assertion failed:
/// .../selectable_region.dart:1919:12 _selectable == null   is not true`):
/// two pages genuinely overlapping, both mounted at once, inside the one
/// [Navigator] that is [LayrzLayout]'s single, stable [SelectableRegion]
/// child during a fade transition.
///
/// [LayrzLayout] is the persistent shell (mirroring go_router's
/// `ShellRoute`, built once via its `builder`). Its [LayrzLayout.body] hosts
/// a declarative `Navigator(pages: ...)` -- the same shape go_router's
/// internal `RouteBuilder` uses -- whose `pages` list is swapped via
/// `setState` on every simulated `context.go(...)` call, exactly as
/// `example/lib/layout.dart`'s `_navigateTo` drives real navigation. Each
/// page is a [_FadePage], matching `example/lib/main.dart`'s `_fadePage`
/// (`LayrzPageTransitions.fade`, which only fades the incoming child --
/// `secondaryAnimation` is unused). Swapping the declarative `pages` list
/// (rather than imperatively pushing) matches go_router: the [Navigator]'s
/// [DefaultTransitionDelegate] keeps the previous page's route in the
/// [Overlay] until ITS OWN exit transition completes, so for the whole
/// transition window both the outgoing and incoming pages are mounted as
/// siblings.
///
/// **This test does NOT reproduce the actual reported crash** -- confirmed
/// by running it against the pre-fix code, where it also passed. The real
/// trigger is `BrowserContextMenu.enabled` (a process-wide, web-only flag)
/// flipping value while `SelectableRegionState` rebuilds mid-transition,
/// which only happens when a page in the overlap contains a
/// `LayrzContextMenu` (as `LayrzTable`'s header does, one per column) and
/// which is compiled out entirely under `flutter test` (`kIsWeb` is always
/// `false` there). See
/// `lib/src/context_menu/src/browser_context_menu_suppressor.dart` for the
/// full mechanism, the upstream Flutter issue it matches
/// (flutter/flutter#186459), and the fix; see
/// `test/context_menu/browser_context_menu_suppressor_test.dart` and
/// `test/context_menu/context_menu_suppression_test.dart` for the tests
/// that do exercise the fix. This test instead guards the adjacent
/// structural fact -- that a plain page overlap alone, without any
/// `LayrzContextMenu` involved, was never itself a problem for
/// [LayrzLayout]'s [SelectableRegion] -- so a future change cannot
/// reintroduce a crash on that simpler path without this test catching it.
void main() {
  group('LayrzLayout selection survives an overlapping declarative page transition', () {
    /// Builds a [LayrzLayout] whose body is a declarative `Navigator(pages:)`
    /// showing [pages], with pop handling wired but unused by these tests.
    Widget buildHarness(List<Page<void>> pages) {
      return LayrzLayout(
        logo: 'assets/test-logo.png',
        items: [
          LayrzNavigatorPage(id: 'home', labelText: 'Home'),
        ],
        selectableContent: true,
        body: Navigator(
          pages: pages,
          onDidRemovePage: (page) => pages.remove(page),
        ),
      );
    }

    testWidgets(
      'swapping pages mid-transition mounts both pages without throwing',
      (tester) async {
        List<Page<void>> pages = [
          const _FadePage(key: ValueKey('table'), child: Text('Table page content')),
        ];

        late StateSetter setPages;

        await pumpThemedApp(
          tester,
          StatefulBuilder(
            builder: (context, setState) {
              setPages = setState;
              return buildHarness(pages);
            },
          ),
        );

        expect(find.byType(SelectableRegion), findsOneWidget);
        expect(find.text('Table page content'), findsOneWidget);

        // Simulate context.go('/text') -- the whole `pages` list is replaced
        // (declarative navigation), not pushed. Pump PARTWAY through the
        // 300ms fade so both the outgoing ('Table page content') and
        // incoming ('Text page content') pages are mounted simultaneously
        // under the single SelectableRegion.
        setPages(() {
          pages = [
            const _FadePage(key: ValueKey('text'), child: Text('Text page content')),
          ];
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Both pages must be mounted at once for this to reproduce the
        // overlap -- if either finder comes back empty, the two routes are
        // not actually overlapping and this test proves nothing.
        expect(find.text('Table page content'), findsOneWidget);
        expect(find.text('Text page content'), findsOneWidget);

        // On unfixed code, the framework rebuilds the selection tree during
        // this overlap and SelectableRegionState.add() is called a second
        // time while _selectable is still non-null, throwing:
        //   Assertion failed: .../selectable_region.dart:1919:12
        //   _selectable == null   is not true
        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Simulate context.go('/table') again (mirrors Text -> Table) while
        // the previous transition may still be settling internal listeners,
        // to confirm the fix holds across repeated transitions.
        setPages(() {
          pages = [
            const _FadePage(key: ValueKey('table2'), child: Text('Table page content 2')),
          ];
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Text page content'), findsOneWidget);
        expect(find.text('Table page content 2'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'select-all still finds text after navigating through an overlapping transition',
      (tester) async {
        List<Page<void>> pages = [
          const _FadePage(key: ValueKey('first'), child: Text('First page selectable text')),
        ];

        late StateSetter setPages;

        await pumpThemedApp(
          tester,
          StatefulBuilder(
            builder: (context, setState) {
              setPages = setState;
              return buildHarness(pages);
            },
          ),
        );

        setPages(() {
          pages = [
            const _FadePage(key: ValueKey('second'), child: Text('Second page selectable text')),
          ];
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // The SelectableRegion must still be functional (registered exactly
        // once) after the overlap -- select-all should still resolve a
        // selection (non-empty selectionEndpoints) instead of the region
        // having lost its Selectable, and must not throw doing so.
        final state = tester.state<SelectableRegionState>(find.byType(SelectableRegion));
        state.selectAll(SelectionChangedCause.keyboard);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(state.selectionEndpoints, isNotEmpty);
      },
    );
  });
}
