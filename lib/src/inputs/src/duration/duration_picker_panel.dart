import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/grid/grid.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import '../number/decimal_separator.dart';
import 'duration_unit.dart';
import '../number/number_input.dart';

/// Internal widget that builds the duration picker panel content.
///
/// This widget is shared between the bottom sheet and the anchored panel.
/// It displays up to four optional number input fields (day, hour, minute,
/// second), each carrying its unit label inside [LayrzNumberInput.suffixText]
/// rather than as a separate label widget, and a reset button.
///
/// The fields are arranged in a responsive [LayrzRow]/[LayrzCol] grid: one
/// field per visual row on compact (`xs`) viewports, and two per row from
/// `sm` upward. One-per-row on compact (rather than two) is deliberate: at
/// the narrowest phone widths, a two-column layout leaves too little room
/// for [LayrzNumberInput.suffixText] words like "Minutes"/"Seconds" to
/// render without overflowing, and it also keeps each field's step buttons
/// far enough apart that a thumb tap cannot land on the wrong field's
/// stepper — the narrower column, taller-panel trade-off was confirmed
/// deliberate by the maintainer.
///
/// **Why compact uses full unit words and desktop uses abbreviations —
/// this is a measured constraint, not a style choice.** Read this before
/// "fixing" the inconsistency:
///
/// - **Desktop** (`sm: 6`, two columns inside the anchored panel's 480px
///   content cap) yields **227px per field**. Bisected against the real
///   end-to-end flow, that width fits at most **7 characters** of
///   [LayrzNumberInput.suffixText] before it overflows
///   [LayrzNumberInput]'s internal chrome. Real translations of "seconds"
///   are 8 characters in Spanish, Portuguese, French, and German
///   ("Segundos"/"Secondes"/"Sekunden") — all confirmed, by measurement,
///   to overflow at this width. Desktop therefore reads
///   `durationUnit{Day,Hour,Minute,Second}Short{Singular,Plural}`
///   (`d`/`h`/`m`/`s`) instead of the long-form `durationField*` keys.
/// - **Compact** (`xs: 12`, one column) yields **380px per field**, which
///   fits up to **16 characters** — no realistic locale word comes close,
///   so it keeps the long-form `durationField*` keys unabridged.
///
/// If a future change to the anchored panel's width cap, this row's
/// padding/spacing, or the fields' internal chrome ever lets the desktop
/// column exceed ~227px by enough to clear 8 characters, the long-form
/// keys become viable there too and this asymmetry should be revisited —
/// see the "KNOWN LIMIT" test in `duration_picker_panel_test.dart`, which
/// pins the 7-character capacity this decision rests on.
class LayrzDurationPickerPanel extends StatefulWidget {
  /// The initial duration to populate the fields.
  final Duration? initialValue;

  /// The set of units to display.
  final Set<LayrzDurationUnit> visibleUnits;

  /// Callback fired when the user changes any field or presses reset.
  final ValueChanged<Duration?> onChanged;

  /// Creates a new [LayrzDurationPickerPanel].
  const LayrzDurationPickerPanel({
    super.key,
    required this.initialValue,
    required this.visibleUnits,
    required this.onChanged,
  });

  @override
  State<LayrzDurationPickerPanel> createState() => _LayrzDurationPickerPanelState();
}

