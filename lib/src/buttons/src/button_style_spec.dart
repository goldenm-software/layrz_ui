import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'button_style.dart';

/// Represents the interaction state rung on the fill ladder.
///
/// Each button style starts at a different rung and climbs the same ladder
/// as the user interacts with it (transparent → tonal → solid). This enum
/// simplifies the state resolution logic by expressing the ladder once,
/// with each style declaring its rungs rather than branches in state functions.
enum _ButtonLadderRung {
  /// Default, idle state — the starting rung for the style.
  defaultState,

  /// Hovered or focused state — one step up the ladder.
  hovered,

  /// Pressed state — the top of the ladder.
  pressed,
}

/// Immutable specification of visual properties for a [LayrzButton] in a given state.
///
/// A [LayrzButtonStyleSpec] holds only paint properties: colors, borders, and shadows.
/// It is computed by [resolve] from a style, state set, and tokens.
@immutable
class LayrzButtonStyleSpec {
  /// The fill color of the button background.
  final Color backgroundColor;

  /// The color of the button border.
  final Color borderColor;

  /// The width of the button border in logical pixels.
  final double borderWidth;

  /// The color of the button content (icon and label text).
  final Color contentColor;

  /// The drop shadows applied to the button.
  final List<BoxShadow> shadows;

  /// Creates a new [LayrzButtonStyleSpec].
  const LayrzButtonStyleSpec({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.contentColor,
    required this.shadows,
  });

