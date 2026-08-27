import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/sheets/src/drag_handle.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed_app.dart';

/// Sets the test binding's viewport to [width] at a fixed 1.0 device pixel
/// ratio, and registers a [WidgetTester.addTearDown] to restore the original
/// view afterward -- matching the reset pattern used elsewhere in the suite
/// (e.g. test/buttons/button_test.dart) so a left-over override cannot leak
/// into a later test.
void setViewportWidth(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('LayrzResponsiveModal.show breakpoint dispatch', () {
    guardedTestWidgets('presents a bottom sheet below the compact breakpoint', (tester) async {
      setViewportWidth(tester, 500);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                builder: (context) => const Text('Modal content'),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Modal content'), findsOneWidget);
      // A bottom sheet uses a DraggableScrollableSheet internally; a dialog
      // does not. Its presence distinguishes which surface was actually used.
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    guardedTestWidgets('presents a dialog at or above the compact breakpoint', (tester) async {
      setViewportWidth(tester, 1200);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                builder: (context) => const Text('Modal content'),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Modal content'), findsOneWidget);
      expect(find.byType(DraggableScrollableSheet), findsNothing);
    });

    guardedTestWidgets('returns the value the presented surface was popped with', (tester) async {
      setViewportWidth(tester, 1200);
      String? result;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () async {
              result = await LayrzResponsiveModal.show<String>(
                context,
                builder: (dialogContext) => GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop('picked'),
                  child: const SizedBox(width: 50, height: 50, child: Text('Pick')),
                ),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();

      expect(result, 'picked');
    });

    guardedTestWidgets('returns null when dismissed without a value', (tester) async {
      setViewportWidth(tester, 1200);
      Object? sentinel = 'unset';
      String? result;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () async {
              result = await LayrzResponsiveModal.show<String>(
                context,
                builder: (context) => const Text('Modal content'),
                canDismiss: true,
              );
              sentinel = null;
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap the barrier (outside the dialog panel) to dismiss without a value.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(sentinel, isNull);
      expect(result, isNull);
    });
  });

  group('LayrzResponsiveModal.show per-call isCompact override', () {
    guardedTestWidgets('forces the sheet on a wide viewport when isCompact: true', (tester) async {
      setViewportWidth(tester, 1400);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                isCompact: true,
                builder: (context) => const Text('Modal content'),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    guardedTestWidgets('forces the dialog on a narrow viewport when isCompact: false', (tester) async {
      setViewportWidth(tester, 400);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                isCompact: false,
                builder: (context) => const Text('Modal content'),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(find.text('Modal content'), findsOneWidget);
    });
  });

  group('LayrzResponsiveModal.show presentation is decided once and never re-evaluated', () {
    guardedTestWidgets('a dialog opened at a wide viewport stays a dialog after resizing narrow', (tester) async {
      setViewportWidth(tester, 1200);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                builder: (context) => const Text('Modal content'),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Confirm it opened as a dialog (no DraggableScrollableSheet).
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(find.text('Modal content'), findsOneWidget);

      // Cross the compact breakpoint while the route is still open. If the
      // presentation were re-evaluated on resize, this would attempt to swap
      // the dialog route for a sheet mid-flight -- neither surface supports
      // that, and 0.0.14 shipped a fix for exactly this shape of bug in
      // LayrzScaffoldShell (setState()/markNeedsBuild() during build when the
      // viewport crossed the compact breakpoint with a detail sheet open).
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();

      // Still a dialog: no DraggableScrollableSheet appeared, content is
      // still present, and no rebuild-during-build error was thrown (the
      // guardedTestWidgets wrapper would fail this test if one had been).
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(find.text('Modal content'), findsOneWidget);
    });

    guardedTestWidgets('a sheet opened at a narrow viewport stays a sheet after resizing wide', (tester) async {
      setViewportWidth(tester, 500);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                builder: (context) => const Text('Modal content'),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);

      tester.view.physicalSize = const Size(1400, 800);
      await tester.pumpAndSettle();

      // Still a sheet: the DraggableScrollableSheet did not get swapped for
      // a dialog panel mid-route.
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      expect(find.text('Modal content'), findsOneWidget);
    });
  });

  group('LayrzResponsiveModal.show equivalent screen-reader announcement across branches', () {
    guardedTestWidgets('the same semanticLabel is announced whether the sheet or dialog branch is chosen', (
      tester,
    ) async {
      const label = 'Choose an option';

      // Narrow viewport -> sheet branch.
      setViewportWidth(tester, 500);
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                semanticLabel: label,
                builder: (context) => const Text('Modal content'),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(label),
        findsOneWidget,
        reason: 'The sheet branch must announce the caller-supplied semanticLabel.',
      );
    });

    guardedTestWidgets('the dialog branch announces the same semanticLabel', (tester) async {
      const label = 'Choose an option';

      setViewportWidth(tester, 1200);
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                semanticLabel: label,
                builder: (context) => const Text('Modal content'),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(label),
        findsOneWidget,
        reason: 'The dialog branch must announce the same semanticLabel the sheet branch does.',
      );
    });
  });

  group('LayrzResponsiveModal.show config objects', () {
    guardedTestWidgets('forwards LayrzDialogConfig maxWidth/maxHeight to the dialog branch', (tester) async {
      setViewportWidth(tester, 1200);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                dialog: const LayrzDialogConfig(maxWidth: 200, maxHeight: 150),
                builder: (context) => const SizedBox.expand(child: Text('Modal content')),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.ancestor(of: find.text('Modal content'), matching: find.byType(ConstrainedBox)).first,
      );
      expect(constrainedBox.constraints.maxWidth, 200);
      expect(constrainedBox.constraints.maxHeight, 150);
    });

    guardedTestWidgets('forwards LayrzBottomSheetConfig showDragHandle to the sheet branch', (tester) async {
      setViewportWidth(tester, 500);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                sheet: const LayrzBottomSheetConfig(showDragHandle: false),
                builder: (context) => const Text('Modal content'),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(DragHandle), findsNothing);
    });
  });
}
