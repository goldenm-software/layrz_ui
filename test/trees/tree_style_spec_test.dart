import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzTreeRowStyleSpec.resolve', () {
    final tokens = LayrzThemeData.light().tokens;

    test('default state (no hover, no press, no selection, not active) is genuinely transparent', () {
      final style = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: false,
        isSelected: false,
        isPartiallySelected: false,
      );

      // Exact transparent black, not merely "some colour with low alpha" --
      // DESIGN-171 (maintainer ruling): the resting fill must let an
      // enclosing container's own surface show through with no seam at all,
      // which only a=0 guarantees regardless of what that container paints.
      expect(style.backgroundColor, const Color(0x00000000));
      expect(style.backgroundColor.a, 0);
      expect(style.activeBorderColor.a, 0);
    });

    test('hovered (unselected, not pressed) composes the hover tint over the transparent base', () {
      final style = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: true,
        isSelected: false,
        isPartiallySelected: false,
      );

      final expected = Color.alphaBlend(
        tokens.colors.sf3.withValues(alpha: 0.6),
        const Color(0x00000000),
      );
      expect(style.backgroundColor, expected);
      // Composing over transparent must still resolve to a visible (opaque
      // alpha) tint -- this is the "hover feedback must remain clearly
      // visible" half of the ruling; only the *resting* fill is transparent.
      expect(style.backgroundColor.a, greaterThan(0));
    });

    test('pressed (unselected, unhovered) composes the pressed tint over the transparent base', () {
      final style = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: false,
        isSelected: false,
        isPartiallySelected: false,
        isPressed: true,
      );

      final expected = Color.alphaBlend(
        tokens.colors.sf4.withValues(alpha: 0.72),
        const Color(0x00000000),
      );
      expect(style.backgroundColor, expected);
      expect(style.backgroundColor.a, greaterThan(0));
    });

    test('pressed takes priority over hover when both are true', () {
      final pressedAndHovered = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: true,
        isSelected: false,
        isPartiallySelected: false,
        isPressed: true,
      );
      final pressedOnly = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: false,
        isSelected: false,
        isPartiallySelected: false,
        isPressed: true,
      );

      expect(pressedAndHovered.backgroundColor, pressedOnly.backgroundColor);
    });

    test('selected state paints a visible translucent primary tint, not primary.shade50', () {
      final style = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: false,
        isSelected: true,
        isPartiallySelected: false,
      );

      expect(style.backgroundColor, tokens.colors.primary.withValues(alpha: 0.12));
      expect(style.backgroundColor.a, greaterThan(0));
      expect(style.checkboxFillColor, tokens.colors.primary.shade500);
    });

    test('partially-selected state paints the same tint as fully-selected', () {
      final selected = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: false,
        isSelected: true,
        isPartiallySelected: false,
      );
      final partial = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: false,
        isSelected: false,
        isPartiallySelected: true,
      );

      expect(partial.backgroundColor, selected.backgroundColor);
      expect(partial.backgroundColor, tokens.colors.primary.withValues(alpha: 0.12));
    });

    test('hover composes on top of the selected tint rather than replacing it', () {
      final selectedOnly = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: false,
        isSelected: true,
        isPartiallySelected: false,
      );
      final selectedAndHovered = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: true,
        isSelected: true,
        isPartiallySelected: false,
      );

      final expected = Color.alphaBlend(
        tokens.colors.sf3.withValues(alpha: 0.6),
        tokens.colors.primary.withValues(alpha: 0.12),
      );
      expect(selectedAndHovered.backgroundColor, expected);
      // Composed, not replaced: hovering a selected row must not fall back to
      // the same fill an unselected hovered row gets, or the two would be
      // visually indistinguishable and "selected" would read as lost.
      expect(selectedAndHovered.backgroundColor, isNot(selectedOnly.backgroundColor));
      final unselectedHovered = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: true,
        isSelected: false,
        isPartiallySelected: false,
      );
      expect(selectedAndHovered.backgroundColor, isNot(unselectedHovered.backgroundColor));
    });

    test('press composes on top of the selected tint rather than replacing it', () {
      final selectedAndPressed = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: false,
        isSelected: true,
        isPartiallySelected: false,
        isPressed: true,
      );

      final expected = Color.alphaBlend(
        tokens.colors.sf4.withValues(alpha: 0.72),
        tokens.colors.primary.withValues(alpha: 0.12),
      );
      expect(selectedAndPressed.backgroundColor, expected);
    });

    test('isActive paints a visible primary-coloured outline while leaving the background untouched', () {
      final active = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: false,
        isSelected: false,
        isPartiallySelected: false,
        isActive: true,
      );
      final inactive = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: false,
        isSelected: false,
        isPartiallySelected: false,
      );

      expect(active.activeBorderColor, tokens.colors.primary.shade500);
      expect(active.backgroundColor, inactive.backgroundColor);
    });

    test('selected AND active compose -- outline, checkbox and tint all mark state together', () {
      final style = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: false,
        isSelected: true,
        isPartiallySelected: false,
        isActive: true,
      );

      expect(style.backgroundColor, tokens.colors.primary.withValues(alpha: 0.12));
      expect(style.activeBorderColor, tokens.colors.primary.shade500);
      expect(style.checkboxFillColor, tokens.colors.primary.shade500);
      expect(style.foregroundColor, tokens.colors.fg1);
    });

    test(
      'REGRESSION: a dark seed primary colour (lightness < 0.40) does not clamp the checkbox fill to black',
      () {
        // kPrimaryColor (#001E60) has an HSL lightness of ~0.19. The tree
        // row's selected background used to read `tokens.colors.primary.shade50`
        // directly; LayrzColorSwatch.fromColor derives shade50 by subtracting
        // 0.40 from the seed's lightness and clamping to [0.0, 1.0] -- for any
        // seed with lightness under 0.40 that clamps straight to 0.0 (fully
        // opaque black in HSL), which is exactly the solid black row bug
        // originally reported against the showroom's /tree-view page. The
        // row's own background fill sidesteps this by applying alpha to the
        // seed colour directly (`primary.withValues(alpha: ...)`, see
        // [LayrzTreeRowStyleSpec.resolve]) rather than reading a derived
        // shade, so it can never clamp to black either -- this test guards
        // both that and the checkbox fill, which still resolves
        // `primary.shade500` and remains exposed to the same upstream defect
        // if it were ever changed to shade50.
        final darkTokens = LayrzThemeData.light(primaryColor: const Color(0xFF001E60)).tokens;
        expect(HSLColor.fromColor(darkTokens.colors.primary).lightness, lessThan(0.40));
        // Confirms the underlying swatch defect is still present upstream --
        // this test would stop proving anything if shade50 were fixed instead
        // and this assertion silently started failing.
        expect(darkTokens.colors.primary.shade50, const Color(0xFF000000));

        final style = LayrzTreeRowStyleSpec.resolve(
          darkTokens,
          isHovered: false,
          isSelected: true,
          isPartiallySelected: false,
        );

        expect(style.backgroundColor, isNot(const Color(0xFF000000)));
        expect(style.backgroundColor, darkTokens.colors.primary.withValues(alpha: 0.12));
        expect(style.checkboxFillColor, isNot(const Color(0xFF000000)));
        expect(style.checkboxFillColor.a, 1);
      },
    );
  });
}
