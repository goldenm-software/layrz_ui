import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

import '../models/time_of_day.dart';
import 'time_field.dart';

/// The shared HH / MM / optional SS text-field panel behind
/// [LayrzTimeInput], [LayrzTimeRangeInput], and the time half of
/// [LayrzDateTimeInput] and [LayrzDateTimeRangeInput] — sized for
/// four-to-five consumers, not three.
///
/// **Zero clock or dial affordance anywhere in this tree.** Every field is a
/// [LayrzPickersTimeField] (a [LayrzNumberInput] wrapper) — a plain text
/// field, never a rendered clock face or draggable dial. This is a hard
/// constraint, not a style preference: the maintainer was explicit that
/// pickers in this batch are "fields, not a clock, fields please."
///
/// **Fields report via [onChanged] and NEVER close the hosting surface.**
/// This is trap 4 (see the implementation plan and
/// `lib/src/inputs/src/duration/duration_input.dart`'s comments) — wiring a
/// field's edit callback to also dismiss the panel makes the *first*
/// keystroke close it. This widget has no notion of "close" at all; only the
/// caller composing it (the `*_surface.dart` files in sibling directories)
/// decides when a surface closes, via a Save button or a single-valued
/// widget's own commit-on-tap rule — never from inside this panel.
///
/// **`showSeconds` toggles the seconds field without layout reflow (D15).**
/// The seconds field's column is always present in the layout; when
/// [showSeconds] is `false` it is rendered as an invisible placeholder of
/// the same size rather than removed, so toggling never changes the row's
/// overall height or the other fields' horizontal position.
///
/// **12h and 24h both supported, 24h is the default** (a deliberate reversal
/// of the old layrz_theme picker's 12h default — see [use24HourFormat]).
/// **No interval snapping** — any minute/second value 0–59 is permitted, no
/// stepping to multiples of 5 or similar.
///
/// **Tab order**: hour, then minute, then (if shown) second, then the
/// meridiem control when [use24HourFormat] is `false` — a sensible left-to-
/// right reading order with no custom `FocusTraversalPolicy` needed, since
/// [LayrzNumberInput] fields already participate in Flutter's default
/// traversal in source order.
///
/// **Narrow-width label switch, no layout reflow (D15).** [build] wraps the
/// field [Row] in a [LayoutBuilder] and, below
/// [LayrzPickersTimeField.kNarrowWidth] per field, swaps each field's
/// unabridged `timePickerHours`/`timePickerMinutes`/`timePickerSeconds`
/// suffix label for a short, singular/plural-aware abbreviation (mirroring
/// `LayrzDurationPickerPanel`'s identical field-width-driven split — see
/// that class's doc comment for the measurement this is based on). Only the
/// label *text* changes between the two forms; every field keeps the exact
/// same [Expanded] slot and the same [LayrzNumberInput] chrome either way, so
/// this never introduces the kind of reflow D15 already forbids for
/// [showSeconds].
///
/// **Meridiem wraps to a second row when even the short-form labels cannot
/// fit (extreme narrow widths only).** Short-form labels alone cannot
/// rescue every geometry: a field narrower than [_kFieldFloorWidth] cannot
/// render [LayrzNumberInput]'s chrome at all -- see that constant's doc
/// comment for the probe this is based on -- and a real 400px phone width
/// with [showSeconds] `true` and [use24HourFormat] `false` (hour, minute,
/// second, and the meridiem control all sharing one row) falls below it even
/// with 1-character labels. [build] detects this and moves
/// [_MeridiemControl] onto its own row below the three time fields instead
/// of splitting the HH:MM:SS group itself -- the three time fields are kept
/// together because that is the reading order a person expects, mirroring
/// `LayrzDurationPickerPanel`'s own resolution of the identical problem via
/// wrapping (see its `_wrapFields`). **Above [_kFieldFloorWidth] this never
/// triggers -- one row stays one row**, and the wrap is a response to
/// available width alone, never to hover/press/focus state, so D15 still
/// holds within any single width.
class LayrzPickersTimeFieldsPanel extends StatelessWidget {
  /// The current time value.
  final LayrzTimeOfDay value;

