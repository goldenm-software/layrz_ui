import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Counts every `didPop` notification the navigator hosting the dialog
/// receives, mirroring the canary already established in
/// test/dialogs/dialog_dismiss_test.dart and dialog_close_button_test.dart --
/// a test that only asserts the dialog's content is gone cannot distinguish
/// "dismissed once" from "dismissed, then popped the page underneath it too".
class _PopCountingObserver extends NavigatorObserver {
  /// Number of `didPop` calls observed so far.
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
  }
}

/// Finds the [Icon] rendered by [LayrzDialog]'s close button via its
/// semantics label -- mirrors `findDialogCloseButton` in
/// dialog_close_button_test.dart, duplicated here rather than imported since
/// that file's helper is private to its own library.
Finder findDialogCloseButton() => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.button == true && widget.properties.label != null,
  description: 'the LayrzDialog close button (Semantics with button: true)',
);

void main() {
  late _PopCountingObserver observer;

  setUp(() {
    observer = _PopCountingObserver();
  });

  /// Pumps a [LayrzApp] whose home page opens a [LayrzDialog] with a title,
  /// content, and (when [withActions] is true) one 'Confirm' action.
  /// [canDismiss] is forwarded verbatim so every route's override
  /// behaviour can be tested from the same harness.
  Future<void> pumpApp(
    WidgetTester tester, {
    required bool withActions,
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
                LayrzDialog.show<void>(
                  context,
                  title: const Text('Dialog title'),
                  content: const Text('Dialog body'),
                  canDismiss: canDismiss,
                  actions: withActions
                      ? [
                          GestureDetector(
                            onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                            child: const SizedBox(width: 40, height: 40, child: Text('Confirm')),
                          ),
                        ]
                      : null,
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

  group('LayrzDialog dismissal gate -- no actions (dismissible by every route)', () {
    guardedTestWidgets('barrier tap dismisses', (tester) async {
      await pumpApp(tester, withActions: false);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Dialog title'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Dialog title'), findsNothing);
      expect(observer.pops, equals(1));
    });

    guardedTestWidgets('Escape dismisses', (tester) async {
      await pumpApp(tester, withActions: false);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Dialog title'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Dialog title'), findsNothing);
      expect(observer.pops, equals(1));
    });

    guardedTestWidgets('the X dismisses and is rendered', (tester) async {
      await pumpApp(tester, withActions: false);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(findDialogCloseButton(), findsOneWidget);

      await tester.tap(findDialogCloseButton());
      await tester.pumpAndSettle();

      expect(find.text('Dialog title'), findsNothing);
      expect(observer.pops, equals(1));
    });

    guardedTestWidgets('system back dismisses', (tester) async {
      await pumpApp(tester, withActions: false);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Dialog title'), findsOneWidget);

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(handled, isTrue, reason: 'a dismissible dialog must report the back gesture as handled by popping');
      expect(find.text('Dialog title'), findsNothing);
      expect(observer.pops, equals(1));
    });
  });

  group('LayrzDialog dismissal gate -- actions present, canDismiss not overridden '
      '(non-dismissible by every route but the action itself)', () {
    guardedTestWidgets('barrier tap does not dismiss', (tester) async {
      await pumpApp(tester, withActions: true);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Dialog title'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Dialog title'), findsOneWidget);
      expect(observer.pops, equals(0));
    });

    guardedTestWidgets('Escape does not dismiss and returns ignored so it keeps propagating', (tester) async {
      await pumpApp(tester, withActions: true);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Dialog title'), findsOneWidget);

      // Wrap the whole app in an outer Focus/Shortcuts-style ancestor handler
      // is unnecessary here -- KeyEventResult.ignored is verified indirectly:
      // the dialog must still be open (not dismissed), which is only
      // possible if the handler declined to act. A direct
      // KeyEventResult.ignored assertion would require intercepting the
      // Focus.onKeyEvent callback itself, which is private to dialog.dart;
      // the externally-observable contract -- "Escape does nothing to this
      // dialog" -- is what every real ancestor listener would see too.
      final result = await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(
        find.text('Dialog title'),
        findsOneWidget,
        reason: 'a non-dismissible dialog must not close on Escape',
      );
      expect(observer.pops, equals(0));
      expect(
        result,
        isFalse,
        reason:
            'sendKeyEvent reports whether ANY handler in the tree consumed the event; the dialog '
            'must not be the one consuming it here (it has nothing else to hand it to in this '
            'harness), which is what "ignored" from the dialog itself is expected to produce',
      );
    });

    guardedTestWidgets('the X is not rendered', (tester) async {
      await pumpApp(tester, withActions: true);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(findDialogCloseButton(), findsNothing);
      // Nothing to tap means nothing can pop -- asserted explicitly (not just
      // implied by the absent finder) so this test would also catch a future
      // regression that renders the icon back but forgets to wire it, or
      // wires it to something that pops the wrong route.
      expect(observer.pops, equals(0));
    });

    guardedTestWidgets('system back does not dismiss', (tester) async {
      await pumpApp(tester, withActions: true);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Dialog title'), findsOneWidget);

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Dialog title'), findsOneWidget, reason: 'the back gesture must not close the dialog');
      expect(observer.pops, equals(0));
      // PopScope(canPop: false) still reports the pop attempt as handled --
      // it intercepts and stops it, rather than declining and letting the
      // gesture fall through to an ancestor (which would be the wrong
      // failure mode: a swallowed dialog dismissal reaching past it to close
      // the page underneath instead).
      expect(
        handled,
        isTrue,
        reason: 'a blocked back gesture must be intercepted here, not silently fall through to an ancestor route',
      );
    });

    guardedTestWidgets('the action itself still dismisses', (tester) async {
      await pumpApp(tester, withActions: true);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Dialog title'), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Dialog title'), findsNothing);
      expect(observer.pops, equals(1));
    });
  });

  group('LayrzDialog dismissal gate -- actions present, canDismiss: true '
      '(dismissible by every route again)', () {
    guardedTestWidgets('barrier tap dismisses', (tester) async {
      await pumpApp(tester, withActions: true, canDismiss: true);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Dialog title'), findsNothing);
      expect(observer.pops, equals(1));
    });

    guardedTestWidgets('Escape dismisses', (tester) async {
      await pumpApp(tester, withActions: true, canDismiss: true);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Dialog title'), findsNothing);
      expect(observer.pops, equals(1));
    });

    guardedTestWidgets('the X renders and dismisses', (tester) async {
      await pumpApp(tester, withActions: true, canDismiss: true);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(findDialogCloseButton(), findsOneWidget);

      await tester.tap(findDialogCloseButton());
      await tester.pumpAndSettle();

      expect(find.text('Dialog title'), findsNothing);
      expect(observer.pops, equals(1));
    });

    guardedTestWidgets('system back dismisses', (tester) async {
      await pumpApp(tester, withActions: true, canDismiss: true);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(handled, isTrue);
      expect(find.text('Dialog title'), findsNothing);
      expect(observer.pops, equals(1));
    });
  });
}
