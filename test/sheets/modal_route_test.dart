import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// A minimal concrete [LayrzModalRoute] used only to prove the abstract base
/// wires its constructor parameters through to [RawDialogRoute] correctly.
/// [LayrzBottomSheet]'s own route (`_BottomSheetRoute`) already exercises this
/// class end-to-end via every `test/sheets/bottom_sheet_*` suite; this file
/// covers the base's own static helpers, which are not tied to any one
/// concrete subclass.
class _TestModalRoute<T> extends LayrzModalRoute<T> {
  _TestModalRoute({required super.pageBuilder})
    : super(
        barrierDismissible: true,
        barrierColor: const Color(0x80000000),
        settings: const RouteSettings(name: '/test_modal'),
      );
}

/// Counts every `didPop` notification the navigator hosting the route
/// receives, mirroring the pattern in `bottom_sheet_double_pop_test.dart`.
class _PopCountingObserver extends NavigatorObserver {
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
  }
}

void main() {
  group('LayrzModalRoute construction', () {
    testWidgets('a concrete subclass pushes and pops through Navigator like any RawDialogRoute', (
      tester,
    ) async {
      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                Navigator.of(context).push<void>(
                  _TestModalRoute<void>(
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return const Center(child: Text('Modal content'));
                    },
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Modal content'), findsOneWidget);
    });
  });

  group('LayrzModalRoute.popIfCurrent', () {
    testWidgets('pops the current route when it is the topmost route', (tester) async {
      final observer = _PopCountingObserver();

      await tester.pumpWidget(
        LayrzApp(
          navigatorObservers: [observer],
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                Navigator.of(context).push<void>(
                  _TestModalRoute<void>(
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return Builder(
                        builder: (innerContext) => GestureDetector(
                          onTap: () => LayrzModalRoute.popIfCurrent(innerContext),
                          child: const Text('Dismiss'),
                        ),
                      );
                    },
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Dismiss'), findsOneWidget);

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(find.text('Dismiss'), findsNothing);
      expect(observer.pops, 1);
    });

    testWidgets('does nothing when the route is no longer current (already popping)', (
      tester,
    ) async {
      final observer = _PopCountingObserver();
      late BuildContext modalContext;

      await tester.pumpWidget(
        LayrzApp(
          navigatorObservers: [observer],
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                Navigator.of(context).push<void>(
                  _TestModalRoute<void>(
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return Builder(
                        builder: (innerContext) {
                          modalContext = innerContext;
                          return const Text('Modal content');
                        },
                      );
                    },
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // First pop starts removing the route via the ordinary Navigator API
      // (bypassing popIfCurrent), simulating the route already being mid-pop.
      Navigator.of(modalContext).pop();
      await tester.pump();

      // A second call, arriving while the first pop is still in flight,
      // must be a no-op: isCurrent is already false by this point.
      LayrzModalRoute.popIfCurrent(modalContext);
      await tester.pumpAndSettle();

      // Exactly one pop should have been observed, not two.
      expect(observer.pops, 1);
    });
  });

  group('LayrzModalRoute.resolveAnimation', () {
    testWidgets('returns the given animation unchanged when reduce-motion is off', (
      tester,
    ) async {
      final controller = AnimationController(vsync: tester, duration: const Duration(seconds: 1));
      addTearDown(controller.dispose);

      late Animation<double> resolved;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Builder(
            builder: (context) {
              resolved = LayrzModalRoute.resolveAnimation(context, controller);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(identical(resolved, controller), isTrue);
    });

    testWidgets('returns an always-stopped animation pinned at 1.0 when reduce-motion is on', (
      tester,
    ) async {
      final controller = AnimationController(vsync: tester, duration: const Duration(seconds: 1));
      addTearDown(controller.dispose);

      late Animation<double> resolved;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              resolved = LayrzModalRoute.resolveAnimation(context, controller);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(identical(resolved, controller), isFalse);
      expect(resolved.value, 1.0);
      expect(resolved, isA<AlwaysStoppedAnimation<double>>());
    });
  });

  group('LayrzModalRoute.keyboardViewInsetsOf', () {
    testWidgets('returns 0 when no keyboard inset is present', (tester) async {
      late double insets;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.zero),
          child: Builder(
            builder: (context) {
              insets = LayrzModalRoute.keyboardViewInsetsOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(insets, 0.0);
    });

    testWidgets('returns the bottom view inset when the keyboard is open', (tester) async {
      late double insets;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 300)),
          child: Builder(
            builder: (context) {
              insets = LayrzModalRoute.keyboardViewInsetsOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(insets, 300.0);
    });
  });
}
