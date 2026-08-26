import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

import '../number/decimal_separator.dart';
import 'duration_unit.dart';
import '../number/number_input.dart';

/// The minimum usable width, in logical pixels, for a single duration unit
/// field inside [LayrzDurationPickerPanel].
///
/// Measured directly against [LayrzNumberInput] (temporary probes, deleted):
/// an 8-character [LayrzNumberInput.suffixText] -- the length of real
/// translations like Spanish "Segundos" -- first stops overflowing
/// [LayrzNumberInput]'s internal chrome between 180px and 184px. 200px keeps
/// a deliberate margin above that measured boundary rather than sitting
/// right on it, so small token/padding drift elsewhere does not immediately
/// reopen the overflow this constant exists to prevent.
///
/// This replaces the old fixed two-column [LayrzRow]/[LayrzCol] grid that
/// depended on the anchored panel's now-removed 280.0-480.0 width cap (see
/// the class doc on [LayrzDurationPickerPanel] for why that cap was
/// removed). With the panel now spanning its anchor field's full width
/// ([LayrzAnchoredPanelWidthPolicy.matchAnchor]), the panel's available
/// width is no longer a fixed, predictable range -- it could be narrower or
/// far wider than 480px depending on the field's own width -- so field
/// sizing must be driven by the panel's own measured width via
/// [LayoutBuilder], not by a viewport breakpoint.
const double _kFieldMinWidth = 200.0;

/// The character-length threshold used to select between the long-form
/// (`durationField*`) and short-form (`durationUnit*Short*`) unit labels.
///
/// Mirrors [_kFieldMinWidth]'s own measured basis: a field narrower than
/// [_kNarrowFieldWidth] cannot safely fit an 8-character label (e.g.
/// "Segundos") without risking overflow, so fields below this width read the
/// short, abbreviated key instead. Fields at or above it read the
/// unabridged long-form key. This is the direct replacement for the old
/// viewport-breakpoint-driven compact/desktop split -- see the class doc.
const double _kNarrowFieldWidth = 280.0;

/// Internal widget that builds the duration picker panel content.
///
/// This widget is shared between the bottom sheet and the anchored panel.
/// It displays up to four optional number input fields (day, hour, minute,
/// second), each carrying its unit label inside [LayrzNumberInput.suffixText]
/// rather than as a separate label widget, and a reset button.
///
/// **Layout: fill-width, minimum-width-aware wrapping, no viewport
/// breakpoints.** The fields are arranged with a [LayoutBuilder] that reads
/// the panel's own measured width -- never [MediaQuery]'s viewport width --
/// and packs as many fields as fit per row without any field dropping below
/// [_kFieldMinWidth]. Fields that do not fit on the current row wrap to a
/// new one. Each row's fields are stretched evenly to fill the full
/// available width (never left stranded at their minimum with empty
/// trailing space), mirroring the maintainer's own description of the fix:
/// "Expanded plus a minWidth constraint, with wrapping."
///
/// **Why this replaced the old [LayrzRow]/[LayrzCol] 12-column grid.** The
/// previous layout picked one or two columns per row from the *viewport*
/// breakpoint (`xs` vs `sm`+), which only worked because the anchored
/// desktop panel was capped to a fixed 280.0-480.0 width
/// ([LayrzAnchoredPanelWidthPolicy.contentSized]) -- a narrow band that made
/// "two columns fit" a safe, constant assumption. The panel now spans its
/// anchor field's full width instead
/// ([LayrzAnchoredPanelWidthPolicy.matchAnchor], set in
/// `duration_input.dart`), so its available width is no longer fixed or
/// narrow: on a wide field it may be well over 1000px, on a narrow one well
/// under 280px. A viewport-breakpoint grid cannot track that -- the
/// viewport and the panel's own width are unrelated once the panel is no
/// longer capped -- so the field count per row must be computed from the
/// panel's own [LayoutBuilder] constraints instead.
///
/// **Why compact used full unit words and desktop used abbreviations --
/// this is still a measured constraint, now field-width-driven rather than
/// viewport-driven.** A field narrower than [_kNarrowFieldWidth] reads the
/// short, count-aware abbreviation (`durationUnit{Day,Hour,Minute,Second}
/// Short{Singular,Plural}`, e.g. `d`/`h`/`m`/`s`) instead of the long-form
/// `durationField*` keys, because real translations of "seconds" are 8
/// characters in Spanish, Portuguese, French, and German
/// ("Segundos"/"Secondes"/"Sekunden") and overflow [LayrzNumberInput]'s
/// chrome below that width -- see [_kFieldMinWidth] and
/// [_kNarrowFieldWidth] for the measurement this rests on.
class LayrzDurationPickerPanel extends StatefulWidget {
  /// The initial duration to populate the fields.
  final Duration? initialValue;

