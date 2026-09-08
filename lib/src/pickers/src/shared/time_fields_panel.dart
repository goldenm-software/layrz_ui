import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import '../models/time_of_day.dart';

/// The shared "digital clock" time panel behind [LayrzTimeInput],
/// [LayrzTimeRangeInput], and the time half of [LayrzDateTimeInput] and
/// [LayrzDateTimeRangeInput].
///
/// **Digital-clock layout, not field rows.** This panel renders big editable
/// `HH : MM` digits (plus an optional `: SS` group when [showSeconds] is
/// `true`) with a colon [Text] separator between each group, and — only in
/// 12-hour mode — a horizontal AM/PM segmented toggle below the digits. There
/// is no [LayrzNumberInput] chrome and no +/- stepper; each digit group is a
/// [_DigitGroup] — a bare [_DigitField] built directly on [EditableText] (see
/// that class's own doc for why) stacked above a small, centered
/// "Hours"/"Minutes"/"Seconds" caption. The colon separators sit between the
/// digit *boxes*, not the box-plus-caption columns — see [_DigitGroup]'s own
/// doc for how they stay pinned to the box regardless of the caption below.
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
/// **12h and 24h both supported, 24h is the default** (a deliberate reversal
/// of the old layrz_theme picker's 12h default — see [use24HourFormat]).
/// **No interval snapping** — any minute/second value 0–59 is permitted, no
/// stepping to multiples of 5 or similar.
///
/// **Mode-aware hour bounds.** The hour group's clamp range depends on
/// [use24HourFormat]:
/// - 24-hour mode: the hour group shows and clamps [LayrzTimeOfDay.hour] in
///   `0`–`23`. No AM/PM toggle is rendered.
/// - 12-hour mode: the hour group shows and clamps
///   [LayrzTimeOfDay.hour12] in `1`–`12` (never `0`–`11`, never `0`–`23`).
///   Edits route through [_setHour12], which performs the same
///   `%12 (+12 if PM)` normalization the previous field-row implementation
///   used — [LayrzTimeOfDay.hour12] already maps midnight and noon to `12`,
///   and [_setHour12] mirrors that back onto [LayrzTimeOfDay.hour] exactly.
///
/// Minute and second always clamp `0`–`59` regardless of hour format.
///
/// **Clamping happens on blur/submit, not per keystroke.** Each [_DigitField]
/// lets the user type freely (subject only to a digit-only
/// [FilteringTextInputFormatter]) and only clamps the typed value into range
/// when the field loses focus or the user submits it — see [_DigitField]'s
/// own doc. [onChanged] itself still clamps defensively as a backstop,
/// mirroring the safety net the old `time_field.dart` field wrapper provided.
///
/// **Tab order**: hour, then minute, then (if shown) second, then the
/// meridiem control when [use24HourFormat] is `false` — a sensible left-to-
/// right reading order with no custom `FocusTraversalPolicy` needed, since
/// [_DigitField] participates in Flutter's default traversal in source order.
class LayrzPickersTimeFieldsPanel extends StatelessWidget {
  /// The current time value.
  final LayrzTimeOfDay value;

  /// Called with the new time whenever any field changes. Fired on every
  /// keystroke-driven clamp or step — see this class's trap-4 doc above for
  /// why this must never be wired to close anything.
  final ValueChanged<LayrzTimeOfDay> onChanged;

  /// Whether the seconds group is shown.
  final bool showSeconds;

  /// Whether the hour group (and its bound) uses 24-hour form. Defaults to
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
    final spacing = tokens.spacing.sp2;

    final digitStyle = tokens.typography.display.copyWith(color: tokens.colors.fg1);
    final captionStyle = tokens.typography.label.copyWith(color: tokens.colors.fg2);

