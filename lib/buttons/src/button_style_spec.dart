import 'package:flutter/widgets.dart';

import 'package:layrz_ui/constants/constants.dart';
import 'package:layrz_ui/extensions/extensions.dart';
import 'package:layrz_ui/tokens/tokens.dart';

import 'button_style.dart';

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
  /// This method computes the paint specification for a button in the given state:
  /// - **disabled** wins over all other states: content becomes [fg3], solid backgrounds
  ///   fade to [fg3] with reduced opacity, tonal backgrounds retain tonal opacity but
  ///   with [fg3], borders become [fg3], shadows become empty.
  /// - **pressed**: solid backgrounds lerp toward content color by ~16%; tonal/outlined
  ///   gain roughly one extra tonal opacity of fill; shadows disappear on elevated.
  /// - **hovered**: same channels as pressed, roughly half the strength.
  /// - **default**: unmodified base colors.
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
    final isPressed = states.contains(WidgetState.pressed);
    final isHovered = states.contains(WidgetState.hovered);

    // Base spec computed from style family (unaffected by state).
    final baseSpec = _baseSpec(style: style, accent: accent, tokens: tokens);

    // If disabled, override all colors.
    if (isDisabled) {
      return LayrzButtonStyleSpec(
        backgroundColor: _disabledBackground(baseSpec, tokens),
        borderColor: style.hasBorder ? tokens.colors.fg3 : const Color(0x00000000),
        borderWidth: baseSpec.borderWidth,
        contentColor: tokens.colors.fg3,
        shadows: const [],
      );
    }

    // Apply pressed/hovered state deltas.
    if (isPressed) {
      return _applyPressedState(baseSpec, style, tokens, accent);
    } else if (isHovered) {
      return _applyHoveredState(baseSpec, style, tokens, accent);
    }

    // Default state — return base spec unmodified.
    return baseSpec;
  }

  /// Computes the base [LayrzButtonStyleSpec] for a given style (unaffected by state).
  static LayrzButtonStyleSpec _baseSpec({
    required LayrzButtonStyle style,
    required Color accent,
    required LayrzTokens tokens,
  }) {
    final contrastColor = accent.contrastColor;

    switch (style) {
      case LayrzButtonStyle.filled || LayrzButtonStyle.filledFab:
        return LayrzButtonStyleSpec(
          backgroundColor: accent,
          borderColor: const Color(0x00000000),
          borderWidth: tokens.border.base,
          contentColor: contrastColor,
          shadows: const [],
        );

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

      case LayrzButtonStyle.filledTonal || LayrzButtonStyle.filledTonalFab:
        return LayrzButtonStyleSpec(
          backgroundColor: accent.withOpacityValue(tokens.colors.tonalOpacity),
          borderColor: const Color(0x00000000),
          borderWidth: tokens.border.base,
          contentColor: accent,
          shadows: const [],
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

  /// Applies pressed state deltas to the base spec.
  static LayrzButtonStyleSpec _applyPressedState(
    LayrzButtonStyleSpec baseSpec,
    LayrzButtonStyle style,
    LayrzTokens tokens,
    Color accent,
  ) {
    // Pressed state uses ~16% lerp factor toward content.
    const lerpFactor = 0.16;
    const pressedTonalExtraOpacity = 0.2;
    const plainOutlinedPressedOpacity = 0.16;

    var backgroundColor = baseSpec.backgroundColor;
    var contentColor = baseSpec.contentColor;
    var borderColor = baseSpec.borderColor;
    List<BoxShadow> shadows = baseSpec.shadows;

    if (style.hasShadow) {
      // Elevated loses shadow on press.
      shadows = const [];
    }

    if (baseSpec.backgroundColor.a > 0.0) {
      // Solid or tonal background — lerp toward content.
      backgroundColor = Color.lerp(
        baseSpec.backgroundColor,
        contentColor,
        lerpFactor,
      )!;
    } else if (style.hasBorder && !style.isTonal) {
      // Outlined (non-tonal) gets a tonal fill on press.
      backgroundColor = accent.withOpacityValue(plainOutlinedPressedOpacity);
    }

    if (style.isTonal && style.hasBorder) {
      // Outlined tonal gains extra opacity on press.
      backgroundColor = accent.withOpacityValue(
        kLayrzButtonOutlinedTonalOpacity + pressedTonalExtraOpacity,
      );
    }

    // Border color may change if style uses tonal fill.
    if (style.hasBorder) {
      borderColor = baseSpec.borderColor;
    }

    return LayrzButtonStyleSpec(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: baseSpec.borderWidth,
      contentColor: contentColor,
      shadows: shadows,
    );
  }

  /// Applies hovered state deltas to the base spec.
  ///
  /// Hovered uses the same channels as pressed but at roughly half strength.
  static LayrzButtonStyleSpec _applyHoveredState(
    LayrzButtonStyleSpec baseSpec,
    LayrzButtonStyle style,
    LayrzTokens tokens,
    Color accent,
  ) {
    // Hovered state uses ~8% lerp factor (half of pressed's 16%).
    const lerpFactor = 0.08;
    const hoveredTonalExtraOpacity = 0.1;
    const plainOutlinedHoveredOpacity = 0.08;

    var backgroundColor = baseSpec.backgroundColor;
    var contentColor = baseSpec.contentColor;
    var borderColor = baseSpec.borderColor;

    if (baseSpec.backgroundColor.a > 0.0) {
      // Solid or tonal background — lerp toward content (lighter).
      backgroundColor = Color.lerp(
        baseSpec.backgroundColor,
        contentColor,
        lerpFactor,
      )!;
    } else if (style.hasBorder && !style.isTonal) {
      // Outlined (non-tonal) gets a tonal fill on hover.
      backgroundColor = accent.withOpacityValue(plainOutlinedHoveredOpacity);
    }

    if (style.isTonal && style.hasBorder) {
      // Outlined tonal gains extra opacity on hover.
      backgroundColor = accent.withOpacityValue(
        kLayrzButtonOutlinedTonalOpacity + hoveredTonalExtraOpacity,
      );
    }

    // Border color unchanged on hover.
    if (style.hasBorder) {
      borderColor = baseSpec.borderColor;
    }

    return LayrzButtonStyleSpec(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: baseSpec.borderWidth,
      contentColor: contentColor,
      shadows: baseSpec.shadows,
    );
  }
}
