import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'snackbar_type.dart';

/// Immutable specification of visual properties for a [LayrzSnackbar] card in the
/// white-card treatment (DESIGN-60 rework — supersedes the first build's
/// filled/full-color "Turn-2" treatment).
///
/// A [LayrzSnackbarStyleSpec] holds only paint properties — surface, accent,
/// title, description, icon, progress-bar, border, and shadow colors/values. It
/// is computed by the static [resolve] from a [LayrzSnackbarType] (or an explicit
/// custom color), the live [LayrzTokens], and an optional custom icon/color pair.
/// This mirrors the `LayrzAlertStyleSpec` pattern
/// (`lib/src/alerts/src/alert_style_spec.dart`): the view widget stays dumb and
/// testable by consuming only this data object, never resolving color logic itself.
///
/// Action buttons (below the content) and the close affordance are no longer part
/// of this spec — both are `LayrzButton`s now, which self-style from their own
/// `type`/`style`/`color`, so the white-on-color chrome fields the filled
/// treatment needed (`actionBorderColor`, `actionBackgroundColor`,
/// `actionHoverBackgroundColor`, `closeColor`, `closeHoverBackgroundColor`,
/// `closeHoverColor`) have been removed entirely.
@immutable
class LayrzSnackbarStyleSpec {
  /// The solid fill color of the snackbar card.
  ///
  /// The white/light card surface — `tokens.colors.sf1`, the same lightest
  /// surface step [LayrzCard] defaults to. Distinct from [accentColor]: the card
  /// no longer takes the semantic color as its background (DESIGN-60 rework).
  final Color surfaceColor;

  /// The semantic (or custom) accent color for this snackbar.
  ///
  /// Painted as **text/icon on the white card**: it is the shared source for
  /// [titleColor], [iconColor], and [progressColor]. Resolved from
  /// [LayrzSnackbarType.accentColor] for semantic types, or from the caller's
  /// `customColor` when [LayrzSnackbarType.custom].
  final Color accentColor;

  /// The color applied to the title text.
  ///
  /// Always equal to [accentColor] — the title inherits the severity color so it
  /// reads as the emphasized line of the card.
  final Color titleColor;

  /// The color applied to the description text.
  ///
  /// A neutral grey token (`tokens.colors.fg2`) rather than the accent color, so
  /// the description reads as secondary body text regardless of severity.
  final Color descriptionColor;

  /// The color of the leading icon glyph.
  ///
  /// Always equal to [accentColor], kept as a separate field for API clarity and
  /// so a future style can diverge icon color from text color without a
  /// breaking change.
  final Color iconColor;

  /// The fill color of the auto-dismiss progress bar.
  ///
  /// Always equal to [accentColor]. Unlike the filled treatment's draining
  /// hairline (bottom edge), the view (R2) places this bar flush at the **top**
  /// edge of the card.
  final Color progressColor;

  /// The border color of the card.
  ///
  /// A subtle neutral border rather than a semantic tint, so the card reads as a
  /// standard elevated surface regardless of severity. Fallback target from the
  /// design reference: `#E2E1DD`.
  final Color borderColor;

  /// The drop shadow painted beneath the card.
  ///
  /// A soft, mostly-neutral shadow (not tinted by [accentColor], unlike the
  /// filled treatment) — fallback target from the design reference:
  /// `0 6px 20px rgba(20,22,26,.10)`.
  final List<BoxShadow> shadow;

  /// Creates a new [LayrzSnackbarStyleSpec].
  const LayrzSnackbarStyleSpec({
    required this.surfaceColor,
    required this.accentColor,
    required this.titleColor,
    required this.descriptionColor,
    required this.iconColor,
    required this.progressColor,
    required this.borderColor,
    required this.shadow,
  });

  /// Returns a copy of this spec with the given fields replaced.
  LayrzSnackbarStyleSpec copyWith({
    Color? surfaceColor,
    Color? accentColor,
    Color? titleColor,
    Color? descriptionColor,
    Color? iconColor,
    Color? progressColor,
    Color? borderColor,
    List<BoxShadow>? shadow,
  }) {
    return LayrzSnackbarStyleSpec(
      surfaceColor: surfaceColor ?? this.surfaceColor,
      accentColor: accentColor ?? this.accentColor,
      titleColor: titleColor ?? this.titleColor,
      descriptionColor: descriptionColor ?? this.descriptionColor,
      iconColor: iconColor ?? this.iconColor,
      progressColor: progressColor ?? this.progressColor,
      borderColor: borderColor ?? this.borderColor,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzSnackbarStyleSpec &&
          runtimeType == other.runtimeType &&
          surfaceColor == other.surfaceColor &&
          accentColor == other.accentColor &&
          titleColor == other.titleColor &&
          descriptionColor == other.descriptionColor &&
          iconColor == other.iconColor &&
          progressColor == other.progressColor &&
          borderColor == other.borderColor &&
          _listEquals(shadow, other.shadow);

  @override
  int get hashCode => Object.hash(
    surfaceColor,
    accentColor,
    titleColor,
    descriptionColor,
    iconColor,
    progressColor,
    borderColor,
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

  /// Resolves a [LayrzSnackbarStyleSpec] from a [type], the live [tokens], and an
  /// optional custom color/icon pair.
  ///
  /// [type] selects the semantic accent via [LayrzSnackbarType.accentColor]. When
  /// [type] is [LayrzSnackbarType.custom], [customColor] supplies the accent
  /// instead (falling back to `tokens.colors.primary.shade500` if null, so a spec
  /// can always be resolved even mid-construction) — used directly as the accent,
  /// on the assumption the caller picked a color legible on white.
  /// [customIcon] is accepted for signature symmetry with the constructor call
  /// site but does not affect any paint property here — icon *color* always
  /// derives from [accentColor], not from which glyph is drawn.
  ///
  /// [tokens] provides the live [LayrzTokens] (surface, neutral text, and border
  /// swatches) so custom themes are respected rather than hardcoding design values.
  static LayrzSnackbarStyleSpec resolve(
    LayrzSnackbarType type,
    LayrzTokens tokens, {
    Color? customColor,
    IconData? customIcon,
  }) {
    final Color accent = type == LayrzSnackbarType.custom
        ? (customColor ?? tokens.colors.primary.shade500)
        : (type.accentColor(tokens) ?? tokens.colors.primary.shade500);

    return LayrzSnackbarStyleSpec(
      surfaceColor: tokens.colors.sf1,
      accentColor: accent,
      titleColor: accent,
      descriptionColor: tokens.colors.fg2,
      iconColor: accent,
      progressColor: accent,
      borderColor: tokens.colors.divider,
      shadow: [
        BoxShadow(
          color: const Color(0xFF14161A).withValues(alpha: 0.10),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
