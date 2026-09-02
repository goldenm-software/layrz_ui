import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/find_button_label.dart';
import '../helpers/no_overflow.dart';
import '../helpers/pump_themed_app.dart';

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
}
