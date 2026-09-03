import "dart:ui" show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

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
  ];
}

DisplayFeature _verticalFold({double viewX = 260, double height = 900}) {
  return DisplayFeature(
    bounds: Rect.fromLTRB(viewX, 0, viewX, height),
    type: DisplayFeatureType.fold,
    state: DisplayFeatureState.postureFlat,
  );
}

/// Pumps a themed, folded [LayrzScaffoldShell] and settles it, so the shell's
/// one-frame-lagged fold resolution (see `_resolveFoldSplit` in
/// scaffold_shell.dart) has landed before assertions run.
Future<void> _pumpFoldedShell(
  WidgetTester tester, {
  required List<LayrzScaffoldItem<_TestItem>> items,
  required LayrzScaffoldController controller,
  required Size size,
  required List<DisplayFeature> displayFeatures,
}) async {
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetDisplayFeatures();
  });
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  tester.view.displayFeatures = displayFeatures;

  await tester.pumpWidget(
    LayrzApp(
      theme: LayrzThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(displayFeatures: displayFeatures),
            child: SizedBox.expand(
              child: LayrzScaffoldShell<_TestItem>(
                controller: controller,
                items: items,
                onDetailsBuild: (item) => Text("detail:${item.name}"),
                itemExtent: 56.0,
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  group("LayrzScaffoldShell folded paths accessibility", () {
    // 904 x 1000: width forces the split's mapped panes, and height 1000
    // comfortably clears kLayrzFoldMinSplitHeight (480) so the split actually
    // renders -- only a vertical seam ever produces one; see fold_split.dart.
    testWidgets("vertical fold side-by-side: both list and detail text are reachable in the semantics tree", (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);

        await _pumpFoldedShell(
          tester,
          items: _buildItems(),
          controller: controller,
          size: const Size(904, 1000),
          displayFeatures: [_verticalFold(viewX: 452, height: 1000)],
        );

        controller.open(const ValueKey("1"));
        await tester.pump();
        await tester.pumpAndSettle();

        // Both panes present visually -- the split, not the sheet.
        expect(find.text("Alpha"), findsWidgets);
        expect(find.text("detail:Alpha"), findsOneWidget);
        expect(find.byType(DraggableScrollableSheet), findsNothing);

        // Both the list row and the detail content must carry real semantics
        // nodes -- not merely be present in the render tree.
        final listItemSemantics = tester.getSemantics(find.text("Alpha").first);
        expect(
          listItemSemantics,
          matchesSemantics(label: "Alpha", isTextField: false),
        );

        // The bare Text("detail:Alpha") has no Semantics-producing ancestor
        // WIDGET of its own (only an implicit one from RenderParagraph), so
        // tester.getSemantics(find.text(...)) walks to the wrong owner here
        // and returns an unrelated (empty-label) node -- verified by dumping
        // the tree with tester.getSemantics(find.byType(WidgetsApp))
        // .toStringDeep(), which shows the real node
        // (label: "detail:Alpha") sitting directly under the shell's root
        // Semantics with no merge. find.bySemanticsLabel locates that real
        // node directly; the assertion below still checks real properties,
        // not mere presence.
        final detailSemantics = tester.getSemantics(find.bySemanticsLabel("detail:Alpha"));
        expect(
          detailSemantics,
          matchesSemantics(label: "detail:Alpha", isTextField: false),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets("vertical fold side-by-side: list row remains announced as tappable/selectable", (tester) async {
      final handle = tester.ensureSemantics();
      try {
        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);

        await _pumpFoldedShell(
          tester,
          items: _buildItems(),
          controller: controller,
          size: const Size(904, 1000),
          displayFeatures: [_verticalFold(viewX: 452, height: 1000)],
        );

        // Closed: the list row must still expose a tap action so it is
        // reachable by assistive technology in the split layout, exactly as
        // it would be in the ordinary wide layout.
        final rowSemantics = tester.getSemantics(find.byType(LayrzTappable).first);
        expect(rowSemantics, matchesSemantics(hasTapAction: true));
      } finally {
        handle.dispose();
      }
    });

    testWidgets(
      "a vertical fold shorter than kLayrzFoldMinSplitHeight falls back to the narrow sheet, "
      "which still exposes real semantics for both list and detail",
      (tester) async {
        // Companion case to the two above: proves the a11y guarantees hold
        // on the OTHER side of the height guard too, where the shell falls
        // back to today's narrow list + sheet path instead of a split.
        final handle = tester.ensureSemantics();
        try {
          final controller = LayrzScaffoldController();
          addTearDown(controller.dispose);

          await _pumpFoldedShell(
            tester,
            items: _buildItems(),
            controller: controller,
            size: const Size(785.7, 411.4), // height 411.4 < 480 -> no split
            displayFeatures: [_verticalFold(viewX: 392.85, height: 411.4)],
          );

          // Assert the list row's baseline reachability BEFORE opening the
          // sheet -- once the sheet is open, the list row sits behind the
          // sheet's own modal barrier and is legitimately (and correctly)
          // excluded from the live semantics tree, exactly as it would be
          // on any non-foldable narrow layout. That occlusion is expected
          // behavior, not something this test exists to probe.
          final rowSemantics = tester.getSemantics(find.byType(LayrzTappable).first);
          expect(rowSemantics, matchesSemantics(hasTapAction: true));

          controller.open(const ValueKey("1"));
          await tester.pump();
          await tester.pumpAndSettle();

          expect(find.byType(DraggableScrollableSheet), findsOneWidget);
          expect(find.text("detail:Alpha"), findsOneWidget);

          // See the same finder note in the split test above.
          final detailSemantics = tester.getSemantics(find.bySemanticsLabel("detail:Alpha"));
          expect(
            detailSemantics,
            matchesSemantics(label: "detail:Alpha", isTextField: false),
          );
        } finally {
          handle.dispose();
        }
      },
    );
  });
}
