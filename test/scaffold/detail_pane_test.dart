import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";
import "package:layrz_ui/src/scaffold/src/detail_pane.dart";

import "../helpers/pump_themed.dart";

/// Direct coverage of [DetailPane]'s "nothing selected" placeholder slot,
/// exercised on the widget itself rather than only through
/// [LayrzScaffoldShell] -- `DetailPane` is `scaffold`-internal (not exported
/// from the package barrel) but is still directly constructible by its file
/// path, mirroring how `list_panel.dart` is imported directly in
/// `scaffold_shell_table_default_test.dart`.
void main() {
  group("DetailPane empty state", () {
    testWidgets("with no builder and no emptyState, renders the localized default", (tester) async {
      await pumpThemed(tester, const DetailPane());

      expect(find.text("No item selected"), findsOneWidget);
    });

    testWidgets("with no builder and a custom emptyState, renders the custom widget instead", (tester) async {
      await pumpThemed(
        tester,
        const DetailPane(
          emptyState: Text("Pick something from the list", key: Key("custom-empty")),
        ),
      );

      expect(find.byKey(const Key("custom-empty")), findsOneWidget);
      expect(find.text("Pick something from the list"), findsOneWidget);
      expect(find.text("No item selected"), findsNothing);
    });

    testWidgets("with a non-null builder, emptyState is ignored entirely", (tester) async {
      await pumpThemed(
        tester,
        DetailPane(
          builder: (_) => const Text("detail content"),
          emptyState: const Text("should not appear", key: Key("ignored-empty")),
        ),
      );

      expect(find.text("detail content"), findsOneWidget);
      expect(find.byKey(const Key("ignored-empty")), findsNothing);
      expect(find.text("No item selected"), findsNothing);
    });
  });
}
