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
  /// The color painted for this entry's marker fill.
  ///
  /// Deliberately a separate token from [connectorColor]: the marker fill is
  /// meant to read as light and unobtrusive when no accent is set, while the
  /// connector line still needs enough contrast against the page background
  /// to stay visible as a spine. Sharing one color between both would force
  /// either a marker too dark to look "neutral" or a connector too light to
  /// see — see [connectorColor]'s doc for the token this diverges from.
  final Color markerColor;

  /// The color painted along this entry's connector segments (the spine
  /// lines above and below its marker).
  ///
  /// When the entry has an explicit [LayrzTimelineEntry.accentColor], this
  /// matches [markerColor] so the whole segment reads as one accented unit.
  /// When there is no accent, this uses a darker neutral than [markerColor]
  /// so the connector line stays visible against the page background even
  /// though the marker fill itself is deliberately light.
  final Color connectorColor;

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
    required this.connectorColor,
    required this.markerContentColor,
    required this.cardBackgroundColor,
    required this.labelColor,
    required this.descriptionColor,
    required this.timestampColor,
  });

  /// Resolves a [LayrzTimelineStyleSpec] for a single entry.
  ///
  /// [accentColor] is the entry's own [LayrzTimelineEntry.accentColor].
  /// When null, [tokens.colors.sf4] is used for the marker fill so an entry
  /// with no explicit accent reads as a light, neutral, non-primary marker,
  /// while [tokens.colors.fg3] — the previous marker token, a mid-grey — is
  /// kept for the connector so the spine line stays visible against the page
  /// background. When [accentColor] is set, both the marker and its
  /// connector use it, so the whole segment reads as one accented unit.
  static LayrzTimelineStyleSpec resolve({
    required Color? accentColor,
    required LayrzTokens tokens,
  }) {
    final marker = accentColor ?? tokens.colors.sf4;
    final connector = accentColor ?? tokens.colors.fg3;
    return LayrzTimelineStyleSpec(
      markerColor: marker,
      connectorColor: connector,
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
    Color? connectorColor,
    Color? markerContentColor,
    Color? cardBackgroundColor,
    Color? labelColor,
    Color? descriptionColor,
    Color? timestampColor,
  }) {
    return LayrzTimelineStyleSpec(
      markerColor: markerColor ?? this.markerColor,
      connectorColor: connectorColor ?? this.connectorColor,
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
          connectorColor == other.connectorColor &&
          markerContentColor == other.markerContentColor &&
          cardBackgroundColor == other.cardBackgroundColor &&
          labelColor == other.labelColor &&
          descriptionColor == other.descriptionColor &&
          timestampColor == other.timestampColor;

  @override
  int get hashCode => Object.hash(
    markerColor,
    connectorColor,
    markerContentColor,
    cardBackgroundColor,
    labelColor,
    descriptionColor,
    timestampColor,
  );
}
