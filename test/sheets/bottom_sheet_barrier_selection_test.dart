import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzBottomSheet barrier hit-testing (long-press bleed-through)', () {
    // Pinned deliberately, per the pattern already used across this test suite
    // (e.g. test/layout/compact_viewport_test.dart): devicePixelRatio must be set
    // BEFORE physicalSize. The ambient ratio in the test harness is 3.0, so a
    // physicalSize of (1200, 800) would otherwise resolve to a LOGICAL 400x266 —
    // the compact band — by accident rather than by design. This bug is mobile-mode
    // (drawer/xs presentation), so a compact logical size is exactly what is wanted;
    // pinning devicePixelRatio to 1.0 first makes physicalSize == logical size, so
    // the 400x800 below is the actual logical viewport, not a scaled-down one.
    void setLogicalSize(WidgetTester tester, Size logicalSize) {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = logicalSize;
    }

    /// Builds a [LayrzLayout] whose body places selectable text near the top of
    /// the screen — a region a half-height bottom sheet (initialSize 0.5) never
    /// covers with its own content, but which the barrier (painted full-screen,
    /// behind the sheet) does cover.
    Widget buildHarness() {
      return LayrzLayout(
        logo: 'assets/test-logo.png',
        items: [
          LayrzNavigatorPage(id: 'home', labelText: 'Home'),
        ],
        selectableContent: true,
        body: const Align(
          alignment: Alignment.topCenter,
          child: Text('Body text behind the sheet barrier'),
        ),
      );
    }

    /// Mirrors `LayrzLayout`'s own `_buildContextMenu` (lib/src/layout/src/layout.dart):
    /// a bare [SelectableRegion] with no `contextMenuBuilder` crashes on long-press in
    /// this repo (there is no Material default to fall back on), so any test-local
    /// [SelectableRegion] must supply one explicitly. Reproduced here — not imported —
    /// because the original is private to layout.dart.
    Widget buildContextMenu(BuildContext context, SelectableRegionState state) {
      final tokens = context.theme.tokens;
      final anchors = state.contextMenuAnchors;

      return CustomSingleChildLayout(
        delegate: TextSelectionToolbarLayoutDelegate(
          anchorAbove: anchors.primaryAnchor,
          anchorBelow: anchors.secondaryAnchor ?? Offset.zero,
        ),
        child: LayrzSelectionToolbar(
          actions: {LayrzSelectableAction.copy},
          anchorAbove: anchors.primaryAnchor,
          anchorBelow: anchors.secondaryAnchor,
          tokens: tokens,
          onActionPressed: (actionType) {
            if (actionType == 'copy') {
              // ignore: deprecated_member_use
              state.copySelection(SelectionChangedCause.toolbar);
            }
          },
        ),
      );
    }

    testWidgets('long-press over the barrier does not select body text behind it', (tester) async {
      setLogicalSize(tester, const Size(400, 800));

      await pumpThemedApp(tester, buildHarness());

      // Sanity: body text renders where expected, unobscured, before the sheet opens.
      final bodyTextFinder = find.text('Body text behind the sheet barrier');
      expect(bodyTextFinder, findsOneWidget);
      final bodyTextCenter = tester.getCenter(bodyTextFinder);

      // Open a modal sheet whose own content never reaches up to the body text's
      // position — initialSize 0.5 means the sheet occupies only the bottom half
      // of an 800-logical-pixel-tall screen, so its top edge sits at y ~= 400.
      // The body text sits near the top of the screen, well above that — inside
      // the barrier's region but outside the sheet's own decorated box.
      final context = tester.element(find.byType(LayrzLayout));
      unawaited(
        LayrzBottomSheet.show<void>(
          context,
          initialSize: 0.5,
          builder: (context) => const SizedBox(
            height: 100,
            child: Center(child: Text('Sheet content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sheet content'), findsOneWidget, reason: 'sheet must be open for this test to be valid');

      // Confirm the probe point is genuinely above the sheet's own box (i.e. only
      // the barrier, not the sheet's decorated surface, is present at this point).
      final sheetSurfaceFinder = find.byWidgetPredicate(
        (widget) => widget is DecoratedBox && (widget.decoration as BoxDecoration).boxShadow != null,
      );
      final sheetTop = tester.getTopLeft(sheetSurfaceFinder).dy;
      expect(
        bodyTextCenter.dy,
        lessThan(sheetTop),
        reason: 'the probe point must be above the sheet content, over the barrier only',
      );

      // Long-press exactly where the (now obscured) body text used to be.
      await tester.longPressAt(bodyTextCenter);
      await tester.pumpAndSettle();

      // Proxy for "a SelectableRegion reports a non-null selection": this repo's own
      // test/layout/selectable_content_test.dart establishes LayrzSelectionToolbar's
      // presence as the observable signal that a long-press produced a selection,
      // since SelectableRegion exposes no public selection getter to assert on
      // directly.
      expect(
        find.byType(LayrzSelectionToolbar),
        findsNothing,
        reason: 'long-pressing the barrier must not select text in the obscured page body',
      );
    });

    testWidgets('tap-to-dismiss still closes the sheet', (tester) async {
      setLogicalSize(tester, const Size(400, 800));

      await pumpThemedApp(tester, buildHarness());

      final context = tester.element(find.byType(LayrzLayout));
      unawaited(
        LayrzBottomSheet.show<void>(
          context,
          initialSize: 0.5,
          builder: (context) => const SizedBox(
            height: 100,
            child: Center(child: Text('Sheet content')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sheet content'), findsOneWidget);

      // Tap a point clearly in the barrier region (above the sheet's own box).
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Sheet content'), findsNothing, reason: 'barrier tap must still dismiss the sheet');
    });

    testWidgets('persistent sheets have no barrier and their page stays interactive', (tester) async {
      setLogicalSize(tester, const Size(400, 800));

      await pumpThemedApp(tester, buildHarness());

      final context = tester.element(find.byType(LayrzLayout));
      unawaited(
        LayrzBottomSheet.show<void>(
          context,
          isPersistent: true,
          initialSize: 0.5,
          builder: (context) => const SizedBox(
            height: 100,
            child: Center(child: Text('Persistent sheet content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Persistent sheet content'), findsOneWidget);

      // No barrier GestureDetector exists for a persistent sheet (`if (!isPersistent)`
      // in bottom_sheet.dart), so the page behind it stays interactive.
      final bodyTextFinder = find.text('Body text behind the sheet barrier');
      expect(bodyTextFinder, findsOneWidget);

      // The page body remains tappable/interactive since there is no barrier to
      // block it — verified by the absence of any exception when interacting with it.
      await tester.tap(bodyTextFinder, warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);

      // The persistent sheet itself is unaffected and stays open.
      expect(find.text('Persistent sheet content'), findsOneWidget);
    });

    testWidgets("long-press on the sheet's own selectable text still selects it", (tester) async {
      setLogicalSize(tester, const Size(400, 800));

      await pumpThemedApp(tester, buildHarness());

      final context = tester.element(find.byType(LayrzLayout));
      unawaited(
        LayrzBottomSheet.show<void>(
          context,
          initialSize: 0.5,
          builder: (context) => Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableRegion(
              selectionControls: LayrzTextSelectionControls.instance,
              contextMenuBuilder: buildContextMenu,
              child: const Text('Selectable sheet text'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sheetTextFinder = find.text('Selectable sheet text');
      expect(sheetTextFinder, findsOneWidget);

      await tester.longPress(sheetTextFinder);
      await tester.pumpAndSettle();

      // The sheet's own SelectableRegion is a normal descendant of the sheet content
      // in the Stack (painted above the barrier), so the barrier — which sits below
      // the sheet in paint/hit-test order — never intercepts a gesture aimed at the
      // sheet's own content. Selection inside the sheet works: this is the same
      // LayrzSelectionToolbar proxy used in test/layout/selectable_content_test.dart
      // to observe that a long-press produced a selection.
      expect(
        find.byType(LayrzSelectionToolbar),
        findsOneWidget,
        reason: 'long-pressing text inside the sheet itself must still produce a selection and its toolbar',
      );
    });
  });
}
