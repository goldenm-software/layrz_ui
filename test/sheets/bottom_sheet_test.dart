import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzBottomSheet', () {
    testWidgets('shows sheet and can be dismissed', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                builder: (context) => const SizedBox(height: 200, child: Text('body')),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
      expect(find.text('body'), findsOneWidget);

      // Dismiss via barrier tap — a point visibly above the sheet's own content.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('body'), findsNothing, reason: 'barrier tap must dismiss the sheet');
    });

    testWidgets('accepts persistent mode without error', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                isPersistent: true,
                builder: (context) => const SizedBox(height: 200),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
    });

    testWidgets('respects custom snapSizes parameter', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                snapSizes: [0.3, 0.6, 0.9],
                builder: (context) => const SizedBox(height: 200),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
    });

    testWidgets('respects custom initialSize parameter', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                initialSize: 0.75,
                builder: (context) => const SizedBox(height: 200),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
    });

    testWidgets('respects custom minSize and maxSize', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                minSize: 0.1,
                maxSize: 0.95,
                builder: (context) => const SizedBox(height: 200),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
    });

    testWidgets('respects showDragHandle false', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                showDragHandle: false,
                builder: (context) => const SizedBox(height: 200),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
    });

    testWidgets('accepts useRootNavigator parameter', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                useRootNavigator: false,
                builder: (context) => const SizedBox(height: 200),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
    });

    testWidgets('uses default snapSizes [0.5, 0.95]', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                builder: (context) => const SizedBox(height: 200),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
    });

    testWidgets('validates snapSizes within minSize/maxSize bounds', (WidgetTester tester) async {
      await pumpThemedApp(tester, const SizedBox());

      expect(
        () {
          LayrzBottomSheet.show<String>(
            tester.element(find.byType(SizedBox).first),
            minSize: 0.25,
            maxSize: 0.95,
            snapSizes: [0.1, 0.9],
            builder: (context) => const SizedBox(),
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('validates snapSizes are in ascending order', (WidgetTester tester) async {
      await pumpThemedApp(tester, const SizedBox());

      expect(
        () {
          LayrzBottomSheet.show<String>(
            tester.element(find.byType(SizedBox).first),
            snapSizes: [0.8, 0.5],
            builder: (context) => const SizedBox(),
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('validates initialSize within minSize/maxSize bounds', (WidgetTester tester) async {
      await pumpThemedApp(tester, const SizedBox());

      expect(
        () {
          LayrzBottomSheet.show<String>(
            tester.element(find.byType(SizedBox).first),
            minSize: 0.3,
            maxSize: 0.8,
            initialSize: 0.9,
            builder: (context) => const SizedBox(),
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('pops with result without re-entrant assertion', (WidgetTester tester) async {
      String? result;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () async {
              result = await LayrzBottomSheet.show<String>(
                context,
                builder: (context) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context, 'test-result');
                  },
                  child: const SizedBox(
                    height: 200,
                    child: Text('Dismiss'),
                  ),
                ),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Pop the sheet with a result via direct Navigator.pop
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      // Verify the result was returned without any assertion errors
      expect(result, equals('test-result'));
    });

    testWidgets('sheet surface does not span the full viewport height', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                builder: (context) => const SizedBox(height: 200, child: Text('body')),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();

      // The decorated sheet surface — identified by the drop shadow only it carries
      // (the drag handle pill is also a DecoratedBox, via Container's borderRadius, but
      // has no boxShadow) — must be sized to the sheet's own extent, not to the full
      // viewport it used to paint across when it decorated DraggableScrollableSheet's
      // own SizedBox.expand.
      final surface = find.byWidgetPredicate(
        (widget) => widget is DecoratedBox && (widget.decoration as BoxDecoration).boxShadow != null,
      );
      expect(
        tester.getSize(surface).height,
        lessThan(800.0),
        reason: 'sheet surface must not span the full viewport height',
      );
    });

    testWidgets('dragging the handle upward grows the sheet', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                builder: (context) => const SizedBox(height: 200, child: Text('body')),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();

      final handle = find.byWidgetPredicate(
        (widget) => widget is Container && widget.constraints?.maxWidth == 40 && widget.constraints?.maxHeight == 4,
      );

      final before = tester.getRect(find.text('body')).top;
      await tester.drag(handle, const Offset(0, -250));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.text('body')).top,
        lessThan(before),
        reason: 'handle drag upward must grow the sheet',
      );
    });

    testWidgets('dragging the handle upward grows the sheet even when its content is scrollable', (
      WidgetTester tester,
    ) async {
      // Covers the plan's highest-risk scenario: the handle's own drag region and the
      // content's scrollable sit in the same subtree and could compete in the gesture
      // arena. This must pass with a genuinely scrollable, over-long content — not just
      // the short, non-scrolling content the sibling test above uses — or a handle
      // implementation that only works when content happens not to scroll would slip
      // through undetected.
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                scrollable: false,
                builder: (context) => ListView.builder(
                  itemCount: 50,
                  itemBuilder: (context, index) => SizedBox(height: 40, child: Text('Item $index')),
                ),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();

      final handle = find.byWidgetPredicate(
        (widget) => widget is Container && widget.constraints?.maxWidth == 40 && widget.constraints?.maxHeight == 4,
      );

      final before = tester.getRect(find.text('Item 0')).top;
      await tester.drag(handle, const Offset(0, -250));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.text('Item 0')).top,
        lessThan(before),
        reason: 'handle drag upward must grow the sheet even when its content is independently scrollable',
      );
      // The handle occupies its own header region, spatially separate from the
      // content below it, so dragging it must not also move the list's own scroll
      // offset — Item 0 must still be the first visible item, not scrolled away.
      expect(find.text('Item 0'), findsOneWidget, reason: 'handle drag must not scroll the content underneath it');
    });

    testWidgets('dragging the handle down past the low snap point dismisses the sheet', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                builder: (context) => const SizedBox(height: 200, child: Text('body')),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
      expect(find.text('body'), findsOneWidget);

      final handle = find.byWidgetPredicate(
        (widget) => widget is Container && widget.constraints?.maxWidth == 40 && widget.constraints?.maxHeight == 4,
      );

      // The default snap points are [0.5, 0.95] with minSize 0.25. Dragging well past
      // the low end (past the 0.5 snap point, toward the 0.25 floor) must dismiss the
      // sheet on release — dismissal falls out of a continuous drag, it is not a
      // separate gesture.
      await tester.drag(handle, const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(
        find.text('body'),
        findsNothing,
        reason: 'dragging the handle past the low snap point must dismiss the sheet',
      );
    });

    testWidgets('scrollable: false lets the caller provide its own scrolling ListView', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                scrollable: false,
                builder: (context) => ListView.builder(
                  itemCount: 50,
                  itemBuilder: (context, index) => SizedBox(height: 40, child: Text('Item $index')),
                ),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();

      // The frame must complete with no unbounded-height assertion — the defect this
      // flag exists to prevent is a ListView nested inside the sheet's own
      // SingleChildScrollView, which throws "Vertical viewport was given unbounded height".
      expect(tester.takeException(), isNull);
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 49'), findsNothing);

      // And the list actually scrolls, using the sheet's own scrollController handed
      // down via PrimaryScrollController — not merely renders once.
      //
      // This must be driven as many small increments rather than one `tester.drag`
      // call: DraggableScrollableSheet's resize/scroll handoff (`applyUserOffset` in
      // the SDK's `_DraggableScrollableSheetScrollPosition`) decides per-call whether
      // a delta resizes the sheet or scrolls its content — it does not split a single
      // large delta across both. `tester.drag` delivers its whole offset in essentially
      // one giant `moveBy` (after an initial touch-slop nudge), so the entire gesture
      // would be consumed growing the sheet to `maxSize`, discarding the remainder and
      // leaving the list unscrolled — that mirrors a real finger's continuous stream of
      // small deltas, which is what actually exercises the handoff.
      final gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
      for (var i = 0; i < 40; i++) {
        await gesture.moveBy(const Offset(0, -75));
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Item 0'), findsNothing);
      expect(find.text('Item 49'), findsOneWidget, reason: 'scrollable: false must produce a working, scrolling frame');
    });

    testWidgets('wraps the sheet content in a ClipRRect matching the decoration radii', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                builder: (context) => const SizedBox(height: 200, child: Text('body')),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();

      // Same predicate the "does not span the full viewport" test above uses to find the
      // sheet's own decorated surface — the DecoratedBox carrying the boxShadow (the drag
      // handle's pill is also a DecoratedBox, via Container's borderRadius, but has none).
      final decoratedBox = tester.widget<DecoratedBox>(
        find.byWidgetPredicate(
          (widget) => widget is DecoratedBox && (widget.decoration as BoxDecoration).boxShadow != null,
        ),
      );

      // The decoration's child must be a ClipRRect, not the content Column directly — this
      // is the structural fix: without it, content taller than the visible area is not
      // clipped to the sheet's rounded top edge and bleeds past it with square corners.
      expect(
        decoratedBox.child,
        isA<ClipRRect>(),
        reason: 'the DecoratedBox must clip its child to the sheet\'s rounded corners',
      );

      final clipRRect = decoratedBox.child! as ClipRRect;
      final decoration = decoratedBox.decoration as BoxDecoration;

      // The clip's radii must be read from the same source as the decoration's, not a
      // separately hardcoded value, or the two can silently drift apart.
      expect(
        clipRRect.borderRadius,
        equals(decoration.borderRadius),
        reason: 'the ClipRRect radii must match the decoration\'s radii exactly',
      );

      expect(
        clipRRect.child,
        isA<Column>(),
        reason: 'the ClipRRect must sit directly between the decoration and the content Column',
      );
    });

    testWidgets(
      'clips content taller than the sheet to the rounded top corners',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // A saturated color unlikely to already appear anywhere in the theme (surface,
        // barrier scrim, drag handle) or the marker would be indistinguishable from its
        // surroundings.
        const markerColor = Color(0xFFFF00FF);

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                LayrzBottomSheet.show<String>(
                  context,
                  // Drag handle hidden so the content's top edge coincides exactly with
                  // the decorated surface's top edge — otherwise the drag handle's own
                  // (transparent) header row would sit over the rounded corners instead,
                  // and the defect this test targets would never reach them.
                  showDragHandle: false,
                  builder: (context) => Container(height: 2000, color: markerColor),
                );
              },
              child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
            ),
          ),
        );

        await tester.tap(find.text('Tap'));
        await tester.pumpAndSettle();

        final surfaceFinder = find.byWidgetPredicate(
          (widget) => widget is DecoratedBox && (widget.decoration as BoxDecoration).boxShadow != null,
        );
        final topLeft = tester.getTopLeft(surfaceFinder);

        late ui.Image image;
        late ByteData bytes;
        await tester.runAsync(() async {
          image = await captureImage(tester.element(surfaceFinder));
          bytes = (await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!;
        });
        addTearDown(image.dispose);

        Color pixelAt(Offset logical) {
          // [captureImage] rasterizes via [OffsetLayer.toImage] with the default
          // pixelRatio of 1.0, which is independent of [FlutterView.devicePixelRatio] —
          // the resulting image is 1:1 with logical pixels, so no scaling is applied here.
          final x = logical.dx.round();
          final y = logical.dy.round();
          final offset = (x + y * image.width) * 4;
          return Color.fromARGB(
            bytes.getUint8(offset + 3),
            bytes.getUint8(offset + 0),
            bytes.getUint8(offset + 1),
            bytes.getUint8(offset + 2),
          );
        }

        // Just inside the decorated surface's bounding box, but outside the rounded
        // corner's arc — the region the decoration itself never paints into, and which
        // must stay clipped away from the (opaque, taller-than-the-sheet) content. Before
        // the fix, the content's square corner bleeds through here with the marker color.
        final cornerPoint = topLeft + const Offset(2, 2);
        expect(
          pixelAt(cornerPoint),
          isNot(equals(markerColor)),
          reason: 'content must be clipped to the rounded top corner, not bleed past it',
        );

        // Sanity check: well inside the sheet, past the corner radius, the marker color
        // must still be visible — proving the corner assertion above is measuring a real
        // clip and not simply an absent or mispositioned widget.
        final insidePoint = topLeft + const Offset(30, 30);
        expect(
          pixelAt(insidePoint),
          equals(markerColor),
          reason: 'the marker content must still paint inside the sheet, away from the corner',
        );
      },
      skip: !canCaptureImage,
    );
  });
}
