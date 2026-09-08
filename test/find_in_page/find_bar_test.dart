import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';

void main() {
  /// Sets a wide desktop viewport so tests don't accidentally exercise the
  /// compact-only default 800×600 test surface (CLAUDE.md testing traps).
  void setWideViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Pumps a [LayrzFindBar] under a real [LayrzApp] (needed for
  /// [LayrzTextInput]'s theming/tokens and for a [Directionality] +
  /// [MediaQuery] ancestor).
  Future<void> pumpFindBar(
    WidgetTester tester, {
    required LayrzFindInPageController controller,
    required VoidCallback onClose,
  }) async {
    await tester.pumpWidget(
      LayrzApp(
        enableFindInPage: false,
        home: Align(
          alignment: Alignment.topLeft,
          child: LayrzFindBar(controller: controller, onClose: onClose),
        ),
      ),
    );
    await tester.pump();
  }

  group('LayrzFindBar', () {
    testWidgets('renders a query field, counter, and prev/next/close buttons', (tester) async {
      setWideViewport(tester);
      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);

      await pumpFindBar(tester, controller: controller, onClose: () {});

      expect(find.byType(LayrzTextInput), findsOneWidget);
      expect(find.text('0 of 0'), findsOneWidget);
      expect(find.byKey(const ValueKey('layrz-find-bar-previous')), findsOneWidget);
      expect(find.byKey(const ValueKey('layrz-find-bar-next')), findsOneWidget);
      expect(find.byKey(const ValueKey('layrz-find-bar-close')), findsOneWidget);
    });

    testWidgets('typing into the query field forwards to controller.setQuery', (tester) async {
      setWideViewport(tester);
      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);

      await pumpFindBar(tester, controller: controller, onClose: () {});

      await tester.enterText(find.byType(LayrzTextInput), 'mango');
      await tester.pump();

      expect(controller.query, 'mango');

      // Flush the pending debounce timer setQuery started, so it never
      // fires after the widget tree is torn down at the end of this test.
      await tester.pump(kFindInPageQueryDebounce + const Duration(milliseconds: 10));
    });

    testWidgets('counter reflects controller.currentIndex/matches live', (tester) async {
      setWideViewport(tester);
      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);

      await pumpFindBar(tester, controller: controller, onClose: () {});

      await tester.pumpWidget(
        LayrzApp(
          enableFindInPage: false,
          home: Column(
            children: [
              const Text('mango one'),
              const Text('mango two'),
              Align(
                alignment: Alignment.topLeft,
                child: LayrzFindBar(controller: controller, onClose: () {}),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      controller.open();
      controller.setQuery('mango');
      controller.searchNow();
      await tester.pump();

      expect(find.text('1 of 2'), findsOneWidget);

      controller.next();
      await tester.pump();
      expect(find.text('2 of 2'), findsOneWidget);

      controller.close();
    });

    testWidgets('tapping close calls onClose', (tester) async {
      setWideViewport(tester);
      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);
      var closed = false;

      await pumpFindBar(tester, controller: controller, onClose: () => closed = true);

      await tester.tap(find.byKey(const ValueKey('layrz-find-bar-close')));
      await tester.pump();

      expect(closed, isTrue);
    });

    testWidgets('tapping next/previous drives controller.next/previous', (tester) async {
      setWideViewport(tester);
      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        LayrzApp(
          enableFindInPage: false,
          home: Column(
            children: [
              const Text('mango one'),
              const Text('mango two'),
              Align(
                alignment: Alignment.topLeft,
                child: LayrzFindBar(controller: controller, onClose: () {}),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      controller.open();
      controller.setQuery('mango');
      controller.searchNow();
      await tester.pump();
      expect(controller.currentIndex, 0);

      await tester.tap(find.byKey(const ValueKey('layrz-find-bar-next')));
      await tester.pump();
      expect(controller.currentIndex, 1);

      await tester.tap(find.byKey(const ValueKey('layrz-find-bar-previous')));
      await tester.pump();
      expect(controller.currentIndex, 0);

      controller.close();
    });

    testWidgets('Escape (local) closes the bar', (tester) async {
      setWideViewport(tester);
      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);
      var closed = false;

      await pumpFindBar(tester, controller: controller, onClose: () => closed = true);

      // Focus the query field, then send Escape through it — the bar's own
      // Focus/onKeyEvent wraps the whole subtree, so it still intercepts.
      await tester.tap(find.byType(LayrzTextInput));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(closed, isTrue);
    });

    testWidgets('Enter in the query field advances to next match', (tester) async {
      setWideViewport(tester);
      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        LayrzApp(
          enableFindInPage: false,
          home: Column(
            children: [
              const Text('mango one'),
              const Text('mango two'),
              Align(
                alignment: Alignment.topLeft,
                child: LayrzFindBar(controller: controller, onClose: () {}),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      controller.open();
      controller.setQuery('mango');
      controller.searchNow();
      await tester.pump();
      expect(controller.currentIndex, 0);

      await tester.tap(find.byType(LayrzTextInput));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(controller.currentIndex, 1);

      controller.close();
    });

    testWidgets('Shift+Enter cycles to previous match', (tester) async {
      setWideViewport(tester);
      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        LayrzApp(
          enableFindInPage: false,
          home: Column(
            children: [
              const Text('mango one'),
              const Text('mango two'),
              Align(
                alignment: Alignment.topLeft,
                child: LayrzFindBar(controller: controller, onClose: () {}),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      controller.open();
      controller.setQuery('mango');
      controller.searchNow();
      await tester.pump();
      expect(controller.currentIndex, 0);

      await tester.tap(find.byType(LayrzTextInput));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect(controller.currentIndex, 1); // wraps backward from 0

      controller.close();
    });

    testWidgets('requests focus for the query field on mount', (tester) async {
      setWideViewport(tester);
      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);

      await pumpFindBar(tester, controller: controller, onClose: () {});
      await tester.pump();

      final editableTextFinder = find.descendant(
        of: find.byType(LayrzTextInput),
        matching: find.byType(EditableText),
      );
      final editableTextWidget = tester.widget<EditableText>(editableTextFinder);
      expect(editableTextWidget.focusNode.hasFocus, isTrue);
    });

    group('searching indicator', () {
      /// Reads the [Opacity] wrapping the bottom-edge [LayrzProgressBar] —
      /// its `opacity` is what actually toggles the indicator's visibility;
      /// the [LayrzProgressBar] itself, and its fixed-height [SizedBox] slot,
      /// stay mounted regardless of [LayrzFindInPageController.isSearching]
      /// so the bar's overall height never shifts.
      double indicatorOpacity(WidgetTester tester) {
        final opacityFinder = find.ancestor(
          of: find.byType(LayrzProgressBar),
          matching: find.byType(Opacity),
        );
        return tester.widget<Opacity>(opacityFinder).opacity;
      }

      testWidgets('the indeterminate LayrzProgressBar is always mounted (no layout shift)', (tester) async {
        setWideViewport(tester);
        final controller = LayrzFindInPageController();
        addTearDown(controller.dispose);

        await pumpFindBar(tester, controller: controller, onClose: () {});

        expect(find.byType(LayrzProgressBar), findsOneWidget);
        final bar = tester.widget<LayrzProgressBar>(find.byType(LayrzProgressBar));
        expect(bar.value, isNull); // indeterminate
        expect(indicatorOpacity(tester), 0.0); // idle: hidden

        final sizedBoxFinder = find.ancestor(
          of: find.byType(LayrzProgressBar),
          matching: find.byWidgetPredicate(
            (widget) => widget is SizedBox && widget.height == kLayrzFindBarSearchingIndicatorHeight,
          ),
        );
        expect(sizedBoxFinder, findsOneWidget);
      });

      testWidgets('becomes visible while controller.isSearching is true, hidden once it settles', (tester) async {
        setWideViewport(tester);
        final controller = LayrzFindInPageController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          LayrzApp(
            enableFindInPage: false,
            home: Column(
              children: [
                const Text('mango one'),
                Align(
                  alignment: Alignment.topLeft,
                  child: LayrzFindBar(controller: controller, onClose: () {}),
                ),
              ],
            ),
          ),
        );
        await tester.pump();

        expect(indicatorOpacity(tester), 0.0);

        controller.open();
        controller.setQuery('mango');
        await tester.pump();

        expect(controller.isSearching, isTrue);
        expect(indicatorOpacity(tester), 1.0);

        // Settle the debounce, the post-frame walk, and the post-frame
        // highlight resolve.
        await tester.pump(kFindInPageQueryDebounce + const Duration(milliseconds: 10));
        await tester.pump();
        await tester.pump();

        expect(controller.isSearching, isFalse);
        expect(indicatorOpacity(tester), 0.0);

        controller.close();
      });

      testWidgets('an instant searchNow does not leave the indicator stuck visible', (tester) async {
        setWideViewport(tester);
        final controller = LayrzFindInPageController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          LayrzApp(
            enableFindInPage: false,
            home: Column(
              children: [
                const Text('mango one'),
                Align(
                  alignment: Alignment.topLeft,
                  child: LayrzFindBar(controller: controller, onClose: () {}),
                ),
              ],
            ),
          ),
        );
        await tester.pump();

        controller.open();
        controller.setQuery('mango');
        controller.searchNow();
        await tester.pump();
        // The walk's own notifyListeners triggers the bar's setState/rebuild
        // in the pump above; the highlight resolution it schedules is a
        // *separate* post-frame callback, requiring one more pumped frame to
        // run and commit.
        await tester.pump();

        expect(controller.isSearching, isFalse);
        expect(indicatorOpacity(tester), 0.0);

        controller.close();
      });

      testWidgets('the indicator is excluded from semantics', (tester) async {
        setWideViewport(tester);
        final controller = LayrzFindInPageController();
        addTearDown(controller.dispose);

        final handle = tester.ensureSemantics();
        try {
          await pumpFindBar(tester, controller: controller, onClose: () {});

          final excludeSemanticsFinder = find.ancestor(
            of: find.byType(LayrzProgressBar),
            matching: find.byType(ExcludeSemantics),
          );
          expect(excludeSemanticsFinder, findsOneWidget);
        } finally {
          handle.dispose();
        }
      });
    });

    group('surface styling', () {
      testWidgets('the bar surface uses tokens.shadow.elevation5', (tester) async {
        setWideViewport(tester);
        final controller = LayrzFindInPageController();
        addTearDown(controller.dispose);

        await pumpFindBar(tester, controller: controller, onClose: () {});

        final context = tester.element(find.byType(LayrzFindBar));
        final tokens = LayrzTheme.of(context).tokens;

        final decoratedBox = tester.widget<DecoratedBox>(
          find.descendant(of: find.byType(LayrzFindBar), matching: find.byType(DecoratedBox)).first,
        );
        final decoration = decoratedBox.decoration as BoxDecoration;

        expect(decoration.boxShadow, tokens.shadow.elevation5);
      });
    });
  });
}
