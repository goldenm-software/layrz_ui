import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Counts every `didPop` notification the navigator hosting the sheet
/// receives, mirroring the pattern established in
/// test/scaffold/scaffold_shell_sheet_dismiss_test.dart for the sibling
/// shell-double-pop defect. A test that only asserts the sheet's content is
/// gone cannot distinguish "dismissed once" from "dismissed, then popped the
/// page underneath it too" — both leave the sheet's content absent. Only a
/// pop count catches the extra pop.
class _PopCountingObserver extends NavigatorObserver {
  /// Number of `didPop` calls observed so far.
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
  }
}

void main() {
  group('LayrzBottomSheet barrier double-pop (fast double-tap during dismiss)', () {
    late _PopCountingObserver observer;

    setUp(() {
      observer = _PopCountingObserver();
    });

    /// Pumps a [LayrzApp] whose home page can be tapped to open the sheet,
    /// wired to [observer] so pops on the app's single Navigator can be
    /// counted. The home page itself is the "route underneath" that a
    /// double-pop would incorrectly remove.
    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        LayrzApp(
          navigatorObservers: [observer],
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzBottomSheet.show<void>(
                    context,
                    builder: (context) => const SizedBox(height: 200, child: Text('Sheet body')),
                  );
                },
                child: const SizedBox(width: 100, height: 100, child: Text('Open')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
      'a second barrier tap during the dismiss animation does not pop the page underneath',
      (tester) async {
        await pumpApp(tester);

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Sheet body'), findsOneWidget, reason: 'sheet must be open for this test to be valid');
        expect(observer.pops, equals(0));

        // First tap on the barrier — a point visibly above the sheet's own content —
        // starts the dismiss animation (does NOT settle it; that is the whole point).
        await tester.tapAt(const Offset(10, 10));
        // Advance partway into the exit transition, deliberately shorter than the
        // full dismiss animation, so the barrier's GestureDetector is still mounted
        // and still hit-testable when the second tap lands.
        await tester.pump(const Duration(milliseconds: 50));

        // Second tap on the same barrier position, while the sheet is still
        // (partially) visible and animating out.
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'a second tap during dismissal must not throw (no double Navigator.pop assertion)',
        );

        // The real damage this bug causes: a second pop reaching past the sheet's
        // own route and removing the page underneath it. In this harness that page
        // is LayrzApp's only route, so losing it manifests as the 'Open' trigger
        // (part of the home page) disappearing along with the sheet.
        expect(
          find.text('Open'),
          findsOneWidget,
          reason: 'the page underneath the sheet must survive a second barrier tap during dismissal',
        );

        expect(
          observer.pops,
          equals(1),
          reason:
              'dismissing the sheet must pop only the sheet\'s own route, never the route underneath, '
              'even when a second tap lands on the barrier mid-animation',
        );
      },
    );

    testWidgets('a single barrier tap still dismisses the sheet normally', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet body'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Sheet body'), findsNothing);
      expect(find.text('Open'), findsOneWidget, reason: 'the page underneath must still be present');
      expect(observer.pops, equals(1));
    });
  });

  group('LayrzBottomSheet Escape-key double-pop (fast double-Escape during dismiss)', () {
    late _PopCountingObserver observer;

    setUp(() {
      observer = _PopCountingObserver();
    });

    /// Same harness as the barrier group above, reused here so the Escape-key
    /// path is exercised against an identical "route underneath" setup.
    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        LayrzApp(
          navigatorObservers: [observer],
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzBottomSheet.show<void>(
                    context,
                    builder: (context) => const SizedBox(height: 200, child: Text('Sheet body')),
                  );
                },
                child: const SizedBox(width: 100, height: 100, child: Text('Open')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
      'a second Escape during the dismiss animation does not pop the page underneath',
      (tester) async {
        await pumpApp(tester);

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Sheet body'), findsOneWidget, reason: 'sheet must be open for this test to be valid');
        expect(observer.pops, equals(0));

        // First Escape starts the dismiss animation (does NOT settle it).
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump(const Duration(milliseconds: 50));

        // Second Escape while the sheet is still animating out. The sheet's
        // Focus node (and its onKeyEvent handler) stays mounted for the whole
        // transition, same as the barrier's GestureDetector.
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'a second Escape during dismissal must not throw (no double Navigator.pop assertion)',
        );
        expect(
          find.text('Open'),
          findsOneWidget,
          reason: 'the page underneath the sheet must survive a second Escape during dismissal',
        );
        expect(
          observer.pops,
          equals(1),
          reason: 'dismissing the sheet must pop only the sheet\'s own route, even with a second Escape mid-animation',
        );
      },
    );

    testWidgets('a single Escape still dismisses the sheet normally', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet body'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Sheet body'), findsNothing);
      expect(find.text('Open'), findsOneWidget, reason: 'the page underneath must still be present');
      expect(observer.pops, equals(1));
    });
  });

  group('LayrzBottomSheet drag-to-dismiss double-pop (second drag during dismiss)', () {
    late _PopCountingObserver observer;

    setUp(() {
      observer = _PopCountingObserver();
    });

    /// Same harness as the other two groups, but opens with a known
    /// [minSize]/snap configuration so a single downward drag reliably
    /// crosses the low snap point and triggers drag-to-dismiss.
    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        LayrzApp(
          navigatorObservers: [observer],
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzBottomSheet.show<void>(
                    context,
                    builder: (context) => const SizedBox(height: 200, child: Text('Sheet body')),
                  );
                },
                child: const SizedBox(width: 100, height: 100, child: Text('Open')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    Finder findDragHandle() {
      return find.byWidgetPredicate(
        (widget) => widget is Container && widget.constraints?.maxWidth == 40 && widget.constraints?.maxHeight == 4,
      );
    }

    testWidgets(
      'a second drag-to-dismiss gesture during the dismiss animation does not pop the page underneath',
      (tester) async {
        await pumpApp(tester);

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Sheet body'), findsOneWidget, reason: 'sheet must be open for this test to be valid');
        expect(observer.pops, equals(0));

        final handle = findDragHandle();
        expect(handle, findsOneWidget);

        // First drag: well past the low snap point, dismisses on release but does
        // NOT settle the resulting animation — a fresh gesture (finger down again)
        // is started immediately after, before the sheet's reverse transition ends.
        final gesture = await tester.startGesture(tester.getCenter(handle));
        await gesture.moveBy(const Offset(0, 300));
        await gesture.up();
        // Advance partway into the exit transition, deliberately shorter than the
        // full dismiss animation.
        await tester.pump(const Duration(milliseconds: 50));

        // Second, independent drag gesture on the same (still-mounted) handle
        // while the first dismissal is still animating out. Asserted present
        // first so a future change that unmounts the handle sooner cannot turn
        // this into a no-op that trivially "passes".
        expect(
          findDragHandle(),
          findsOneWidget,
          reason: 'the drag handle must still be mounted mid-dismiss for this test to prove anything',
        );
        final secondGesture = await tester.startGesture(tester.getCenter(findDragHandle()));
        await secondGesture.moveBy(const Offset(0, 300));
        await secondGesture.up();
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'a second drag-to-dismiss during dismissal must not throw (no double Navigator.pop assertion)',
        );
        expect(
          find.text('Open'),
          findsOneWidget,
          reason: 'the page underneath the sheet must survive a second drag-to-dismiss during dismissal',
        );
        expect(
          observer.pops,
          equals(1),
          reason:
              'dismissing the sheet must pop only the sheet\'s own route, even with a second '
              'drag-to-dismiss gesture landing mid-animation',
        );
      },
    );

    testWidgets('a single drag-to-dismiss still dismisses the sheet normally', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet body'), findsOneWidget);

      final handle = findDragHandle();
      expect(handle, findsOneWidget);

      await tester.drag(handle, const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Sheet body'), findsNothing);
      expect(find.text('Open'), findsOneWidget, reason: 'the page underneath must still be present');
      expect(observer.pops, equals(1));
    });
  });
}
