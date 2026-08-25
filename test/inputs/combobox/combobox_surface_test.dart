import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/combobox/combobox_surface.dart';

import '../../helpers/pump_themed.dart';
import '../../helpers/pump_themed_app.dart';

void main() {
  group('DesktopOverlay', () {
    testWidgets('shows the empty text when there are no options', (tester) async {
      await pumpThemed(
        tester,
        DesktopOverlay(
          options: const [],
          highlightedIndex: -1,
          onSelected: (_) {},
          emptyText: 'No matches',
        ),
      );

      expect(find.text('No matches'), findsOneWidget);
      expect(find.byType(OptionItem), findsNothing);
    });

    testWidgets('renders one OptionItem per option', (tester) async {
      await pumpThemed(
        tester,
        DesktopOverlay(
          options: const ['Alpha', 'Bravo', 'Charlie'],
          highlightedIndex: -1,
          onSelected: (_) {},
          emptyText: 'No matches',
        ),
      );

      expect(find.byType(OptionItem), findsNWidgets(3));
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Bravo'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
    });

    testWidgets('tapping an option calls onSelected with that option', (tester) async {
      String? selected;

      await pumpThemed(
        tester,
        DesktopOverlay(
          options: const ['Alpha', 'Bravo'],
          highlightedIndex: -1,
          onSelected: (value) => selected = value,
          emptyText: 'No matches',
        ),
      );

      await tester.tap(find.text('Bravo'));
      await tester.pump();

      expect(selected, 'Bravo');
    });

    testWidgets('the highlighted option renders with a different background', (tester) async {
      await pumpThemed(
        tester,
        DesktopOverlay(
          options: const ['Alpha', 'Bravo'],
          highlightedIndex: 1,
          onSelected: (_) {},
          emptyText: 'No matches',
        ),
      );

      final containers = tester
          .widgetList<Container>(
            find.descendant(of: find.byType(OptionItem), matching: find.byType(Container)),
          )
          .toList();

      expect(containers, hasLength(2));
      expect(containers[0].color, isNot(containers[1].color));
    });

    testWidgets(
      'the shadow-bearing decoration is an ancestor of the scroll viewport, '
      'not a descendant of it (elevation must not be clipped)',
      (tester) async {
        // A BoxShadow paints outside its own box's bounds. SingleChildScrollView
        // clips at exactly those bounds (Clip.hardEdge by default). So the
        // decoration that carries the elevation shadow must be an ANCESTOR of
        // the SingleChildScrollView, never a descendant/child of it — otherwise
        // the shadow is painted and then clipped away, invisibly. Reading
        // `decoration.boxShadow` alone cannot catch this: it is non-null on both
        // sides of the fix. Only the ancestry relationship distinguishes them.
        final options = List.generate(20, (i) => 'Option $i');

        await pumpThemed(
          tester,
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
            child: DesktopOverlay(
              options: options,
              highlightedIndex: -1,
              onSelected: (_) {},
              emptyText: 'No matches',
            ),
          ),
        );

        final shadowDecoratedFinder = find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).boxShadow != null,
        );

        expect(
          shadowDecoratedFinder,
          findsOneWidget,
          reason: 'exactly one decoration should carry the elevation shadow',
        );

        expect(
          find.ancestor(of: find.byType(SingleChildScrollView), matching: shadowDecoratedFinder),
          findsOneWidget,
          reason:
              'the shadow-bearing decoration must wrap the scroll viewport, '
              'not sit inside it, or the shadow is clipped away invisibly',
        );
      },
    );

    testWidgets(
      'does not overflow with many options, and the list actually scrolls (DESIGN-35)',
      (tester) async {
        // Regression test for the 840px overflow: a Container(constraints:
        // maxHeight) used to sit inside the SingleChildScrollView, clamping the
        // Column to the same bound as the viewport so it could never scroll while
        // the Column itself overflowed. The fix leaves the Column free to exceed
        // the bound the outer constraint applies to the scroll view, so it scrolls
        // instead of overflowing.
        final options = List.generate(30, (i) => 'Option $i');

        await pumpThemed(
          tester,
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 300),
            child: DesktopOverlay(
              options: options,
              highlightedIndex: -1,
              onSelected: (_) {},
              emptyText: 'No matches',
            ),
          ),
        );

        expect(tester.takeException(), isNull);

        final beforeRect = tester.getRect(find.text('Option 29'));

        await tester.drag(find.byType(DesktopOverlay), const Offset(0, -400));
        await tester.pump();

        expect(tester.takeException(), isNull);

        final afterRect = tester.getRect(find.text('Option 29'));
        expect(
          afterRect.top,
          lessThan(beforeRect.top),
          reason: 'dragging up must have scrolled later options into view',
        );
      },
    );
  });

  group('OptionItem', () {
    testWidgets('renders its option text', (tester) async {
      await pumpThemed(
        tester,
        OptionItem(
          option: 'Solo option',
          isHighlighted: false,
          onTap: () {},
        ),
      );

      expect(find.text('Solo option'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await pumpThemed(
        tester,
        OptionItem(
          option: 'Tap me',
          isHighlighted: false,
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('BottomSheetContent', () {
    testWidgets('shows the empty text when there are no options', (tester) async {
      await pumpThemed(
        tester,
        const BottomSheetContent(
          options: [],
          emptyText: 'Nothing here',
        ),
      );

      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('renders every option as scrollable text, never a ListView', (tester) async {
      // Building on a Column (not a ListView) is what lets this content sit
      // inside LayrzBottomSheet with `scrollable: false` without asserting
      // "Vertical viewport was given unbounded height" — a same-axis ListView
      // nested under the sheet's own scrollable does exactly that (DESIGN-35).
      await pumpThemed(
        tester,
        const BottomSheetContent(
          options: ['One', 'Two', 'Three'],
          emptyText: 'Nothing here',
        ),
      );

      expect(find.byType(ListView), findsNothing);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);
    });

    testWidgets('tapping an option pops the enclosing sheet route with that value', (tester) async {
      String? result;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            return GestureDetector(
              onTap: () async {
                result = await LayrzBottomSheet.show<String?>(
                  context,
                  builder: (context) => const BottomSheetContent(
                    options: ['First', 'Second'],
                    emptyText: 'Nothing here',
                  ),
                  useRootNavigator: true,
                  scrollable: false,
                );
              },
              child: const Text('open sheet'),
            );
          },
        ),
      );

      await tester.tap(find.text('open sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheetContent), findsOneWidget);

      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheetContent), findsNothing);
      expect(result, 'Second');
    });
  });
}