    // The colon must line up with the digit *boxes*, not with the captions
    // sitting below them. Each box is `tokens.spacing.sp2` taller than its
    // digit glyph on the top and bottom (the box's own vertical padding) plus
    // a 2px border reserve (see `_DigitField`), so the colon is pushed down
    // by that same amount before its text renders -- centering it on the box
    // instead of on the taller box+caption column an unadorned
    // `CrossAxisAlignment.start` would align it to.
    final colonTopOffset = tokens.spacing.sp2 + 2;
    final colon = Padding(
      padding: EdgeInsets.only(top: colonTopOffset, left: tokens.spacing.sp1, right: tokens.spacing.sp1),
      child: Text(':', style: digitStyle),
    );

    final hourField = use24HourFormat
        ? _DigitGroup(
            value: value.hour,
            minimum: 0,
            maximum: 23,
            onChanged: _setHour,
            style: digitStyle,
            caption: l10n.timePickerHours,
            captionStyle: captionStyle,
            gap: tokens.spacing.sp1,
          )
        : _DigitGroup(
            value: value.hour12,
            minimum: 1,
            maximum: 12,
            onChanged: (h) => _setHour12(h, isPm: value.isPm),
            style: digitStyle,
            caption: l10n.timePickerHours,
            captionStyle: captionStyle,
            gap: tokens.spacing.sp1,
          );

    final minuteField = _DigitGroup(
      value: value.minute,
      minimum: 0,
      maximum: 59,
      onChanged: _setMinute,
      style: digitStyle,
      caption: l10n.timePickerMinutes,
      captionStyle: captionStyle,
      gap: tokens.spacing.sp1,
    );

    final digitRow = <Widget>[hourField, colon, minuteField];
    if (showSeconds) {
      digitRow
        ..add(colon)
        ..add(
          _DigitGroup(
            value: value.second,
            minimum: 0,
            maximum: 59,
            onChanged: _setSecond,
            style: digitStyle,
            caption: l10n.timePickerSeconds,
            captionStyle: captionStyle,
            gap: tokens.spacing.sp1,
          ),
        );
    }

    return FocusTraversalGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: digitRow,
            ),
          ),
          if (!use24HourFormat) ...[
            SizedBox(height: spacing),
            _MeridiemControl(isPm: value.isPm, onChanged: _setMeridiem),
          ],
        ],
      ),
    );
  }
}

/// One `HH`/`MM`/`SS` group: a [_DigitField] box stacked above its small,
/// centered caption (`"Hours"`/`"Minutes"`/`"Seconds"`).
///
/// Kept as its own widget (rather than composing the [Column] inline in
/// [LayrzPickersTimeFieldsPanel.build]) so the colon separators in that
/// build method can stay siblings of these columns in a single
/// [IntrinsicHeight] row, pinned via `CrossAxisAlignment.start` to the
/// digit box's own top edge -- the colon must align to the box, not to the
/// taller box-plus-caption column, so a caption below never pushes the
/// colon down.
class _DigitGroup extends StatelessWidget {
  /// The current, already in-range value the inner [_DigitField] displays.
  final int value;

  /// The lowest value the inner [_DigitField] accepts once clamped.
  final int minimum;

  /// The highest value the inner [_DigitField] accepts once clamped.
  final int maximum;

  /// Called with the new, already-clamped value on blur or submit.
  final ValueChanged<int> onChanged;

  /// The text style applied to the typed digits.
  final TextStyle style;

  /// The full-word caption shown below the box, e.g. `"Hours"`.
  final String caption;

  /// The text style applied to [caption].
  final TextStyle captionStyle;

  /// The vertical gap between the digit box and its caption.
  final double gap;

  /// Creates a new [_DigitGroup].
  const _DigitGroup({
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
    required this.style,
    required this.caption,
    required this.captionStyle,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DigitField(
          value: value,
          minimum: minimum,
          maximum: maximum,
          onChanged: onChanged,
          style: style,
        ),
        SizedBox(height: gap),
        Text(caption, style: captionStyle, textAlign: TextAlign.center),
      ],
    );
  }
}

