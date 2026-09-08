import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';
import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzContextMenu — trigger and dismissal', () {
    testWidgets('opens on secondary tap (right-click) at a wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzContextMenu(
          entries: const [
            LayrzContextMenuEntry(labelText: 'Copy', onTap: _noop),
          ],
          child: const SizedBox(width: 200, height: 100, child: Text('Target')),
        ),
      );

      expect(find.text('Copy'), findsNothing);

      await tester.tap(
        find.text('Target'),
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('opens on long press at a compact/touch viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzContextMenu(
          entries: const [
            LayrzContextMenuEntry(labelText: 'Share', onTap: _noop),
          ],
          child: const SizedBox(width: 150, height: 80, child: Text('Target')),
        ),
      );

      expect(find.text('Share'), findsNothing);

      await tester.longPress(find.text('Target'));
      await tester.pumpAndSettle();

      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('panel is anchored near the pointer location, not centered on the child', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzContextMenu(
          entries: const [
            LayrzContextMenuEntry(labelText: 'Copy', onTap: _noop),
          ],
          child: const SizedBox(width: 400, height: 300, child: ColoredBox(color: Color(0xFFEEEEEE))),
        ),
      );

      // Right-click near the top-left corner of the (centered) child rather
      // than its center.
      final childTopLeft = tester.getTopLeft(find.byType(ColoredBox));
      final clickPoint = childTopLeft + const Offset(10, 10);

      final gesture = await tester.startGesture(
        clickPoint,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await gesture.up();
      await tester.pumpAndSettle();

      final panelTopLeft = tester.getTopLeft(find.text('Copy').hitTestable());

      // The panel's own top-left corner should land close to the pointer,
      // not at the child's (much farther-away) center.
      expect((panelTopLeft - clickPoint).distance, lessThan(60.0));
    });

    testWidgets('panel width is clamped to kLayrzDropdownMenuMaxWidth, not full-viewport', (tester) async {
      // Regression test for the width bug: the panel used to stretch to
      // (nearly) the full overlay width. At a wide 1600px viewport, the
      // rendered panel must stay within the same width band
      // `LayrzDropdownMenu` uses, never anywhere close to full-viewport.
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzContextMenu(
          entries: const [
            LayrzContextMenuEntry(labelText: 'Copy', onTap: _noop),
            LayrzContextMenuEntry(labelText: 'Paste', onTap: _noop),
          ],
          child: const SizedBox(width: 200, height: 100, child: Text('Target')),
        ),
      );

      await tester.tap(
        find.text('Target'),
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      expect(find.text('Copy'), findsOneWidget);

      final panelSize = tester.getSize(
        find.ancestor(
          of: find.text('Copy'),
          matching: find.byType(ClipRRect),
        ),
      );

      expect(panelSize.width, lessThanOrEqualTo(kLayrzDropdownMenuMaxWidth));
    });

    testWidgets('dismisses on outside tap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Outside-tap dismissal is implemented via a `TapRegion`, which only
      // detects taps through a `TapRegionSurface` ancestor — provided by a
      // real `WidgetsApp`/`LayrzApp`, not by the minimal `pumpThemed` tree.
      // See `pumpThemedApp`'s own doc comment.
      await pumpThemedApp(
        tester,
        LayrzContextMenu(
          entries: const [
            LayrzContextMenuEntry(labelText: 'Copy', onTap: _noop),
          ],
          child: const SizedBox(width: 200, height: 100, child: Text('Target')),
        ),
      );

      await tester.tap(
        find.text('Target'),
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(find.text('Copy'), findsOneWidget);

      // Tap far away from both the child and the panel.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Copy'), findsNothing);
    });

    testWidgets('an entry onTap fires and the menu closes', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var tapCount = 0;

      await pumpThemed(
        tester,
        LayrzContextMenu(
          entries: [
            LayrzContextMenuEntry(labelText: 'Copy', onTap: () => tapCount++),
          ],
          child: const SizedBox(width: 200, height: 100, child: Text('Target')),
        ),
      );

      await tester.tap(
        find.text('Target'),
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(find.text('Copy'), findsOneWidget);

      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();

      expect(tapCount, 1);
      expect(find.text('Copy'), findsNothing);
    });

    testWidgets('a disabled entry does not fire onTap and stays visible', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var tapCount = 0;

      await pumpThemed(
        tester,
        LayrzContextMenu(
          entries: [
            LayrzContextMenuEntry(labelText: 'Delete', onTap: () => tapCount++, enabled: false),
          ],
          child: const SizedBox(width: 200, height: 100, child: Text('Target')),
        ),
      );

      await tester.tap(
        find.text('Target'),
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(tapCount, 0);
      // Menu stays open — a disabled entry never closes it.
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('LayrzContextMenuDivider renders as a thin separator', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzContextMenu(
          entries: const [
            LayrzContextMenuEntry(labelText: 'Copy', onTap: _noop),
            LayrzContextMenuDivider(),
            LayrzContextMenuEntry(labelText: 'Paste', onTap: _noop),
          ],
          child: const SizedBox(width: 200, height: 100, child: Text('Target')),
        ),
      );

      await tester.tap(
        find.text('Target'),
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      final dividerFinder = find.byWidgetPredicate(
        (widget) => widget is Container && widget.constraints?.maxHeight == 1,
      );
      // Fall back to a direct height-1 Container search compatible with the
      // divider's construction (Container(height: 1, color: ...)).
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      expect(dividerFinder, findsWidgets);
    });

    testWidgets('LayrzContextMenuLabel renders non-interactively', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzContextMenu(
          entries: const [
            LayrzContextMenuLabel(labelText: 'Actions'),
            LayrzContextMenuEntry(labelText: 'Copy', onTap: _noop),
          ],
          child: const SizedBox(width: 200, height: 100, child: Text('Target')),
        ),
      );

      await tester.tap(
        find.text('Target'),
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      expect(find.text('Actions'), findsOneWidget);

      // Tapping the label text must not throw and must not close the menu
      // (it has no GestureDetector of its own to hit).
      await tester.tap(find.text('Actions'), warnIfMissed: false);
      await tester.pump();
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('renders bare child when there is no Overlay ancestor', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: LayrzContextMenu(
            entries: const [
              LayrzContextMenuEntry(labelText: 'Copy', onTap: _noop),
            ],
            child: const Text('Target'),
          ),
        ),
      );

      expect(find.text('Target'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('LayrzContextMenu — accessibility', () {
    testWidgets('menu semantics are present only while the menu is open', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzContextMenu(
            entries: const [
              LayrzContextMenuEntry(labelText: 'Copy', onTap: _noop),
            ],
            child: const SizedBox(width: 200, height: 100, child: Text('Target')),
          ),
        );

        // Closed: no entry semantics in the tree.
        expect(find.bySemanticsLabel('Copy'), findsNothing);

        await tester.tap(
          find.text('Target'),
          buttons: kSecondaryMouseButton,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();

        // Open: the entry exposes button semantics with the label text.
        expect(
          tester.getSemantics(find.text('Copy')),
          matchesSemantics(
            label: 'Copy',
            isButton: true,
            hasTapAction: true,
            isFocusable: true,
            hasFocusAction: true,
            hasEnabledState: true,
            isEnabled: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('a disabled entry exposes disabled button semantics', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzContextMenu(
            entries: const [
              LayrzContextMenuEntry(labelText: 'Delete', onTap: _noop, enabled: false),
            ],
            child: const SizedBox(width: 200, height: 100, child: Text('Target')),
          ),
        );

        await tester.tap(
          find.text('Target'),
          buttons: kSecondaryMouseButton,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();

        expect(
          tester.getSemantics(find.text('Delete')),
          matchesSemantics(
            label: 'Delete',
            isButton: true,
            hasTapAction: false,
            hasEnabledState: true,
            isEnabled: false,
          ),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}

void _noop() {}
