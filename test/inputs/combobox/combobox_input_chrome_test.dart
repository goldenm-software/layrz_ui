import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/combobox/combobox_surface.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/pump_themed_app.dart';

/// DESIGN-98 superseded every "look-and-feel parity" guarantee this file used
/// to pin.
///
/// Before DESIGN-98, `LayrzComboBoxInput`'s desktop branch opened
/// `LayrzAnchoredPanel`, and `_buildFieldChrome` -- the SAME function building
/// both the closed field and the panel's first row (Q3) -- meant the panel's
/// input row inherited the field's own hintText, slots, and lack of border
/// structurally. That entire mechanism is gone: the maintainer's DESIGN-98
/// instruction ("use the EndDrawer instead of the overlay, because it's kinda
/// weird after a few days of usage") replaced the field-continuing panel with
/// [LayrzEndDrawer] hosting a wholly independent [BottomSheetContent] surface
/// -- the same one the compact/mobile band already opened. There is no more
/// panel row sharing the field's own chrome, no more "field row IS the input,
/// continuing" contract, and so nothing left for a "look-and-feel parity"
/// group to assert against `LayrzComboBoxPanelContent` on desktop specifically
/// -- `LayrzComboBoxPanelContent` is no longer built by the real desktop flow
/// at all (see `combobox_input.dart`'s class doc's Q3 section).
///
/// [BottomSheetContent]'s own look-and-feel (search field, hint, filtering,
/// commit-by-pop) is unit-tested directly in `combobox_surface_test.dart`,
/// which already covers both the mobile and (now) desktop hosts identically,
/// since both open the exact same widget. This file's remaining tests assert
/// what DESIGN-98 actually changed: the desktop panel's geometry (still
/// governed, differently, by `LayrzEndDrawer`'s fixed width) and that the
/// closed field alone keeps its own border, with no panel row left to
/// (mis)inherit it from.
void main() {
  group('LayrzComboBoxInput desktop drawer (DESIGN-98)', () {
    testWidgets('the closed field keeps its own bordered chrome, both before and while the drawer is open', (
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

      // The closed field's own chrome is the FIRST one in the tree -- while
      // the drawer is open, `BottomSheetContent`'s own search field also uses
      // `LayrzInputChrome` (see `combobox_surface.dart`), so `.first` is what
      // disambiguates the closed field's from the drawer's own.
      Container closedChromeContainer() => tester.widget<Container>(
        find.descendant(of: find.byType(LayrzInputChrome).first, matching: find.byType(Container)).first,
      );

      final closedBefore = (closedChromeContainer().decoration as BoxDecoration).border;
      expect(closedBefore, isNotNull, reason: 'the closed field must paint its own border');

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      // Post-DESIGN-98 there is no `LayrzComboBoxPanelContent` in the real
      // desktop flow at all (see the file doc) -- the drawer hosts
      // `BottomSheetContent` instead, which has its own `LayrzInputChrome`
      // for its search field, so two chromes are expected here: the closed
      // field's own and the drawer's.
      expect(find.byType(LayrzComboBoxPanelContent), findsNothing);
      expect(find.byType(LayrzInputChrome), findsNWidgets(2));

      final closedWhileOpen = (closedChromeContainer().decoration as BoxDecoration).border;
      expect(closedWhileOpen, isNotNull, reason: 'the closed field keeps its border while the drawer is open too');
    });

    testWidgets('with no caller-supplied slots, the closed field renders no invented prefix/suffix icon', (
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

      final chrome = find.byType(LayrzInputChrome).first;
      expect(find.descendant(of: chrome, matching: find.byType(Icon)), findsNothing);
    });
  });

  // DESIGN-145/Q9 parity: pinned again here (in addition to the existing
  // `combobox_input_test.dart` coverage) with an explicit width assertion, so a
  // future regression that lets the panel outgrow the anchor -- horizontally or
  // vertically -- fails loudly rather than only being caught by eye against a
  // screenshot. Mirrors the geometry-assertion style in
  // `select_input_test.dart`'s own DESIGN-145 regression group and
  // `anchored_panel_border_test.dart`.
  //
  // DESIGN-98 changes what "geometry" means here: the drawer is a fixed-width
  // (`LayrzEndDrawer.width`, 420px) right-edge panel independent of the anchor
  // field's own width, so it no longer tracks the field's width the way
  // `LayrzAnchoredPanel.matchAnchor` did. This group now pins the NEW
  // geometry contract instead of the old one.
  group('LayrzComboBoxInput panel geometry (DESIGN-98)', () {
    testWidgets('the drawer opens at a fixed width, independent of the anchor field\'s own width', (tester) async {
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

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      final drawerWidth = tester.getSize(find.byType(BottomSheetContent)).width;
      expect(drawerWidth, closeTo(LayrzEndDrawer.width, 1.0));

      final drawerRect = tester.getRect(find.byType(BottomSheetContent));
      expect(drawerRect.right, lessThanOrEqualTo(1449.0));
    });
  });
}
