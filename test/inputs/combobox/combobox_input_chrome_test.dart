import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/combobox/combobox_surface.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/pump_themed_app.dart';

void main() {
  // These regressions pin the "look and feel" requirement the maintainer
  // gave verbatim: "needs to look like the select, aka, a field inside of
  // the container hiding the original field behind, and the list of items
  // below, however, the field inside of the container is partially search,
  // partially just a TextInput, on ComboBox, the options ... are
  // suggestions, not options ... The thing that I want to change is the
  // look and feel." Two concrete, previously-untested guarantees follow
  // from that: the panel's own input row must read as the field's own text
  // input continuing into the panel (its own hintText, its own slots -- not
  // Select's search chrome), and the option list must never carry Select's
  // "this is THE answer" affordance (a checkmark on a selected row).
  //
  // `LayrzComboBoxInput` already satisfies both, structurally: `_buildFieldChrome`
  // is the SAME function building both the closed field and the panel's first
  // row (Q3 -- see the class doc), so whatever slots/hint the caller passes to
  // the widget are exactly what the panel shows, with no separate search-styled
  // path to diverge from it. These tests exist so that guarantee cannot be
  // silently reintroduced later (e.g. by a future change that special-cases the
  // panel's field row).
  group('LayrzComboBoxInput panel chrome (look-and-feel parity, not Select search chrome)', () {
    testWidgets("the panel's field row shows the field's own hintText, not a search label", (tester) async {
      // Desktop-sized viewport: below `kMediumGrid` (960px), `context.isCompact`
      // is true and `_openOverlay` routes to the mobile bottom sheet instead of
      // `LayrzAnchoredPanel` -- every test in this group needs the desktop panel
      // specifically, so every one of them sets this explicitly (mirrors
      // `combobox_input_test.dart`'s own DESIGN-145 regression, which does the
      // same for the same reason).
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        const LayrzComboBoxInput(
          labelText: 'Country',
          hintText: 'Select or type a country',
          options: ['United States', 'Canada', 'Mexico'],
        ),
      );

      // Closed: the hint is visible directly.
      expect(find.text('Select or type a country'), findsOneWidget);

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      // Open: the SAME hint text -- not `LayrzUiL10n.selectSearch` ("Search in
      // the list"), which never appears anywhere in a `LayrzComboBoxInput` tree.
      expect(
        find.descendant(of: find.byType(LayrzComboBoxPanelContent), matching: find.text('Select or type a country')),
        findsOneWidget,
      );
      expect(find.text(contextL10n(tester).selectSearch), findsNothing);
    });

    testWidgets('the panel never renders a magnifier icon (no Select-style search chrome)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        const LayrzComboBoxInput(
          labelText: 'Country',
          hintText: 'Select or type a country',
          options: ['United States', 'Canada', 'Mexico'],
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(LayrzComboBoxPanelContent), matching: find.byIcon(MdiIcons.magnify)),
        findsNothing,
        reason: "ComboBox's panel input is a continuation of the field's own TextInput, not a search box",
      );
    });

    testWidgets('a caller-supplied prefixIcon appears on both the closed field and the open panel row', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        const LayrzComboBoxInput(
          labelText: 'Country',
          hintText: 'Select or type a country',
          prefixIcon: MdiIcons.flagOutline,
          options: ['United States', 'Canada', 'Mexico'],
        ),
      );

      // Closed field shows the caller's own prefix.
      expect(find.byIcon(MdiIcons.flagOutline), findsOneWidget);

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      // Open panel's field row shows the SAME slot -- inherited from the parent
      // field, never substituted or dropped, per "inherit the slots from the
      // parent container".
      expect(
        find.descendant(of: find.byType(LayrzComboBoxPanelContent), matching: find.byIcon(MdiIcons.flagOutline)),
        findsOneWidget,
      );
    });

    testWidgets('a caller-supplied suffixIcon appears on both the closed field and the open panel row', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        const LayrzComboBoxInput(
          labelText: 'Country',
          hintText: 'Select or type a country',
          suffixIcon: MdiIcons.earth,
          options: ['United States', 'Canada', 'Mexico'],
        ),
      );

      expect(find.byIcon(MdiIcons.earth), findsOneWidget);

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(LayrzComboBoxPanelContent), matching: find.byIcon(MdiIcons.earth)),
        findsOneWidget,
      );
    });

    testWidgets('with no caller-supplied slots, the panel row renders no prefix/suffix at all (no invented chrome)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        const LayrzComboBoxInput(
          labelText: 'Country',
          hintText: 'Select or type a country',
          options: ['United States', 'Canada', 'Mexico'],
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      // No icon of any kind decorates the panel's field row -- the widget must
      // not invent a slot (e.g. a magnifier) the caller never asked for.
      final chrome = find.byType(LayrzInputChrome).last;
      expect(find.descendant(of: chrome, matching: find.byType(Icon)), findsNothing);
    });

    testWidgets('option rows never render a selected-state checkmark (suggestions, not a committed choice)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController(text: 'Canada');

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Country',
          controller: controller,
          options: const ['United States', 'Canada', 'Mexico'],
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      // Even though the field's current text exactly matches an option
      // ("Canada"), the option list must not mark it as a committed selection
      // the way `LayrzSelectInput`'s `_SelectItemRow` marks `isSelected` with a
      // checkmark -- ComboBox's options are advisory suggestions, not a
      // single-answer picker. A highlight from keyboard navigation is a
      // different, permitted affordance; this only pins the absence of a
      // checkmark icon.
      expect(find.byIcon(MdiIcons.check), findsNothing);

      controller.dispose();
    });
  });

  // DESIGN-145/Q9 parity: pinned again here (in addition to the existing
  // `combobox_input_test.dart` coverage) with an explicit width assertion, so a
  // future regression that lets the panel outgrow the anchor -- horizontally or
  // vertically -- fails loudly rather than only being caught by eye against a
  // screenshot. Mirrors the geometry-assertion style in
  // `select_input_test.dart`'s own DESIGN-145 regression group and
  // `anchored_panel_border_test.dart`.
  group('LayrzComboBoxInput panel geometry stays within the field/viewport bounds', () {
    testWidgets('the panel never renders wider than the anchor field, under the showroom list-detail layout', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1449, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Mirrors LayrzScaffoldShell's own wide-layout composition (ListPanel at a
      // fixed 300px + a 1px divider + Expanded(DetailPane)), which is the actual
      // production host for the showroom's ComboBox demo -- not a bare `Center`.
      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Row(
            children: [
              const SizedBox(width: 300),
              Container(width: 1),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        LayrzComboBoxInput(
                          labelText: 'Country',
                          hintText: 'Select or type a country',
                          options: [
                            'United States',
                            'Canada',
                            'Mexico',
                            'United Kingdom',
                            'Germany',
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      final fieldRect = tester.getRect(find.byType(LayrzInputChrome).first);

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      final panelRect = tester.getRect(find.byType(LayrzComboBoxPanelContent));

      expect(panelRect.width, closeTo(fieldRect.width, 0.5));
      expect(panelRect.left, closeTo(fieldRect.left, 0.5));
      expect(panelRect.right, lessThanOrEqualTo(1449.0));
    });
  });
}

/// Convenience accessor for the app's [LayrzUiL10n], scoped to the widget tree
/// under test. Kept local to this file: nothing else in this module needs it.
LayrzUiL10n contextL10n(WidgetTester tester) {
  final context = tester.element(find.byType(LayrzComboBoxInput));
  return LayrzUiL10n.of(context);
}