  /// The set of units to display.
  final Set<LayrzDurationUnit> visibleUnits;

  /// Callback fired when the user edits any field's value.
  ///
  /// Fired on every day/hour/minute/second field change, but never on reset --
  /// see [onReset] for that. This distinction lets a caller keep the panel open
  /// while the user is composing a value across multiple fields (e.g. typing an
  /// hour, then a minute) and close it only on an explicit reset, instead of
  /// closing on every keystroke or step-button tap. Callers that want the same
  /// handling for both may simply pass the same function to both parameters.
  final ValueChanged<Duration?> onChanged;

  /// Callback fired when the user presses the reset button.
  ///
  /// Fired once, after every field has been cleared to zero. Kept distinct
  /// from [onChanged] so a caller can treat "the user reset the picker" as a
  /// deliberate close-and-commit action, without treating an ordinary field
  /// edit -- which also changes the reported [Duration] -- the same way.
  /// Defaults to [onChanged] when not supplied, preserving the single-callback
  /// behavior existing callers rely on.
  final ValueChanged<Duration?>? onReset;

  /// Creates a new [LayrzDurationPickerPanel].
  const LayrzDurationPickerPanel({
    super.key,
    required this.initialValue,
    required this.visibleUnits,
    required this.onChanged,
    this.onReset,
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
    (widget.onReset ?? widget.onChanged)(_computeDuration());
  }

  void _handleValueChanged() {
    widget.onChanged(_computeDuration());
  }

  /// The label shown inside the day field's [LayrzNumberInput.suffixText].
  ///
  /// [isNarrow] selects the short form below [_kNarrowFieldWidth] -- see the
  /// class doc comment for the measurement behind the threshold.
  String _dayLabel(LayrzUiL10n l10n, {required bool isNarrow}) {
    if (!isNarrow) return l10n.durationFieldDay;
    return _day == 1 ? l10n.durationUnitDayShortSingular : l10n.durationUnitDayShortPlural;
  }

  /// The label shown inside the hour field's [LayrzNumberInput.suffixText].
  ///
  /// See [_dayLabel] for the narrow/wide split this mirrors.
  String _hourLabel(LayrzUiL10n l10n, {required bool isNarrow}) {
    if (!isNarrow) return l10n.durationFieldHour;
    return _hour == 1 ? l10n.durationUnitHourShortSingular : l10n.durationUnitHourShortPlural;
  }

  /// The label shown inside the minute field's [LayrzNumberInput.suffixText].
  ///
  /// See [_dayLabel] for the narrow/wide split this mirrors.
  String _minuteLabel(LayrzUiL10n l10n, {required bool isNarrow}) {
    if (!isNarrow) return l10n.durationFieldMinute;
    return _minute == 1 ? l10n.durationUnitMinuteShortSingular : l10n.durationUnitMinuteShortPlural;
  }

  /// The label shown inside the second field's [LayrzNumberInput.suffixText].
  ///
  /// See [_dayLabel] for the narrow/wide split this mirrors.
  String _secondLabel(LayrzUiL10n l10n, {required bool isNarrow}) {
    if (!isNarrow) return l10n.durationFieldSecond;
    return _second == 1 ? l10n.durationUnitSecondShortSingular : l10n.durationUnitSecondShortPlural;
  }

  /// Builds the ordered list of visible unit fields (day, hour, minute,
  /// second), each wrapped in a [KeyedSubtree] carrying the same
  /// `layrz_duration_field_*` key the previous grid-based layout assigned,
  /// so existing finders in tests keep working unchanged.
  ///
  /// [isNarrow] is computed once by [build] from the panel's own measured
  /// per-field width (see [_kNarrowFieldWidth]) and threaded through to
  /// every field's label getter.
  List<Widget> _buildFields(LayrzUiL10n l10n, {required bool isNarrow}) {
    final fields = <Widget>[];

    if (widget.visibleUnits.contains(LayrzDurationUnit.day)) {
      fields.add(
        KeyedSubtree(
          key: const ValueKey('layrz_duration_field_day'),
          child: LayrzNumberInput(
            hintText: l10n.durationFieldDay,
            suffixText: _dayLabel(l10n, isNarrow: isNarrow),
            value: _day,
            onChanged: (v) {
              setState(() => _day = v?.toInt() ?? 0);
              _handleValueChanged();
            },
            decimalSeparator: LayrzDecimalSeparator.dot,
            minimum: 0,
            step: 1,
            // Duration components are always whole numbers -- there is no
            // fractional day once hours are their own field. Zero forbids the
            // decimal separator at the keystroke level (see
            // NumericInputFormatter, which only accepts the separator when
            // maximumDecimalDigits > 0) and, with `value` now an int rather
            // than `.toDouble()`, makes LayrzNumberInput's default
            // `num.toString()` formatting render "2", not "2.0".
            maximumDecimalDigits: 0,
            hideStepButtons: false,
          ),
        ),
      );
    }

    if (widget.visibleUnits.contains(LayrzDurationUnit.hour)) {
      fields.add(
        KeyedSubtree(
          key: const ValueKey('layrz_duration_field_hour'),
          child: LayrzNumberInput(
            hintText: l10n.durationFieldHour,
            suffixText: _hourLabel(l10n, isNarrow: isNarrow),
            value: _hour,
            onChanged: (v) {
              final newVal = v?.toInt() ?? 0;
              setState(() => _hour = newVal.clamp(0, 23));
              _handleValueChanged();
            },
            decimalSeparator: LayrzDecimalSeparator.dot,
            minimum: 0,
            maximum: 23,
            step: 1,
            // See the day field's `maximumDecimalDigits: 0` comment above.
            maximumDecimalDigits: 0,
            hideStepButtons: false,
          ),
        ),
      );
    }

    if (widget.visibleUnits.contains(LayrzDurationUnit.minute)) {
      fields.add(
        KeyedSubtree(
          key: const ValueKey('layrz_duration_field_minute'),
          child: LayrzNumberInput(
            hintText: l10n.durationFieldMinute,
            suffixText: _minuteLabel(l10n, isNarrow: isNarrow),
            value: _minute,
            onChanged: (v) {
              final newVal = v?.toInt() ?? 0;
              setState(() => _minute = newVal.clamp(0, 59));
              _handleValueChanged();
            },
            decimalSeparator: LayrzDecimalSeparator.dot,
            minimum: 0,
            maximum: 59,
            step: 1,
            // See the day field's `maximumDecimalDigits: 0` comment above.
            maximumDecimalDigits: 0,
            hideStepButtons: false,
          ),
        ),
      );
    }

    if (widget.visibleUnits.contains(LayrzDurationUnit.second)) {
      fields.add(
        KeyedSubtree(
          key: const ValueKey('layrz_duration_field_second'),
          child: LayrzNumberInput(
            hintText: l10n.durationFieldSecond,
            suffixText: _secondLabel(l10n, isNarrow: isNarrow),
            value: _second,
            onChanged: (v) {
              final newVal = v?.toInt() ?? 0;
              setState(() => _second = newVal.clamp(0, 59));
              _handleValueChanged();
            },
            decimalSeparator: LayrzDecimalSeparator.dot,
            minimum: 0,
            maximum: 59,
            step: 1,
            // See the day field's `maximumDecimalDigits: 0` comment above.
            maximumDecimalDigits: 0,
            hideStepButtons: false,
          ),
        ),
      );
    }

    return fields;
  }

  /// Lays out [fields] into rows of [fieldsPerRow], each field stretched to
  /// fill an equal share of [availableWidth] so a row never leaves empty
  /// trailing space -- the "fill the available width" half of the
  /// requirement, alongside [_kFieldMinWidth]'s "never shrink below usable"
  /// half. A row with fewer than [fieldsPerRow] fields (the last, partial
  /// row) still divides the same [availableWidth] among just its own
  /// fields, so it fills the row too rather than sizing to [fieldsPerRow]'s
  /// share and leaving a gap.
  ///
  /// [spacing] is the horizontal gap reserved between fields on the same row
  /// and the vertical gap reserved between rows.
  Widget _wrapFields({
    required List<Widget> fields,
    required double availableWidth,
    required int fieldsPerRow,
    required double spacing,
  }) {
    final rows = <Widget>[];
    for (var i = 0; i < fields.length; i += fieldsPerRow) {
      final rowFields = fields.sublist(i, (i + fieldsPerRow).clamp(0, fields.length));
      final gapWidth = spacing * (rowFields.length - 1);
      final fieldWidth = (availableWidth - gapWidth) / rowFields.length;

      final rowChildren = <Widget>[];
      for (var j = 0; j < rowFields.length; j++) {
        rowChildren.add(SizedBox(width: fieldWidth, child: rowFields[j]));
        if (j < rowFields.length - 1) {
          rowChildren.add(SizedBox(width: spacing));
        }
      }

      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowChildren));
      if (i + fieldsPerRow < fields.length) {
        rows.add(SizedBox(height: spacing));
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;

    return Padding(
      // sp2 (10px): every pixel of padding here is a pixel the fields below
      // do not have for their own content, so this stays at the design
      // system's own "standard density" input padding (input_chrome.dart)
      // rather than the roomier sp4 -- unchanged from before this pass.
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The panel's OWN measured width, not the viewport
          // (MediaQuery.sizeOf) -- the panel now spans its anchor field's
          // full width (matchAnchor), which has no fixed relationship to the
          // viewport once it is no longer capped to a narrow contentSized
          // range. See the class doc comment for why this replaced the old
          // viewport-breakpoint-driven grid.
          final availableWidth = constraints.maxWidth;

          // sp1 (6px): reclaims a little more width for the field content
          // than the row's old default sp2 (10px) gap, while still leaving a
          // visible gap between fields rather than letting their borders
          // touch -- unchanged from before this pass.
          final spacing = tokens.spacing.sp1;

          // How many fields fit on one row without any of them dropping
          // below _kFieldMinWidth: solve n * _kFieldMinWidth + (n-1) *
          // spacing <= availableWidth for the largest integer n, floored at
          // 1 so a single field is never asked to be narrower than the
          // panel itself allows (a panel narrower than _kFieldMinWidth still
          // renders one field per row rather than throwing). The upper bound
          // is never less than 1 either -- an empty visibleUnits set (no
          // fields at all, just the reset button) would otherwise make
          // `clamp(1, 0)` throw before _buildFields even runs.
          final fieldsPerRow = ((availableWidth + spacing) / (_kFieldMinWidth + spacing)).floor().clamp(
            1,
            widget.visibleUnits.length.clamp(1, 4),
          );

          // The width each field in a full row actually receives once
          // fieldsPerRow fields evenly share availableWidth. Used only to
          // pick the long-form vs short-form label -- see _kNarrowFieldWidth.
          final perFieldWidth = (availableWidth - spacing * (fieldsPerRow - 1)) / fieldsPerRow;
          final isNarrow = perFieldWidth < _kNarrowFieldWidth;

          final fields = _buildFields(l10n, isNarrow: isNarrow);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _wrapFields(
                fields: fields,
                availableWidth: availableWidth,
                fieldsPerRow: fieldsPerRow,
                spacing: spacing,
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
          );
        },
      ),
    );
  }
}
