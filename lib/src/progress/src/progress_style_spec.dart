import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Semantic type classification for [LayrzProgressBar] accent colors.
///
/// Mirrors the `LayrzChipType` convention (`lib/src/chips/src/chip_type.dart`)
/// so that semantic color selection reads the same way across every component
/// in the design system rather than inventing a second vocabulary.
enum LayrzProgressBarType {
  /// Informational semantic type — use `LayrzTokens.colors.info` for neutral progress.
  info,

  /// Success semantic type — use `LayrzTokens.colors.success` for positive progress.
  success,

  /// Warning semantic type — use `LayrzTokens.colors.warning` for cautionary progress.
  warning,

  /// Danger semantic type — use `LayrzTokens.colors.danger` for destructive/critical progress.
  danger,

  /// Contextual semantic type — use `LayrzTokens.colors.contextual` for context-dependent progress.
  context,

  /// Custom type — use explicit `color` value from the [LayrzProgressBar] constructor.
  ///
  /// The `color` parameter is only honoured when `type == custom`.
  /// Defaults to `LayrzTokens.colors.primary` if both `type` is custom and `color` is null.
  custom;

  /// Returns the semantic color for this progress bar type.
  ///
  /// For non-custom types, returns the associated semantic color token.
  /// For custom type, returns null — the caller must provide an explicit color.
  Color? colorToken(LayrzTokens tokens) {
    switch (this) {
      case LayrzProgressBarType.info:
        return tokens.colors.info.shade500;
      case LayrzProgressBarType.success:
        return tokens.colors.success.shade500;
      case LayrzProgressBarType.warning:
        return tokens.colors.warning.shade500;
      case LayrzProgressBarType.danger:
        return tokens.colors.danger.shade500;
      case LayrzProgressBarType.context:
        return tokens.colors.contextual.shade500;
      case LayrzProgressBarType.custom:
        return null;
    }
  }
}

/// Immutable specification of visual properties for a [LayrzProgressBar].
///
/// A [LayrzProgressStyleSpec] holds only paint properties: the track color and
/// the fill/indicator color. It is computed by [resolve] from a semantic
/// [LayrzProgressBarType] (or an explicit custom color) and the current
/// [LayrzTokens], keeping color resolution a pure function of its inputs —
/// no interaction states are involved, since a progress bar is not tappable.
@immutable
class LayrzProgressStyleSpec {
  /// The fill color of the track (the unfilled background of the bar).
  final Color trackColor;

  /// The fill color of the indicator (the determinate fill or indeterminate sweep).
  final Color indicatorColor;

  /// Creates a new [LayrzProgressStyleSpec].
  const LayrzProgressStyleSpec({
    required this.trackColor,
    required this.indicatorColor,
  });

  /// Returns a copy of this spec with the given fields replaced.
  LayrzProgressStyleSpec copyWith({
    Color? trackColor,
    Color? indicatorColor,
  }) {
    return LayrzProgressStyleSpec(
      trackColor: trackColor ?? this.trackColor,
      indicatorColor: indicatorColor ?? this.indicatorColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzProgressStyleSpec &&
          runtimeType == other.runtimeType &&
          trackColor == other.trackColor &&
          indicatorColor == other.indicatorColor;

  @override
  int get hashCode => Object.hash(trackColor, indicatorColor);

  /// Resolves a [LayrzProgressStyleSpec] from a semantic [type], an optional
  /// explicit [color] (honoured only when `type == LayrzProgressBarType.custom`),
  /// and the current [tokens].
  ///
  /// [type] selects the semantic accent color, following the `LayrzChipType`
  /// convention. [color] is the explicit accent used when [type] is
  /// [LayrzProgressBarType.custom]; it falls back to `tokens.colors.primary.shade500`
  /// when null. [tokens] provides the surface color used for the track.
  static LayrzProgressStyleSpec resolve({
    required LayrzProgressBarType type,
    required Color? color,
    required LayrzTokens tokens,
  }) {
    final accent = type.colorToken(tokens) ?? color ?? tokens.colors.primary.shade500;

    return LayrzProgressStyleSpec(
      trackColor: tokens.colors.sf3,
      indicatorColor: accent,
    );
  }
}
