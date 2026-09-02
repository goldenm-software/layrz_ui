import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';

/// One HH/MM/SS field of [LayrzPickersTimeFieldsPanel] — a thin, documented
/// wrapper around [LayrzNumberInput] that enforces the clamp-not-drop rule
/// for out-of-range typed input.
///
/// **A text field, never a clock or dial** — this is the hard constraint the
/// whole time-fields surface exists to satisfy. [LayrzNumberInput] is a
/// plain numeric text input (the same primitive `LayrzDurationPickerPanel`
/// uses for its own day/hour/minute/second fields), so composing it here
/// introduces zero clock/dial affordance anywhere in the tree.
///
/// **Out-of-range typed input is clamped, not silently dropped**: typing "99"
/// into an hour field (`maximum: 23`) reports `23` via [onChanged], not a
/// rejected/ignored keystroke and not `null`. [LayrzNumberInput]'s own
/// `maximum`/`minimum` already clamp at the point [onChanged] fires (see
/// `duration_picker_panel.dart`'s identical use of the same clamp pattern),
/// so this wrapper does not re-implement clamping — it only fixes the
/// decimal-free integer configuration every time field shares.
class LayrzPickersTimeField extends StatelessWidget {
  /// The current field value.
  final int value;

  /// The lowest value this field accepts.
  final int minimum;

  /// The highest value this field accepts.
  final int maximum;

  /// Called with the new, already-clamped value on every edit — a keystroke
  /// or a step-button tap. **Never closes any surface** — see this module's
  /// trap-4 discipline; the caller composing this field is responsible for
  /// keeping whatever panel hosts it open across this callback.
  final ValueChanged<int> onChanged;

  /// The label shown inside the field (via [LayrzNumberInput.suffixText]),
  /// e.g. a localized "Hours"/"Minutes"/"Seconds".
  final String label;

  /// Placeholder/hint text shown when the field is empty.
  final String hintText;

  /// Creates a new [LayrzPickersTimeField].
  const LayrzPickersTimeField({
    super.key,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
    required this.label,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return LayrzNumberInput(
      hintText: hintText,
      suffixText: label,
      value: value,
      onChanged: (v) {
        final clamped = (v?.toInt() ?? minimum).clamp(minimum, maximum);
        onChanged(clamped);
      },
      minimum: minimum,
      maximum: maximum,
      step: 1,
      decimalSeparator: LayrzDecimalSeparator.dot,
      // Time components are always whole numbers -- see the identical
      // reasoning on `LayrzDurationPickerPanel`'s own fields.
      maximumDecimalDigits: 0,
      hideStepButtons: false,
    );
  }
}
