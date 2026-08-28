import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Counts every `didPop` notification the navigator hosting the dialog
/// receives, mirroring test/sheets/bottom_sheet_double_pop_test.dart's
/// canary for the sibling sheet. A test that only asserts the dialog's
/// content is gone cannot distinguish "dismissed once" from "dismissed, then
/// popped the page underneath it too" -- both leave the dialog's content
/// absent. Only a pop count catches the extra pop.
class _PopCountingObserver extends NavigatorObserver {
  /// Number of `didPop` calls observed so far.
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
  }
}

void main() {
  group('LayrzDialog barrier double-pop (fast double-tap during dismiss)', () {
    late _PopCountingObserver observer;

    setUp(() {
      observer = _PopCountingObserver();
    });

    /// Pumps a [LayrzApp] whose home page can be tapped to open the dialog,
    /// wired to [observer] so pops on the app's single Navigator can be
    /// counted. The home page itself is the "route underneath" that a
    /// double-pop would incorrectly remove. canDismiss is forced true (no
    /// actions) so the barrier tap path is exercised directly.
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
                  LayrzDialog.show<void>(
                    context,
                    content: const SizedBox(height: 100, width: 100, child: Text('Dialog body')),
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
        expect(find.text('Dialog body'), findsOneWidget, reason: 'dialog must be open for this test to be valid');
        expect(observer.pops, equals(0));

        // First tap on the barrier -- a point outside the centered panel --
        // starts the dismiss animation (does NOT settle it; that is the point).
        await tester.tapAt(const Offset(10, 10));
        // Advance partway into the exit transition, deliberately shorter than
        // the full dismiss animation (200ms), so the barrier's GestureDetector
        // is still mounted and still hit-testable when the second tap lands.
        await tester.pump(const Duration(milliseconds: 50));

        // Second tap on the same barrier position, while the dialog is still
        // (partially) visible and animating out.
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'a second tap during dismissal must not throw (no double Navigator.pop assertion)',
        );

        // The real damage this bug causes: a second pop reaching past the
        // dialog's own route and removing the page underneath it. In this
        // harness that page is LayrzApp's only route, so losing it manifests
        // as the 'Open' trigger (part of the home page) disappearing along
        // with the dialog.
        expect(
          find.text('Open'),
          findsOneWidget,
          reason: 'the page underneath the dialog must survive a second barrier tap during dismissal',
        );

        expect(
          observer.pops,
          equals(1),
          reason:
              'dismissing the dialog must pop only the dialog\'s own route, never the route underneath, '
              'even when a second tap lands on the barrier mid-animation',
        );
      },
    );

    testWidgets('a single barrier tap still dismisses the dialog normally', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Dialog body'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dialog body'), findsNothing);
      expect(find.text('Open'), findsOneWidget, reason: 'the page underneath must still be present');
      expect(observer.pops, equals(1));
    });
  });

  group('LayrzDialog Escape-key double-pop (fast double-Escape during dismiss)', () {
    late _PopCountingObserver observer;

    setUp(() {
      observer = _PopCountingObserver();
    });

    /// Same harness as the barrier group above, reused here so the
    /// Escape-key path is exercised against an identical "route underneath"
    /// setup.
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
                  LayrzDialog.show<void>(
                    context,
                    content: const SizedBox(height: 100, width: 100, child: Text('Dialog body')),
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
        expect(find.text('Dialog body'), findsOneWidget, reason: 'dialog must be open for this test to be valid');
        expect(observer.pops, equals(0));

        // First Escape starts the dismiss animation (does NOT settle it).
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump(const Duration(milliseconds: 50));

        // Second Escape while the dialog is still animating out. The
        // dialog's Focus node (and its onKeyEvent handler) stays mounted for
        // the whole transition, same as the barrier's GestureDetector.
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
          reason: 'the page underneath the dialog must survive a second Escape during dismissal',
        );
        expect(
          observer.pops,
          equals(1),
          reason:
              'dismissing the dialog must pop only the dialog\'s own route, even with a second Escape '
              'mid-animation',
        );
      },
    );

    testWidgets('a single Escape still dismisses the dialog normally', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Dialog body'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dialog body'), findsNothing);
      expect(find.text('Open'), findsOneWidget, reason: 'the page underneath must still be present');
      expect(observer.pops, equals(1));
    });
  });

  group('LayrzDialog canDismiss: false does not dismiss on barrier tap', () {
    testWidgets('a barrier tap is a no-op when canDismiss is false', (tester) async {
      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzDialog.show<void>(
                    context,
                    content: const Text('Dialog body'),
                    actions: [SizedBox(width: 10, height: 10, child: Text('Confirm'))],
                  );
                },
                child: const SizedBox(width: 100, height: 100, child: Text('Open')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Dialog body'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(
        find.text('Dialog body'),
        findsOneWidget,
        reason:
            'a dialog with actions defaults to canDismiss: false, so a stray barrier tap must not '
            'discard an unmade decision',
      );
    });
  });

  group('LayrzDialog stacking guard', () {
    testWidgets('opening a second LayrzDialog while one is open throws', (tester) async {
      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzDialog.show<void>(
                    context,
                    content: Builder(
                      builder: (innerContext) => GestureDetector(
                        onTap: () {
                          LayrzDialog.show<void>(innerContext, content: const Text('Second dialog'));
                        },
                        child: const SizedBox(width: 100, height: 100, child: Text('Open second')),
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

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Open second'), findsOneWidget);

      // The assertion in LayrzDialog.show throws synchronously inside the
      // onTap handler invoked by the gesture recognizer, so it surfaces
      // through FlutterError reporting / takeException rather than through
      // the Future returned by tester.tap() itself.
      await tester.tap(find.text('Open second'));
      expect(
        tester.takeException(),
        isA<FlutterError>(),
        reason: 'LayrzDialog.show must refuse to stack a second dialog over an already-open one',
      );
    });
  });
}
