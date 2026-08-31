import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Immutable specification of visual properties for a single
/// [LayrzTimelineEntry], resolved once per build.
///
/// Mirrors the house `*StyleSpec` convention (see `LayrzChipStyleSpec`): a
/// pure function of the entry's own data and the active [LayrzTokens], with
/// no interaction states of its own — a timeline entry does not respond to
/// hover, press, or focus.
@immutable
class LayrzTimelineStyleSpec {
  /// The color painted for this entry's marker fill and its connector
  /// segments.
  final Color markerColor;

  /// The color painted for the marker's icon or dot content, chosen for
  /// contrast against [markerColor].
  final Color markerContentColor;

  /// The color of the content card's background.
  final Color cardBackgroundColor;

  /// The color of [LayrzTimelineEntry.labelText].
  final Color labelColor;

  /// The color of [LayrzTimelineEntry.descriptionText].
  final Color descriptionColor;

  /// The color of [LayrzTimelineEntry.timestampText].
  final Color timestampColor;

  /// Creates a [LayrzTimelineStyleSpec].
  const LayrzTimelineStyleSpec({
    required this.markerColor,
    required this.markerContentColor,
    required this.cardBackgroundColor,
    required this.labelColor,
    required this.descriptionColor,
    required this.timestampColor,
  });

  /// Resolves a [LayrzTimelineStyleSpec] for a single entry.
  ///
  /// [accentColor] is the entry's own [LayrzTimelineEntry.accentColor];
  /// when null, [tokens.colors.fg3] is used for the marker so an entry with
  /// no explicit accent still reads as a neutral, non-primary marker.
  static LayrzTimelineStyleSpec resolve({
    required Color? accentColor,
    required LayrzTokens tokens,
  }) {
    final marker = accentColor ?? tokens.colors.sf4;
    return LayrzTimelineStyleSpec(
      markerColor: marker,
      markerContentColor: marker.contrastColor,
      cardBackgroundColor: tokens.colors.sf2,
      labelColor: tokens.colors.fg1,
      descriptionColor: tokens.colors.fg2,
      timestampColor: tokens.colors.fg3,
    );
  }

  /// Returns a copy of this spec with the given fields replaced.
  LayrzTimelineStyleSpec copyWith({
    Color? markerColor,
    Color? markerContentColor,
    Color? cardBackgroundColor,
    Color? labelColor,
    Color? descriptionColor,
    Color? timestampColor,
  }) {
    return LayrzTimelineStyleSpec(
      markerColor: markerColor ?? this.markerColor,
      markerContentColor: markerContentColor ?? this.markerContentColor,
      cardBackgroundColor: cardBackgroundColor ?? this.cardBackgroundColor,
      labelColor: labelColor ?? this.labelColor,
      descriptionColor: descriptionColor ?? this.descriptionColor,
      timestampColor: timestampColor ?? this.timestampColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzTimelineStyleSpec &&
          runtimeType == other.runtimeType &&
          markerColor == other.markerColor &&
          markerContentColor == other.markerContentColor &&
          cardBackgroundColor == other.cardBackgroundColor &&
          labelColor == other.labelColor &&
          descriptionColor == other.descriptionColor &&
          timestampColor == other.timestampColor;

  @override
  int get hashCode => Object.hash(
    markerColor,
    markerContentColor,
    cardBackgroundColor,
    labelColor,
    descriptionColor,
    timestampColor,
  );
}
