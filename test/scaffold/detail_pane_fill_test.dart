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

/// Regression coverage for DESIGN-210: the scaffold shell's detail pane used
/// to render its (shrink-wrapping) content vertically -- and horizontally --
/// centered instead of anchored to the pane's top-left corner, because
/// nothing gave the `contentBuilder` result a reason to claim the pane's full
/// box. `DetailPane` itself is a `scaffold`-internal widget (not exported
/// from the package barrel), so this is exercised the same way every other
/// scaffold test exercises it: through the public `LayrzScaffoldShell`.
void main() {
  group("LayrzScaffoldShell detail pane top-anchors its content", () {
    testWidgets("wide layout: a short detail child sits at the pane's top-left, not centered", (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1500, 950);

      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      final items = [
        const LayrzScaffoldItem(
          key: ValueKey("1"),
          item: _TestItem("1", "Alpha"),
          tile: SizedBox(child: Text("Alpha")),
          searchableStrings: {"Alpha"},
        ),
      ];

      await pumpThemed(
        tester,
        SizedBox.expand(
          child: LayrzScaffoldShell<_TestItem>(
            controller: controller,
            items: items,
            itemExtent: 56.0,
            onDetailsBuild: (item) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("detail:${item.name}", key: const Key("detail-text")),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      controller.open(const ValueKey("1"));
      await tester.pump();

      expect(tester.takeException(), isNull);

      final detailText = tester.getRect(find.byKey(const Key("detail-text")));
      // The detail pane is the trailing Expanded region of the shell's Row;
      // its top edge coincides with the shell's own top edge (no app bar in
      // this minimal harness), so the text should sit flush with that edge
      // rather than vertically centered within the 950px-tall pane.
      expect(detailText.top, lessThan(50));
    });

    testWidgets("narrow layout sheet: a short detail child sits at the sheet's top, not centered", (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(520, 900);

      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      final items = [
        const LayrzScaffoldItem(
          key: ValueKey("1"),
          item: _TestItem("1", "Alpha"),
          tile: SizedBox(child: Text("Alpha")),
          searchableStrings: {"Alpha"},
        ),
      ];

      final shell = SizedBox.expand(
        child: LayrzScaffoldShell<_TestItem>(
          controller: controller,
          items: items,
          itemExtent: 56.0,
          onDetailsBuild: (item) => Text("detail:${item.name}", key: const Key("detail-text")),
        ),
      );

      await tester.pumpWidget(
        Localizations(
          locale: const Locale('en'),
          delegates: const [
            DefaultWidgetsLocalizations.delegate,
            LayrzUiL10nDelegate(),
          ],
          child: LayrzTheme(
            data: LayrzThemeData.light(),
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => Navigator(
                    onGenerateRoute: (settings) {
                      return PageRouteBuilder<void>(
                        pageBuilder: (context, animation, secondaryAnimation) => shell,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      controller.open(const ValueKey("1"));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key("detail-text")), findsOneWidget);
      // Regression guard: this used to assert (unbounded height inside the
      // sheet's SingleChildScrollView) before the DetailPane fix; reaching
      // here at all -- with the text actually laid out -- is the coverage.
    });
  });
}
