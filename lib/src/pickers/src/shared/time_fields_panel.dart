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
/// same slot and the same [LayrzNumberInput] chrome either way, so this
/// never introduces the kind of reflow D15 already forbids for
/// [showSeconds].
///
/// **Fields wrap across rows, driven by [LayrzPickersTimeField.kNarrowWidth]
/// (Finding 3, DESIGN-98).** Before this, the three time fields
/// (hour/minute/second) always shared a single row regardless of available
/// width -- correct under the old
/// [LayrzAnchoredPanelWidthPolicy.matchAnchor] container (an anchor field's
/// own, often-wide, width), but inside the fixed 420px-wide
/// [LayrzEndDrawer] this panel actually receives only ~372px (420 minus the
/// drawer's own `2*sp3` padding minus the hosting surface's own `sp2`
/// padding -- see `LayrzDateTimeSurface`/`LayrzTimeSurface`'s own
/// `Padding`), which put every field at 120px on a fixed 3-field row --
/// below even [_kFieldFloorWidth] (140.0). [build] now solves `n *
/// kNarrowWidth + (n-1) * spacing <= availableWidth` for the largest n
/// (mirroring [LayrzDurationPickerPanel]'s `fieldsPerRow` derivation in
/// spirit, adapted to solve against the label-length threshold rather than
/// the hard overflow floor -- see the `fieldsPerRow` local in [build] for
/// why: a lone field on its own row always receives the full
/// [availableWidth], so reducing the field count per row can only ever
/// widen the fields that remain, never narrow them, which makes the label
/// threshold the binding constraint long before the hard floor could be).
/// At drawer width this solves to **one field per row**, each stretched to
/// the panel's own full ~372px width -- comfortably above [kNarrowWidth]
/// (280.0), which is also what **restores the long-form**
/// `timePickerHours`/`timePickerMinutes`/`timePickerSeconds` **labels**
/// inside the drawer, reversing what an earlier pass had documented as a
/// permanent loss of the unabridged labels once the drawer replaced the old
/// wide-anchor container. The maintainer's own words -- *"it should look
/// like the number input"*, referring to [LayrzDurationPickerPanel]'s
/// stacked full-width `− value label +` rows -- are the target shape this
/// produces at drawer width.
///
/// **The meridiem control joins the last field row when it fits there
/// without pushing any field below [_kFieldFloorWidth]; otherwise it drops
/// to its own row below every field row.** This is the same width-driven
/// decision the pre-wrap implementation made (there was only ever one field
/// row to consider); it now also accounts for however many field rows the
/// wrap above produced. A field row of exactly one field never shares that
/// row with the meridiem control -- the maintainer's target shape is a
/// stack of single, full-width rows -- so the meridiem control gets its own
/// row whenever [fieldsPerRow] resolves to 1. The wrap is a response to
/// available width alone, never to hover/press/focus state, so D15 still
/// holds within any single width.
///
/// **The field row never stretches wider than [_kMaxRowWidth].** DESIGN-47:
/// the maintainer's own words, with a screenshot, were *"It must fillup the
/// fields completely"* -- the screenshot showed two [LayrzPickersTimeField]s
/// sitting in a very wide host (the old anchored panel, which matched a wide
/// input field's own width) with the `+`/`−` steppers and suffix labels
/// bunched at the far edges of each field and a large dead gap in the middle,
/// because [LayrzNumberInput]'s content is centered within whatever width its
/// own `Expanded` chrome is given rather than stretched to fill it. The fix
/// is not inside [LayrzNumberInput] (out of scope for this fix, and shared by
/// every numeric field in the library) -- it is to stop handing this row more
/// width than it needs in the first place. [build] centers a
/// [ConstrainedBox]-capped copy of [availableWidth] and derives every
/// field-width computation below from that capped value, not the raw
/// [LayoutBuilder] constraint, so a field reads as one coherent, tightly
/// packed control regardless of how wide its host (an [LayrzEndDrawer] or a
/// [LayrzBottomSheet]) happens to be. **This does not touch the existing
/// 280px/140px thresholds** ([LayrzPickersTimeField.kNarrowWidth],
/// [_kFieldFloorWidth]): those are evaluated against the same capped width a
/// narrow host already provides unchanged (a host narrower than
/// [_kMaxRowWidth] is unaffected by the cap), so the narrow-width regressions
/// those constants exist to prevent keep passing exactly as before.
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
          // (LayrzEndDrawer or LayrzBottomSheet's Padding, see the class
          // doc's _bounded reasoning), so its own
          // constraints -- not the device's viewport size -- are what
          // determine whether a field's label fits. Mirrors
          // LayrzDurationPickerPanel's identical LayoutBuilder-over-MediaQuery
          // choice; see LayrzPickersTimeField.kNarrowWidth for the
          // measurement basis.
          //
          // Capped at _kMaxRowWidth (see that constant's doc and this
          // class's "field row never stretches" note) -- every width
          // computation below derives from this capped value, not the raw
          // constraint, so a wide host never leaves the fields stretched
          // apart with dead space between them.
          final availableWidth = constraints.maxWidth.clamp(0.0, _kMaxRowWidth);

          // How many of the three time-field slots (hour, minute, second --
          // second always reserves its slot even when hidden, see the
          // Visibility(maintainSize: true) below) share one row.
          //
          // Solved against LayrzPickersTimeField.kNarrowWidth (280.0), NOT
          // _kFieldFloorWidth (140.0): a lone field on its own row always
          // receives the FULL availableWidth (there is no way for fewer
          // fields per row to ever produce a narrower field -- reducing
          // fieldsPerRow only ever widens the fields that remain on each
          // row), so the label-length threshold, not the hard
          // overflow-safety floor, is what actually decides how many fields
          // pack into one row. This mirrors LayrzDurationPickerPanel's
          // `fieldsPerRow` derivation in spirit (solve n * threshold +
          // (n-1) * spacing <= availableWidth for the largest n), but against
          // the label threshold rather than the hard minimum, since Duration
          // has no separate "still renders, just abbreviated" width band the
          // way this panel's narrow-label switch provides -- see this
          // class's own "Fields wrap across rows" doc for the DESIGN-98
          // arithmetic this restores (one field per row inside the 420px
          // LayrzEndDrawer). Unlike Duration's variable field count, this
          // panel always has exactly 3 slots, so the upper bound is fixed at
          // 3 rather than derived from a visible-units set.
          //
          // _kFieldFloorWidth remains the hard overflow-safety floor used
          // only by the separate meridiem-sharing decision below, where a
          // full row's width is already fixed and the only question is
          // whether an additional trailing control still fits inside it.
          const fieldSlots = 3;
          final fieldsPerRow = ((availableWidth + spacing) / (LayrzPickersTimeField.kNarrowWidth + spacing))
              .floor()
              .clamp(1, fieldSlots);

          // The width each field receives once fieldsPerRow fields evenly
          // share availableWidth -- used for the narrow-label decision below.
          // This is the width of a FULL row; the meridiem-sharing check
          // further down separately re-derives the width for the specific
          // row the meridiem control might join.
          final perFieldWidthFullRow = (availableWidth - spacing * (fieldsPerRow - 1)) / fieldsPerRow;
          final isNarrow = perFieldWidthFullRow < LayrzPickersTimeField.kNarrowWidth;

          final displayedHour = use24HourFormat ? value.hour : value.hour12;

          final hourField = use24HourFormat
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
                );

          final minuteField = LayrzPickersTimeField(
            value: value.minute,
            minimum: 0,
            maximum: 59,
            onChanged: _setMinute,
            label: _minuteLabel(l10n, isNarrow: isNarrow),
            hintText: l10n.timePickerMinutes,
          );

          // Always present in the tree at the same size, whether visible or
          // not, so toggling `showSeconds` never reflows the panel -- see
          // this class's doc comment (D15).
          final secondField = Visibility(
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
          );

          final fields = [hourField, minuteField, secondField];

          // Whether the meridiem control can share the LAST field row
          // without pushing any field on that row below _kFieldFloorWidth.
          // A full multi-field row (fieldsPerRow >= 2) may have room; a
          // lone field on its own row (fieldsPerRow == 1) never shares --
          // the maintainer's target shape at that width is a stack of
          // single, full-width rows, not a field squeezed beside a
          // meridiem toggle. See this class's own "meridiem control joins
          // the last field row" doc.
          final fieldsOnLastRow = fieldSlots - (fieldsPerRow * ((fieldSlots - 1) ~/ fieldsPerRow));
          final lastRowFieldsWidth = availableWidth - spacing * (fieldsOnLastRow - 1);
          final meridiemReserved = spacing + _kMeridiemWidthEstimate;
          final lastRowWithMeridiemPerField = (lastRowFieldsWidth - meridiemReserved) / fieldsOnLastRow;
          final meridiemSharesLastRow =
              use24HourFormat == false && fieldsPerRow > 1 && lastRowWithMeridiemPerField >= _kFieldFloorWidth;

          final fieldRows = _wrapFields(
            fields: fields,
            availableWidth: availableWidth,
            fieldsPerRow: fieldsPerRow,
            spacing: spacing,
            trailingOnLastRow: meridiemSharesLastRow
                ? IntrinsicWidth(
                    child: _MeridiemControl(isPm: value.isPm, onChanged: _setMeridiem),
                  )
                : null,
            trailingWidth: meridiemReserved,
          );

          final body = !use24HourFormat && !meridiemSharesLastRow
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    fieldRows,
                    SizedBox(height: spacing),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: IntrinsicWidth(
                        child: _MeridiemControl(isPm: value.isPm, onChanged: _setMeridiem),
                      ),
                    ),
                  ],
                )
              : fieldRows;

          // Sizes the (possibly capped) body to exactly availableWidth and
          // centers it within whatever wider width LayoutBuilder's raw
          // constraints actually offered -- the mechanism behind "the field
          // row never stretches wider than _kMaxRowWidth" (see this class's
          // doc comment). When the host is already narrower than
          // _kMaxRowWidth, availableWidth equals constraints.maxWidth and
          // this is a no-op: the SizedBox merely matches the width the body
          // would already have taken.
          return Center(
            child: SizedBox(width: availableWidth, child: body),
          );
        },
      ),
    );
  }

  /// Lays [fields] out across as many rows of [fieldsPerRow] as needed,
  /// each row's fields stretched evenly to fill [availableWidth] -- mirrors
  /// [LayrzDurationPickerPanel]'s identical `_wrapFields` helper, adapted
  /// for this panel's two differences: a fixed 3-field count (Duration's
  /// field count varies with [LayrzDurationPickerPanel.visibleUnits]), and
  /// an optional [trailingOnLastRow] widget (the meridiem control) appended
  /// after the last row's fields when it fits there -- see this class's own
  /// "meridiem control joins the last field row" doc for when that happens.
  /// [trailingWidth] reserves that widget's own share of the last row's
  /// width so the fields sharing that row are not stretched into it.
  Widget _wrapFields({
    required List<Widget> fields,
    required double availableWidth,
    required int fieldsPerRow,
    required double spacing,
    required Widget? trailingOnLastRow,
    required double trailingWidth,
  }) {
    final rows = <Widget>[];
    for (var i = 0; i < fields.length; i += fieldsPerRow) {
      final rowFields = fields.sublist(i, (i + fieldsPerRow).clamp(0, fields.length));
      final isLastRow = i + fieldsPerRow >= fields.length;
      final hasTrailing = isLastRow && trailingOnLastRow != null;

      final rowWidth = hasTrailing ? availableWidth - trailingWidth : availableWidth;
      final gapWidth = spacing * (rowFields.length - 1);
      final fieldWidth = (rowWidth - gapWidth) / rowFields.length;

      final rowChildren = <Widget>[];
      for (var j = 0; j < rowFields.length; j++) {
        rowChildren.add(SizedBox(width: fieldWidth, child: rowFields[j]));
        if (j < rowFields.length - 1) {
          rowChildren.add(SizedBox(width: spacing));
        }
      }
      if (hasTrailing) {
        rowChildren.add(SizedBox(width: spacing));
        rowChildren.add(trailingOnLastRow);
      }

      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowChildren));
      if (i + fieldsPerRow < fields.length) {
        rows.add(SizedBox(height: spacing));
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

/// The field row's own maximum width, in logical pixels, regardless of how
/// wide its host actually is.
///
/// See [LayrzPickersTimeFieldsPanel]'s "field row never stretches wider than
/// [_kMaxRowWidth]" doc section for the DESIGN-47 problem this solves.
///
/// **900.0, not a smaller value** -- the floor is not "whatever fits three
/// fields", it is "whatever this file's own narrow-width regressions already
/// rely on staying unabridged." `time_fields_panel_test.dart`'s "at or above
/// the narrow-width threshold" test pins exactly 900px as the width three
/// unabridged-label fields ([LayrzPickersTimeField.kNarrowWidth] each, 280.0)
/// plus two [spacing] (sp1, 6.0) gaps first clears comfortably
/// (`(900 - 6*2) / 3 = 296px`, just above 280.0). A cap below 900 would
/// silently re-trigger that same narrow-width label switch this file's own
/// suite already guards against — 900.0 is the smallest cap that cannot
/// regress it, not a number chosen for its own sake. Still comfortably below
/// what a wide desktop input field's drawer width (this panel's other host,
/// alongside [LayrzEndDrawer.width] at 420.0, already narrower than this cap
/// and therefore unaffected by it) can otherwise stretch to.
const double _kMaxRowWidth = 900.0;

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