  /// Called with the new time whenever any field changes. Fired on every
  /// keystroke or step-button tap — see this class's trap-4 doc above for
  /// why this must never be wired to close anything.
  final ValueChanged<LayrzTimeOfDay> onChanged;

  /// Whether the seconds field is shown. Toggling this never reflows the
  /// panel — see this class's doc comment.
  final bool showSeconds;

  /// Whether the hour field (and its bound) uses 24-hour form. Defaults to
  /// `true`, reversing the old layrz_theme picker's 12h default.
  final bool use24HourFormat;

  /// Creates a new [LayrzPickersTimeFieldsPanel].
  const LayrzPickersTimeFieldsPanel({
    super.key,
    required this.value,
    required this.onChanged,
    this.showSeconds = false,
    this.use24HourFormat = true,
  });

  /// This panel's focus-traversal contract: fields participate in Flutter's
  /// default [FocusTraversalGroup] ordering (see the class doc's "Tab
  /// order" note), wrapped once by [build] so no caller needs to supply its
  /// own group. `U10`'s `time_fields_keyboard_handler.dart` augments this
  /// with arrow-key stepping by wrapping each field's own [FocusNode]
  /// (owned internally by [LayrzNumberInput]) rather than by editing this
  /// file — there is no injectable per-key seam here the way the grids
  /// expose one, because [LayrzNumberInput] already owns standard text-field
  /// key handling (arrow keys move the caret, not between fields) and
  /// overriding that behavior is `U10`'s call to make, not this unit's.

  void _setHour(int hour24) => onChanged(value.copyWith(hour: hour24));

  void _setHour12(int hour12, {required bool isPm}) {
    final normalized = hour12 % 12;
    final hour24 = isPm ? normalized + 12 : normalized;
    onChanged(value.copyWith(hour: hour24));
  }

  void _setMinute(int minute) => onChanged(value.copyWith(minute: minute));

  void _setSecond(int second) => onChanged(value.copyWith(second: second));

  void _setMeridiem({required bool isPm}) {
    final wasPm = value.isPm;
    if (wasPm == isPm) return;
    final delta = isPm ? 12 : -12;
    onChanged(value.copyWith(hour: value.hour + delta));
  }

  /// The label shown inside the hour field's [LayrzNumberInput.suffixText].
  ///
  /// [isNarrow] selects the short, singular/plural-aware form below
  /// [LayrzPickersTimeField.kNarrowWidth] -- see that constant's doc comment
  /// for the measurement this mirrors from `LayrzDurationPickerPanel`.
  String _hourLabel(LayrzUiL10n l10n, int displayedHour, {required bool isNarrow}) {
    if (!isNarrow) return l10n.timePickerHours;
    return displayedHour == 1 ? l10n.timePickerHourShortSingular : l10n.timePickerHourShortPlural;
  }

  /// The label shown inside the minute field's [LayrzNumberInput.suffixText].
  ///
  /// See [_hourLabel] for the narrow/wide split this mirrors.
  String _minuteLabel(LayrzUiL10n l10n, {required bool isNarrow}) {
    if (!isNarrow) return l10n.timePickerMinutes;
    return value.minute == 1 ? l10n.timePickerMinuteShortSingular : l10n.timePickerMinuteShortPlural;
  }

