import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Counts every `didPop` notification the navigator hosting the dialog
/// receives, mirroring the canary already established in
/// test/dialogs/dialog_dismiss_test.dart for the barrier and Escape dismiss
/// paths. A test that only asserts the dialog's content is gone cannot
/// distinguish "dismissed once" from "dismissed, then popped the page
/// underneath it too" -- both leave the dialog's content absent. Only a pop
/// count catches the extra pop.
class _PopCountingObserver extends NavigatorObserver {
  /// Number of `didPop` calls observed so far.
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
  }
}

/// Finds the [Icon] rendered by [LayrzDialog]'s close button via its
/// semantics label, since the icon itself carries no visible text for
/// [find.text] to match. The button's own [Semantics] wrap sets
/// `excludeSemantics: true`, so locating the ancestor by its semantic
/// properties is the reliable route to "tap the close button" regardless of
/// which layout (title row vs. floating) placed it.
Finder findDialogCloseButton() => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.button == true && widget.properties.label != null,
  description: 'the LayrzDialog close button (Semantics with button: true)',
);

void main() {
  group('LayrzDialog close (X) button placement', () {
    guardedTestWidgets('appears in the title row when title is supplied', (tester) async {
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
                    title: const Text('My title'),
                    content: const Text('My content'),
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

      expect(find.text('My title'), findsOneWidget);
      expect(findDialogCloseButton(), findsOneWidget);

      // The close button and the title text must share a common Row
      // ancestor -- the title-row placement, not the floating one.
      final titleFinder = find.text('My title');
      final rowFinder = find.ancestor(of: titleFinder, matching: find.byType(Row));
      expect(
        rowFinder,
        findsOneWidget,
        reason: 'the title must be laid out inside a Row (shared with the close button) when a title is supplied',
      );

      final closeButtonInRow = find.descendant(of: rowFinder, matching: findDialogCloseButton());
      expect(
        closeButtonInRow,
        findsOneWidget,
        reason: 'the close button must be composed into the same title Row, not floated separately',
      );
    });

    guardedTestWidgets('floats over the panel when there is no title (content-only)', (tester) async {
      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzDialog.show<void>(context, content: const Text('Only content'));
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

      expect(find.text('Only content'), findsOneWidget);
      expect(findDialogCloseButton(), findsOneWidget);

      // No title exists to share a Row with, so the close button must reach
      // the panel via a Positioned ancestor (the floating placement) instead.
      final positionedAncestor = find.ancestor(
        of: findDialogCloseButton(),
        matching: find.byType(Positioned),
      );
      expect(
        positionedAncestor,
        findsOneWidget,
        reason: 'with no title, the close button must be positioned via a Positioned overlay',
      );
    });

    guardedTestWidgets('floats over the panel when using the child escape hatch', (tester) async {
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
                    child: const Text('Freeform child content'),
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

      expect(find.text('Freeform child content'), findsOneWidget);
      expect(
        findDialogCloseButton(),
        findsOneWidget,
        reason:
            'the child escape hatch still gets a close affordance -- the caller does not '
            'have to build one itself',
      );

      final positionedAncestor = find.ancestor(
        of: findDialogCloseButton(),
        matching: find.byType(Positioned),
      );
      expect(
        positionedAncestor,
        findsOneWidget,
        reason:
            'the child escape hatch has no title row, so the close button floats the same '
            'way a title-less content dialog does',
      );

      // The child content must still be visible underneath/around the
      // floating close button -- the button must not replace it.
      expect(tester.takeException(), isNull);
    });

    guardedTestWidgets('appears with actions present too (title + content + actions)', (tester) async {
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
                    title: const Text('Confirm'),
                    content: const Text('Body'),
                    actions: const [SizedBox(width: 10, height: 10, child: Text('OK'))],
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

      expect(findDialogCloseButton(), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });
  });

  group('LayrzDialog close (X) button dismissal', () {
    late _PopCountingObserver observer;

    setUp(() {
      observer = _PopCountingObserver();
    });

    guardedTestWidgets('tapping the close button dismisses the dialog', (tester) async {
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
                    title: const Text('Dismiss me'),
                    content: const Text('Body'),
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
      expect(find.text('Dismiss me'), findsOneWidget);

      await tester.tap(findDialogCloseButton());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dismiss me'), findsNothing);
      expect(find.text('Open'), findsOneWidget, reason: 'the page underneath must still be present');
      expect(observer.pops, equals(1));
    });

    guardedTestWidgets('tapping the floating close button (no title) dismisses the dialog', (tester) async {
      await tester.pumpWidget(
        LayrzApp(
          navigatorObservers: [observer],
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzDialog.show<void>(context, content: const Text('Dismiss me too'));
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
      expect(find.text('Dismiss me too'), findsOneWidget);

      await tester.tap(findDialogCloseButton());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dismiss me too'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
      expect(observer.pops, equals(1));
    });

    // Regression canary mirroring dialog_dismiss_test.dart's own barrier and
    // Escape double-pop tests: a fast double-tap on the close button during
    // the exit transition must not reach past the dialog's own route and
    // silently pop the caller's page too. The button's own gesture handler
    // stays mounted for the whole exit transition (same as the barrier's
    // GestureDetector), so without popIfCurrent's isCurrent guard this would
    // double-pop exactly the way the barrier and Escape bugs did.
    guardedTestWidgets('a second tap on the close button during the dismiss animation does not pop the page '
        'underneath', (tester) async {
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
                    title: const Text('Title'),
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

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Dialog body'), findsOneWidget, reason: 'dialog must be open for this test to be valid');
      expect(observer.pops, equals(0));

      final closeButton = findDialogCloseButton();
      expect(closeButton, findsOneWidget);

      // First tap starts the dismiss animation (does NOT settle it) -- the
      // close button's LayrzTappable stays mounted and hit-testable for the
      // whole exit transition, same as the barrier's GestureDetector.
      await tester.tap(closeButton);
      await tester.pump(const Duration(milliseconds: 50));

      // Second tap on the same (still-mounted) close button while the
      // dialog is still animating out.
      expect(
        findDialogCloseButton(),
        findsOneWidget,
        reason: 'the close button must still be mounted mid-dismiss for this test to prove anything',
      );
      await tester.tap(findDialogCloseButton(), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'a second tap during dismissal must not throw (no double Navigator.pop assertion)',
      );
      expect(
        find.text('Open'),
        findsOneWidget,
        reason: 'the page underneath the dialog must survive a second close-button tap during dismissal',
      );
      expect(
        observer.pops,
        equals(1),
        reason:
            'dismissing the dialog must pop only the dialog\'s own route, even with a second '
            'close-button tap landing mid-animation',
      );
    });

    guardedTestWidgets('dismisses through popIfCurrent even when barrierDismissible is false', (tester) async {
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
                    title: const Text('Decision required'),
                    content: const Text('Body'),
                    actions: const [SizedBox(width: 10, height: 10, child: Text('Confirm'))],
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
      expect(find.text('Decision required'), findsOneWidget);

      // The barrier itself must resist a stray tap (actions present ->
      // barrierDismissible defaults to false) -- confirming the dialog's
      // default protection is active for this test to mean anything.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(
        find.text('Decision required'),
        findsOneWidget,
        reason: 'barrier must not dismiss a decision-bearing dialog, for this test setup to be valid',
      );

      // The X, however, always dismisses -- see the doc-comment tension
      // noted on LayrzDialog.show's barrierDismissible parameter.
      await tester.tap(findDialogCloseButton());
      await tester.pumpAndSettle();

      expect(find.text('Decision required'), findsNothing);
      expect(observer.pops, equals(1));
    });
  });

  group('LayrzDialog close (X) button accessibility', () {
    testWidgets('carries a semantic label sourced from context.l10n', (tester) async {
      final handle = tester.ensureSemantics();

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
                    title: const Text('Title'),
                    content: const Text('Body'),
                  );
                },
                child: const SizedBox(width: 100, height: 100, child: Text('Open')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final l10nCloseLabel = LayrzUiL10n.of(tester.element(find.text('Open'))).dialogsCloseButtonLabel;
      expect(l10nCloseLabel, isNotEmpty);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final semanticsWidget = tester.widget<Semantics>(findDialogCloseButton());
      expect(semanticsWidget.properties.label, equals(l10nCloseLabel));
      expect(semanticsWidget.properties.button, isTrue);

      handle.dispose();
    });
  });
}
