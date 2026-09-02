import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTreeRow', () {
    guardedTestWidgets('renders its child content', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzTreeRow<String>(
          node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
          depth: 0,
          isExpanded: false,
          isLeaf: true,
          isSelected: false,
          isPartiallySelected: false,
          totalDepth: 0,
          child: const Text('Alpha'),
        ),
      );

      expect(find.text('Alpha'), findsOneWidget);
    });

    guardedTestWidgets('a leaf row renders no chevron toggle affordance', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var toggled = false;

      await pumpThemed(
        tester,
        LayrzTreeRow<String>(
          node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
          depth: 0,
          isExpanded: false,
          isLeaf: true,
          isSelected: false,
          isPartiallySelected: false,
          totalDepth: 0,
          onToggle: () => toggled = true,
          child: const Text('Alpha'),
        ),
      );

      // Even though onToggle is technically supplied here, isLeaf: true is
      // the contract a leaf row is built under in tree_sliver_view.dart
      // (onToggle is always null there for a leaf) — this row still must not
      // expose a tappable chevron for a leaf. There is no chevron icon to tap.
      expect(find.byType(AnimatedRotation), findsNothing);
      expect(toggled, isFalse);
    });

    guardedTestWidgets('a parent row renders a tappable chevron that calls onToggle', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var toggled = false;

      await pumpThemed(
        tester,
        LayrzTreeRow<String>(
          node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
          depth: 0,
          isExpanded: false,
          isLeaf: false,
          isSelected: false,
          isPartiallySelected: false,
          totalDepth: 1,
          onToggle: () => toggled = true,
          child: const Text('Alpha'),
        ),
      );

      expect(find.byType(AnimatedRotation), findsOneWidget);

      await tester.tap(find.byType(AnimatedRotation));
      await tester.pump();

      expect(toggled, isTrue);
    });

    guardedTestWidgets('no checkbox affordance and no selected-state semantics when onSelect is null', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzTreeRow<String>(
            node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
            depth: 0,
            isExpanded: false,
            isLeaf: true,
            isSelected: false,
            isPartiallySelected: false,
            totalDepth: 0,
            child: const Text('Alpha'),
          ),
        );

        // hasSelectedState defaults to false in matchesSemantics: with no
        // onSelect, the row must carry no selection semantics at all, not
        // merely report "not selected".
        expect(tester.getSemantics(find.byType(LayrzTreeRow<String>)), matchesSemantics());
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a checkbox affordance appears and toggles selection when onSelect is provided', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var selected = false;

      await pumpThemed(
        tester,
        LayrzTreeRow<String>(
          node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
          depth: 0,
          isExpanded: false,
          isLeaf: true,
          isSelected: false,
          isPartiallySelected: false,
          totalDepth: 0,
          onSelect: () => selected = true,
          child: const Text('Alpha'),
        ),
      );

      // The checkbox affordance is the only additional LayrzTappable beyond
      // the (absent, since isLeaf) chevron, so a single tap on it is
      // unambiguous here.
      await tester.tap(find.byType(LayrzTappable));
      await tester.pump();

      expect(selected, isTrue);
    });

    guardedTestWidgets('indentation grows the row width used by deeper nodes', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzTreeRow<String>(
          node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
          depth: 3,
          isExpanded: false,
          isLeaf: true,
          isSelected: false,
          isPartiallySelected: false,
          totalDepth: 3,
          child: const Text('Alpha'),
        ),
      );

      final guide = tester.widget<LayrzTreeIndentGuide>(find.byType(LayrzTreeIndentGuide));
      expect(guide.depth, 3);
    });

    guardedTestWidgets('an unselected row renders neither the check nor the minus checkbox glyph', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzTreeRow<String>(
          node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
          depth: 0,
          isExpanded: false,
          isLeaf: true,
          isSelected: false,
          isPartiallySelected: false,
          totalDepth: 0,
          onSelect: () {},
          child: const Text('Alpha'),
        ),
      );

      expect(find.byIcon(MdiIcons.check), findsNothing);
      expect(find.byIcon(MdiIcons.minus), findsNothing);
    });

    guardedTestWidgets('a fully-selected row renders the check glyph and not the minus glyph', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzTreeRow<String>(
          node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
          depth: 0,
          isExpanded: false,
          isLeaf: true,
          isSelected: true,
          isPartiallySelected: false,
          totalDepth: 0,
          onSelect: () {},
          child: const Text('Alpha'),
        ),
      );

      expect(find.byIcon(MdiIcons.check), findsOneWidget);
      expect(find.byIcon(MdiIcons.minus), findsNothing);
    });

    guardedTestWidgets('a partially-selected row renders the minus glyph and not the check glyph', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzTreeRow<String>(
          node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
          depth: 0,
          isExpanded: false,
          isLeaf: true,
          isSelected: false,
          isPartiallySelected: true,
          totalDepth: 0,
          onSelect: () {},
          child: const Text('Alpha'),
        ),
      );

      expect(find.byIcon(MdiIcons.minus), findsOneWidget);
      expect(find.byIcon(MdiIcons.check), findsNothing);
    });

    guardedTestWidgets('isActive: false paints a fully transparent outline and carries no focus semantics', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzTreeRow<String>(
            node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
            depth: 0,
            isExpanded: false,
            isLeaf: true,
            isSelected: false,
            isPartiallySelected: false,
            totalDepth: 0,
            child: const Text('Alpha'),
          ),
        );

        final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
        final decoration = decoratedBox.decoration as BoxDecoration;
        expect((decoration.border as Border).top.color.a, 0);

        // isFocused/isFocusable both default to false in matchesSemantics: an
        // inactive row must carry no focus concept at all -- not merely "not
        // focused" -- exactly mirroring the isSelected/isFocusable trap this
        // same pattern already avoids for selection (Semantics.focused: false
        // would still set isFocusable, which is why the row passes `null`
        // instead when inactive).
        expect(tester.getSemantics(find.byType(LayrzTreeRow<String>)), matchesSemantics());
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('isActive: true paints a visible outline and announces focused semantics', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzTreeRow<String>(
            node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
            depth: 0,
            isExpanded: false,
            isLeaf: true,
            isSelected: false,
            isPartiallySelected: false,
            totalDepth: 0,
            isActive: true,
            child: const Text('Alpha'),
          ),
        );

        final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
        final decoration = decoratedBox.decoration as BoxDecoration;
        // The active border must actually be visible (non-zero alpha) -- this
        // is what would fail if the active-row treatment were ever removed
        // and isActive silently stopped changing anything.
        expect(decoration.border, isNotNull);
        expect((decoration.border as Border).top.color.a, greaterThan(0));

        expect(
          tester.getSemantics(find.byType(LayrzTreeRow<String>)),
          matchesSemantics(isFocused: true, isFocusable: true),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('an unselected, inactive, idle row is genuinely transparent -- never a black background', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzTreeRow<String>(
          node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
          depth: 0,
          isExpanded: false,
          isLeaf: true,
          isSelected: false,
          isPartiallySelected: false,
          totalDepth: 0,
          child: const Text('Alpha'),
        ),
      );

      // DESIGN-171 (maintainer ruling): resting paints nothing at all, so an
      // enclosing container's own surface (and its rounded border) shows
      // through with no seam, rather than an opaque colour that merely
      // happens to match most containers.
      final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.color, const Color(0x00000000));
      expect(decoration.color, isNot(const Color(0xFF000000)));
    });

    guardedTestWidgets(
      'a selected row paints a visible translucent primary tint -- the checkbox is no longer the sole marker',
      (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzTreeRow<String>(
            node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
            depth: 0,
            isExpanded: false,
            isLeaf: true,
            isSelected: true,
            isPartiallySelected: false,
            totalDepth: 0,
            onSelect: () {},
            child: const Text('Alpha'),
          ),
        );

        final tokens = LayrzThemeData.light().tokens;
        // With onSelect provided, the checkbox affordance paints a second,
        // unrelated DecoratedBox -- so a plain find.byType(DecoratedBox) is
        // ambiguous here. The row's own DecoratedBox is the outermost one in
        // its subtree (it wraps the checkbox, not the reverse), so it is the
        // first match in the descendant search's tree order.
        final decoratedBox = tester.widget<DecoratedBox>(
          find.descendant(of: find.byType(LayrzTreeRow<String>), matching: find.byType(DecoratedBox)).first,
        );
        final decoration = decoratedBox.decoration as BoxDecoration;

        expect(decoration.color, tokens.colors.primary.withValues(alpha: 0.12));

        // Text stays legible against the translucent tint.
        final defaultTextStyle = tester.widget<DefaultTextStyle>(
          find.descendant(of: find.byType(LayrzTreeRow<String>), matching: find.byType(DefaultTextStyle)).first,
        );
        expect(defaultTextStyle.style.color, tokens.colors.fg1);
      },
    );

    guardedTestWidgets('selected AND active together: outline marks focus, checkbox and tint mark selection', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzTreeRow<String>(
          node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
          depth: 0,
          isExpanded: false,
          isLeaf: true,
          isSelected: true,
          isPartiallySelected: false,
          totalDepth: 0,
          isActive: true,
          onSelect: () {},
          child: const Text('Alpha'),
        ),
      );

      final tokens = LayrzThemeData.light().tokens;
      // See the previous test for why this can't be a plain
      // find.byType(DecoratedBox): the checkbox affordance paints its own.
      final decoratedBox = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(LayrzTreeRow<String>), matching: find.byType(DecoratedBox)).first,
      );
      final decoration = decoratedBox.decoration as BoxDecoration;

      expect(decoration.color, tokens.colors.primary.withValues(alpha: 0.12));
      expect((decoration.border as Border).top.color, tokens.colors.primary.shade500);

      // The checkbox itself is still a visual marker of selection: filled
      // with the primary colour and painting the check glyph.
      expect(find.byIcon(MdiIcons.check), findsOneWidget);
    });

    guardedTestWidgets('hovering paints a visible tint composed over the transparent resting base', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzTreeRow<String>(
          node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
          depth: 0,
          isExpanded: false,
          isLeaf: true,
          isSelected: false,
          isPartiallySelected: false,
          totalDepth: 0,
          child: const Text('Alpha'),
        ),
      );

      final tokens = LayrzThemeData.light().tokens;
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(LayrzTreeRow<String>)));
      await tester.pump();

      final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = decoratedBox.decoration as BoxDecoration;
      final expected = Color.alphaBlend(tokens.colors.sf3.withValues(alpha: 0.6), const Color(0x00000000));
      expect(decoration.color, expected);
      expect(decoration.color!.a, greaterThan(0));
    });

    guardedTestWidgets('the row fill is inset from the row\'s own outer edge in every state, never full-bleed', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Wrap the row exactly like the showroom wraps LayrzTreeView: a
      // rounded-border container. This reproduces the maintainer's
      // photographed setup at the single-row level -- the fill must never
      // reach the container's edge (let alone its rounded corner) regardless
      // of the state painting it, since the row has no way to know the
      // container's radius. Hover is the state the maintainer's screenshot
      // actually showed bleeding, so it is asserted here, not resting (which
      // paints nothing at all and could never bleed anyway).
      await pumpThemed(
        tester,
        DecoratedBox(
          decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(12)),
          child: LayrzTreeRow<String>(
            node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
            depth: 0,
            isExpanded: false,
            isLeaf: true,
            isSelected: false,
            isPartiallySelected: false,
            totalDepth: 0,
            child: const Text('Alpha'),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(LayrzTreeRow<String>)));
      await tester.pump();

      final rowRect = tester.getRect(find.byType(LayrzTreeRow<String>));
      final fillRect = tester.getRect(find.byType(DecoratedBox).last);

      // Strictly inside on both left and right -- not merely "no wider than",
      // which a fill sized exactly to the row's own bounds would also
      // satisfy. A container border of any radius drawn at rowRect's edges
      // can never be crossed by a rect that never reaches those edges.
      expect(fillRect.left, greaterThan(rowRect.left));
      expect(fillRect.right, lessThan(rowRect.right));
    });

    guardedTestWidgets(
      'the active outline is the only geometry-neutral difference -- row size is identical either way',
      (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzTreeRow<String>(
            node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
            depth: 0,
            isExpanded: false,
            isLeaf: true,
            isSelected: false,
            isPartiallySelected: false,
            totalDepth: 0,
            child: const Text('Alpha'),
          ),
        );
        final inactiveSize = tester.getSize(find.byType(LayrzTreeRow<String>));

        await pumpThemed(
          tester,
          LayrzTreeRow<String>(
            node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
            depth: 0,
            isExpanded: false,
            isLeaf: true,
            isSelected: false,
            isPartiallySelected: false,
            totalDepth: 0,
            isActive: true,
            child: const Text('Alpha'),
          ),
        );
        final activeSize = tester.getSize(find.byType(LayrzTreeRow<String>));

        // Per D15: the active-row outline changes colour only. If it grew
        // the row (e.g. via border width instead of colour), this equality
        // would fail.
        expect(activeSize, inactiveSize);
      },
    );
  });
}
