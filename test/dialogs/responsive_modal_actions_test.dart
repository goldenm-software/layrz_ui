import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/find_button_label.dart';
import '../helpers/no_overflow.dart';
import '../helpers/pump_themed_app.dart';

/// Finds the drag handle's visible pill, matching the predicate already used
/// in test/sheets/bottom_sheet_double_pop_test.dart's and
/// test/sheets/bottom_sheet_dismissal_gate_test.dart's own `findDragHandle` --
/// duplicated here rather than imported since those helpers are private to
/// their own libraries.
Finder findDragHandle() {
  return find.byWidgetPredicate(
    (widget) => widget is Container && widget.constraints?.maxWidth == 40 && widget.constraints?.maxHeight == 4,
  );
}

/// Sets the test binding's viewport to [width]x[height] at a fixed 1.0 device
/// pixel ratio, and registers a [WidgetTester.addTearDown] to restore the
/// original view afterward -- matching the reset pattern used by
/// test/dialogs/responsive_modal_test.dart so a left-over override can never
/// leak into a later test.
void setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// A wide viewport, comfortably above the 960px compact/wide breakpoint, so
/// [LayrzResponsiveModal.show] resolves to the dialog branch.
const _wideViewport = Size(1600, 1200);

/// A narrow viewport, comfortably below the 960px compact/wide breakpoint, so
/// [LayrzResponsiveModal.show] resolves to the sheet branch.
const _narrowViewport = Size(400, 800);

