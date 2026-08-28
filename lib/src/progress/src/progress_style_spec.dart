import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'progress_type.dart';

/// Immutable specification of visual properties for a [LayrzProgressBar].
///
/// A [LayrzProgressStyleSpec] holds only paint properties: the track color and
/// the fill/indicator color. It is computed by [resolve] from a semantic
/// [LayrzProgressType] (or an explicit custom color) and the current
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
  /// explicit [color] (honoured only when `type == LayrzProgressType.custom`),
  /// and the current [tokens].
  ///
  /// [type] selects the semantic accent color, following the `LayrzChipType`
  /// convention. [color] is the explicit accent used when [type] is
  /// [LayrzProgressType.custom]; it falls back to `tokens.colors.primary.shade500`
  /// when null. [tokens] provides the surface color used for the track.
  static LayrzProgressStyleSpec resolve({
    required LayrzProgressType type,
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
