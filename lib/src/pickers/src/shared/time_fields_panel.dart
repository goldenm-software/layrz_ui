import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

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

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return FocusTraversalGroup(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: use24HourFormat
                ? LayrzPickersTimeField(
                    value: value.hour,
                    minimum: 0,
                    maximum: 23,
                    onChanged: _setHour,
                    label: l10n.timePickerHours,
                    hintText: l10n.timePickerHours,
                  )
                : LayrzPickersTimeField(
                    value: value.hour12,
                    minimum: 1,
                    maximum: 12,
                    onChanged: (h) => _setHour12(h, isPm: value.isPm),
                    label: l10n.timePickerHours,
                    hintText: l10n.timePickerHours,
                  ),
          ),
          SizedBox(width: tokens.spacing.sp1),
          Expanded(
            child: LayrzPickersTimeField(
              value: value.minute,
              minimum: 0,
              maximum: 59,
              onChanged: _setMinute,
              label: l10n.timePickerMinutes,
              hintText: l10n.timePickerMinutes,
            ),
          ),
          SizedBox(width: tokens.spacing.sp1),
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
                label: l10n.timePickerSeconds,
                hintText: l10n.timePickerSeconds,
              ),
            ),
          ),
          if (!use24HourFormat) ...[
            SizedBox(width: tokens.spacing.sp1),
            IntrinsicWidth(
              child: _MeridiemControl(isPm: value.isPm, onChanged: _setMeridiem),
            ),
          ],
        ],
      ),
    );
  }
}

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
