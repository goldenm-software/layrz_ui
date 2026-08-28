import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzTreeRowStyleSpec.resolve', () {
    final tokens = LayrzThemeData.light().tokens;

    test('default state (no hover, no selection, not active) uses the idle surface with a transparent outline', () {
      final style = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: false,
        isSelected: false,
        isPartiallySelected: false,
      );

      expect(style.backgroundColor, tokens.colors.sf1);
      expect(style.activeBorderColor.a, 0);
    });

    test('hovered (unselected) state uses the second surface step', () {
      final style = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: true,
        isSelected: false,
        isPartiallySelected: false,
      );

      expect(style.backgroundColor, tokens.colors.sf2);
    });

    test('selected state paints no background fill -- the checkbox alone marks selection', () {
      final style = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: false,
        isSelected: true,
        isPartiallySelected: false,
      );

      expect(style.backgroundColor, tokens.colors.sf1);
      expect(style.checkboxFillColor, tokens.colors.primary.shade500);
    });

    test('partially-selected state paints no background fill, matching the unselected background', () {
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
      expect(partial.backgroundColor, tokens.colors.sf1);
    });

    test('selected state does not override hover -- background remains driven by hover alone', () {
      final style = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: true,
        isSelected: true,
        isPartiallySelected: false,
      );

      expect(style.backgroundColor, tokens.colors.sf2);
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

    test('selected AND active compose -- outline and checkbox mark state, background stays idle', () {
      final style = LayrzTreeRowStyleSpec.resolve(
        tokens,
        isHovered: false,
        isSelected: true,
        isPartiallySelected: false,
        isActive: true,
      );

      expect(style.backgroundColor, tokens.colors.sf1);
      expect(style.activeBorderColor, tokens.colors.primary.shade500);
      expect(style.checkboxFillColor, tokens.colors.primary.shade500);
      expect(style.foregroundColor, tokens.colors.fg1);
    });

    test(
      'REGRESSION: a dark seed primary colour (lightness < 0.40) does not clamp the checkbox fill to black',
      () {
        // kPrimaryColor (#001E60) has an HSL lightness of ~0.19. The tree row's
        // selected background used to read `tokens.colors.primary.shade50`
        // directly; LayrzColorSwatch.fromColor derives shade50 by subtracting
        // 0.40 from the seed's lightness and clamping to [0.0, 1.0] -- for any
        // seed with lightness under 0.40 that clamps straight to 0.0 (fully
        // opaque black in HSL), which is exactly the solid black row bug
        // originally reported against the showroom's /tree-view page. The
        // background fill that hit this defect has since been removed
        // entirely (selection is now marked by the checkbox alone, per
        // maintainer review, DESIGN-93); this test now guards the checkbox
        // fill instead, which still resolves `primary.shade500` and remains
        // exposed to the same upstream defect if it were ever changed to
        // shade50.
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

        expect(style.backgroundColor, darkTokens.colors.sf1);
        expect(style.checkboxFillColor, isNot(const Color(0xFF000000)));
        expect(style.checkboxFillColor.a, 1);
      },
    );
  });
}