/// A bare, chrome-free digit-group field built directly on [EditableText] —
/// not [LayrzNumberInput] and not [LayrzTextInput].
///
/// This is the widget behind each `HH`/`MM`/`SS` group in the digital-clock
/// layout. It exists as its own primitive (rather than reusing an existing
/// input) because the big-digit look has no room for [LayrzInputChrome]'s
/// label/error/affix slots — but it still reads as a real input, not a bare
/// number: the [EditableText] sits inside its own filled, padded, rounded
/// box (`tokens.colors.sf2` background, [LayrzRadiusTokens.br2] corners,
/// [LayrzSpacingTokens.sp3] horizontal / [LayrzSpacingTokens.sp2] vertical
/// padding), which is what gives each digit group its bigger visual presence
/// — not an enlarged font. Focus is shown by the box itself tinting its
/// border to [LayrzColorTokens.primary] (a color change, not a geometry
/// change — see decision D15): the border is always painted, at the same
/// width, in a transparent color when unfocused, so the box never resizes
/// when focus toggles.
///
/// **Exactly one [EditableText] per instance** — this keeps every group
/// keyboard-accessible and discoverable by `find.byType(EditableText)`,
/// mirroring the discoverability contract every other input in this design
/// system already provides.
///
/// **Digit-only input.** A [FilteringTextInputFormatter.digitsOnly] rejects
/// any non-digit keystroke outright, and a [LengthLimitingTextInputFormatter]
/// caps entry at two characters (no group in this panel — hour, minute, or
/// second — ever needs a third digit).
///
/// **Clamp on blur, not on keystroke.** While the field has focus, whatever
/// digits the user has typed so far are shown verbatim (including an
/// intermediate, out-of-range, or empty value mid-edit) — clamping every
/// keystroke would fight the user typing a second digit (e.g. typing "1" then
/// "2" for "12" would otherwise clamp "1" against a `minimum` of 1 before the
/// second keystroke ever lands). The typed value is only clamped into
/// [minimum]–[maximum] and reported via [onChanged] when the field loses
/// focus ([FocusNode.hasFocus] flips to `false`) or the user submits it
/// (presses Enter / the keyboard's "done" action). [onChanged] itself still
/// clamps defensively before calling back, as a backstop mirroring the old
/// `time_field.dart` field wrapper's guarantee that a caller only ever
/// receives an in-range value.
class _DigitField extends StatefulWidget {
  /// The current, already in-range value this field displays when not being
  /// edited.
  final int value;

  /// The lowest value this field accepts once clamped.
  final int minimum;

  /// The highest value this field accepts once clamped.
  final int maximum;

  /// Called with the new, already-clamped value on blur or submit.
  final ValueChanged<int> onChanged;

  /// The text style applied to the typed digits.
  final TextStyle style;

  /// Creates a new [_DigitField].
  const _DigitField({
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
    required this.style,
  });

  @override
  State<_DigitField> createState() => _DigitFieldState();
}

