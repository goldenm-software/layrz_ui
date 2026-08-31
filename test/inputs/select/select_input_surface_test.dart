import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
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
      const LayrzSelectItem(value: 'apple', child: Text('Apple'), searchableStrings: {'Apple'}),
      const LayrzSelectItem(value: 'banana', child: Text('Banana'), searchableStrings: {'Banana'}),
      const LayrzSelectItem(value: 'cherry', child: Text('Cherry'), searchableStrings: {'Cherry'}),
    ];

    testWidgets('renders all items by default', (tester) async {
      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          itemExtent: 40,
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
          itemExtent: 40,
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
          itemExtent: 40,
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

    testWidgets('search filters items using searchableStrings (typed into the surface\'s own search field)', (
      tester,
    ) async {
      // REWRITE (DESIGN-145 reverts search ownership back to the surface: it owns
      // its own internal search field again, rather than being fed a `query` by
      // the caller). The filtering behavior itself survives; only where the query
      // comes from moved back.
      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          itemExtent: 40,
          items: items,
          enableSearch: true,
          canUnselect: false,
          onItemSelected: (_) {},
        ),
      );

      await tester.enterText(find.byType(EditableText), 'ban');
      await tester.pumpAndSettle();

      // Assert the narrowing, not mere presence: the right item remains and the
      // wrong ones are gone.
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Cherry'), findsNothing);
    });

    testWidgets('search matches searchableStrings even when the matched text is not in the child', (
      tester,
    ) async {
      // The whole reason `searchableStrings` and `child` are separate fields: an item
      // can be found by text that never appears on screen at all (a code, an ID, an
      // alternate spelling).
      final itemsWithHiddenSearchTerms = <LayrzSelectItem<String>>[
        const LayrzSelectItem(value: 'apple', child: Text('Apple'), searchableStrings: {'Apple', 'fruit-001'}),
        const LayrzSelectItem(value: 'banana', child: Text('Banana'), searchableStrings: {'Banana', 'fruit-002'}),
      ];

      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          itemExtent: 40,
          items: itemsWithHiddenSearchTerms,
          enableSearch: true,
          canUnselect: false,
          onItemSelected: (_) {},
        ),
      );

      await tester.enterText(find.byType(EditableText), 'fruit-002');
      await tester.pumpAndSettle();

      // "fruit-002" appears nowhere in either item's rendered child -- only in
      // Banana's searchableStrings -- yet it narrows the list to just Banana.
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
    });

    testWidgets('search uses a custom filter function when provided (typed into the surface\'s own search field)', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          itemExtent: 40,
          items: items,
          enableSearch: true,
          canUnselect: false,
          filter: (query, item) => item.value == 'cherry',
          onItemSelected: (_) {},
        ),
      );

      await tester.enterText(find.byType(EditableText), 'anything');
      await tester.pumpAndSettle();

      // The custom filter always matches only "cherry", regardless of query.
      expect(find.text('Cherry'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('the search field\'s own clear affordance restores the full list', (
      tester,
    ) async {
      // REWRITE (DESIGN-145): the surface owns its own search field again, and
      // that field grows its own inline clear ("x") suffix the moment it holds
      // text -- restoring the dedicated clear affordance a prior rewrite of this
      // test noted as gone.
      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          itemExtent: 40,
          items: items,
          enableSearch: true,
          canUnselect: false,
          onItemSelected: (_) {},
        ),
      );

      await tester.enterText(find.byType(EditableText), 'ban');
      await tester.pumpAndSettle();

      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Cherry'), findsNothing);

      await tester.tap(find.byIcon(MdiIcons.close));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets(
      'shows the default empty-list message when search matches nothing (typed into the surface\'s own search field)',
      (tester) async {
        await pumpThemed(
          tester,
          LayrzSelectInputSurface<String>(
            itemExtent: 40,
            items: items,
            enableSearch: true,
            canUnselect: false,
            onItemSelected: (_) {},
          ),
        );

        await tester.enterText(find.byType(EditableText), 'zzz-no-match');
        await tester.pumpAndSettle();

        expect(find.text('Apple'), findsNothing);
        expect(find.text('Banana'), findsNothing);
        expect(find.text('Cherry'), findsNothing);
        // The default l10n empty-state text is rendered; exact copy is an
        // l10n concern, so this only proves *a* message replaces the list.
        expect(
          find.text(LayrzUiL10n.of(tester.element(find.byType(LayrzSelectInputSurface<String>))).selectEmpty),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows a custom empty-list message when provided (typed into the surface\'s own search field)', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          itemExtent: 40,
          items: items,
          enableSearch: true,
          canUnselect: false,
          emptyListText: 'Nothing here',
          onItemSelected: (_) {},
        ),
      );

      await tester.enterText(find.byType(EditableText), 'zzz-no-match');
      await tester.pumpAndSettle();

      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('enableSearch: false renders no search field and always shows every item', (tester) async {
      // The false path needs no search UI at all (see select_input.dart's class
      // doc): `_updateFilteredItems` forces the query to '' whenever
      // `enableSearch` is false, and no search field is built in the first place.
      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          itemExtent: 40,
          items: items,
          enableSearch: false,
          canUnselect: false,
          onItemSelected: (_) {},
        ),
      );

      expect(find.byType(EditableText), findsNothing);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('selected item shows a selection indicator icon', (tester) async {
      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          itemExtent: 40,
          items: items,
          selectedItem: items[1],
          enableSearch: true,
          canUnselect: false,
          onItemSelected: (_) {},
        ),
      );

      // `byIcon`, not a bare `Icon` predicate: `enableSearch: true` now also
      // renders the internal search field's own decorative magnifier icon (see
      // the class doc), so a bare "any Icon" count would find two.
      expect(find.byIcon(MdiIcons.check), findsOneWidget);
    });

    testWidgets('renders the item\'s child widget (its only presentation)', (tester) async {
      final customItems = <LayrzSelectItem<String>>[
        const LayrzSelectItem(value: 'custom', child: Text('Custom Widget')),
      ];

      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          itemExtent: 40,
          items: customItems,
          enableSearch: false,
          canUnselect: false,
          onItemSelected: (_) {},
        ),
      );

      expect(find.text('Custom Widget'), findsOneWidget);
    });

    testWidgets('custom item child is forced to the body text style, never inherited implicitly', (tester) async {
      // Regression guard for the "white text" bug: a bare `item.child` with no
      // explicit color (like this plain Text) must not depend on whatever
      // DefaultTextStyle happens to be ambient -- it must resolve to the real
      // tokens.typography.body color every time. `pumpThemed` deliberately sets
      // up no DefaultTextStyle at all (see its own doc comment), so this fails
      // against the bare `item.child ?? Text(...)` rendering (color resolves to
      // null, which the engine then paints white) and passes once the row wraps
      // `item.child` in its own `DefaultTextStyle(style: tokens.typography.body)`.
      final customItems = <LayrzSelectItem<String>>[
        const LayrzSelectItem(value: 'custom', child: Text('Custom Widget')),
      ];

      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          itemExtent: 40,
          items: customItems,
          enableSearch: false,
          canUnselect: false,
          onItemSelected: (_) {},
        ),
      );

      final richText = tester.widget<RichText>(
        find.descendant(of: find.text('Custom Widget'), matching: find.byType(RichText)),
      );
      final bodyColor = LayrzThemeData.light().tokens.typography.body.color;

      expect(richText.text.style?.color, isNotNull);
      expect(richText.text.style?.color, equals(bodyColor));
    });

    group('keyboard navigation', () {
      testWidgets('arrow down then enter selects the first item', (tester) async {
        LayrzSelectItem<String>? selected;

        await pumpThemed(
          tester,
          LayrzSelectInputSurface<String>(
            itemExtent: 40,
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
            itemExtent: 40,
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
            itemExtent: 40,
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
            itemExtent: 40,
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
                          itemExtent: 40,
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
            itemExtent: 40,
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

    testWidgets(
      'the internal ListView has no phantom leading gap from the ambient top inset '
      '(device-confirmed on an iPhone 17 Pro Max: ~59px gap with the keyboard open)',
      (tester) async {
        // A bare `ListView.builder` with no explicit `padding:` falls back to deriving
        // its scroll-axis padding from the ambient `MediaQuery.maybeOf(context).padding`
        // (SDK's `ScrollView.buildSlivers`, scroll_view.dart, around lines 900-916 on the
        // pinned 3.47 SDK) -- unconditionally, whenever an ancestor `MediaQuery` reports a
        // nonzero `padding.top`. This surface's `ListView` is never the outermost
        // scrollable in either of its real hosts (the bottom sheet or the anchored
        // panel), both of which already own and account for the device's top inset in
        // their own chrome -- so this inner `ListView` re-applying the same inset a
        // SECOND time, entirely inside its own viewport, is the phantom gap.
        //
        // `tester.view.padding` defaults to ZERO, which is the "no notch" condition
        // where this bug cannot occur -- an explicit `FakeViewPadding` is required to
        // reproduce it at all.
        const topInset = 59.0;

        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);

        // devicePixelRatio pinned BEFORE physicalSize, per this repo's established
        // convention (see layout_list_padding_test.dart) -- otherwise the ambient test
        // devicePixelRatio skews the physical->logical mapping.
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, 800);
        tester.view.padding = const FakeViewPadding(top: topInset);
        tester.view.viewPadding = const FakeViewPadding(top: topInset);

        await pumpThemed(
          tester,
          LayrzSelectInputSurface<String>(
            itemExtent: 40,
            items: items,
            enableSearch: true,
            canUnselect: false,
            onItemSelected: (_) {},
          ),
        );
        await tester.pumpAndSettle();

        final listRect = tester.getRect(find.byType(ListView));
        // `find.text('Apple')` rather than `find.byKey(ValueKey('apple'))`: the key
        // lives on `_SelectItemRow` (a `StatelessWidget`, so its `Element` never
        // carries an independent `RenderObject` of its own to hit-test/measure),
        // which `getRect` cannot resolve directly. The item row also wraps its text
        // in `tokens.spacing.sp1` of vertical padding, so this measures a few logical
        // pixels short of the row's own top edge -- immaterial next to the ~59px
        // phantom gap under test; `closeTo`'s tolerance below is widened accordingly.
        final firstRowRect = tester.getRect(find.text('Apple'));

        // CRITICAL ASSERTION: the first row must start flush with the ListView's own
        // viewport top -- no phantom leading inset from the ambient top padding being
        // auto-applied a second time. A non-zero gap here means `topInset` leaked into
        // this `ListView`'s own SliverPadding on top of whatever the surface's real
        // hosts already consumed for it.
        expect(
          firstRowRect.top,
          // Tolerance covers the row's own internal vertical padding/centering
          // (measured ~13px between the ListView's viewport top and the rendered
          // text's own top edge with the fix applied) -- far below the ~59px
          // phantom gap this test guards against, so a regression still fails
          // clearly.
          closeTo(listRect.top, 20.0),
          reason:
              'CRITICAL: the first item row must start at the top of the ListView\'s own '
              'viewport, with no phantom leading gap. A gap here means the ambient '
              'MediaQuery.padding.top ($topInset px) is leaking into this internal '
              'ListView and being auto-applied as scroll-axis padding.',
        );
      },
    );

    testWidgets('disposes internal controllers and focus nodes without throwing', (tester) async {
      await pumpThemed(
        tester,
        LayrzSelectInputSurface<String>(
          itemExtent: 40,
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
