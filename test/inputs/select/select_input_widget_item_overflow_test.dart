import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

/// Regression coverage for [LayrzSelectInput]'s closed (idle) field overflowing
/// when the selected item's `child` is a widget wider than the field — e.g. a
/// `Row` with an icon and an unbounded `Text`.
///
/// The closed field overlays `selectedItem.child` on the editable field via a
/// `Stack`, which passes LOOSE constraints, so a `Row` with an unbounded `Text`
/// used to lay out at its intrinsic width and overflow horizontally. The fix
/// bounds the overlay to the field width (`Positioned.fill` + `ClipRect`), so a
/// wide child is clipped to the field rather than throwing a `RenderFlex`
/// overflow. These tests assert on the absence of a render exception, not on
/// reading the source.
void main() {
  group('LayrzSelectInput closed field — wide widget item does not overflow', () {
    // The selected item's presentation is a Row with an icon and a long label,
    // the exact shape that previously overflowed.
    List<LayrzSelectItem<String>> items() => [
      LayrzSelectItem<String>(
        value: 'a',
        searchableStrings: const {'Alpha'},
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(MdiIcons.truckOutline, size: 16),
            const SizedBox(width: 4),
            const Text('A very long selected item label that easily exceeds a narrow field width'),
          ],
        ),
      ),
    ];

    testWidgets('a narrow field with a wide Row+text selected item renders without overflow', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 800);

      await pumpThemedApp(
        tester,
        Center(
          // Constrain the field to a narrow width so the wide selected-item Row
          // would overflow it if unbounded.
          child: SizedBox(
            width: 180,
            child: LayrzSelectInput<String>(
              itemExtent: 40,
              items: items(),
              value: 'a',
              labelText: 'Vehicle',
            ),
          ),
        ),
      );

      // The selected item's Row is shown in the closed field; it must NOT
      // overflow (no RenderFlex overflow exception).
      expect(tester.takeException(), isNull);
      // The overlaid child is present.
      expect(find.byIcon(MdiIcons.truckOutline), findsOneWidget);
    });

    testWidgets('the wide selected item is clipped to the field (ClipRect present)', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 800);

      await pumpThemedApp(
        tester,
        Center(
          child: SizedBox(
            width: 180,
            child: LayrzSelectInput<String>(
              itemExtent: 40,
              items: items(),
              value: 'a',
              labelText: 'Vehicle',
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      // The overlay bounds the selected item to the field via a ClipRect, so a
      // wide child paints clipped rather than overflowing.
      expect(find.byType(ClipRect), findsWidgets);
    });
  });
}