  /// Returns a copy of this spec with the given fields replaced.
  LayrzButtonStyleSpec copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    Color? contentColor,
    List<BoxShadow>? shadows,
  }) {
    return LayrzButtonStyleSpec(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      contentColor: contentColor ?? this.contentColor,
      shadows: shadows ?? this.shadows,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzButtonStyleSpec &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          contentColor == other.contentColor &&
          shadows == other.shadows;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    contentColor,
    Object.hashAll(shadows),
  );

  /// Resolves a [LayrzButtonStyleSpec] from a style, state set, tokens, and accent color.
  ///
  /// This method computes the paint specification for a button in the given state using
  /// a four-state model with a fill ladder:
  /// - **State precedence**: disabled > pressed > hovered/focused > default
  /// - **Four states**:
  ///   1. Default (idle)
  ///   2. Hovered or focused (pointer over, or keyboard focus)
  ///   3. Pressed (pointer/finger held down)
  ///   4. Disabled (non-interactive: disabled, loading, or in cooldown)
  ///
  /// - **Fill ladder** (style-dependent):
  ///   - `text` / `fab`: transparent → tonal → tonal (stronger)
  ///   - `outlined` / `outlinedFab`: transparent + border → tonal + border → solid + border
  ///   - `outlinedTonal` / `outlinedTonalFab`: tonal + border → stronger tonal + border → solid + border
  ///   - `filledTonal` / `filledTonalFab`: tonal → stronger tonal → solid
  ///   - `filled` / `filledFab`: solid → solid (color shift) → solid (stronger shift)
  ///   - `elevated` / `elevatedFab`: solid + shadow → solid + bigger shadow → solid (no shadow)
  ///
  /// - **Border invariant**: Outlined pairs keep `borderColor` **identical** across all states
  /// - **Shadow invariant**: Only `elevated` changes shadows (grows on hover, disappears on press);
  ///   `filled` never gains shadows; all others have fixed shadows
  ///
  /// [accent] is the primary color for the button variant (brand color or semantic).
  /// Geometry (height, width, padding, borderWidth) is byte-identical across states
  /// and must not be affected by this method (per decision D15).
  static LayrzButtonStyleSpec resolve({
    required LayrzButtonStyle style,
    required Set<WidgetState> states,
    required LayrzTokens tokens,
    required Color accent,
  }) {
    final isDisabled = states.contains(WidgetState.disabled);

    // Base spec computed from style family (unaffected by state).
    final baseSpec = _baseSpec(style: style, accent: accent, tokens: tokens);

    // If disabled, override all colors and clear shadows.
    if (isDisabled) {
      return LayrzButtonStyleSpec(
        backgroundColor: _disabledBackground(baseSpec, tokens),
        borderColor: style.hasBorder ? tokens.colors.fg3 : const Color(0x00000000),
        borderWidth: baseSpec.borderWidth,
        contentColor: tokens.colors.fg3,
        shadows: const [],
      );
    }

    // Determine which rung of the fill ladder to apply based on interaction state.
    // Precedence: pressed > hovered/focused > default.
    final rung = _determineRung(states);

    // Apply the rung deltas.
    return _applyRung(baseSpec, style, tokens, accent, rung);
  }

  /// Determines which rung of the fill ladder to apply based on interaction state.
  ///
  /// **Precedence**: pressed > hovered/focused > default.
  ///
  /// Focus is treated identically to hover: both map to the same visual appearance.
  /// This satisfies WCAG 2.4.7 (Focus Visible, AA) without adding a fifth state.
  static _ButtonLadderRung _determineRung(Set<WidgetState> states) {
    if (states.contains(WidgetState.pressed)) {
      return _ButtonLadderRung.pressed;
    } else if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
      return _ButtonLadderRung.hovered;
    }
    return _ButtonLadderRung.defaultState;
  }

  /// Computes the base [LayrzButtonStyleSpec] for a given style (unaffected by state).
  static LayrzButtonStyleSpec _baseSpec({
    required LayrzButtonStyle style,
    required Color accent,
    required LayrzTokens tokens,
  }) {
    final contrastColor = accent.contrastColor;

    switch (style) {
      case LayrzButtonStyle.elevated || LayrzButtonStyle.elevatedFab:
        return LayrzButtonStyleSpec(
          backgroundColor: accent,
          borderColor: const Color(0x00000000),
          borderWidth: tokens.border.base,
          contentColor: contrastColor,
          // Small components use the compact shadow ramp rather than elevation.
          // Compact shadows have greater vertical drop and higher opacity so they
          // provide clear separation at small sizes where elevation's faint offset
          // shadow would dissolve into the surface.
          shadows: tokens.shadow.compact1,
        );

      case LayrzButtonStyle.outlined || LayrzButtonStyle.outlinedFab:
        return LayrzButtonStyleSpec(
          backgroundColor: const Color(0x00000000),
          borderColor: accent,
          borderWidth: tokens.border.base,
          contentColor: accent,
          shadows: const [],
        );

      case LayrzButtonStyle.outlinedTonal || LayrzButtonStyle.outlinedTonalFab:
        return LayrzButtonStyleSpec(
          backgroundColor: accent.withOpacityValue(kLayrzButtonOutlinedTonalOpacity),
          borderColor: accent,
          borderWidth: tokens.border.base,
          contentColor: accent,
          shadows: const [],
        );
    }
  }

  /// Computes background color for disabled state.
  ///
  /// Solid backgrounds (filled, elevated) fade to [fg3] with reduced opacity.
  /// Tonal backgrounds retain the tonal opacity structure but use [fg3].
  static Color _disabledBackground(
    LayrzButtonStyleSpec baseSpec,
    LayrzTokens tokens,
  ) {
    // If background is fully transparent, keep it transparent (outlined buttons).
    if (baseSpec.backgroundColor.a == 0.0) {
      return const Color(0x00000000);
    }

    // If background has non-zero opacity, it's either solid or tonal.
    // Treat as solid fill and fade to fg3.
    return tokens.colors.fg3.withOpacityValue(0.4);
  }

  /// Applies the given rung of the fill ladder to the base spec.
  ///
  /// Each style has three rungs on the fill ladder:
  /// - **defaultState**: the base spec as-is
  /// - **hovered**: one step up the ladder (more opaque or more colored)
  /// - **pressed**: the top of the ladder (most opaque or most colored)
  ///
  /// The ladder is expressed per-style via switch logic that computes the
  /// appropriate fill, border, and shadow for each rung. This consolidates
  /// all state-dependent transformations in one place, ensuring adding a
  /// new style requires declaring its rungs once, not editing multiple branches.
  ///
  /// When a style's background reaches fully opaque (α = 1.0), the content color
  /// must change to ensure readability. For tonal and outlined styles that reach
  /// solid at the pressed rung, contentColor becomes [accent.contrastColor].
  static LayrzButtonStyleSpec _applyRung(
    LayrzButtonStyleSpec baseSpec,
    LayrzButtonStyle style,
    LayrzTokens tokens,
    Color accent,
    _ButtonLadderRung rung,
  ) {
    // Default rung returns the base spec unmodified.
    if (rung == _ButtonLadderRung.defaultState) {
      return baseSpec;
    }

    // Hovered/pressed lerp factors for filled/elevated styles.
    const hoveredLerpFactor = 0.18;
    const pressedLerpFactor = 0.34;

    final contentColor = baseSpec.contentColor;
    final contrastColor = accent.contrastColor;

    switch (style) {
      // elevated / elevatedFab: solid + shadow → solid + bigger shadow → solid (no shadow)
      case LayrzButtonStyle.elevated || LayrzButtonStyle.elevatedFab:
        final lerpFactor = rung == _ButtonLadderRung.hovered ? hoveredLerpFactor : pressedLerpFactor;
        final backgroundColor = Color.lerp(baseSpec.backgroundColor, contentColor, lerpFactor)!;
        final List<BoxShadow> shadows = rung == _ButtonLadderRung.pressed
            ? const []
            : rung == _ButtonLadderRung.hovered
            ? tokens.shadow.compact2
            : baseSpec.shadows;
        return baseSpec.copyWith(
          backgroundColor: backgroundColor,
          shadows: shadows,
        );

      // outlined / outlinedFab: transparent + border → tonal + border → solid + border
      case LayrzButtonStyle.outlined || LayrzButtonStyle.outlinedFab:
        final opacity = rung == _ButtonLadderRung.hovered
            ? kLayrzButtonOutlinedHoveredOpacity
            : 1.0; // Pressed reaches solid
        final backgroundColor = accent.withOpacityValue(opacity);
        // At pressed rung, content color becomes contrast (avoid accent-on-accent).
        final actualContentColor = rung == _ButtonLadderRung.pressed ? contrastColor : contentColor;
        return baseSpec.copyWith(
          backgroundColor: backgroundColor,
          contentColor: actualContentColor,
        );

      // outlinedTonal / outlinedTonalFab: tonal + border → tonal (stronger) + border → solid + border
      case LayrzButtonStyle.outlinedTonal || LayrzButtonStyle.outlinedTonalFab:
        final opacity = rung == _ButtonLadderRung.hovered
            ? kLayrzButtonOutlinedTonalOpacity + kLayrzButtonOutlinedTonalHoveredDelta
            : kLayrzButtonOutlinedTonalOpacity + kLayrzButtonOutlinedTonalPressedDelta;
        final cappedOpacity = opacity.clamp(0.0, 1.0);
        final backgroundColor = accent.withOpacityValue(cappedOpacity);
        // At pressed rung, content color becomes contrast (avoid accent-on-accent).
        final actualContentColor = rung == _ButtonLadderRung.pressed && cappedOpacity >= 1.0
            ? contrastColor
            : contentColor;
        return baseSpec.copyWith(
          backgroundColor: backgroundColor,
          contentColor: actualContentColor,
        );
    }
  }
}
