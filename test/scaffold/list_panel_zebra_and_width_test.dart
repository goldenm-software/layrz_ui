import "dart:ui" show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

import "../helpers/pump_themed.dart";

/// Minimal domain object for testing.
class _TestItem {
  const _TestItem(this.id, this.name);

  final String id;
  final String name;
}

/// Pumps a [LayrzScaffoldShell] at the given [size] with [items].
Future<void> _pumpShell(
  WidgetTester tester, {
  required List<LayrzScaffoldItem<_TestItem>> items,
  required LayrzScaffoldController controller,
  required Size size,
}) async {
  addTearDown(tester.view.reset);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;

  await pumpThemed(
    tester,
    SizedBox.expand(
      child: LayrzScaffoldShell<_TestItem>(
        controller: controller,
        items: items,
        itemExtent: 56.0,
      ),
    ),
  );
  expect(tester.takeException(), isNull);
}

/// Builds [count] plain (action-less) items, each named by its index.
List<LayrzScaffoldItem<_TestItem>> _plainItems(int count) {
  return List.generate(
    count,
    (i) => LayrzScaffoldItem<_TestItem>(
      key: ValueKey("$i"),
      item: _TestItem("$i", "Item $i"),
      tile: Text("Item $i"),
      searchableStrings: {"Item $i"},
    ),
  );
}

const _kWideSize = Size(1500, 950);

void main() {
  group("ListPanel — zebra striping (DESIGN-62.3)", () {
    testWidgets("even-index row resolves to sf1, odd-index row resolves to sf2", (tester) async {
      final controller = LayrzScaffoldController();
      final items = _plainItems(4);

      await _pumpShell(tester, items: items, controller: controller, size: _kWideSize);

      final tokens = LayrzThemeData.light().tokens;
      final tappables = tester.widgetList<LayrzTappable>(find.byType(LayrzTappable)).toList();

      expect(tappables.length, 4);
      expect(tappables[0].color, tokens.colors.sf1, reason: "row 0 (even) must be sf1");
      expect(tappables[1].color, tokens.colors.sf2, reason: "row 1 (odd) must be sf2");
      expect(tappables[2].color, tokens.colors.sf1, reason: "row 2 (even) must be sf1");
      expect(tappables[3].color, tokens.colors.sf2, reason: "row 3 (odd) must be sf2");

      controller.dispose();
    });

    testWidgets("a selected row resolves to sf4 regardless of its parity", (tester) async {
      // Select item index 1 (odd) — sf4 must win over the sf2 its parity would
      // otherwise resolve to.
      final controller = LayrzScaffoldController(initialOpenedKey: const ValueKey("1"));
      final items = _plainItems(4);

      await _pumpShell(tester, items: items, controller: controller, size: _kWideSize);

      final tokens = LayrzThemeData.light().tokens;
      final tappables = tester.widgetList<LayrzTappable>(find.byType(LayrzTappable)).toList();

      expect(tappables.length, 4);
      expect(tappables[0].color, tokens.colors.sf1, reason: "row 0 (even, unselected) must be sf1");
      expect(tappables[1].color, tokens.colors.sf4, reason: "row 1 (odd, SELECTED) must be sf4 — selected wins");
      expect(tappables[2].color, tokens.colors.sf1, reason: "row 2 (even, unselected) must be sf1");
      expect(tappables[3].color, tokens.colors.sf2, reason: "row 3 (odd, unselected) must be sf2");

      controller.dispose();
    });

    testWidgets("an even-index selected row also resolves to sf4, not sf1", (tester) async {
      final controller = LayrzScaffoldController(initialOpenedKey: const ValueKey("0"));
      final items = _plainItems(2);

      await _pumpShell(tester, items: items, controller: controller, size: _kWideSize);

      final tokens = LayrzThemeData.light().tokens;
      final tappables = tester.widgetList<LayrzTappable>(find.byType(LayrzTappable)).toList();

      expect(tappables[0].color, tokens.colors.sf4, reason: "row 0 (even, SELECTED) must be sf4 — selected wins");
      expect(tappables[1].color, tokens.colors.sf2, reason: "row 1 (odd, unselected) must be sf2");

      controller.dispose();
    });
  });

  group("ListPanel — default width (DESIGN-62.2)", () {
    testWidgets("with no explicit width, the panel renders at kLayrzScaffoldListWidth (400)", (tester) async {
      final controller = LayrzScaffoldController();
      final items = _plainItems(2);

      await _pumpShell(tester, items: items, controller: controller, size: _kWideSize);

      expect(kLayrzScaffoldListWidth, 400.0);

      // Locate the ListPanel's own Container by matching its width against the
      // constant — it is the outermost Container carrying an explicit `width`
      // in the wide (non-folded) layout.
      final containers = tester.widgetList<Container>(find.byType(Container));
      final widthMatches = containers.where((c) => c.constraints?.maxWidth == kLayrzScaffoldListWidth);
      expect(
        widthMatches,
        isNotEmpty,
        reason: "expected a Container constrained to kLayrzScaffoldListWidth (400) — the list panel's default",
      );

      controller.dispose();
    });

    testWidgets(
      "with an explicit width via the fold-split path, the panel honors that value instead of 400",
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.view.resetDisplayFeatures();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(520, 900);
        // A vertical fold at view-x 260 forces LayrzScaffoldShell's fold-aware
        // side-by-side layout (`_buildFoldedSideBySideLayout`), which passes
        // `width: split.leadingExtent` (~260, well under the 400 default) to
        // ListPanel explicitly -- proving the `?? default` fallback change in
        // FIX 62.2 left this explicit-width path untouched.
        final displayFeatures = [
          const DisplayFeature(
            bounds: Rect.fromLTRB(260, 0, 260, 900),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureFlat,
          ),
        ];
        tester.view.displayFeatures = displayFeatures;

        final controller = LayrzScaffoldController();
        final items = _plainItems(2);

        await tester.pumpWidget(
          LayrzApp(
            theme: LayrzThemeData.light(),
            home: Builder(
              builder: (context) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(displayFeatures: displayFeatures),
                  child: SizedBox.expand(
                    child: LayrzScaffoldShell<_TestItem>(
                      controller: controller,
                      items: items,
                      itemExtent: 56.0,
                    ),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        final containers = tester.widgetList<Container>(find.byType(Container));
        final widthMatches400 = containers.where((c) => c.constraints?.maxWidth == kLayrzScaffoldListWidth);
        expect(
          widthMatches400,
          isEmpty,
          reason: "the fold-split path must NOT fall back to the 400 default",
        );

        controller.dispose();
      },
    );
  });
}
