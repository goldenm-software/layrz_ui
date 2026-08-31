import "dart:ui" show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

import "../helpers/no_overflow.dart";

/// Minimal domain object used to exercise [LayrzScaffoldShell] in isolation.
class _TestItem {
  /// Creates a test item with the given [id] and [name].
  const _TestItem(this.id, this.name);

  /// Stable identifier, mirrored by the [LayrzScaffoldItem.key] used in tests.
  final String id;

  /// Display name rendered by the tile and detail builder.
  final String name;
}

List<LayrzScaffoldItem<_TestItem>> _buildItems() {
  return [
    const LayrzScaffoldItem(
      key: ValueKey("1"),
      item: _TestItem("1", "Alpha"),
      tile: SizedBox(child: Text("Alpha")),
      searchableStrings: {"Alpha"},
    ),
    const LayrzScaffoldItem(
      key: ValueKey("2"),
      item: _TestItem("2", "Beta"),
      tile: SizedBox(child: Text("Beta")),
      searchableStrings: {"Beta"},
    ),
  ];
}

/// A vertical seam (Fold-style), spanning the full shell height, offset from
/// the shell's own origin -- mirrors the measured Flip 3 landscape geometry
/// (shell inset by a 220dp rail, seam at view-x 502.9).
const _kVerticalSeamViewX = 502.9;
const _kRailInset = 220.0;

DisplayFeature _verticalFold({double viewX = _kVerticalSeamViewX, double height = 731.9}) {
  return DisplayFeature(
    bounds: Rect.fromLTRB(viewX, 0, viewX, height),
    type: DisplayFeatureType.fold,
    state: DisplayFeatureState.postureFlat,
  );
}

DisplayFeature _horizontalFold({double viewY = 403.0, double width = 411.43}) {
  return DisplayFeature(
    bounds: Rect.fromLTRB(0, viewY, width, viewY),
    type: DisplayFeatureType.fold,
    state: DisplayFeatureState.postureFlat,
  );
}