class _LayrzDurationPickerPanelState extends State<LayrzDurationPickerPanel> {
  late int _day;
  late int _hour;
  late int _minute;
  late int _second;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.initialValue == null) {
      _day = 0;
      _hour = 0;
      _minute = 0;
      _second = 0;
    } else {
      final duration = widget.initialValue!;
      _day = duration.inDays;
      _hour = (duration.inHours % 24);
      _minute = (duration.inMinutes % 60);
      _second = (duration.inSeconds % 60);
    }
  }

  Duration _computeDuration() {
    return Duration(
      days: _day,
      hours: _hour,
      minutes: _minute,
      seconds: _second,
    );
  }

  void _handleReset() {
    setState(() {
      _day = 0;
      _hour = 0;
      _minute = 0;
      _second = 0;
    });
    widget.onChanged(_computeDuration());
  }

  void _handleValueChanged() {
    widget.onChanged(_computeDuration());
  }

  /// The label shown inside the day field's [LayrzNumberInput.suffixText].
  ///
  /// Compact keeps the long-form field label (16 characters of headroom at
  /// 380px). Desktop reads the short, count-aware abbreviation (7 characters
  /// of headroom at 227px) — see the class doc comment for the measurement
  /// behind this split.
  String _dayLabel(LayrzUiL10n l10n, {required bool isCompact}) {
    if (isCompact) return l10n.durationFieldDay;
    return _day == 1 ? l10n.durationUnitDayShortSingular : l10n.durationUnitDayShortPlural;
  }

  /// The label shown inside the hour field's [LayrzNumberInput.suffixText].
  ///
  /// See [_dayLabel] for the compact/desktop split this mirrors.
  String _hourLabel(LayrzUiL10n l10n, {required bool isCompact}) {
    if (isCompact) return l10n.durationFieldHour;
    return _hour == 1 ? l10n.durationUnitHourShortSingular : l10n.durationUnitHourShortPlural;
  }

  /// The label shown inside the minute field's [LayrzNumberInput.suffixText].
  ///
  /// See [_dayLabel] for the compact/desktop split this mirrors.
  String _minuteLabel(LayrzUiL10n l10n, {required bool isCompact}) {
    if (isCompact) return l10n.durationFieldMinute;
    return _minute == 1 ? l10n.durationUnitMinuteShortSingular : l10n.durationUnitMinuteShortPlural;
  }

  /// The label shown inside the second field's [LayrzNumberInput.suffixText].
  ///
  /// See [_dayLabel] for the compact/desktop split this mirrors.
  String _secondLabel(LayrzUiL10n l10n, {required bool isCompact}) {
    if (isCompact) return l10n.durationFieldSecond;
    return _second == 1 ? l10n.durationUnitSecondShortSingular : l10n.durationUnitSecondShortPlural;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;

    // Same breakpoint source of truth LayrzRow itself uses to resolve each
    // LayrzCol's span (breakpointWidth = the viewport, not this panel's own
    // layout width) — so the suffix picked below always matches the column
    // count actually rendered, never a viewport read that could disagree
    // with it.
    final band = tokens.breakpoints.bandAt(MediaQuery.sizeOf(context).width);
    final isCompact = band == LayrzBreakpoint.xs;

    final fields = <LayrzCol>[];

    if (widget.visibleUnits.contains(LayrzDurationUnit.day)) {
      fields.add(
        LayrzCol(
          key: const ValueKey('layrz_duration_field_day'),
          xs: 12,
          sm: 6,
          child: LayrzNumberInput(
            hintText: l10n.durationFieldDay,
            suffixText: _dayLabel(l10n, isCompact: isCompact),
            value: _day.toDouble(),
            onChanged: (v) {
              setState(() => _day = v?.toInt() ?? 0);
              _handleValueChanged();
            },
            decimalSeparator: LayrzDecimalSeparator.dot,
            minimum: 0,
            step: 1,
            hideStepButtons: false,
          ),
        ),
      );
    }

    if (widget.visibleUnits.contains(LayrzDurationUnit.hour)) {
      fields.add(
        LayrzCol(
          key: const ValueKey('layrz_duration_field_hour'),
          xs: 12,
          sm: 6,
          child: LayrzNumberInput(
            hintText: l10n.durationFieldHour,
            suffixText: _hourLabel(l10n, isCompact: isCompact),
            value: _hour.toDouble(),
            onChanged: (v) {
              final newVal = v?.toInt() ?? 0;
              setState(() => _hour = newVal.clamp(0, 23));
              _handleValueChanged();
            },
            decimalSeparator: LayrzDecimalSeparator.dot,
            minimum: 0,
            maximum: 23,
            step: 1,
            hideStepButtons: false,
          ),
        ),
      );
    }

    if (widget.visibleUnits.contains(LayrzDurationUnit.minute)) {
      fields.add(
        LayrzCol(
          key: const ValueKey('layrz_duration_field_minute'),
          xs: 12,
          sm: 6,
          child: LayrzNumberInput(
            hintText: l10n.durationFieldMinute,
            suffixText: _minuteLabel(l10n, isCompact: isCompact),
            value: _minute.toDouble(),
            onChanged: (v) {
              final newVal = v?.toInt() ?? 0;
              setState(() => _minute = newVal.clamp(0, 59));
              _handleValueChanged();
            },
            decimalSeparator: LayrzDecimalSeparator.dot,
            minimum: 0,
            maximum: 59,
            step: 1,
            hideStepButtons: false,
          ),
        ),
      );
    }

    if (widget.visibleUnits.contains(LayrzDurationUnit.second)) {
      fields.add(
        LayrzCol(
          key: const ValueKey('layrz_duration_field_second'),
          xs: 12,
          sm: 6,
          child: LayrzNumberInput(
            hintText: l10n.durationFieldSecond,
            suffixText: _secondLabel(l10n, isCompact: isCompact),
            value: _second.toDouble(),
            onChanged: (v) {
              final newVal = v?.toInt() ?? 0;
              setState(() => _second = newVal.clamp(0, 59));
              _handleValueChanged();
            },
            decimalSeparator: LayrzDecimalSeparator.dot,
            minimum: 0,
            maximum: 59,
            step: 1,
            hideStepButtons: false,
          ),
        ),
      );
    }

    return Padding(
      // sp2 (10px), not sp4 (20px): the anchored desktop panel is capped at
      // maxWidth: 480 (duration_input.dart), and every pixel of padding here
      // is a pixel the sm:6 (two-column) row does not have for its content.
      // At sp4 + the row's default inter-column gap, the "Seconds"/"Minutes"
      // suffixText overflowed LayrzNumberInput's chrome by a few pixels on
      // that capped width — measured, not assumed — and sp3 alone left only
      // a few pixels of margin above that overflow threshold. sp2 matches
      // the padding token this design system already uses as its own
      // "standard density" input padding (input_chrome.dart), so it is not
      // an arbitrary shrink.
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // sp1 (6px), not the row's default sp2 (10px) gap: reclaims a
          // little more width for the same reason as the padding above,
          // while still leaving a visible gap between stacked/side-by-side
          // fields rather than letting their borders touch.
          LayrzRow(spacing: tokens.spacing.sp1, children: fields),
          SizedBox(height: tokens.spacing.sp4),
          SizedBox(
            width: double.infinity,
            child: LayrzButton(
              labelText: l10n.durationReset,
              onTap: _handleReset,
              type: LayrzButtonType.info,
            ),
          ),
        ],
      ),
    );
  }
}
