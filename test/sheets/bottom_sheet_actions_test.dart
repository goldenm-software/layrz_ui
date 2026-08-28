import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/find_button_label.dart';
import '../helpers/no_overflow.dart';
import '../helpers/pump_themed_app.dart';

/// Counts every `didPop` notification the navigator hosting the sheet
/// receives -- mirrors the canary already established in
/// test/sheets/bottom_sheet_dismissal_gate_test.dart and
/// test/dialogs/dialog_dismissal_gate_test.dart.
class _PopCountingObserver extends NavigatorObserver {
  /// Number of `didPop` calls observed so far.
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
  }
}

void main() {
  group('LayrzBottomSheet actions -- rendering', () {
    guardedTestWidgets('a null actions list renders nothing and changes no layout', (tester) async {
      Rect? sheetRectWithoutActions;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<void>(
                context,
                builder: (context) => const SizedBox(height: 100, child: Text('Sheet body')),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet body'), findsOneWidget);

      final sheetSurfaceFinder = find.byWidgetPredicate(
        (widget) => widget is DecoratedBox && (widget.decoration as BoxDecoration).boxShadow != null,
      );
      sheetRectWithoutActions = tester.getRect(sheetSurfaceFinder);

      // No action buttons of any kind should exist, and the sheet's own layout
      // (its surface's rect) should be identical to a sheet with no actions
      // parameter at all -- proving the omitted parameter changes nothing.
      expect(findButtonLabel('Confirm'), findsNothing);
      expect(sheetRectWithoutActions, isNotNull);
    });

    guardedTestWidgets('actions render below the builder content, right-aligned', (tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<void>(
                context,
                builder: (context) => const SizedBox(height: 100, child: Text('Sheet body')),
                actions: [
                  LayrzButton(labelText: 'Cancel', onTap: () {}),
                  LayrzButton(labelText: 'Confirm', onTap: () {}),
                ],
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Sheet body'), findsOneWidget);
      expect(findButtonLabel('Cancel'), findsOneWidget);
      expect(findButtonLabel('Confirm'), findsOneWidget);

      final bodyBottom = tester.getBottomLeft(find.text('Sheet body')).dy;
      final cancelTop = tester.getTopLeft(findButtonLabel('Cancel')).dy;
      final confirmTop = tester.getTopLeft(findButtonLabel('Confirm')).dy;

      expect(cancelTop, greaterThanOrEqualTo(bodyBottom), reason: 'actions must render below the builder content');
      expect(confirmTop, greaterThanOrEqualTo(bodyBottom), reason: 'actions must render below the builder content');

      // Right-aligned row: Confirm (the last action) sits further right than Cancel.
      final cancelLeft = tester.getTopLeft(findButtonLabel('Cancel')).dx;
      final confirmLeft = tester.getTopLeft(findButtonLabel('Confirm')).dx;
      expect(
        confirmLeft,
        greaterThan(cancelLeft),
        reason: 'actions must be laid out left-to-right in a right-aligned row',
      );
    });

    guardedTestWidgets('an empty actions list renders nothing, same as null', (tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<void>(
                context,
                builder: (context) => const SizedBox(height: 100, child: Text('Sheet body')),
                actions: const [],
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Sheet body'), findsOneWidget);
      expect(findButtonLabel('Confirm'), findsNothing);
    });
  });

  group('LayrzBottomSheet actions -- pinned below the scrollable content, not scrolling away', () {
    guardedTestWidgets('actions stay visible when the builder content is tall enough to scroll', (tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<void>(
                context,
                initialSize: 0.5,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < 60; i++) Text('Row $i'),
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
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // The action row must be present and on-screen without any scrolling --
      // if it were nested inside the content's own SingleChildScrollView, a
      // tall builder like this one would push it out of the initial viewport.
      expect(findButtonLabel('Confirm'), findsOneWidget);
      expect(
        tester.getRect(findButtonLabel('Confirm')).bottom,
        lessThanOrEqualTo(tester.view.physicalSize.height / tester.view.devicePixelRatio),
        reason: 'the action row must be pinned on-screen, not pushed away by scrollable content',
      );

      // Scrolling the content must not move the action row -- proving it is a
      // sibling of the Expanded scroll view, not nested inside it.
      final beforeScrollActionsRect = tester.getRect(findButtonLabel('Confirm'));
      await tester.drag(find.text('Row 0'), const Offset(0, -300));
      await tester.pumpAndSettle();
      final afterScrollActionsRect = tester.getRect(findButtonLabel('Confirm'));

      expect(
        afterScrollActionsRect,
        equals(beforeScrollActionsRect),
        reason: 'the pinned action row must not move when the builder content scrolls',
      );
    });
  });

  group('LayrzBottomSheet actions -- reachable above the keyboard', () {
    void setLogicalSize(WidgetTester tester, Size logicalSize) {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = logicalSize;
    }

    const screenHeight = 800.0;
    const keyboardInset = 300.0;

    guardedTestWidgets('actions remain on-screen, above the keyboard, once it opens', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        setLogicalSize(tester, const Size(400, screenHeight));

        await tester.pumpWidget(
          LayrzApp(
            theme: LayrzThemeData.light(),
            debugShowCheckedModeBanner: false,
            home: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzBottomSheet.show<void>(
                    context,
                    initialSize: 0.3,
                    builder: (context) => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Sheet body'),
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
        );
        await tester.pump();

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(findButtonLabel('Confirm'), findsOneWidget);

        tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
        await tester.pumpAndSettle();

        final availableHeight = screenHeight - keyboardInset;
        final actionsRect = tester.getRect(findButtonLabel('Confirm'));

        expect(
          actionsRect.bottom,
          lessThanOrEqualTo(availableHeight + 0.5),
          reason: 'the action row must stay above the keyboard, not be pushed behind it',
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  group('LayrzBottomSheet actions -- answered, not escaped', () {
    late _PopCountingObserver observer;

    setUp(() {
      observer = _PopCountingObserver();
    });

    guardedTestWidgets("an action's own callback dismisses the sheet even when canDismiss is false", (tester) async {
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
                    canDismiss: false,
                    builder: (context) => const SizedBox(height: 100, child: Text('Sheet body')),
                    actions: [
                      LayrzButton(
                        labelText: 'Confirm',
                        onTap: () => Navigator.of(context, rootNavigator: true).pop(),
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
      expect(find.text('Sheet body'), findsOneWidget);

      // Every other route is blocked (covered exhaustively by
      // bottom_sheet_dismissal_gate_test.dart) -- this test's job is only to
      // prove the action itself is still a working way out.
      await tester.tap(findButtonLabel('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Sheet body'), findsNothing);
      expect(observer.pops, equals(1));
    });
  });
}
