import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import '../models/month.dart';
import '../shared/grid_keyboard_handler.dart';
import '../shared/month_grid.dart';
import '../shared/picker_inline_footer.dart';

/// The surface content for [LayrzMonthInput]: a single
/// [LayrzPickersMonthGrid] page with its own year-navigation state.
///
/// **DESIGN-98: no longer commits on tap.** Before DESIGN-98 this surface had
/// no Cancel/Save footer at all — screenshot 2 (per the implementation plan)
/// read as "the 3-rows-by-4-columns month grid" rather than "a dialog", and a
/// tap fired [onMonthSelected] immediately (decision D75,
/// `engineering/milestone-4.md`). The maintainer's DESIGN-98 instruction
/// moves this widget onto [LayrzEndDrawer] **with actions**, which
/// supersedes that: a tap now only updates this surface's own in-progress
/// [_draft]; nothing is reported or closed until Save.
class LayrzMonthSurface extends StatefulWidget {
  /// The currently selected month, or `null`.
  final LayrzMonth? value;

  /// The earliest selectable month, inclusive.
  final LayrzMonth? minimum;

  /// The latest selectable month, inclusive.
  final LayrzMonth? maximum;

  /// Individually disabled months.
  final Set<LayrzMonth> disabledMonths;

  /// Called with the drafted month when the user presses Save. Never called
  /// for a disabled or unselected value.
  final ValueChanged<LayrzMonth> onMonthSelected;

  /// Called when the user presses Cancel or otherwise dismisses the surface
  /// involuntarily. `null` on the mobile [LayrzBottomSheet] path, which has
  /// no Cancel action of its own.
  final VoidCallback? onCancel;

  /// Called on every draft mutation (a month tap), so [LayrzMonthInput] can
  /// refresh the `actions` it builds outside this surface. Ignored when
  /// [showInlineFooter] is `true`.
  final VoidCallback? onDraftChanged;

  /// Whether this surface renders its own Cancel/Save footer inline, as the
  /// last child of its scrolling body.
  ///
  /// Defaults to `false` — see [LayrzDateSurface.showInlineFooter]'s
  /// identical doc for why every commit-on-tap-turned-Save-carrying surface
  /// defaults this to `false` rather than `true`.
  final bool showInlineFooter;

  /// Creates a new [LayrzMonthSurface].
  const LayrzMonthSurface({
    super.key,
    required this.value,
    this.minimum,
    this.maximum,
    this.disabledMonths = const {},
    required this.onMonthSelected,
    this.onCancel,
    this.onDraftChanged,
    this.showInlineFooter = false,
  });

  @override
  State<LayrzMonthSurface> createState() => LayrzMonthSurfaceState();
}

/// State for [LayrzMonthSurface].
///
/// **Public, not library-private, so [LayrzMonthInput] can reach it through a
/// [GlobalKey]** (DESIGN-98) — see [LayrzDateRangeSurfaceState]'s identical
/// class doc for the full rationale.
class LayrzMonthSurfaceState extends State<LayrzMonthSurface> {
  late int _displayedYear;

  /// The tapped-but-unsaved month. `null` until the user taps a cell.
  LayrzMonth? _draft;

  @override
  void initState() {
    super.initState();
    _seed();
    // Syncs the caller's external draft-state mirror immediately -- see
    // LayrzDateRangeSurfaceState's identical initState comment for why.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDraftChanged?.call());
  }

  @override
  void didUpdateWidget(LayrzMonthSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _seed();
  }

  void _seed() {
    _displayedYear = widget.value?.year ?? DateTime.now().year;
    _draft = widget.value;
  }

  void _handleYearChanged(int year) => setState(() => _displayedYear = year);

  void _handleMonthTap(DateTime date) {
    setState(() => _draft = LayrzMonth.fromDateTime(date));
    widget.onDraftChanged?.call();
  }

  /// Whether a draft month has been tapped and Save is reachable. Read by
  /// [LayrzMonthInput] through a [GlobalKey].
  bool get canSave => _draft != null;

  /// Commits the draft via [LayrzMonthSurface.onMonthSelected]. Invoked by
  /// [LayrzMonthInput] through a [GlobalKey] when the Save action it builds
  /// is pressed.
  void save() {
    final draft = _draft;
    if (draft == null) return;
    widget.onMonthSelected(draft);
  }

  /// Whether [month] is unselectable — mirrors [LayrzPickersMonthGrid]'s own
  /// internal `_isDisabled` exactly ([minimum]/[maximum] bounds plus
  /// [disabledMonths]), so `buildMonthGridKeyboardHandler`'s
  /// skip-disabled-cells and Enter/Space-never-selects-a-disabled-cell
  /// behavior agrees with what the grid itself would actually let a tap
  /// select. Duplicated rather than read back from the grid because
  /// [LayrzPickersMonthGrid] does not expose its resolved disabled set —
  /// see `grid_keyboard_handler.dart`'s `isDisabled` parameter doc.
  bool _isDisabled(DateTime month) {
    final minimum = widget.minimum?.toDateTime();
    final maximum = widget.maximum?.toDateTime();
    if (minimum != null && month.isBefore(DateTime(minimum.year, minimum.month))) return true;
    if (maximum != null && month.isAfter(DateTime(maximum.year, maximum.month))) return true;
    return widget.disabledMonths.any((m) => m.year == month.year && m.month == month.month);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayrzPickersMonthGrid(
            displayedYear: _displayedYear,
            onYearChanged: _handleYearChanged,
            reference: DateTime.now(),
            selectedMonth: _draft?.toDateTime(),
            minimum: widget.minimum?.toDateTime(),
            maximum: widget.maximum?.toDateTime(),
            disabledMonths: widget.disabledMonths.map((m) => m.toDateTime()).toSet(),
            onMonthTap: _handleMonthTap,
            keyboardHandler: buildMonthGridKeyboardHandler(
              isDisabled: _isDisabled,
              onSelect: _handleMonthTap,
              onYearChanged: _handleYearChanged,
            ),
          ),
          if (widget.showInlineFooter && widget.onCancel != null) ...[
            SizedBox(height: tokens.spacing.sp3),
            LayrzPickerInlineFooter(
              onCancel: widget.onCancel!,
              onSave: canSave ? save : null,
            ),
          ],
        ],
      ),
    );
  }
}