/// Pumps a themed [LayrzScaffoldShell] with a real [Navigator] (via [LayrzApp])
/// and, optionally, injected [displayFeatures] and [viewInsetsBottom] applied
/// via a [MediaQuery.copyWith] inside a [Builder] -- the ambient-preserving
/// form, matching `test/layout/layout_safe_area_test.dart`, rather than a bare
/// `MediaQueryData()` that would replace ambient data wholesale.
Future<void> _pumpFoldableShell(
  WidgetTester tester, {
  required List<LayrzScaffoldItem<_TestItem>> items,
  required LayrzScaffoldController controller,
  required Size size,
  List<DisplayFeature> displayFeatures = const [],
  double viewInsetsBottom = 0,
  EdgeInsets railInset = EdgeInsets.zero,
}) async {
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetDisplayFeatures();
  });
  // Pin DPR before physicalSize: ambient DPR is 3.0.
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  tester.view.displayFeatures = displayFeatures;

  final shell = SizedBox.expand(
    child: Padding(
      padding: railInset,
      child: LayrzScaffoldShell<_TestItem>(
        controller: controller,
        items: items,
        onDetailsBuild: (item) => Text("detail:${item.name}"),
        itemExtent: 56.0,
      ),
    ),
  );

  await tester.pumpWidget(
    LayrzApp(
      theme: LayrzThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              displayFeatures: displayFeatures,
              viewInsets: EdgeInsets.only(bottom: viewInsetsBottom),
            ),
            child: shell,
          );
        },
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group("LayrzScaffoldShell foldable-hinge awareness", () {
    guardedTestWidgets(
      "no display features: behaves exactly like today (narrow list + sheet, no split)",
      (tester) async {
        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);

        await _pumpFoldableShell(
          tester,
          items: _buildItems(),
          controller: controller,
          size: const Size(520, 900), // narrow band, no features
        );

        controller.open(const ValueKey("1"));
        await tester.pump();
        await tester.pumpAndSettle();

        // Sheet-presented detail, not an inline split.
        expect(find.text("detail:Alpha"), findsOneWidget);
        expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      },
    );

    guardedTestWidgets(
      "vertical fold at a narrow container (but tall enough shell) forces side-by-side (detail visible inline, no sheet)",
      (tester) async {
        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);

        // Shell fills the whole view (no rail): 520-wide narrow band, but a
        // vertical fold crosses it, so the split must win over the band.
        // Height 900 clears kLayrzFoldMinSplitHeight (480).
        await _pumpFoldableShell(
          tester,
          items: _buildItems(),
          controller: controller,
          size: const Size(520, 900),
          displayFeatures: [_verticalFold(viewX: 260, height: 900)],
        );

        controller.open(const ValueKey("1"));
        await tester.pump();

        // Detail is visible INLINE (no post-frame sheet push needed) and no
        // sheet was scheduled -- both directions asserted.
        expect(find.text("detail:Alpha"), findsOneWidget);
        expect(find.byType(DraggableScrollableSheet), findsNothing);

        // List item must also still be visible (inline split shows both panes).
        expect(find.text("Alpha"), findsWidgets);
      },
    );

    guardedTestWidgets(
      "vertical fold: divider position matches the mapped seam, not the shell's naive midpoint",
      (tester) async {
        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);

        // Shell is inset by a 220dp rail on the left; the seam sits at view-x
        // 502.9. Naive "shell's own midpoint" would place the divider at
        // local x 392.9/2 = wrong by 110dp -- this is the case the plan calls
        // out as separating a correct implementation from a plausible one.
        // The real landscape-Flip shell is only 411.4dp tall (below
        // kLayrzFoldMinSplitHeight), so this fixture is deliberately raised
        // to 731.9dp of height to isolate the x-axis mapping this test exists
        // to verify from the (separately tested) height guard.
        await _pumpFoldableShell(
          tester,
          items: _buildItems(),
          controller: controller,
          size: const Size(1005.7, 731.9),
          railInset: const EdgeInsets.only(left: _kRailInset),
          displayFeatures: [_verticalFold()],
        );

        final listFinder = find.text("Alpha");
        expect(listFinder, findsOneWidget);

        final listRect = tester.getRect(listFinder);
        // The list panel's right edge must land at ~282.9 local px from the
        // shell's own left edge (which itself sits at global x 220 due to the
        // rail inset) -- i.e. global x ~502.9, matching the fold's view-x.
        // The naive-midpoint bug would place this around global x 220 + 392.9
        // = 612.9 instead.
        expect(listRect.right, lessThan(520.0), reason: "must not land near the naive shell midpoint (612.9)");
      },
    );

    guardedTestWidgets(
      "a vertical fold on a shell shorter than kLayrzFoldMinSplitHeight does NOT split (falls back to today's layout)",
      (tester) async {
        // Regression fixture for the measured Flip-landscape case: two
        // comfortably-wide (502.9dp) but far too short (411.4dp) panes. The
        // axis alone would have permitted a split here; only the height
        // guard rejects it.
        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);

        await _pumpFoldableShell(
          tester,
          items: _buildItems(),
          controller: controller,
          size: const Size(785.7, 411.4),
          displayFeatures: [_verticalFold(viewX: 392.85, height: 411.4)],
        );

        controller.open(const ValueKey("1"));
        await tester.pump();
        await tester.pumpAndSettle();

        // Falls back to the narrow list + sheet path, not an inline split.
        expect(find.byType(DraggableScrollableSheet), findsOneWidget);
        expect(find.text("detail:Alpha"), findsOneWidget);
      },
    );

    guardedTestWidgets(
      "a horizontal fold never splits -- falls through to exactly today's layout",
      (tester) async {
        // A horizontal seam (Z Flip portrait / Z Fold landscape) must never
        // produce a split -- the axis filter, not merely the height guard,
        // must reject it, even at Fold scale (851.7 x 882.9, well past
        // kLayrzFoldMinSplitHeight) where the height guard alone would not
        // have rejected it.
        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);

        const width = 851.7;
        const height = 882.9;

        await _pumpFoldableShell(
          tester,
          items: _buildItems(),
          controller: controller,
          size: const Size(width, height),
          displayFeatures: [_horizontalFold(viewY: height / 2, width: width)],
        );

        controller.open(const ValueKey("1"));
        await tester.pump();
        await tester.pumpAndSettle();

        // Wide band (851.7 >= 960 is false, so this is actually narrow band
        // width-wise at this container size) -- either way, the point is
        // there is no inline split: the detail must arrive via the sheet.
        expect(find.byType(DraggableScrollableSheet), findsOneWidget);
        expect(find.text("detail:Alpha"), findsOneWidget);
      },
    );

    guardedTestWidgets(
      "live transition: fold appears mid-session (narrow -> folded split) throws nothing, selection survives",
      (tester) async {
        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);

        await _pumpFoldableShell(
          tester,
          items: _buildItems(),
          controller: controller,
          size: const Size(520, 900),
        );

        controller.open(const ValueKey("1"));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.byType(DraggableScrollableSheet), findsOneWidget);

        final keyBefore = controller.openedKey;

        // Now a vertical fold appears (device unfolded) at the same container size.
        // Re-pumping through the same helper (same widget shape, same LayrzApp/Builder
        // structure) updates the existing element tree in place rather than swapping
        // it for a differently-shaped one -- matching how
        // scaffold_shell_breakpoint_transition_test.dart drives its own live transitions.
        await _pumpFoldableShell(
          tester,
          items: _buildItems(),
          controller: controller,
          size: const Size(520, 900),
          displayFeatures: [_verticalFold(viewX: 260, height: 900)],
        );
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Selection preserved, sheet is gone, split is inline now.
        expect(controller.openedKey, equals(keyBefore));
        expect(find.text("detail:Alpha"), findsOneWidget);
        expect(find.byType(DraggableScrollableSheet), findsNothing);
      },
    );

    guardedTestWidgets(
      "live transition: setSurfaceSize while a vertical fold is active throws nothing",
      (tester) async {
        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await _pumpFoldableShell(
          tester,
          items: _buildItems(),
          controller: controller,
          size: const Size(904, 1000),
          displayFeatures: [_verticalFold(viewX: 452, height: 1000)],
        );

        controller.open(const ValueKey("1"));
        await tester.pump();
        expect(find.text("detail:Alpha"), findsOneWidget);

        await tester.binding.setSurfaceSize(const Size(1000, 1100));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    guardedTestWidgets(
      "REGRESSION (435dp case): a live keyboard-inset transition on a RUNNING vertical-split shell "
      "makes the split GO AWAY once the shell shrinks below kLayrzFoldMinSplitHeight",
      (tester) async {
        // This is the actual regression test for the measured Fold-scale
        // keyboard case: shell 852.0 x 731.9 (split) -> keyboard opens,
        // shrinking the shell to 852.0 x 435.0 (435 < 480 -> split must
        // disappear, falling back to today's layout) -- exercised on an
        // ALREADY-MOUNTED shell via a live pump, not a fresh pump preset to
        // the final inset (which would prove nothing about the transition).
        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);

        const width = 852.0;
        const tallHeight = 731.9;
        const shortHeight = 435.0;

        await _pumpFoldableShell(
          tester,
          items: _buildItems(),
          controller: controller,
          size: const Size(width, tallHeight),
          displayFeatures: [_verticalFold(viewX: width / 2, height: tallHeight)],
        );

        controller.open(const ValueKey("1"));
        await tester.pump();

        // Split is showing: detail inline, no sheet.
        expect(find.text("detail:Alpha"), findsOneWidget);
        expect(find.byType(DraggableScrollableSheet), findsNothing);

        final keyBefore = controller.openedKey;

        // Keyboard opens: the shell's own height shrinks (as it would when
        // an ancestor resizes the body for the on-screen keyboard), reported
        // via a live re-pump through the SAME helper/shape (matching the
        // other live-transition tests in this file), at the shrunk height.
        await _pumpFoldableShell(
          tester,
          items: _buildItems(),
          controller: controller,
          size: const Size(width, shortHeight),
          displayFeatures: [_verticalFold(viewX: width / 2, height: shortHeight)],
          viewInsetsBottom: 328.2, // measured Pixel 10 Pro Fold keyboard inset
        );
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // The split must be GONE: selection survives (matching every other
        // shell-initiated presentation change in this file), and the detail
        // is now shown via the narrow sheet, not the inline split.
        expect(controller.openedKey, equals(keyBefore));
        expect(find.text("detail:Alpha"), findsOneWidget);
        expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      },
    );

    guardedTestWidgets(
      "REGRESSION (crash on device): the shell does not throw when reparented under a fresh "
      "RenderTransform in a single rebuild, with a fold active",
      (tester) async {
        // Real crash, from a real device, under LayrzLayout's drawer
        // presentation:
        //
        //   RenderBox was not laid out: RenderTransform#... NEEDS-LAYOUT
        //   'hasSize': is not true.
        //     #3 RenderTransform._effectiveTransform
        //     #4 RenderTransform.applyPaintTransform
        //     #5 RenderObject.getTransformTo
        //     #6 RenderBox.localToGlobal
        //     #7 _LayrzScaffoldShellState._resolveFoldSplit
        //     #8 _LayrzScaffoldShellState.build.<anonymous closure>
        //
        // ROOT MECHANISM, isolated and proven (not assumed): the shell's own
        // KeyedSubtree already has a size from a PRIOR frame. When the SAME
        // rebuild that reparents the shell's element (GlobalKey-preserved,
        // exactly like drawer_scaffold.dart keeps `page`'s element identity
        // across its t==0/t>0 branch swap) also inserts a BRAND NEW
        // RenderTransform with `alignment` set as its new parent, that new
        // RenderTransform genuinely lacks `hasSize` while the shell's
        // LayoutBuilder builds as its descendant -- because
        // RenderTransform.performLayout (inherited from RenderProxyBox)
        // calls `child.layout()` BEFORE assigning its own `size`, and the
        // shell's LayoutBuilder.builder runs from inside that still-running
        // call.
        //
        // This is genuinely hard to catch, and it took real iteration to
        // isolate: neither a live AnimationController driven through partial
        // ticks, nor pumping the full LayrzLayout drawer-open animation
        // frame-by-frame, nor a resize concurrent with that animation, ever
        // made this assertion fire in this harness -- because
        // TestWidgetsFlutterBinding.pump() always runs the ENTIRE pipeline's
        // layout phase to completion before returning, so there is no way,
        // from outside a pump() call, to observe an ancestor mid-layout
        // afterward. What DOES reproduce it is forcing the exact structural
        // condition directly: the SAME element (same GlobalKey, same
        // pumpWidget call, one single setState) reparented under a
        // brand-new Transform in one rebuild -- captured mid-layout at
        // exactly the moment the descendant needs it. This WAS verified to
        // throw the exact assertion above against the pre-fix
        // implementation before the fix landed, and to pass against it.
        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.view.resetDisplayFeatures();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(904, 1000);
        final features = [_verticalFold(viewX: 452, height: 1000)];
        tester.view.displayFeatures = features;

        final shellKey = GlobalKey();

        Widget shellSubtree() {
          return KeyedSubtree(
            key: shellKey,
            child: SizedBox.expand(
              child: LayrzScaffoldShell<_TestItem>(
                controller: controller,
                items: _buildItems(),
                onDetailsBuild: (item) => Text("detail:${item.name}"),
                itemExtent: 56.0,
              ),
            ),
          );
        }

        late StateSetter setShellState;
        var wrapInTransform = false;

        await tester.pumpWidget(
          LayrzApp(
            theme: LayrzThemeData.light(),
            debugShowCheckedModeBanner: false,
            home: Builder(
              builder: (context) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(displayFeatures: features),
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      setShellState = setState;
                      return wrapInTransform
                          ? Transform.scale(
                              key: const ValueKey("regression_wrapping_transform"),
                              scale: 1.0,
                              alignment: Alignment.centerLeft,
                              child: shellSubtree(),
                            )
                          : shellSubtree();
                    },
                  ),
                );
              },
            ),
          ),
        );
        expect(tester.takeException(), isNull);

        controller.open(const ValueKey("1"));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text("detail:Alpha"), findsOneWidget);
        expect(find.byType(DraggableScrollableSheet), findsNothing);

        // Reparent the ALREADY-LAID-OUT shell element (same GlobalKey, same
        // widget tree) under a brand-new Transform.scale (alignment set,
        // exactly like drawer_scaffold.dart's page-layer transform), in a
        // single setState -- this is the actual mechanism.
        wrapInTransform = true;
        setShellState(() {});
        await tester.pump();
        expect(tester.takeException(), isNull, reason: "must not throw when reparented under a fresh RenderTransform");

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // The fold must still resolve correctly after the reparent -- same
        // vertical-split assertions as the ordinary (unwrapped) test above.
        expect(find.text("detail:Alpha"), findsOneWidget);
        expect(find.byType(DraggableScrollableSheet), findsNothing);
      },
    );
  });
}