void main() {
  group('LayrzResponsiveModal.show actions -- null/empty rendering (both branches)', () {
    guardedTestWidgets('a null actions list renders no action row on the dialog branch', (tester) async {
      setViewport(tester, _wideViewport);

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
      expect(findButtonLabel('Confirm'), findsNothing);
    });

    guardedTestWidgets('an empty actions list renders no action row on the dialog branch', (tester) async {
      setViewport(tester, _wideViewport);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                actions: const [],
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
      expect(findButtonLabel('Confirm'), findsNothing);
    });

    guardedTestWidgets('a null actions list renders no action row on the sheet branch', (tester) async {
      setViewport(tester, _narrowViewport);

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
      expect(findButtonLabel('Confirm'), findsNothing);
    });

    guardedTestWidgets('an empty actions list renders no action row on the sheet branch', (tester) async {
      setViewport(tester, _narrowViewport);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                actions: const [],
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
      expect(findButtonLabel('Confirm'), findsNothing);
    });
  });

  group('LayrzResponsiveModal.show actions -- rendered on the dialog branch', () {
    guardedTestWidgets('actions render below the builder content, right-aligned, at a wide viewport', (
      tester,
    ) async {
      setViewport(tester, _wideViewport);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                builder: (context) => const SizedBox(height: 60, child: Text('Modal content')),
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

      expect(find.text('Modal content'), findsOneWidget);
      expect(findButtonLabel('Cancel'), findsOneWidget);
      expect(findButtonLabel('Confirm'), findsOneWidget);

      // Also asserts the "other form absent" direction for the compact branching:
      // a dialog-branch presentation must show no DraggableScrollableSheet at all.
      expect(find.byType(DraggableScrollableSheet), findsNothing);

      final contentBottom = tester.getBottomLeft(find.text('Modal content')).dy;
      final cancelTop = tester.getTopLeft(findButtonLabel('Cancel')).dy;
      final confirmTop = tester.getTopLeft(findButtonLabel('Confirm')).dy;

      expect(cancelTop, greaterThanOrEqualTo(contentBottom), reason: 'actions must render below the content');
      expect(confirmTop, greaterThanOrEqualTo(contentBottom), reason: 'actions must render below the content');

      final cancelLeft = tester.getTopLeft(findButtonLabel('Cancel')).dx;
      final confirmLeft = tester.getTopLeft(findButtonLabel('Confirm')).dx;
      expect(
        confirmLeft,
        greaterThan(cancelLeft),
        reason: 'actions must be laid out left-to-right in a right-aligned row',
      );
    });

    guardedTestWidgets('actions stay pinned when the dialog branch content is tall enough to scroll', (
      tester,
    ) async {
      setViewport(tester, _wideViewport);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                builder: (context) => ListView(
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
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(findButtonLabel('Confirm'), findsOneWidget);
      final beforeScrollRect = tester.getRect(findButtonLabel('Confirm'));

      // Dragging the ListView content must not move the pinned actions row --
      // proving it is a sibling of the Expanded builder content, not nested
      // inside whatever scrollable the builder itself returns.
      await tester.drag(find.text('Row 0'), const Offset(0, -300));
      await tester.pumpAndSettle();
      final afterScrollRect = tester.getRect(findButtonLabel('Confirm'));

      expect(
        afterScrollRect,
        equals(beforeScrollRect),
        reason: 'the pinned action row must not move when the dialog branch content scrolls',
      );
    });
  });

  group('LayrzResponsiveModal.show actions -- rendered on the sheet branch', () {
    guardedTestWidgets('actions render below the builder content, right-aligned, at a narrow viewport', (
      tester,
    ) async {
      setViewport(tester, _narrowViewport);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                builder: (context) => const SizedBox(height: 60, child: Text('Modal content')),
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

      expect(find.text('Modal content'), findsOneWidget);
      expect(findButtonLabel('Cancel'), findsOneWidget);
      expect(findButtonLabel('Confirm'), findsOneWidget);

      // Also asserts the "other form absent" direction: a sheet-branch
      // presentation must actually use a DraggableScrollableSheet.
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);

      final contentBottom = tester.getBottomLeft(find.text('Modal content')).dy;
      final cancelTop = tester.getTopLeft(findButtonLabel('Cancel')).dy;
      final confirmTop = tester.getTopLeft(findButtonLabel('Confirm')).dy;

      expect(cancelTop, greaterThanOrEqualTo(contentBottom), reason: 'actions must render below the content');
      expect(confirmTop, greaterThanOrEqualTo(contentBottom), reason: 'actions must render below the content');

      final cancelLeft = tester.getTopLeft(findButtonLabel('Cancel')).dx;
      final confirmLeft = tester.getTopLeft(findButtonLabel('Confirm')).dx;
      expect(
        confirmLeft,
        greaterThan(cancelLeft),
        reason: 'actions must be laid out left-to-right in a right-aligned row',
      );
    });

    guardedTestWidgets(
      'actions stay pinned when the sheet branch content is tall enough to scroll (scrollable: true default)',
      (tester) async {
        setViewport(tester, _narrowViewport);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                LayrzResponsiveModal.show<void>(
                  context,
                  sheet: const LayrzBottomSheetConfig(initialSize: 0.5),
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

        expect(findButtonLabel('Confirm'), findsOneWidget);
        expect(
          tester.getRect(findButtonLabel('Confirm')).bottom,
          lessThanOrEqualTo(tester.view.physicalSize.height / tester.view.devicePixelRatio),
          reason: 'the action row must be pinned on-screen, not pushed away by scrollable content',
        );

        final beforeScrollRect = tester.getRect(findButtonLabel('Confirm'));
        await tester.drag(find.text('Row 0'), const Offset(0, -300));
        await tester.pumpAndSettle();
        final afterScrollRect = tester.getRect(findButtonLabel('Confirm'));

        expect(
          afterScrollRect,
          equals(beforeScrollRect),
          reason: 'the pinned action row must not move when the sheet branch content scrolls',
        );
      },
    );

    guardedTestWidgets('actions stay pinned on the sheet branch when scrollable: false', (tester) async {
      setViewport(tester, _narrowViewport);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                sheet: const LayrzBottomSheetConfig(initialSize: 0.5, scrollable: false),
                builder: (context) => ListView(
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

      expect(findButtonLabel('Confirm'), findsOneWidget);
      final beforeScrollRect = tester.getRect(findButtonLabel('Confirm'));

      await tester.drag(find.text('Row 0'), const Offset(0, -300));
      await tester.pumpAndSettle();
      final afterScrollRect = tester.getRect(findButtonLabel('Confirm'));

      expect(
        afterScrollRect,
        equals(beforeScrollRect),
        reason: 'the pinned action row must not move when scrollable: false and the builder supplies its own ListView',
      );
    });
  });

  group('LayrzResponsiveModal.show actions -- isCompact override wins over viewport', () {
    guardedTestWidgets('a narrow viewport paired with isCompact: false still pins actions on the dialog branch', (
      tester,
    ) async {
      // Narrow viewport (would default to the sheet branch), explicitly forced to the
      // dialog branch -- proves the override, not the derived isCompact, decides which
      // branch's pinning behaviour applies.
      setViewport(tester, _narrowViewport);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                isCompact: false,
                builder: (context) => const SizedBox(height: 60, child: Text('Modal content')),
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

      // The dialog branch was forced: no DraggableScrollableSheet, and the
      // action row is still present and pinned below the content.
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(findButtonLabel('Confirm'), findsOneWidget);

      final contentBottom = tester.getBottomLeft(find.text('Modal content')).dy;
      final confirmTop = tester.getTopLeft(findButtonLabel('Confirm')).dy;
      expect(confirmTop, greaterThanOrEqualTo(contentBottom));
    });

    guardedTestWidgets('a wide viewport paired with isCompact: true still pins actions on the sheet branch', (
      tester,
    ) async {
      // Wide viewport (would default to the dialog branch), explicitly forced to the
      // sheet branch.
      setViewport(tester, _wideViewport);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                isCompact: true,
                builder: (context) => const SizedBox(height: 60, child: Text('Modal content')),
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

      // The sheet branch was forced: a DraggableScrollableSheet is present,
      // and the action row is still present and pinned below the content.
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      expect(findButtonLabel('Confirm'), findsOneWidget);

      final contentBottom = tester.getBottomLeft(find.text('Modal content')).dy;
      final confirmTop = tester.getTopLeft(findButtonLabel('Confirm')).dy;
      expect(confirmTop, greaterThanOrEqualTo(contentBottom));
    });
  });

  group('LayrzResponsiveModal.show actions -- dialog branch shrink-wraps to content (DESIGN-164 follow-up)', () {
    guardedTestWidgets('a short-content dialog panel shrink-wraps instead of growing to maxHeight', (tester) async {
      setViewport(tester, _wideViewport);

      const contentHeight = 60.0;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                builder: (context) => const SizedBox(
                  height: contentHeight,
                  child: Text('Modal content'),
                ),
                actions: [
                  LayrzButton(labelText: 'Close', onTap: () {}),
                ],
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Modal content'), findsOneWidget);
      expect(findButtonLabel('Close'), findsOneWidget);

      // The panel's own decoration is the nearest DecoratedBox ancestor of the
      // built content -- dialog.dart's _DialogContent wraps widget.child (here,
      // _DialogBodyWithPinnedActions, which paints no DecoratedBox of its own)
      // directly in the panel's DecoratedBox with no intermediate one between,
      // so this is unambiguous even though LayrzButton/LayrzTappable also paint
      // their own DecoratedBoxes elsewhere in the tree.
      final panelFinder = find.ancestor(
        of: find.text('Modal content'),
        matching: find.byType(DecoratedBox),
      );
      expect(panelFinder, findsOneWidget);
      final panelHeight = tester.getSize(panelFinder).height;

      // This is the maintainer's actual complaint: before the fix, Expanded's
      // tight fit forced the Column (and therefore the panel) to the full
      // LayrzDialogConfig.maxHeight (640) regardless of content. A shrink-wrapped
      // panel must land well under that, and roughly at content + the action row
      // + the fixed paddings/gaps around them, not at the ceiling.
      const maxHeight = 640.0; // LayrzDialogConfig.maxHeight default.
      expect(
        panelHeight,
        lessThan(maxHeight * 0.5),
        reason:
            'a short-content dialog panel must shrink-wrap, not grow to maxHeight ($maxHeight) -- '
            'measured panel height was $panelHeight',
      );

      final closeButtonRect = tester.getRect(findButtonLabel('Close'));
      final contentBottom = tester.getBottomLeft(find.text('Modal content')).dy;

      // The action row sits directly below the content -- no enormous empty
      // gap between them, which is the visual symptom the maintainer reported
      // ("the button stranded at the very bottom" with content up top).
      expect(
        closeButtonRect.top - contentBottom,
        lessThan(100),
        reason:
            'the action row must sit directly below the content, not stranded far below it -- '
            'gap measured was ${closeButtonRect.top - contentBottom}',
      );
    });

    guardedTestWidgets('tall content still caps the dialog panel at maxHeight with actions pinned and scrollable', (
      tester,
    ) async {
      setViewport(tester, _wideViewport);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzResponsiveModal.show<void>(
                context,
                builder: (context) => ListView(
                  children: [
                    for (int i = 0; i < 200; i++) Text('Row $i'),
                  ],
                ),
                actions: [
                  LayrzButton(labelText: 'Close', onTap: () {}),
                ],
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(findButtonLabel('Close'), findsOneWidget);
      expect(find.text('Row 0'), findsOneWidget);

      final panelFinder = find.ancestor(
        of: find.text('Row 0'),
        matching: find.byType(DecoratedBox),
      );
      expect(panelFinder, findsOneWidget);
      final panelHeight = tester.getSize(panelFinder).height;

      const maxHeight = 640.0; // LayrzDialogConfig.maxHeight default.
      expect(
        panelHeight,
        lessThanOrEqualTo(maxHeight),
        reason: 'the dialog panel must cap at maxHeight ($maxHeight) rather than growing to fit 200 rows',
      );
      expect(
        panelHeight,
        greaterThan(maxHeight * 0.5),
        reason: 'with content taller than maxHeight, the panel should still occupy close to the full bound',
      );

      final beforeScrollRect = tester.getRect(findButtonLabel('Close'));
      await tester.drag(find.text('Row 0'), const Offset(0, -300));
      await tester.pumpAndSettle();
      final afterScrollRect = tester.getRect(findButtonLabel('Close'));

      expect(
        afterScrollRect,
        equals(beforeScrollRect),
        reason: 'the pinned action row must not move when tall content scrolls, even at maxHeight',
      );
    });
  });

  group('LayrzResponsiveModal.show actions -- sheet branch sizing (DESIGN-164 follow-up)', () {
    guardedTestWidgets(
      'a short-content sheet still occupies its configured initialSize fraction (draggable sheet contract, not a shrink-wrap regression)',
      (tester) async {
        setViewport(tester, _narrowViewport);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                LayrzResponsiveModal.show<void>(
                  context,
                  sheet: const LayrzBottomSheetConfig(initialSize: 0.5),
                  builder: (context) => const SizedBox(height: 60, child: Text('Modal content')),
                  actions: [
                    LayrzButton(labelText: 'Close', onTap: () {}),
                  ],
                );
              },
              child: const SizedBox(width: 100, height: 100, child: Text('Open')),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Modal content'), findsOneWidget);
        expect(findButtonLabel('Close'), findsOneWidget);

        // DraggableScrollableSheet itself always expands to fill the viewport
        // (SizedBox.expand) -- the actual visible sheet surface is the
        // DecoratedBox built inside its own `builder`, sized by a
        // FractionallySizedBox to initialChildSize (see bottom_sheet.dart's
        // own comment on this). That surface is, by design, a "sheet occupies
        // a fraction of the viewport" shape -- unlike LayrzDialog, it is never
        // meant to shrink-wrap to content regardless of how little the
        // builder returns, because the whole point of a draggable sheet is a
        // fixed, draggable occupied fraction. This asserts that contract
        // still holds (no regression), not the dialog's shrink-wrap
        // behaviour.
        final sheetSurfaceFinder = find.ancestor(
          of: find.text('Modal content'),
          matching: find.byType(DecoratedBox),
        );
        expect(sheetSurfaceFinder, findsOneWidget);
        final sheetHeight = tester.getSize(sheetSurfaceFinder).height;
        final viewportHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;

        expect(
          sheetHeight,
          closeTo(viewportHeight * 0.5, 1.0),
          reason: 'a sheet with initialSize: 0.5 and short content must still occupy half the viewport height',
        );

        final closeButtonRect = tester.getRect(findButtonLabel('Close'));
        expect(
          closeButtonRect.bottom,
          lessThanOrEqualTo(viewportHeight),
          reason: 'the pinned action row must stay on-screen within the sheet',
        );
      },
    );
  });

  group('LayrzResponsiveModal.show actions -- an action can dismiss the modal', () {
    guardedTestWidgets('tapping an action pops the dialog branch with its value', (tester) async {
      setViewport(tester, _wideViewport);
      String? result;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () async {
              result = await LayrzResponsiveModal.show<String>(
                context,
                builder: (context) => const Text('Modal content'),
                actions: [
                  LayrzButton(
                    labelText: 'Confirm',
                    onTap: () => Navigator.of(context, rootNavigator: true).pop('confirmed'),
                  ),
                ],
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Confirm'));
      await tester.pumpAndSettle();

      expect(result, 'confirmed');
    });

    guardedTestWidgets('tapping an action pops the sheet branch with its value', (tester) async {
      setViewport(tester, _narrowViewport);
      String? result;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () async {
              result = await LayrzResponsiveModal.show<String>(
                context,
                builder: (context) => const Text('Modal content'),
                actions: [
                  LayrzButton(
                    labelText: 'Confirm',
                    onTap: () => Navigator.of(context, rootNavigator: true).pop('confirmed'),
                  ),
                ],
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Confirm'));
      await tester.pumpAndSettle();

      expect(result, 'confirmed');
    });
  });

  group('LayrzResponsiveModal.show canDismiss -- infers from actions (DESIGN-164 follow-up)', () {
    guardedTestWidgets(
      'dialog branch: actions present + canDismiss unset => barrier tap does not dismiss',
      (tester) async {
        setViewport(tester, _wideViewport);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                LayrzResponsiveModal.show<void>(
                  context,
                  builder: (context) => const Text('Modal content'),
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
        expect(find.text('Modal content'), findsOneWidget);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(
          find.text('Modal content'),
          findsOneWidget,
          reason: 'a dialog carrying actions must not be dismissed by a barrier tap when canDismiss is unset',
        );
      },
    );

    guardedTestWidgets(
      'sheet branch: actions present + canDismiss unset => barrier tap does not dismiss',
      (tester) async {
        setViewport(tester, _narrowViewport);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                LayrzResponsiveModal.show<void>(
                  context,
                  builder: (context) => const Text('Modal content'),
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
        expect(find.text('Modal content'), findsOneWidget);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(
          find.text('Modal content'),
          findsOneWidget,
          reason: 'a sheet carrying actions must not be dismissed by a barrier tap when canDismiss is unset',
        );
      },
    );

    guardedTestWidgets(
      'sheet branch: actions present + canDismiss unset => drag-to-dismiss does not dismiss',
      (tester) async {
        setViewport(tester, _narrowViewport);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                LayrzResponsiveModal.show<void>(
                  context,
                  builder: (context) => const Text('Modal content'),
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
        expect(find.text('Modal content'), findsOneWidget);

        final handle = findDragHandle();
        expect(handle, findsOneWidget, reason: 'the drag handle must still render even when non-dismissible');
        await tester.drag(handle, const Offset(0, 300));
        await tester.pumpAndSettle();

        expect(
          find.text('Modal content'),
          findsOneWidget,
          reason: 'a sheet carrying actions must not be draggable away when canDismiss is unset',
        );
      },
    );

    guardedTestWidgets(
      'dialog branch: canDismiss: true + actions present => barrier tap DOES dismiss (explicit override wins)',
      (tester) async {
        setViewport(tester, _wideViewport);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                LayrzResponsiveModal.show<void>(
                  context,
                  canDismiss: true,
                  builder: (context) => const Text('Modal content'),
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
        expect(find.text('Modal content'), findsOneWidget);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(
          find.text('Modal content'),
          findsNothing,
          reason: 'canDismiss: true must win over the actions-present inference, on the dialog branch',
        );
      },
    );

    guardedTestWidgets(
      'sheet branch: canDismiss: true + actions present => barrier tap DOES dismiss (explicit override wins)',
      (tester) async {
        setViewport(tester, _narrowViewport);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                LayrzResponsiveModal.show<void>(
                  context,
                  canDismiss: true,
                  builder: (context) => const Text('Modal content'),
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
        expect(find.text('Modal content'), findsOneWidget);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(
          find.text('Modal content'),
          findsNothing,
          reason: 'canDismiss: true must win over the actions-present inference, on the sheet branch',
        );
      },
    );

    guardedTestWidgets(
      'dialog branch: canDismiss: false + no actions => barrier tap does NOT dismiss (explicit override wins)',
      (tester) async {
        setViewport(tester, _wideViewport);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                LayrzResponsiveModal.show<void>(
                  context,
                  canDismiss: false,
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

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(
          find.text('Modal content'),
          findsOneWidget,
          reason: 'canDismiss: false must win over the no-actions inference, on the dialog branch',
        );
      },
    );

    guardedTestWidgets(
      'sheet branch: canDismiss: false + no actions => barrier tap does NOT dismiss (explicit override wins)',
      (tester) async {
        setViewport(tester, _narrowViewport);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                LayrzResponsiveModal.show<void>(
                  context,
                  canDismiss: false,
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

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(
          find.text('Modal content'),
          findsOneWidget,
          reason: 'canDismiss: false must win over the no-actions inference, on the sheet branch',
        );
      },
    );

    guardedTestWidgets(
      'dialog branch: empty actions list + canDismiss unset => IS dismissable (no buttons to answer with)',
      (tester) async {
        setViewport(tester, _wideViewport);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                LayrzResponsiveModal.show<void>(
                  context,
                  actions: const [],
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

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(
          find.text('Modal content'),
          findsNothing,
          reason: 'an empty actions list has nothing to answer with, so it must not lock the dialog in',
        );
      },
    );

    guardedTestWidgets(
      'sheet branch: empty actions list + canDismiss unset => IS dismissable (no buttons to answer with)',
      (tester) async {
        setViewport(tester, _narrowViewport);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                LayrzResponsiveModal.show<void>(
                  context,
                  actions: const [],
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

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(
          find.text('Modal content'),
          findsNothing,
          reason: 'an empty actions list has nothing to answer with, so it must not lock the sheet in',
        );
      },
    );
  });
}
