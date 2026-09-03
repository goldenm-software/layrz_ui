import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/calendar/calendar.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

/// The width, in logical pixels, reserved for [LayrzPickersWeekNumberGutter]
/// when it renders its full (non-compact) numeric column.
const double kWeekNumberGutterWidth = 28.0;

/// The width, in logical pixels, reserved for the gutter's cut/decorative
/// form below `isCompact` — a thin strip, not a tappable column.
const double kWeekNumberGutterCompactWidth = 6.0;

/// One column of ISO 8601 week numbers, one per grid row, alongside
/// [LayrzPickersDayGrid].
///
/// **Cut below `isCompact`.** [showWeekNumbers] defaults to `true`, but on a
/// compact viewport this widget renders only a thin, non-tappable decorative
/// strip ([kWeekNumberGutterCompactWidth] wide, no numbers) rather than its
/// full numeric column ([kWeekNumberGutterWidth] wide) — thumb space on a
/// small screen goes to the day cells themselves; nobody picking "the 14th"
/// needs to know it is week 37. This widget reads `context.isCompact`
/// itself so every caller gets this behavior with no extra wiring.
///
/// Purely decorative: never tappable, never focusable, in either form.
class LayrzPickersWeekNumberGutter extends StatelessWidget {
  /// The first day (as a plain calendar date) of each of the grid's rows, in
  /// order — one entry per row, used to compute that row's ISO week number
  /// via [isoWeekNumberOf].
  final List<DateTime> rowStartDates;

  /// The height of a single day-grid row, so each week number vertically
  /// aligns with its row.
  final double rowHeight;

  /// Whether this gutter renders at all. When `false`, this widget renders
  /// an empty [SizedBox] of zero width — callers should prefer not
  /// constructing it at all when `showWeekNumbers` is `false`, but this flag
  /// keeps the widget safe to include unconditionally.
  final bool visible;

  /// Creates a new [LayrzPickersWeekNumberGutter].
  const LayrzPickersWeekNumberGutter({
    super.key,
    required this.rowStartDates,
    required this.rowHeight,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final tokens = context.tokens;
    final isCompact = context.isCompact;
    final width = isCompact ? kWeekNumberGutterCompactWidth : kWeekNumberGutterWidth;

    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            for (final rowStart in rowStartDates)
              SizedBox(
                height: rowHeight,
                child: isCompact
                    ? Center(
                        child: Container(
                          width: 2.0,
                          height: rowHeight * 0.4,
                          decoration: BoxDecoration(
                            color: tokens.colors.divider,
                            borderRadius: tokens.radius.br1,
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          '${isoWeekNumberOf(rowStart)}',
                          style: tokens.typography.label.copyWith(color: tokens.colors.fg4, fontSize: 10.0),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
