import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import '../number/decimal_separator.dart';
import 'duration_unit.dart';
import '../number/number_input.dart';

/// Internal widget that builds the duration picker panel content.
///
/// This widget is shared between the bottom sheet and the anchored panel.
/// It displays four optional number input fields (day, hour, minute, second)
/// and a reset button.
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;

    final fields = <Widget>[];

    if (widget.visibleUnits.contains(LayrzDurationUnit.day)) {
      fields.add(
        LayrzNumberInput(
          hintText: l10n.durationFieldDay,
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
      );
      fields.add(
        Text(
          l10n.durationFieldDay,
          style: tokens.typography.label,
          textAlign: TextAlign.center,
        ),
      );
    }

    if (widget.visibleUnits.contains(LayrzDurationUnit.hour)) {
      fields.add(
        LayrzNumberInput(
          hintText: l10n.durationFieldHour,
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
      );
      fields.add(
        Text(
          l10n.durationFieldHour,
          style: tokens.typography.label,
          textAlign: TextAlign.center,
        ),
      );
    }

    if (widget.visibleUnits.contains(LayrzDurationUnit.minute)) {
      fields.add(
        LayrzNumberInput(
          hintText: l10n.durationFieldMinute,
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
      );
      fields.add(
        Text(
          l10n.durationFieldMinute,
          style: tokens.typography.label,
          textAlign: TextAlign.center,
        ),
      );
    }

    if (widget.visibleUnits.contains(LayrzDurationUnit.second)) {
      fields.add(
        LayrzNumberInput(
          hintText: l10n.durationFieldSecond,
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
      );
      fields.add(
        Text(
          l10n.durationFieldSecond,
          style: tokens.typography.label,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            childAspectRatio: 1.0,
            children: fields,
          ),
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
