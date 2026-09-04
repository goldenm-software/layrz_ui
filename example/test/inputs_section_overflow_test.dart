import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:example/src/sections/inputs/inputs_section.dart';

/// Permanent overflow regression coverage for [InputsSection] (DESIGN-157).
///
/// `_buildTile` renders each row in the list pane as a `Row` with a fixed
/// 30-logical-pixel [LayrzAvatar] plus a `Column` (widget name + category
/// [LayrzChip]) with no `Expanded`/`Flexible` wrapper around that `Column`.
/// The `Column` therefore laid out at its intrinsic width, which — for
/// longer component names such as "DateTime Range Input" — exceeds the
/// space actually available inside the list pane.
///
/// The list pane itself (`ListPanel`, `lib/src/scaffold/src/list_panel.dart`)
/// is a fixed-width `Container` (`width: 300`) with `tokens.spacing.pd1`
/// padding (6px each side) around its `Column`, and each row is wrapped in
/// a `Padding` using `tokens.spacing.pd2` (10px each side,
/// `lib/src/scaffold/src/list_panel.dart:176-177`). That leaves
/// `300 - 2*6 - 2*10 = 268` logical pixels for `_buildTile`'s own `Row` —
/// the exact width this test pins the whole [InputsSection] to, so the
/// overflow reproduces exactly as it does inside the real showroom's list
/// pane, without hand-picking an arbitrary narrow width.
///
/// Flutter reports a `RenderFlex` overflow via [FlutterError.reportError],
/// which [TestWidgetsFlutterBinding] captures into
/// [WidgetTester.takeException] instead of throwing synchronously — a test
/// that renders the tree and only checks `findsOneWidget` would pass even
/// while every row overflows and gets clipped. This test explicitly drains
/// and asserts on `tester.takeException()` after pumping, which is the only
/// way to make that failure mode visible.
void main() {
  /// The list pane's real fixed width (300) minus its own padding (2*6) and
  /// the per-row padding (2*10) — see the file-level doc comment above for
  /// the exact derivation. This is the width `_buildTile`'s `Row` actually
  /// receives inside the real showroom, not an arbitrary narrow value.
  const listPaneContentWidth = 268.0;

  Future<void> pumpInputsSection(WidgetTester tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // devicePixelRatio must be pinned before physicalSize -- otherwise the
    // ambient test devicePixelRatio (3.0) skews the physical -> logical
    // mapping and the forced width no longer lands where intended.
    tester.view.devicePixelRatio = 1.0;
    // Height is generous and irrelevant to this bug; only the width matters,
    // since InputsSection's list pane has a fixed logical width and the
    // overflow is horizontal.
    tester.view.physicalSize = const Size(1200, 900);

    await tester.pumpWidget(
      const LayrzApp(
        home: InputsSection(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'REGRESSION (DESIGN-157): the list pane tile row does not overflow at the pane\'s actual content width',
    (tester) async {
      await pumpInputsSection(tester);

      // Sanity: the section actually rendered its list tiles, so a passing
      // "no overflow" assertion below is meaningful and not vacuously true
      // because nothing was on screen.
      expect(find.text('Text Input'), findsOneWidget);

      expect(
        tester.takeException(),
        isNull,
        reason:
            'InputsSection must not report a RenderFlex overflow while pumped at its default '
            'size. If this fails, _buildTile\'s Column (widget name + category chip) is once '
            'again laying out unconstrained next to the fixed-size avatar.',
      );

      // Directly reproduces the list pane's real content width (300 total,
      // minus ListPanel's own 6px padding on each side, minus the 10px
      // per-row padding on each side -- see the file doc comment) by
      // constraining a single tile's Row to exactly that width. This is
      // the actual condition that overflowed: every tile in the pane uses
      // the same Row, so this is representative of the whole list, not a
      // cherry-picked case.
      final tileRowFinder = find.ancestor(
        of: find.text('Text Input'),
        matching: find.byType(Row),
      );
      expect(tileRowFinder, findsWidgets);

      await tester.pumpWidget(
        LayrzApp(
          home: Center(
            child: SizedBox(
              width: listPaneContentWidth,
              child: const InputsSection(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason:
            'InputsSection\'s tile Row must not overflow at the list pane\'s real content '
            'width (300 - 2*6 padding - 2*10 padding = ${listPaneContentWidth}px). Before the '
            'DESIGN-157 fix, the unconstrained name/chip Column overflowed this Row by 8px at '
            'exactly this width.',
      );
    },
  );

  testWidgets(
    'REGRESSION (DESIGN-157): every demo entry\'s tile renders without overflow at the pane content width',
    (tester) async {
      // Constrains the whole section directly to the list pane's real
      // content width so every tile -- not just the first -- lays out
      // under the exact horizontal budget that reproduced the bug.
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 2400);

      await tester.pumpWidget(
        LayrzApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: listPaneContentWidth,
              height: 2400,
              child: const InputsSection(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason:
            'No tile in InputsSection\'s list may overflow at the list pane\'s real content '
            'width, regardless of how long the demo\'s name or category text is.',
      );
    },
  );
}
