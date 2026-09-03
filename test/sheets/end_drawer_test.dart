import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/find_button_label.dart';
import '../helpers/no_overflow.dart';

/// Counts every `didPop` notification the navigator hosting the drawer
/// receives -- mirrors the canary already established in
/// test/sheets/bottom_sheet_dismissal_gate_test.dart.
class _PopCountingObserver extends NavigatorObserver {
  /// Number of `didPop` calls observed so far.
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
  }
}

void setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('LayrzEndDrawer -- actions pin to the bottom edge', () {
    guardedTestWidgets('a short body leaves the actions row flush with the drawer bottom, not floating above a gap', (
      tester,
    ) async {
      setWideViewport(tester);

      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzEndDrawer.show<void>(
                    context,
                    semanticLabel: 'Drawer',
                    builder: (context) => const SizedBox(height: 40, child: Text('Short body')),
                    actions: [
                      LayrzButton(labelText: 'Confirm', onTap: () {}),
                    ],
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

      expect(find.text('Short body'), findsOneWidget);
      expect(findButtonLabel('Confirm'), findsOneWidget);

      // The bug this reproduces: composing the footer as a trailing child of
      // the scrolling body leaves it directly under short content, with a
      // large empty gap filling the rest of the drawer down to its true
      // bottom edge. Asserting the action's bottom edge lands at the
      // viewport's bottom edge (the drawer is full-height) is what proves
      // the actions row is pinned structurally, not merely present.
      final actionsBottom = tester.getRect(findButtonLabel('Confirm')).bottom;
      final viewportHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;

      expect(
        actionsBottom,
        greaterThan(viewportHeight - 60),
        reason:
            'the actions row must sit near the drawer\'s own bottom edge, not directly under '
            'short content with empty space below it',
      );
    });

    guardedTestWidgets('content scrolls independently above pinned actions when it exceeds available height', (
      tester,
    ) async {
      setWideViewport(tester);

      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzEndDrawer.show<void>(
                    context,
                    semanticLabel: 'Drawer',
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < 80; i++) Text('Row $i'),
                      ],
                    ),
                    actions: [
                      LayrzButton(labelText: 'Confirm', onTap: () {}),
                    ],
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

      expect(findButtonLabel('Confirm'), findsOneWidget);
      final beforeScroll = tester.getRect(findButtonLabel('Confirm'));

      await tester.drag(find.text('Row 0'), const Offset(0, -300));
      await tester.pumpAndSettle();

      final afterScroll = tester.getRect(findButtonLabel('Confirm'));
      expect(
        afterScroll,
        equals(beforeScroll),
        reason: 'the pinned actions row must not move when the scrolling content is dragged',
      );
    });

    guardedTestWidgets('a null actions list renders nothing and changes no layout', (tester) async {
      setWideViewport(tester);

      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzEndDrawer.show<void>(
                    context,
                    builder: (context) => const SizedBox(height: 40, child: Text('Body')),
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

      expect(find.text('Body'), findsOneWidget);
      expect(findButtonLabel('Confirm'), findsNothing);
    });

    guardedTestWidgets('an empty actions list renders nothing, same as null', (tester) async {
      setWideViewport(tester);

      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzEndDrawer.show<void>(
                    context,
                    builder: (context) => const SizedBox(height: 40, child: Text('Body')),
                    actions: const [],
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

      expect(find.text('Body'), findsOneWidget);
      expect(findButtonLabel('Confirm'), findsNothing);
    });
  });

  group('LayrzEndDrawer -- canDismiss inference', () {
    late _PopCountingObserver observer;

    setUp(() {
      observer = _PopCountingObserver();
    });

    guardedTestWidgets('barrier tap dismisses when actions is null', (tester) async {
      setWideViewport(tester);

      await tester.pumpWidget(
        LayrzApp(
          navigatorObservers: [observer],
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzEndDrawer.show<void>(
                    context,
                    semanticLabel: 'Drawer',
                    builder: (context) => const SizedBox(height: 40, child: Text('Body')),
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
      expect(find.text('Body'), findsOneWidget);

      // Tap the barrier, well away from the right-edge drawer.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Body'), findsNothing);
      expect(observer.pops, equals(1));
    });

    guardedTestWidgets('barrier tap dismisses when actions is empty', (tester) async {
      setWideViewport(tester);

      await tester.pumpWidget(
        LayrzApp(
          navigatorObservers: [observer],
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzEndDrawer.show<void>(
                    context,
                    semanticLabel: 'Drawer',
                    builder: (context) => const SizedBox(height: 40, child: Text('Body')),
                    actions: const [],
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

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Body'), findsNothing);
      expect(observer.pops, equals(1));
    });

    guardedTestWidgets('barrier tap does NOT dismiss when actions is a non-empty list', (tester) async {
      setWideViewport(tester);

      await tester.pumpWidget(
        LayrzApp(
          navigatorObservers: [observer],
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzEndDrawer.show<void>(
                    context,
                    semanticLabel: 'Drawer',
                    builder: (context) => const SizedBox(height: 40, child: Text('Body')),
                    actions: [
                      LayrzButton(labelText: 'Confirm', onTap: () {}),
                    ],
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

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Body'), findsOneWidget);
      expect(observer.pops, equals(0));
    });

    guardedTestWidgets('Escape does NOT dismiss when actions is present, but does when null', (tester) async {
      setWideViewport(tester);

      await tester.pumpWidget(
        LayrzApp(
          navigatorObservers: [observer],
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzEndDrawer.show<void>(
                    context,
                    semanticLabel: 'Drawer',
                    builder: (drawerContext) => const SizedBox(height: 40, child: Text('Body')),
                    actions: [
                      Builder(
                        builder: (actionContext) => LayrzButton(
                          labelText: 'Confirm',
                          onTap: () => Navigator.of(actionContext, rootNavigator: true).pop(),
                        ),
                      ),
                    ],
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

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Body'), findsOneWidget, reason: 'Escape must not dismiss a drawer with actions present');
      expect(observer.pops, equals(0));

      // An action's own callback still dismisses.
      await tester.tap(findButtonLabel('Confirm'));
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsNothing);
    });

    guardedTestWidgets('canDismiss: true explicitly reopens the barrier even with actions present', (tester) async {
      setWideViewport(tester);

      await tester.pumpWidget(
        LayrzApp(
          navigatorObservers: [observer],
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzEndDrawer.show<void>(
                    context,
                    semanticLabel: 'Drawer',
                    canDismiss: true,
                    builder: (context) => const SizedBox(height: 40, child: Text('Body')),
                    actions: [
                      LayrzButton(labelText: 'Confirm', onTap: () {}),
                    ],
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

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Body'), findsNothing);
      expect(observer.pops, equals(1));
    });
  });

  group('LayrzEndDrawer -- involuntary close discards state', () {
    guardedTestWidgets('reopening reconstructs a fresh State, not the previous one', (tester) async {
      setWideViewport(tester);

      int buildCount = 0;

      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzEndDrawer.show<void>(
                    context,
                    semanticLabel: 'Drawer',
                    builder: (context) {
                      buildCount++;
                      return const SizedBox(height: 40, child: Text('Body'));
                    },
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
      final firstOpenCount = buildCount;
      expect(firstOpenCount, greaterThan(0));

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // The builder is invoked again on the second open, proving
      // Navigator.push built a fresh subtree rather than reusing state.
      expect(buildCount, greaterThan(firstOpenCount));
    });
  });

  group('LayrzEndDrawer -- accessibility', () {
    guardedTestWidgets('exposes route semantics with the caller-supplied label', (tester) async {
      setWideViewport(tester);
      final handle = tester.ensureSemantics();

      try {
        await tester.pumpWidget(
          LayrzApp(
            theme: LayrzThemeData.light(),
            debugShowCheckedModeBanner: false,
            home: Center(
              child: Builder(
                builder: (context) => GestureDetector(
                  onTap: () {
                    LayrzEndDrawer.show<void>(
                      context,
                      semanticLabel: 'Choose an option',
                      builder: (context) => const SizedBox(height: 40, child: Text('Body')),
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

        // Mirrors test/dialogs/dialog_a11y_test.dart's identical assertion:
        // find the Semantics widget carrying the caller's label and check
        // its real scopesRoute/namesRoute properties directly, rather than a
        // bare findsOneWidget on a semantics-label finder (which would pass
        // even if scopesRoute/namesRoute were both false).
        final semanticsWidget = tester.widget<Semantics>(
          find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == 'Choose an option'),
        );
        expect(semanticsWidget.properties.scopesRoute, isTrue);
        expect(semanticsWidget.properties.namesRoute, isTrue);
      } finally {
        handle.dispose();
      }
    });
  });

  // The title slot, added after the maintainer's device review reported
  // "labelText IS a title, not like the image" against a caller
  // (LayrzComboBoxInput) that was rendering its own small, centered,
  // caption-styled `labelText` inside the drawer's scrolling body instead of
  // a real title. `LayrzEndDrawer` had no visible title mechanism of its own
  // before this -- `semanticLabel` only ever reached a screen reader. This
  // slot fixes that at the source, mirroring `LayrzDialog`'s own `title`
  // slot styling (headline, left-aligned) exactly, so every future
  // `LayrzEndDrawer` caller gets a real title for free instead of
  // reinventing (and mis-styling) one per surface.
  group('LayrzEndDrawer -- title slot', () {
    guardedTestWidgets('renders the title styled with LayrzTextTheme.headline, above the scrolling body', (
      tester,
    ) async {
      setWideViewport(tester);
      late LayrzTokens tokens;

      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) {
                tokens = context.tokens;
                return GestureDetector(
                  onTap: () {
                    LayrzEndDrawer.show<void>(
                      context,
                      semanticLabel: 'Choose an option',
                      title: const Text('Country'),
                      builder: (context) => const SizedBox(height: 40, child: Text('Body')),
                    );
                  },
                  child: const SizedBox(width: 100, height: 100, child: Text('Open')),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final titleFinder = find.text('Country');
      expect(titleFinder, findsOneWidget);

      final resolvedStyle = DefaultTextStyle.of(tester.element(titleFinder)).style;
      expect(resolvedStyle.fontSize, tokens.typography.headline.fontSize);
      expect(resolvedStyle.fontWeight, tokens.typography.headline.fontWeight);

      final titleTop = tester.getTopLeft(titleFinder).dy;
      final bodyTop = tester.getTopLeft(find.text('Body')).dy;
      expect(titleTop, lessThan(bodyTop), reason: 'the title must render above the scrolling body');
    });

    guardedTestWidgets('title is left-aligned, not centered, matching LayrzDialog\'s own title convention', (
      tester,
    ) async {
      setWideViewport(tester);

      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzEndDrawer.show<void>(
                    context,
                    semanticLabel: 'Choose an option',
                    title: const Text('Country'),
                    builder: (context) => const SizedBox(height: 40, child: Text('Body')),
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

      final titleRect = tester.getRect(find.text('Country'));
      final drawerRect = tester.getRect(
        find.byWidgetPredicate((widget) => widget is SizedBox && widget.width == LayrzEndDrawer.width),
      );

      // Left-aligned means the title's own left edge sits close to the
      // drawer's left edge (well within its own padding), not floating in
      // the middle of the drawer's width the way a centered title would.
      expect(titleRect.left - drawerRect.left, lessThan(LayrzEndDrawer.width / 4));
    });

    guardedTestWidgets('omitting title renders no title row at all', (tester) async {
      setWideViewport(tester);

      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzEndDrawer.show<void>(
                    context,
                    semanticLabel: 'Choose an option',
                    builder: (context) => const SizedBox(height: 40, child: Text('Body')),
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

      expect(find.text('Body'), findsOneWidget);
      // Nothing else in the tree carries the (deliberately distinct) title
      // text used by the other tests in this group -- the closest available
      // proxy for "no title row was built" without a widget key to search by.
      expect(find.text('Country'), findsNothing);
    });
  });
}
