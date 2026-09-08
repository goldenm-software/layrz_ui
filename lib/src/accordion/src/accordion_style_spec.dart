import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Immutable specification of visual properties for a [LayrzAccordion] header
/// in a given interaction state.
///
/// A [LayrzAccordionStyleSpec] holds only paint properties -- background,
/// border, content colors, and the expanded-state elevation shadow. It is
/// computed by [resolve] from a state set and the active [LayrzTokens],
/// following the same base-spec-plus-state-delta approach as
/// `LayrzButtonStyleSpec`.
///
/// Per decision D15, only colour changes across interaction states -- geometry
/// (padding, border width, corner radius) is fixed and does not vary with the
/// returned spec. [shadow] is likewise constant across interaction states --
/// it varies only with expansion progress, which is the widget's function,
/// not an interaction state, and is applied by `_buildPanelShell`, not here.
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

  /// The drop shadow painted around the whole panel while fully expanded.
  ///
  /// This is the panel's full-elevation shadow -- resolved once from
  /// [LayrzTokens.shadow.elevation2] (medium elevation), regardless of
  /// interaction state. It is not itself animated: `_buildPanelShell` fades
  /// this exact list in and out by scaling each [BoxShadow]'s alpha by the
  /// shared expansion `progress` (0 collapsed, 1 fully expanded), so the
  /// panel reads as flat while collapsed and as a raised card once open,
  /// with the border still visible under the shadow in both states.
  final List<BoxShadow> shadow;

  /// Creates a new [LayrzAccordionStyleSpec].
  const LayrzAccordionStyleSpec({
    required this.headerBackgroundColor,
    required this.headerContentColor,
    required this.borderColor,
    required this.borderWidth,
    required this.shadow,
  });

  /// Returns a copy of this spec with the given fields replaced.
  LayrzAccordionStyleSpec copyWith({
    Color? headerBackgroundColor,
    Color? headerContentColor,
    Color? borderColor,
    double? borderWidth,
    List<BoxShadow>? shadow,
  }) {
    return LayrzAccordionStyleSpec(
      headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
      headerContentColor: headerContentColor ?? this.headerContentColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      shadow: shadow ?? this.shadow,
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
          borderWidth == other.borderWidth &&
          _listEquals(shadow, other.shadow);

  @override
  int get hashCode => Object.hash(
    headerBackgroundColor,
    headerContentColor,
    borderColor,
    borderWidth,
    Object.hashAll(shadow),
  );

  /// Element-wise equality for the [shadow] list, since [List] does not override `==`.
  static bool _listEquals(List<BoxShadow> a, List<BoxShadow> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

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
  /// [tokens] supplies every color, the border width, and the elevation
  /// shadow; no value here is hardcoded outside of the token lookups
  /// themselves.
  ///
  /// **Shadow.** [shadow] is always [LayrzTokens.shadow.elevation2] (medium
  /// elevation) regardless of interaction state -- it is the panel's
  /// full-expanded shadow, faded in and out by `_buildPanelShell` as the
  /// panel opens and closes, not a per-state visual like the colors above.
  static LayrzAccordionStyleSpec resolve({
    required Set<WidgetState> states,
    required LayrzTokens tokens,
  }) {
    final borderWidth = tokens.border.base;
    final shadow = tokens.shadow.elevation2;

    if (states.contains(WidgetState.disabled)) {
      return LayrzAccordionStyleSpec(
        headerBackgroundColor: tokens.colors.sf1,
        headerContentColor: tokens.colors.fg3,
        borderColor: tokens.colors.fg3,
        borderWidth: borderWidth,
        shadow: shadow,
      );
    }

    if (states.contains(WidgetState.pressed)) {
      return LayrzAccordionStyleSpec(
        headerBackgroundColor: tokens.colors.sf3,
        headerContentColor: tokens.colors.fg1,
        borderColor: tokens.colors.divider,
        borderWidth: borderWidth,
        shadow: shadow,
      );
    }

    if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
      return LayrzAccordionStyleSpec(
        headerBackgroundColor: tokens.colors.sf2,
        headerContentColor: tokens.colors.fg1,
        borderColor: tokens.colors.divider,
        borderWidth: borderWidth,
        shadow: shadow,
      );
    }

    return LayrzAccordionStyleSpec(
      headerBackgroundColor: tokens.colors.sf1,
      headerContentColor: tokens.colors.fg1,
      borderColor: tokens.colors.divider,
      borderWidth: borderWidth,
      shadow: shadow,
    );
  }
}
