import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Counts every `didPop` notification the navigator hosting the sheet
/// receives, mirroring the canary already established in
/// test/dialogs/dialog_dismissal_gate_test.dart and
/// test/sheets/bottom_sheet_double_pop_test.dart -- a test that only asserts
/// the sheet's content is gone cannot distinguish "dismissed once" from
/// "dismissed, then popped the page underneath it too".
class _PopCountingObserver extends NavigatorObserver {
  /// Number of `didPop` calls observed so far.
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
  }
}

/// Finds the drag handle's visible pill, matching the predicate already used
/// in test/sheets/bottom_sheet_double_pop_test.dart's `findDragHandle`,
/// duplicated here rather than imported since that file's helper is private
/// to its own library.
Finder findDragHandle() {
  return find.byWidgetPredicate(
    (widget) => widget is Container && widget.constraints?.maxWidth == 40 && widget.constraints?.maxHeight == 4,
  );
}

void main() {
  late _PopCountingObserver observer;

  setUp(() {
    observer = _PopCountingObserver();
  });

  /// Pumps a [LayrzApp] whose home page opens a modal [LayrzBottomSheet],
  /// with [canDismiss] forwarded verbatim so every route's override
  /// behaviour can be tested from the same harness. The sheet's content
  /// carries its own explicit dismiss button, mirroring the dialog gate
  /// test's 'Confirm' action, so "the action itself still dismisses" can be
  /// verified independently of every other route.
  Future<void> pumpApp(
    WidgetTester tester, {
    bool? canDismiss,
  }) async {
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
                  canDismiss: canDismiss ?? true,
                  builder: (sheetContext) => SizedBox(
                    height: 200,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(sheetContext, rootNavigator: true).pop(),
                        child: const SizedBox(width: 40, height: 40, child: Text('Confirm')),
                      ),
                    ),
                  ),
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

  group('LayrzBottomSheet dismissal gate -- canDismiss: true (default, every route dismisses)', () {
    guardedTestWidgets('barrier tap dismisses', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Confirm'), findsNothing);
      expect(observer.pops, equals(1));
    });

    guardedTestWidgets('Escape dismisses', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Confirm'), findsNothing);
      expect(observer.pops, equals(1));
    });

    guardedTestWidgets('drag-to-dismiss past the low snap point dismisses', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm'), findsOneWidget);

      final handle = findDragHandle();
      expect(handle, findsOneWidget);
      await tester.drag(handle, const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(find.text('Confirm'), findsNothing);
      expect(observer.pops, equals(1));
    });

    guardedTestWidgets('system back dismisses', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm'), findsOneWidget);

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(handled, isTrue, reason: 'a dismissible sheet must report the back gesture as handled by popping');
      expect(find.text('Confirm'), findsNothing);
      expect(observer.pops, equals(1));
    });

    guardedTestWidgets('the sheet\'s own content can still dismiss it', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm'), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm'), findsNothing);
      expect(observer.pops, equals(1));
    });
  });

  group(
    'LayrzBottomSheet dismissal gate -- canDismiss: false (non-dismissible by every route but its own content)',
    () {
      guardedTestWidgets('barrier tap does not dismiss', (tester) async {
        await pumpApp(tester, canDismiss: false);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Confirm'), findsOneWidget);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(find.text('Confirm'), findsOneWidget);
        expect(observer.pops, equals(0));
      });

      guardedTestWidgets('Escape does not dismiss and returns ignored so it keeps propagating', (tester) async {
        await pumpApp(tester, canDismiss: false);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Confirm'), findsOneWidget);

        // Same reasoning as dialog_dismissal_gate_test.dart's equivalent case: the
        // externally-observable contract ("Escape does nothing to this sheet") is
        // what every real ancestor listener would see too, since intercepting the
        // private Focus.onKeyEvent callback directly is not possible from outside
        // bottom_sheet.dart.
        final result = await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(
          find.text('Confirm'),
          findsOneWidget,
          reason: 'a non-dismissible sheet must not close on Escape',
        );
        expect(observer.pops, equals(0));
        expect(
          result,
          isFalse,
          reason:
              'sendKeyEvent reports whether ANY handler in the tree consumed the event; the sheet '
              'must not be the one consuming it here (it has nothing else to hand it to in this '
              'harness), which is what "ignored" from the sheet itself is expected to produce',
        );
      });

      guardedTestWidgets('drag-to-dismiss past the low snap point snaps back instead of dismissing', (tester) async {
        await pumpApp(tester, canDismiss: false);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Confirm'), findsOneWidget);

        final handle = findDragHandle();
        expect(handle, findsOneWidget, reason: 'the drag handle must still render even when non-dismissible');
        await tester.drag(handle, const Offset(0, 300));
        await tester.pumpAndSettle();

        expect(
          find.text('Confirm'),
          findsOneWidget,
          reason: 'a non-dismissible sheet must not be draggable away',
        );
        expect(observer.pops, equals(0));
      });

      guardedTestWidgets('system back does not dismiss', (tester) async {
        await pumpApp(tester, canDismiss: false);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Confirm'), findsOneWidget);

        final handled = await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('Confirm'), findsOneWidget, reason: 'the back gesture must not close the sheet');
        expect(observer.pops, equals(0));
        // PopScope(canPop: false) still reports the pop attempt as handled -- it
        // intercepts and stops it, rather than declining and letting the gesture
        // fall through to an ancestor (which would be the wrong failure mode: a
        // swallowed sheet dismissal reaching past it to close the page underneath
        // instead). Mirrors dialog_dismissal_gate_test.dart's equivalent assertion.
        expect(
          handled,
          isTrue,
          reason: 'a blocked back gesture must be intercepted here, not silently fall through to an ancestor route',
        );
      });

      guardedTestWidgets('the sheet\'s own content can still dismiss it', (tester) async {
        await pumpApp(tester, canDismiss: false);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Confirm'), findsOneWidget);

        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();

        expect(find.text('Confirm'), findsNothing);
        expect(observer.pops, equals(1));
      });
    },
  );

  group('LayrzBottomSheet dismissal gate -- persistent + canDismiss: false composition', () {
    /// A persistent sheet paints no barrier at all -- canDismiss is a separate
    /// axis from isPersistent (see LayrzBottomSheet.show's own doc), so this
    /// verifies Escape and system back are still blocked even with no barrier
    /// to gate in the first place.
    Future<void> pumpPersistentApp(WidgetTester tester) async {
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
                    isPersistent: true,
                    canDismiss: false,
                    builder: (context) => const SizedBox(height: 200, child: Text('Persistent body')),
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

    guardedTestWidgets('Escape does not dismiss a persistent, non-dismissible sheet', (tester) async {
      await pumpPersistentApp(tester);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Persistent body'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Persistent body'), findsOneWidget);
      expect(observer.pops, equals(0));
    });

    guardedTestWidgets('system back does not dismiss a persistent, non-dismissible sheet', (tester) async {
      await pumpPersistentApp(tester);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Persistent body'), findsOneWidget);

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Persistent body'), findsOneWidget);
      expect(observer.pops, equals(0));
      expect(handled, isTrue);
    });
  });
}
