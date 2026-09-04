import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Immutable specification of visual properties for a [LayrzAccordion] header
/// in a given interaction state.
///
/// A [LayrzAccordionStyleSpec] holds only paint properties -- background,
/// border, and content colors. It is computed by [resolve] from a state set
/// and the active [LayrzTokens], following the same base-spec-plus-state-delta
/// approach as `LayrzButtonStyleSpec`.
///
/// Per decision D15, only colour changes across interaction states -- geometry
/// (padding, border width, corner radius) is fixed and does not vary with the
/// returned spec.
@immutable
class LayrzAccordionStyleSpec {
  /// The fill color of the header row.
  final Color headerBackgroundColor;

  /// The color of the header's leading icon, title text, and trailing chevron.
  final Color headerContentColor;

  /// The color of the border drawn around the whole accordion panel.
  final Color borderColor;

  /// The width of the border in logical pixels.
  final double borderWidth;

  /// Creates a new [LayrzAccordionStyleSpec].
  const LayrzAccordionStyleSpec({
    required this.headerBackgroundColor,
    required this.headerContentColor,
    required this.borderColor,
    required this.borderWidth,
  });

  /// Returns a copy of this spec with the given fields replaced.
  LayrzAccordionStyleSpec copyWith({
    Color? headerBackgroundColor,
    Color? headerContentColor,
    Color? borderColor,
    double? borderWidth,
  }) {
    return LayrzAccordionStyleSpec(
      headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
      headerContentColor: headerContentColor ?? this.headerContentColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzAccordionStyleSpec &&
          runtimeType == other.runtimeType &&
          headerBackgroundColor == other.headerBackgroundColor &&
          headerContentColor == other.headerContentColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth;

  @override
  int get hashCode => Object.hash(
    headerBackgroundColor,
    headerContentColor,
    borderColor,
    borderWidth,
  );

  /// Resolves a [LayrzAccordionStyleSpec] from an interaction state set and tokens.
  ///
  /// **State precedence**: disabled > pressed > hovered/focused > default.
  ///
  /// - **Default (idle)**: header fill is [LayrzTokens.colors.sf1], content is
  ///   [LayrzTokens.colors.fg1], border is [LayrzTokens.colors.divider].
  /// - **Hovered or focused**: header fill lifts to [LayrzTokens.colors.sf2],
  ///   signalling the whole row is a single tap/keyboard target (not just the
  ///   chevron). Focus is mapped identically to hover, satisfying WCAG 2.4.7
  ///   without a fifth state.
  /// - **Pressed**: header fill deepens further to [LayrzTokens.colors.sf3].
  /// - **Disabled**: content and border fade to [LayrzTokens.colors.fg3]; the
  ///   header fill stays [LayrzTokens.colors.sf1] since a disabled accordion
  ///   still occupies its normal position in the layout, it simply stops
  ///   responding.
  ///
  /// [tokens] supplies every color and the border width; no value here is
  /// hardcoded outside of the token lookups themselves.
  static LayrzAccordionStyleSpec resolve({
    required Set<WidgetState> states,
    required LayrzTokens tokens,
  }) {
    final borderWidth = tokens.border.base;

    if (states.contains(WidgetState.disabled)) {
      return LayrzAccordionStyleSpec(
        headerBackgroundColor: tokens.colors.sf1,
        headerContentColor: tokens.colors.fg3,
        borderColor: tokens.colors.fg3,
        borderWidth: borderWidth,
      );
    }

    if (states.contains(WidgetState.pressed)) {
      return LayrzAccordionStyleSpec(
        headerBackgroundColor: tokens.colors.sf3,
        headerContentColor: tokens.colors.fg1,
        borderColor: tokens.colors.divider,
        borderWidth: borderWidth,
      );
    }

    if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
      return LayrzAccordionStyleSpec(
        headerBackgroundColor: tokens.colors.sf2,
        headerContentColor: tokens.colors.fg1,
        borderColor: tokens.colors.divider,
        borderWidth: borderWidth,
      );
    }

    return LayrzAccordionStyleSpec(
      headerBackgroundColor: tokens.colors.sf1,
      headerContentColor: tokens.colors.fg1,
      borderColor: tokens.colors.divider,
      borderWidth: borderWidth,
    );
  }
}