/// State for [_DigitField].
class _DigitFieldState extends State<_DigitField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatted(widget.value));
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(_DigitField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only resync the displayed text from an external value change while the
    // field is not being actively edited -- otherwise a caller's own
    // clamp-on-`onChanged` echo would stomp the digits the user is still
    // mid-way through typing.
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = _formatted(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Two-digit, zero-padded display form, e.g. `6` -> `"06"`, `31` -> `"31"`.
  String _formatted(int v) => v.toString().padLeft(2, '0');

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) _commit();
  }

  /// Clamps whatever digits are currently typed into [_DigitField.minimum]–
  /// [_DigitField.maximum], reports the clamped value via
  /// [_DigitField.onChanged], and resyncs the displayed text to the clamped,
  /// zero-padded form. Called on blur and on submit — see this class's own
  /// "Clamp on blur" doc.
  void _commit() {
    final typed = int.tryParse(_controller.text);
    final clamped = (typed ?? widget.minimum).clamp(widget.minimum, widget.maximum);
    _controller.text = _formatted(clamped);
    widget.onChanged(clamped);
  }

  void _handleChanged(String text) {
    // Defensive backstop only -- see this class's "Clamp on blur" doc. A
    // value already within range is reported as-is so a caller watching
    // every keystroke (not just blur) still only ever observes in-range
    // values; an out-of-range or unparsable intermediate value is left
    // alone here and is only actually clamped in [_commit].
    final typed = int.tryParse(text);
    if (typed != null && typed >= widget.minimum && typed <= widget.maximum) {
      widget.onChanged(typed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focusNode.requestFocus(),
      child: AnimatedBuilder(
        animation: _focusNode,
        builder: (context, child) {
          return AnimatedContainer(
            duration: tokens.motion.dHover,
            curve: tokens.motion.easing,
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp3, vertical: tokens.spacing.sp2),
            decoration: BoxDecoration(
              color: tokens.colors.sf2,
              borderRadius: tokens.radius.br2,
              border: Border.all(
                color: _focusNode.hasFocus ? tokens.colors.primary : const Color(0x00000000),
                width: 2,
              ),
            ),
            child: child,
          );
        },
        child: IntrinsicWidth(
          child: EditableText(
            controller: _controller,
            focusNode: _focusNode,
            style: widget.style,
            cursorColor: tokens.colors.primary,
            backgroundCursorColor: tokens.colors.fg3,
            selectionColor: tokens.colors.primary.withValues(alpha: tokens.colors.tonalOpacity),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: _handleChanged,
            onSubmitted: (_) => _commit(),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

/// A two-state AM/PM toggle, built from two [LayrzButton]s side by side — no
/// custom tappable [Container]s, no Material `ToggleButtons`.
///
/// The currently-selected meridiem renders as [LayrzButtonStyle.filled] (a
/// solid, primary-accent button — [LayrzButtonType.custom] with no [color]
/// override defaults to [LayrzColorTokens.primary]), and the other renders
/// as [LayrzButtonStyle.text] (a quiet, no-fill/no-border button), so the
/// active state reads as prominent and the inactive one as a low-emphasis
/// alternative — matching how filled vs. text buttons are used everywhere
/// else in this design system. Both buttons stay tappable regardless of
/// selection: tapping the already-selected one re-fires [onChanged] with the
/// same value (a no-op from the caller's perspective), tapping the other
/// switches it.
///
/// Laid out as two equal-width [Expanded] cells in one [Row] with a small
/// gap between them. **Accessibility note:** [LayrzButton] already provides
/// button semantics (label, tap action, disabled state), but it has no
/// `selected` semantics flag the way the previous hand-rolled
/// `Semantics(selected: ...)` did — a screen reader announces "AM, button" /
/// "PM, button" but not which one is currently active. That is an accepted,
/// temporary regression versus the old control, not something this pass
/// attempts to recover; the visual filled/text contrast still communicates
/// the selection sightedly.
class _MeridiemControl extends StatelessWidget {
  /// Whether PM is the currently selected meridiem.
  final bool isPm;

  /// Called with the newly selected meridiem when either cell is tapped.
  final void Function({required bool isPm}) onChanged;

  /// Creates a new [_MeridiemControl].
  const _MeridiemControl({required this.isPm, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    Widget buildOption({required bool value, required String label}) {
      final isActive = isPm == value;
      return Expanded(
        child: LayrzButton(
          labelText: label,
          style: isActive ? LayrzButtonStyle.filled : LayrzButtonStyle.text,
          onTap: () => onChanged(isPm: value),
        ),
      );
    }

    return Row(
      children: [
        buildOption(value: false, label: l10n.timeMeridiemAm),
        SizedBox(width: tokens.spacing.sp1),
        buildOption(value: true, label: l10n.timeMeridiemPm),
      ],
    );
  }
}
