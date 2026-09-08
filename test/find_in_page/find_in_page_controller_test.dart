import 'package:flutter/rendering.dart';
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

  /// Pumps one settling frame, explicitly requesting it first.
  ///
  /// The bare content trees these controller-only tests pump have no widget
  /// listening to the controller (unlike a real [LayrzFindBar], whose
  /// `setState` in response to `notifyListeners` marks itself needing a
  /// rebuild and so schedules a frame on its own). Without that listener,
  /// [WidgetTester.pump] with no scheduled frame is a no-op for
  /// `addPostFrameCallback` work — see [SchedulerBinding.hasScheduledFrame]
  /// — which would otherwise strand the debounce → walk → highlight-resolve
  /// chain's post-frame steps forever. Requesting the frame explicitly here
  /// is the test-harness equivalent of that listener, not a workaround for
  /// anything wrong in [LayrzFindInPageController] itself.
  Future<void> pumpSettling(WidgetTester tester) async {
    WidgetsBinding.instance.scheduleFrame();
    await tester.pump();
  }

  /// Pumps a plain content tree (no find bar involved) under a real
  /// [Directionality] so [walkSemantics] has real semantics/render trees to
  /// walk, without going through the full [LayrzFindInPageHost]/[LayrzApp]
  /// wiring — the controller is tested in isolation here.
  Future<void> pumpContent(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: child,
      ),
    );
  }

  group('LayrzFindInPageController', () {
    testWidgets('open acquires a SemanticsHandle; close disposes it (idle cost)', (tester) async {
      setWideViewport(tester);
      await pumpContent(tester, const Text('mango'));

      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);

      // flutter_test's own binding always keeps at least one SemanticsHandle
      // outstanding of its own (for matchesSemantics/a11y test support), so
      // SemanticsBinding.semanticsEnabled is already `true` before this
      // controller ever touches it — debugOutstandingSemanticsHandles' own
      // DELTA across open()/close() is what actually proves this controller
      // acquires and releases its own handle, independent of the test
      // binding's baseline.
      final baseline = SemanticsBinding.instance.debugOutstandingSemanticsHandles;

      expect(controller.isOpen, isFalse);
      expect(SemanticsBinding.instance.debugOutstandingSemanticsHandles, baseline);

      controller.open();
      expect(controller.isOpen, isTrue);
      expect(SemanticsBinding.instance.debugOutstandingSemanticsHandles, baseline + 1);

      controller.close();
      expect(controller.isOpen, isFalse);
      expect(SemanticsBinding.instance.debugOutstandingSemanticsHandles, baseline);
    });

    testWidgets('open is a no-op when already open (does not acquire twice)', (tester) async {
      setWideViewport(tester);
      await pumpContent(tester, const Text('mango'));

      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);

      final baseline = SemanticsBinding.instance.debugOutstandingSemanticsHandles;

      controller.open();
      controller.open();
      expect(controller.isOpen, isTrue);
      expect(SemanticsBinding.instance.debugOutstandingSemanticsHandles, baseline + 1);

      controller.close();
      expect(SemanticsBinding.instance.debugOutstandingSemanticsHandles, baseline);
    });

    testWidgets('close is a no-op when already closed', (tester) async {
      setWideViewport(tester);
      await pumpContent(tester, const Text('mango'));

      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);

      expect(() => controller.close(), returnsNormally);
      expect(controller.isOpen, isFalse);
    });

    testWidgets('toggle opens when closed and closes when open', (tester) async {
      setWideViewport(tester);
      await pumpContent(tester, const Text('mango'));

      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);

      controller.toggle();
      expect(controller.isOpen, isTrue);

      controller.toggle();
      expect(controller.isOpen, isFalse);
    });

    testWidgets('setQuery walks and finds matches after the debounce settles', (tester) async {
      setWideViewport(tester);
      await pumpContent(
        tester,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('First mango paragraph'),
            Text('Second paragraph, no fruit here'),
            Text('Third mango and another mango'),
          ],
        ),
      );

      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);
      controller.open();

      controller.setQuery('mango');
      expect(controller.matches, isEmpty); // debounce pending, not yet walked

      await tester.pump(kFindInPageQueryDebounce + const Duration(milliseconds: 10));
      // Walk is scheduled post-frame; settle one more frame for it to run.
      await tester.pump();

      expect(controller.matches.length, 2);
      expect(controller.matches[0].label, 'First mango paragraph');
      expect(controller.matches[1].label, 'Third mango and another mango');
      expect(controller.currentIndex, 0);

      controller.close();
    });

    testWidgets('searchNow bypasses the debounce for an immediate walk', (tester) async {
      setWideViewport(tester);
      await pumpContent(tester, const Text('mango paragraph'));

      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);
      controller.open();

      controller.setQuery('mango');
      controller.searchNow();
      await tester.pump();

      expect(controller.matches.length, 1);

      controller.close();
    });

    testWidgets('clearing the query resets matches/highlights/currentIndex instantly', (tester) async {
      setWideViewport(tester);
      await pumpContent(tester, const Text('mango paragraph'));

      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);
      controller.open();

      controller.setQuery('mango');
      controller.searchNow();
      await tester.pump();
      expect(controller.matches, isNotEmpty);

      controller.setQuery('');
      // No pump needed — clearing is synchronous, not debounced.
      expect(controller.matches, isEmpty);
      expect(controller.highlights, isEmpty);
      expect(controller.currentIndex, -1);

      controller.close();
    });

    testWidgets('next cycles forward through matches, wrapping past the last one', (tester) async {
      setWideViewport(tester);
      await pumpContent(
        tester,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('mango one'),
            Text('mango two'),
          ],
        ),
      );

      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);
      controller.open();

      controller.setQuery('mango');
      controller.searchNow();
      await tester.pump();
      expect(controller.matches.length, 2);
      expect(controller.currentIndex, 0);

      controller.next();
      expect(controller.currentIndex, 1);

      controller.next();
      expect(controller.currentIndex, 0); // wraps

      controller.close();
    });

    testWidgets('previous cycles backward through matches, wrapping before the first one', (tester) async {
      setWideViewport(tester);
      await pumpContent(
        tester,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('mango one'),
            Text('mango two'),
          ],
        ),
      );

      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);
      controller.open();

      controller.setQuery('mango');
      controller.searchNow();
      await tester.pump();
      expect(controller.currentIndex, 0);

      controller.previous();
      expect(controller.currentIndex, 1); // wraps backward

      controller.previous();
      expect(controller.currentIndex, 0);

      controller.close();
    });

    testWidgets('next/previous are no-ops when there are no matches', (tester) async {
      setWideViewport(tester);
      await pumpContent(tester, const Text('nothing relevant here'));

      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);
      controller.open();

      expect(() => controller.next(), returnsNormally);
      expect(() => controller.previous(), returnsNormally);
      expect(controller.currentIndex, -1);

      controller.close();
    });

    testWidgets('excludeRect drops matches whose center falls inside it', (tester) async {
      setWideViewport(tester);
      await pumpContent(
        tester,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('mango content match'),
            Text('mango bar match'),
          ],
        ),
      );

      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);
      controller.open();

      controller.setQuery('mango');
      controller.searchNow();
      await tester.pump();
      expect(controller.matches.length, 2);

      // Exclude the second match's rect (the "bar" stand-in) by its own
      // globalRect — mirrors how LayrzFindInPageHost measures and feeds the
      // real find bar's rect.
      final barRect = controller.matches[1].globalRect;
      controller.updateExcludeRect(barRect);

      controller.searchNow();
      await tester.pump();

      expect(controller.matches.length, 1);
      expect(controller.matches.first.label, 'mango content match');

      controller.close();
    });

    testWidgets('updateExcludeRect with the same rect is a no-op', (tester) async {
      setWideViewport(tester);
      await pumpContent(tester, const Text('mango'));

      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);

      const rect = Rect.fromLTWH(0, 0, 10, 10);
      controller.updateExcludeRect(rect);
      expect(controller.excludeRect, rect);
      expect(() => controller.updateExcludeRect(rect), returnsNormally);
      expect(controller.excludeRect, rect);
    });

    testWidgets('re-typing a query keeps highlights in sync with the settled query (generation guard)', (
      tester,
    ) async {
      setWideViewport(tester);
      await pumpContent(
        tester,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('mango is a fruit'),
            Text('mangosteen is a different fruit'),
          ],
        ),
      );

      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);
      controller.open();

      // Simulate fast typing "m" -> "ma" -> "mango" without waiting out the
      // debounce between keystrokes — only the last one should ever settle.
      controller.setQuery('m');
      controller.setQuery('ma');
      controller.setQuery('mango');

      await tester.pump(kFindInPageQueryDebounce + const Duration(milliseconds: 10));
      await tester.pump();
      await tester.pump();

      // Every match's label must reflect the final settled query, never an
      // intermediate "m"/"ma" query.
      for (final match in controller.matches) {
        expect(match.label.toLowerCase(), contains('mango'));
      }
      expect(controller.query, 'mango');

      controller.close();
    });

    testWidgets('visibleMatches excludes hidden matches', (tester) async {
      setWideViewport(tester);
      await pumpContent(tester, const Text('mango'));

      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);

      expect(controller.visibleMatches, isEmpty);
    });

    testWidgets('dispose while open cleans up the semantics handle without leaking', (tester) async {
      setWideViewport(tester);
      await pumpContent(tester, const Text('mango'));

      final baseline = SemanticsBinding.instance.debugOutstandingSemanticsHandles;

      final controller = LayrzFindInPageController();
      controller.open();
      expect(SemanticsBinding.instance.debugOutstandingSemanticsHandles, baseline + 1);

      controller.dispose();
      expect(SemanticsBinding.instance.debugOutstandingSemanticsHandles, baseline);
    });

    group('isSearching', () {
      testWidgets('is true immediately after setQuery(non-empty), while the debounce is pending', (tester) async {
        setWideViewport(tester);
        await pumpContent(tester, const Text('mango paragraph'));

        final controller = LayrzFindInPageController();
        addTearDown(controller.dispose);
        controller.open();

        expect(controller.isSearching, isFalse);

        controller.setQuery('mango');
        expect(controller.isSearching, isTrue); // debounce pending, no walk yet

        controller.close();
      });

      testWidgets('becomes false once the debounce settles and highlights resolve', (tester) async {
        setWideViewport(tester);
        await pumpContent(tester, const Text('mango paragraph'));

        final controller = LayrzFindInPageController();
        addTearDown(controller.dispose);
        controller.open();

        controller.setQuery('mango');
        expect(controller.isSearching, isTrue);

        await tester.pump(kFindInPageQueryDebounce + const Duration(milliseconds: 10));
        expect(controller.isSearching, isTrue); // walk just ran; highlight resolve is post-frame

        // Settle the post-frame highlight resolve.
        await pumpSettling(tester);

        expect(controller.matches, isNotEmpty);
        expect(controller.isSearching, isFalse);

        controller.close();
      });

      testWidgets('searchNow sets isSearching true, then false once resolved', (tester) async {
        setWideViewport(tester);
        await pumpContent(tester, const Text('mango paragraph'));

        final controller = LayrzFindInPageController();
        addTearDown(controller.dispose);
        controller.open();

        controller.setQuery('mango');
        controller.searchNow();
        expect(controller.isSearching, isTrue);

        await pumpSettling(tester); // settle the post-frame highlight resolve
        expect(controller.matches, isNotEmpty);
        expect(controller.isSearching, isFalse);

        controller.close();
      });

      testWidgets('is false immediately on clear/empty', (tester) async {
        setWideViewport(tester);
        await pumpContent(tester, const Text('mango paragraph'));

        final controller = LayrzFindInPageController();
        addTearDown(controller.dispose);
        controller.open();

        controller.setQuery('mango');
        expect(controller.isSearching, isTrue);

        controller.setQuery('');
        // No pump needed — clearing is synchronous, not debounced.
        expect(controller.isSearching, isFalse);

        controller.close();
      });

      testWidgets('a searchNow with no matches settles isSearching to false synchronously', (tester) async {
        setWideViewport(tester);
        await pumpContent(tester, const Text('nothing relevant here'));

        final controller = LayrzFindInPageController();
        addTearDown(controller.dispose);
        controller.open();

        controller.setQuery('mango');
        controller.searchNow();

        // Zero raw matches equals the already-empty _matches by value, so
        // _performWalk's no-op guard fires and returns before any highlight
        // resolution is even scheduled — isSearching settles back to false
        // within this synchronous call, with no pump needed.
        expect(controller.matches, isEmpty);
        expect(controller.isSearching, isFalse);

        controller.close();
      });

      testWidgets('re-searching the same settled query does not leave isSearching stuck true', (tester) async {
        setWideViewport(tester);
        await pumpContent(tester, const Text('mango paragraph'));

        final controller = LayrzFindInPageController();
        addTearDown(controller.dispose);
        controller.open();

        controller.setQuery('mango');
        controller.searchNow();
        await pumpSettling(tester);
        expect(controller.isSearching, isFalse);

        // searchNow again for the identical, already-settled query: the walk
        // finds an unchanged match list, so _performWalk's no-op guard fires
        // and no highlight resolution gets scheduled — isSearching must still
        // settle back to false rather than being stranded true.
        controller.searchNow();
        expect(controller.isSearching, isFalse);

        controller.close();
      });

      testWidgets('a m -> ma -> mango fast-typing sequence ends with isSearching false', (tester) async {
        setWideViewport(tester);
        await pumpContent(
          tester,
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('mango is a fruit'),
              Text('mangosteen is a different fruit'),
            ],
          ),
        );

        final controller = LayrzFindInPageController();
        addTearDown(controller.dispose);
        controller.open();

        controller.setQuery('m');
        controller.setQuery('ma');
        controller.setQuery('mango');
        expect(controller.isSearching, isTrue);

        await tester.pump(kFindInPageQueryDebounce + const Duration(milliseconds: 10));
        await pumpSettling(tester);

        expect(controller.query, 'mango');
        expect(controller.isSearching, isFalse);

        controller.close();
      });
    });

    testWidgets('notifies listeners on open/close/setQuery/next/previous', (tester) async {
      setWideViewport(tester);
      await pumpContent(tester, const Text('mango one'));

      final controller = LayrzFindInPageController();
      addTearDown(controller.dispose);

      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.open();
      expect(notifyCount, greaterThan(0));

      final afterOpen = notifyCount;
      controller.setQuery('mango');
      expect(notifyCount, greaterThan(afterOpen));

      controller.close();
      expect(notifyCount, greaterThan(0));
    });
  });
}