  /// The label shown inside the second field's [LayrzNumberInput.suffixText].
  ///
  /// See [_hourLabel] for the narrow/wide split this mirrors.
  String _secondLabel(LayrzUiL10n l10n, {required bool isNarrow}) {
    if (!isNarrow) return l10n.timePickerSeconds;
    return value.second == 1 ? l10n.timePickerSecondShortSingular : l10n.timePickerSecondShortPlural;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final spacing = tokens.spacing.sp1;

    return FocusTraversalGroup(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The row's own measured width, not the viewport (MediaQuery) --
          // this panel is always hosted inside a bounded-width ancestor
          // (LayrzAnchoredPanel or LayrzBottomSheet's Padding, see the class
          // doc's _bounded reasoning), so its own constraints -- not the
          // device's viewport size -- are what determine whether a field's
          // label fits. Mirrors LayrzDurationPickerPanel's identical
          // LayoutBuilder-over-MediaQuery choice; see LayrzPickersTimeField
          // .kNarrowWidth for the measurement basis.
          final availableWidth = constraints.maxWidth;

          // Slot count: hour, minute, second (always reserves its slot, see
          // the Visibility(maintainSize: true) below), and the meridiem
          // control when not in 24h form. The meridiem control is an
          // IntrinsicWidth column of "AM"/"PM" text, not a suffix-labeled
          // LayrzNumberInput, so it is excluded from the narrow-width label
          // decision -- only the three LayrzPickersTimeField slots share
          // availableWidth for that purpose.
          const fieldSlots = 3;
          final meridiemReserved = use24HourFormat ? 0.0 : (spacing + _kMeridiemWidthEstimate);

          // Per-field width if the meridiem control (when shown) stays on
          // the same row as the three time fields -- the ordinary,
          // single-row layout.
          final sameRowFieldsWidth = availableWidth - meridiemReserved - spacing * (fieldSlots - 1);
          final sameRowPerFieldWidth = sameRowFieldsWidth / fieldSlots;

          // Below _kFieldFloorWidth, LayrzNumberInput's own chrome cannot
          // render without overflowing regardless of label length -- see
          // that constant's doc comment. When the meridiem control sharing
          // the row would push fields below that floor, wrap it onto its
          // own row instead, so the three time fields divide the full
          // availableWidth among themselves. See the class doc's "Meridiem
          // wraps to a second row" section.
          final wrapMeridiem = !use24HourFormat && sameRowPerFieldWidth < _kFieldFloorWidth;

          final effectiveFieldsWidth = wrapMeridiem ? availableWidth - spacing * (fieldSlots - 1) : sameRowFieldsWidth;
          final perFieldWidth = effectiveFieldsWidth / fieldSlots;
          final isNarrow = perFieldWidth < LayrzPickersTimeField.kNarrowWidth;

          final displayedHour = use24HourFormat ? value.hour : value.hour12;

          final timeFieldsRow = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: use24HourFormat
                    ? LayrzPickersTimeField(
                        value: value.hour,
                        minimum: 0,
                        maximum: 23,
                        onChanged: _setHour,
                        label: _hourLabel(l10n, displayedHour, isNarrow: isNarrow),
                        hintText: l10n.timePickerHours,
                      )
                    : LayrzPickersTimeField(
                        value: value.hour12,
                        minimum: 1,
                        maximum: 12,
                        onChanged: (h) => _setHour12(h, isPm: value.isPm),
                        label: _hourLabel(l10n, displayedHour, isNarrow: isNarrow),
                        hintText: l10n.timePickerHours,
                      ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: LayrzPickersTimeField(
                  value: value.minute,
                  minimum: 0,
                  maximum: 59,
                  onChanged: _setMinute,
                  label: _minuteLabel(l10n, isNarrow: isNarrow),
                  hintText: l10n.timePickerMinutes,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                // Always present in the tree at the same size, whether visible or
                // not, so toggling `showSeconds` never reflows the row -- see this
                // class's doc comment (D15).
                child: Visibility(
                  visible: showSeconds,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                  child: LayrzPickersTimeField(
                    value: value.second,
                    minimum: 0,
                    maximum: 59,
                    onChanged: _setSecond,
                    label: _secondLabel(l10n, isNarrow: isNarrow),
                    hintText: l10n.timePickerSeconds,
                  ),
                ),
              ),
              // Only ever shares this row with the time fields when it fits
              // without pushing any field below _kFieldFloorWidth -- see
              // wrapMeridiem above.
              if (!use24HourFormat && !wrapMeridiem) ...[
                SizedBox(width: spacing),
                IntrinsicWidth(
                  child: _MeridiemControl(isPm: value.isPm, onChanged: _setMeridiem),
                ),
              ],
            ],
          );

          if (!wrapMeridiem) return timeFieldsRow;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              timeFieldsRow,
              SizedBox(height: spacing),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IntrinsicWidth(
                  child: _MeridiemControl(isPm: value.isPm, onChanged: _setMeridiem),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A conservative estimate of [_MeridiemControl]'s own rendered width, used
/// only to reserve its share of [LayoutBuilder]'s measured width before
/// dividing the remainder among the three [LayrzPickersTimeField] slots --
/// see the `meridiemReserved` local in [LayrzPickersTimeFieldsPanel.build].
///
/// [_MeridiemControl] sizes itself to its own two-letter "AM"/"PM" text plus
/// token padding via [IntrinsicWidth], so its real width is small and stable
/// across locales (unlike the field labels this file's narrow-width split
/// exists to handle) -- this constant only needs to be roughly right, not
/// exact, because under-reserving merely makes the narrow-width switch
/// trigger a few pixels later than ideal rather than causing any overflow of
/// its own.
const double _kMeridiemWidthEstimate = 56.0;

/// The absolute minimum width, in logical pixels, a single
/// [LayrzPickersTimeField] can render at without its [LayrzNumberInput]
/// chrome overflowing -- independent of label length, unlike
/// [LayrzPickersTimeField.kNarrowWidth].
///
/// Measured directly against [LayrzNumberInput] with `hideStepButtons:
/// false` (this panel never hides the step buttons) and a single-character
/// suffix (the shortest label this file's narrow-width switch ever
/// produces, e.g. "h"): overflow was observed at widths up to and including
/// 118px, and first stopped at 120px. 140.0 keeps a deliberate 20px margin
/// above that measured boundary, mirroring the same reasoning
/// `LayrzDurationPickerPanel`'s own `_kFieldMinWidth` documents for its
/// 180-184px probe -> 200.0 constant.
///
/// This floor is what [LayrzPickersTimeField.kNarrowWidth] alone cannot
/// rescue: at a real 400px phone width with [LayrzPickersTimeFieldsPanel
/// .showSeconds] `true` and [LayrzPickersTimeFieldsPanel.use24HourFormat]
/// `false`, the meridiem control's own reserved width plus inter-field
/// spacing leaves each of the three time fields only ~113px -- already
/// below this floor before any label length is even considered. See the
/// class doc's "Meridiem wraps to a second row" section for how [build]
/// responds to that case.
const double _kFieldFloorWidth = 140.0;

/// A two-state AM/PM toggle, rendered as plain text buttons — no Material
/// `ToggleButtons`, no clock affordance.
class _MeridiemControl extends StatelessWidget {
  final bool isPm;
  final void Function({required bool isPm}) onChanged;

  const _MeridiemControl({required this.isPm, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    Widget buildOption({required bool value, required String label}) {
      final isActive = isPm == value;
      return Semantics(
        button: true,
        selected: isActive,
        label: label,
        onTap: () => onChanged(isPm: value),
        child: GestureDetector(
          onTap: () => onChanged(isPm: value),
          behavior: HitTestBehavior.opaque,
          child: ExcludeSemantics(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2, vertical: tokens.spacing.sp1),
              decoration: BoxDecoration(
                color: isActive ? tokens.colors.primary : tokens.colors.sf2,
                borderRadius: tokens.radius.br1,
              ),
              child: Text(
                label,
                style: tokens.typography.label.copyWith(color: isActive ? tokens.colors.sf1 : tokens.colors.fg2),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildOption(value: false, label: l10n.timeMeridiemAm),
        SizedBox(height: tokens.spacing.sp1),
        buildOption(value: true, label: l10n.timeMeridiemPm),
      ],
    );
  }
}
