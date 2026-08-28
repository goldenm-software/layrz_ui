import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/tokens/tokens.dart';

/// Immutable specification of visual properties for a single day cell in a
/// [LayrzCalendar], resolved once per cell from [LayrzTokens] and the cell's
/// own state.
///
/// Mirrors the house `*StyleSpec` pattern (e.g. `LayrzAlertStyleSpec`) rather
/// than `LayrzThemeExtension` — the latter has no shipped adopter in this
/// repo and is not the pattern this batch introduces (dossier §4.3/§11.7/R6).
/// A [LayrzCalendarDayCellStyleSpec] holds paint-only properties; it carries
/// no behaviour.
@immutable
class LayrzCalendarDayCellStyleSpec {
  /// Creates a new [LayrzCalendarDayCellStyleSpec].
  const LayrzCalendarDayCellStyleSpec({
    required this.backgroundColor,
    required this.borderColor,
    required this.dateColor,
    required this.eventColor,
  });

  /// Resolves the style for a single day cell from [tokens] and its state.
  ///
  /// [isDisabled] alone determines [dateColor]/[backgroundColor] here —
  /// whether a day has events is deliberately **not** an input to this spec
  /// at all. Per the plan's criterion, "a day with no events and a day that
  /// is disabled must not share a render branch"; keeping "has events" out
  /// of this factory's parameter list entirely is what enforces that
  /// separation. The day-cell surface is responsible for keeping the "no
  /// events" branch visually and structurally distinct on its own.
  factory LayrzCalendarDayCellStyleSpec.resolve({
    required LayrzTokens tokens,
    required bool isToday,
    required bool isOutsideMonth,
    required bool isDisabled,
  }) {
    final Color backgroundColor;
    if (isToday) {
      backgroundColor = tokens.colors.primary.shade500.withValues(alpha: 0.08);
    } else {
      backgroundColor = tokens.colors.sf1;
    }

    final Color borderColor = isToday ? tokens.colors.primary.shade500 : tokens.colors.divider;

    final Color dateColor;
    if (isDisabled) {
      dateColor = tokens.colors.fg4;
    } else if (isOutsideMonth) {
      dateColor = tokens.colors.fg3;
    } else {
      dateColor = tokens.colors.fg1;
    }

    return LayrzCalendarDayCellStyleSpec(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      dateColor: dateColor,
      eventColor: tokens.colors.info.shade500,
    );
  }

  /// The fill color of the day cell.
  final Color backgroundColor;

  /// The color of the day cell's border.
  final Color borderColor;

  /// The color of the day-of-month number.
  final Color dateColor;

  /// The fallback event accent color used when a [LayrzCalendarEntry] carries
  /// no explicit `color`.
  final Color eventColor;

  /// Returns a copy of this spec with the given fields replaced.
  LayrzCalendarDayCellStyleSpec copyWith({
    Color? backgroundColor,
    Color? borderColor,
    Color? dateColor,
    Color? eventColor,
  }) {
    return LayrzCalendarDayCellStyleSpec(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      dateColor: dateColor ?? this.dateColor,
      eventColor: eventColor ?? this.eventColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzCalendarDayCellStyleSpec &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          dateColor == other.dateColor &&
          eventColor == other.eventColor;

  @override
  int get hashCode => Object.hash(backgroundColor, borderColor, dateColor, eventColor);
}

/// Composes [LayrzTokens.typography]'s `body` size with `title`'s emphasis
/// for the month grid's structural text (the weekday header row and each
/// day-of-month number).
///
/// **Ruling (Kenny): "titleStyle is too big for the days on month mode,
/// let's use the body style, but inherit the title weight and features."**
/// `title` (18px, w600) read as oversized once actually rendered in a month
/// cell; `body` (14px, w400) is the right size, but plain `body` is what
/// looked muted in the first place. This composes the two rather than
/// hardcoding a weight value, so the result tracks [LayrzTokens.typography]
/// automatically if the design system's font changes — never
/// `FontWeight.w600` as a literal.
///
/// **What carries over from `title`:** [TextStyle.fontWeight],
/// [TextStyle.fontFamily], and [TextStyle.letterSpacing] — the properties
/// that make title read as a heading rather than a numeric value.
/// **What does NOT carry over:** [TextStyle.fontSize] (this is the whole
/// point — body's size, not title's), [TextStyle.color] and
/// [TextStyle.decoration] (both resolved separately per the caller's own
/// state, e.g. disabled/outside-month/today), and [TextStyle.height] — title
/// and body are tuned for their own size in this scale, so carrying title's
/// line-height ratio across to a smaller font size would not reproduce the
/// same visual rhythm; body's own height is left alone.
TextStyle titleWeightedBodyStyle(LayrzTokens tokens) {
  final title = tokens.typography.title;
  return tokens.typography.body.copyWith(
    fontWeight: title.fontWeight,
    fontFamily: title.fontFamily,
    letterSpacing: title.letterSpacing,
  );
}
