import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/select/select_input_surface.dart';

import '../../helpers/pump_themed.dart';

/// Direct tests for [LayrzSelectInputSurface], the selection surface content
/// shared by [LayrzSelectInput]'s desktop and mobile presentations.
///
/// This mirrors `lib/src/inputs/src/select/select_input_surface.dart`, repaying
/// test debt that was deliberately parked while the widget it covers was being
/// repaired (see Engram #1194) -- `select_input_test.dart` and
/// `select_input_a11y_test.dart` only ever exercised this surface indirectly,
/// through the full [LayrzSelectInput].
void main() {
  group('LayrzSelectInputSurface', () {
    final items = <LayrzSelectItem<String>>[
      const LayrzSelectItem(labelText: 'Apple', value: 'apple'),
      const LayrzSelectItem(labelText: 'Banana', value: 'banana'),
      const LayrzSelectItem(labelText: 'Cherry', value: 'cherry'),
    ];

    testWidgets('renders all items by default', (tester) async {
      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          items: items,
          enableSearch: true,
          canUnselect: false,
          onItemSelected: (_) {},
        ),
      );

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('tapping an item invokes onItemSelected with that item', (tester) async {
      LayrzSelectItem<String>? selected;

      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          items: items,
          enableSearch: true,
          canUnselect: false,
          onItemSelected: (item) => selected = item,
        ),
      );

      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();

      expect(selected?.value, equals('banana'));
    });

    testWidgets('tapping an item closes the panel via panelController when provided', (tester) async {
      final controller = MenuController();

      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          items: items,
          enableSearch: true,
          canUnselect: false,
          panelController: controller,
          onItemSelected: (_) {},
        ),
      );

      // No assertion errors calling close() on a controller with no attached
      // anchor is the behaviour under test -- MenuController.close() is a
      // no-op when nothing is attached, so tapping must not throw.
      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('search filters items using the default label match (query supplied by the caller)', (
      tester,
    ) async {
      // REWRITE (was: typed into the surface's own now-removed search box). The
      // surface no longer owns a search box -- the caller (LayrzSelectInput's
      // field) is the searcher and feeds the query in via this parameter. The
      // filtering behavior itself survives; only where the query comes from moved.
      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          items: items,
          enableSearch: true,
          canUnselect: false,
          query: 'ban',
          onItemSelected: (_) {},
        ),
      );

      // Assert the narrowing, not mere presence: the right item remains and the
      // wrong ones are gone.
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Cherry'), findsNothing);
    });

    testWidgets('search uses a custom filter function when provided (query supplied by the caller)', (
      tester,
    ) async {
      // REWRITE (was: typed into the surface's own now-removed search box).
      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          items: items,
          enableSearch: true,
          canUnselect: false,
          filter: (query, item) => item.value == 'cherry',
          query: 'anything',
          onItemSelected: (_) {},
        ),
      );

      // The custom filter always matches only "cherry", regardless of query.
      expect(find.text('Cherry'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('clearing the query restores the full list (no dedicated clear affordance on the surface)', (
      tester,
    ) async {
      // REWRITE, with a caveat: the surface's own inline clear (close) icon is
      // gone along with its search box -- that was a UI affordance on the
      // now-removed internal LayrzTextInput, not a capability of the surface
      // itself. There is no equivalent "clear" control on the surface to tap;
      // the caller (LayrzSelectInput's field) owns the query text entirely now.
      // What survives is the underlying behavior this test actually pins: an
      // empty query restores the full list. Proven here by rebuilding the SAME
      // mounted surface with a new `query` value via `didUpdateWidget`, exactly
      // as LayrzSelectInput does when its field's text changes.
      var query = 'ban';

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LayrzButton(
                  labelText: 'Clear',
                  onTap: () => setState(() => query = ''),
                ),
                LayrzSelectInputSurface<String>(
                  items: items,
                  enableSearch: true,
                  canUnselect: false,
                  query: query,
                  onItemSelected: (_) {},
                ),
              ],
            );
          },
        ),
      );
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Cherry'), findsNothing);

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets(
      'shows the default empty-list message when search matches nothing (query supplied by the caller)',
      (tester) async {
        // REWRITE (was: typed into the surface's own now-removed search box).
        await pumpThemed(
          tester,
          LayrzSelectInputSurface<String>(
            items: items,
            enableSearch: true,
            canUnselect: false,
            query: 'zzz-no-match',
            onItemSelected: (_) {},
          ),
        );

        expect(find.text('Apple'), findsNothing);
        expect(find.text('Banana'), findsNothing);
        expect(find.text('Cherry'), findsNothing);
        // The default l10n empty-state text is rendered; exact copy is an
        // l10n concern, so this only proves *a* message replaces the list.
        expect(find.byType(Text), findsOneWidget);
      },
    );

    testWidgets('shows a custom empty-list message when provided (query supplied by the caller)', (
      tester,
    ) async {
      // REWRITE (was: typed into the surface's own now-removed search box).
      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          items: items,
          enableSearch: true,
          canUnselect: false,
          emptyListText: 'Nothing here',
          query: 'zzz-no-match',
          onItemSelected: (_) {},
        ),
      );

      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('enableSearch: false ignores any query and always shows every item', (tester) async {
      // New coverage, prompted by retiring the old enableSearch:false focus test:
      // the false path needs no mode logic (see select_input.dart's class doc),
      // which specifically means it must never filter, even if a `query` were
      // somehow supplied. `_updateFilteredItems` forces the query to '' whenever
      // `enableSearch` is false; this pins that directly rather than leaving it
      // implicit.
      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          items: items,
          enableSearch: false,
          canUnselect: false,
          query: 'ban',
          onItemSelected: (_) {},
        ),
      );

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('selected item shows a selection indicator icon', (tester) async {
      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          items: items,
          selectedItem: items[1],
          enableSearch: true,
          canUnselect: false,
          onItemSelected: (_) {},
        ),
      );

      expect(find.byWidgetPredicate((w) => w is Icon), findsOneWidget);
    });

    testWidgets('renders custom item child when provided instead of default label text', (tester) async {
      final customItems = <LayrzSelectItem<String>>[
        LayrzSelectItem(labelText: 'Custom', value: 'custom', child: const Text('Custom Widget')),
      ];

      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          items: customItems,
          enableSearch: false,
          canUnselect: false,
          onItemSelected: (_) {},
        ),
      );

      expect(find.text('Custom Widget'), findsOneWidget);
      expect(find.text('Custom'), findsNothing);
    });

    group('keyboard navigation', () {
      testWidgets('arrow down then enter selects the first item', (tester) async {
        LayrzSelectItem<String>? selected;

        await pumpThemed(
          tester,
          LayrzSelectInputSurface<String>(
            items: items,
            enableSearch: false,
            canUnselect: false,
            onItemSelected: (item) => selected = item,
          ),
        );
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(selected?.value, equals('apple'));
      });

      testWidgets('arrow up wraps to the last item from no highlight', (tester) async {
        LayrzSelectItem<String>? selected;

        await pumpThemed(
          tester,
          LayrzSelectInputSurface<String>(
            items: items,
            enableSearch: false,
            canUnselect: false,
            onItemSelected: (item) => selected = item,
          ),
        );
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(selected?.value, equals('cherry'));
      });

      testWidgets('arrow down wraps from the last item back to the first', (tester) async {
        LayrzSelectItem<String>? selected;

        await pumpThemed(
          tester,
          LayrzSelectInputSurface<String>(
            items: items,
            enableSearch: false,
            canUnselect: false,
            onItemSelected: (item) => selected = item,
          ),
        );
        await tester.pump();

        // `items.length` presses walk from "no highlight" to the last item
        // (index `length - 1`); one more press is the wrap back to index 0.
        for (var i = 0; i < items.length + 1; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(selected?.value, equals('apple'));
      });

      testWidgets('enter with no highlight and no items does not call onItemSelected', (tester) async {
        var called = false;

        await pumpThemed(
          tester,
          LayrzSelectInputSurface<String>(
            items: const [],
            enableSearch: false,
            canUnselect: false,
            onItemSelected: (_) => called = true,
          ),
        );
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(called, isFalse);
      });

      testWidgets('escape pops the current route when no panelController is provided', (tester) async {
        await tester.pumpWidget(
          LayrzApp(
            home: Builder(
              builder: (context) {
                return LayrzButton(
                  labelText: 'Open',
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder<void>(
                        pageBuilder: (context, animation, secondaryAnimation) => LayrzSelectInputSurface<String>(
                          items: items,
                          enableSearch: false,
                          canUnselect: false,
                          onItemSelected: (_) {},
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();
        expect(find.byType(LayrzSelectInputSurface<String>), findsOneWidget);

        // No panelController -- routes to `Navigator.pop(context)` directly.
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.byType(LayrzSelectInputSurface<String>), findsNothing);
      });

      testWidgets('escape closes the panel via panelController when provided', (tester) async {
        final controller = MenuController();

        await pumpThemed(
          tester,
          LayrzSelectInputSurface<String>(
            items: items,
            enableSearch: false,
            canUnselect: false,
            panelController: controller,
            onItemSelected: (_) {},
          ),
        );
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // No attached anchor, so MenuController.close() is a no-op -- the
        // assertion here is that routing through it does not throw.
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('disposes internal controllers and focus nodes without throwing', (tester) async {
      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          items: items,
          enableSearch: true,
          canUnselect: false,
          onItemSelected: (_) {},
        ),
      );

      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isNull);
    });
  });
}
