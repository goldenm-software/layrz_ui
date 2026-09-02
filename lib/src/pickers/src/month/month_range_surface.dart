import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import '../models/month.dart';
import '../models/month_range.dart';
import '../shared/grid_keyboard_handler.dart';
import '../shared/month_grid.dart';
import '../shared/picker_drawer_footer.dart';
import '../shared/range_draft.dart';
import '../shared/range_policy.dart';

/// The surface content for [LayrzMonthRangeInput]: a [LayrzPickersMonthGrid]
/// plus a Cancel/Clear/Save footer.
///
/// **Container**: as of DESIGN-49, [LayrzMonthRangeInput] hosts this surface
/// in [LayrzPickerDrawer] on desktop, [LayrzBottomSheet] below `isCompact` —
/// see [LayrzPickerDrawer]'s own class doc for the maintainer's ruling. That
/// container wiring lives in `month_range_input.dart`, not this file. Order
/// and styling of the footer follow [LayrzPickerDrawerFooter]'s own doc
/// (DESIGN-46).
///
/// **Switches its selection policy by [consecutive]** — [LayrzArbitraryRangePolicy]
/// (default, set-membership, no adjacency concept) or
/// [LayrzContiguousRangePolicy] (endpoint-adjust state machine, identical in
/// shape to [LayrzDateRangeSurface]'s). **This is the sole surface in the
/// batch where the arbitrary policy is reachable** — every other range
/// widget is contiguous-only, per the maintainer's explicit carve-out.
///
/// In arbitrary mode there is no "interior" concept: every unselected month
/// is always tappable, and every selected month is individually
/// deselectable by tapping it again — the old "interior locked, only
/// endpoints deselectable" model does not apply here even in spirit, because
/// there is no anchor/end pair to lock an interior against.
///
/// **Cancel/Save live inside this panel, visible from the first frame** —
/// `liliana`'s hard requirement that a range surface never leave the user
/// guessing whether a tap already counted. Reset is visible as soon as
/// anything is selected.
///
/// **Involuntary close discards the draft**: [initState] and
/// [didUpdateWidget] both re-seed [_draft] (and the displayed year) from
/// [widget.arbitraryValue]/[widget.rangeValue], so a dismissed panel never
/// leaves stale in-progress state for the next open — see the implementation
/// plan's "Involuntary close" section, which cites [LayrzAnchoredPanel]'s
/// eager-child `State` reuse as the mechanism this guards against. No
/// generation-key/`ValueKey` forced-reconstruction is used here: closing an
/// anchored panel removes its overlay entry rather than hiding it, so a
/// reopen already reconstructs this widget's `State` and reruns [initState]
/// on its own — the re-seed in [didUpdateWidget] exists for the (rarer) case
/// of the hosting widget rebuilding this surface in place without a
/// close/reopen cycle.
class LayrzMonthRangeSurface extends StatefulWidget {
  /// Whether this surface operates in consecutive (contiguous) mode via
  /// [LayrzContiguousRangePolicy] rather than the default arbitrary
  /// (non-contiguous) multi-select mode via [LayrzArbitraryRangePolicy].
  final bool consecutive;

  /// The currently committed selection in arbitrary mode. Ignored when
  /// [consecutive] is `true`.
  final List<LayrzMonth> arbitraryValue;

  /// The currently committed range in consecutive mode. Ignored when
  /// [consecutive] is `false`.
  final LayrzMonthRange? rangeValue;

  /// The earliest selectable month, inclusive.
  final LayrzMonth? minimum;

  /// The latest selectable month, inclusive.
  final LayrzMonth? maximum;

  /// Individually disabled months. **Ignored in consecutive mode**, matching
  /// old layrz_theme behaviour.
  final Set<LayrzMonth> disabledMonths;

  /// Called with the sorted selected months when the user presses Save in
  /// arbitrary mode.
  final ValueChanged<List<LayrzMonth>> onArbitrarySave;

  /// Called with the saved range when the user presses Save in consecutive
  /// mode.
  final ValueChanged<LayrzMonthRange> onRangeSave;

  /// Called when the user presses Cancel or otherwise dismisses the panel
  /// involuntarily. The caller is responsible for actually closing the
  /// hosting surface; this widget only reports the intent.
  final VoidCallback onCancel;

  /// Creates a new [LayrzMonthRangeSurface].
  const LayrzMonthRangeSurface({
    super.key,
    required this.consecutive,
    required this.arbitraryValue,
    required this.rangeValue,
    this.minimum,
    this.maximum,
    this.disabledMonths = const {},
    required this.onArbitrarySave,
    required this.onRangeSave,
    required this.onCancel,
  });

  @override
  State<LayrzMonthRangeSurface> createState() => _LayrzMonthRangeSurfaceState();
}

class _LayrzMonthRangeSurfaceState extends State<LayrzMonthRangeSurface> {
  late LayrzRangeDraft<LayrzMonth> _draft;
  late int _displayedYear;

  /// The consecutive-mode policy, ordering months chronologically via
  /// [LayrzMonth.compareTo].
  final _contiguousPolicy = LayrzContiguousRangePolicy<LayrzMonth>(compare: (a, b) => a.compareTo(b));

  /// The default arbitrary-mode policy: pure set membership, no adjacency.
  final _arbitraryPolicy = const LayrzArbitraryRangePolicy<LayrzMonth>();

  LayrzRangePolicy<LayrzMonth> get _policy => widget.consecutive ? _contiguousPolicy : _arbitraryPolicy;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  @override
  void didUpdateWidget(LayrzMonthRangeSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.consecutive != widget.consecutive ||
        oldWidget.arbitraryValue != widget.arbitraryValue ||
        oldWidget.rangeValue != widget.rangeValue) {
      _seed();
    }
  }

  /// Re-seeds [_draft] and [_displayedYear] from the widget's committed
  /// value for the active mode. See the class doc's "Involuntary close"
  /// paragraph for why this must run on every genuine external value change,
  /// not only in [initState].
  void _seed() {
    if (widget.consecutive) {
      final range = widget.rangeValue;
      _draft = range == null
          ? const LayrzRangeDraft<LayrzMonth>.empty()
          : LayrzRangeDraft<LayrzMonth>.complete(anchor: range.start, end: range.end);
      _displayedYear = range?.start.year ?? DateTime.now().year;
    } else {
      final selection = widget.arbitraryValue.toSet();
      _draft = LayrzRangeDraft<LayrzMonth>.arbitrary(selection);
      _displayedYear = widget.arbitraryValue.isEmpty ? DateTime.now().year : widget.arbitraryValue.first.year;
    }
  }

  void _handleTap(DateTime monthDate) {
    final month = LayrzMonth.fromDateTime(monthDate);
    setState(() => _draft = _policy.onTap(_draft, month));
  }

  void _handleReset() => setState(() => _draft = const LayrzRangeDraft<LayrzMonth>.empty());

  void _handleYearChanged(int year) => setState(() => _displayedYear = year);

  /// Whether [monthDate] is unselectable — mirrors [LayrzPickersMonthGrid]'s
  /// own internal [minimum]/[maximum] bounds plus this surface's own
  /// per-mode rules ([disabledMonths] only in arbitrary mode, matching
  /// [build]'s identical carve-out; [_policy.isRejected] for the
  /// contiguous-mode interior lock), so `buildMonthGridKeyboardHandler`'s
  /// skip-disabled-cells and Enter/Space-never-selects behavior agrees with
  /// what the grid itself would actually let a tap select. See
  /// `LayrzMonthSurface._isDisabled`'s identical doc for why this is
  /// duplicated rather than read back from the grid.
  bool _isDisabled(DateTime monthDate) {
    final minimum = widget.minimum?.toDateTime();
    final maximum = widget.maximum?.toDateTime();
    if (minimum != null && monthDate.isBefore(DateTime(minimum.year, minimum.month))) return true;
    if (maximum != null && monthDate.isAfter(DateTime(maximum.year, maximum.month))) return true;
    if (!widget.consecutive) {
      return widget.disabledMonths.any((m) => m.year == monthDate.year && m.month == monthDate.month);
    }
    return _policy.isRejected(_draft, LayrzMonth.fromDateTime(monthDate));
  }

  bool get _hasSelection => widget.consecutive ? _draft.anchor != null : _draft.arbitrarySelection.isNotEmpty;

  bool get _canSave => widget.consecutive ? _draft.isComplete : _draft.arbitrarySelection.isNotEmpty;

  void _handleSave() {
    if (!_canSave) return;
    if (widget.consecutive) {
      widget.onRangeSave(LayrzMonthRange(start: _draft.anchor as LayrzMonth, end: _draft.end as LayrzMonth));
    } else {
      final sorted = _draft.arbitrarySelection.toList()..sort();
      widget.onArbitrarySave(sorted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final visibleMonths = [for (var m = 1; m <= 12; m++) LayrzMonth(year: _displayedYear, month: m)];

    // Only the contiguous policy has an "interior" concept to reject --
    // LayrzArbitraryRangePolicy.isRejected always returns false, so this set
    // is empty (and every cell tappable) in arbitrary mode.
    final rejected = {
      for (final m in visibleMonths)
        if (_policy.isRejected(_draft, m)) m.toDateTime(),
    };

    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayrzPickersMonthGrid(
            displayedYear: _displayedYear,
            onYearChanged: _handleYearChanged,
            reference: DateTime.now(),
            rangeStart: widget.consecutive ? _draft.anchor?.toDateTime() : null,
            rangeEnd: widget.consecutive ? _draft.end?.toDateTime() : null,
            arbitrarySelection: widget.consecutive
                ? const {}
                : _draft.arbitrarySelection.map((m) => m.toDateTime()).toSet(),
            rejectedMonths: rejected,
            minimum: widget.minimum?.toDateTime(),
            maximum: widget.maximum?.toDateTime(),
            disabledMonths: widget.consecutive ? const {} : widget.disabledMonths.map((m) => m.toDateTime()).toSet(),
            onMonthTap: _handleTap,
            keyboardHandler: buildMonthGridKeyboardHandler(
              isDisabled: _isDisabled,
              onSelect: _handleTap,
              onYearChanged: _handleYearChanged,
            ),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzPickerDrawerFooter(
            onCancel: widget.onCancel,
            onClear: _hasSelection ? _handleReset : null,
            onSave: _canSave ? _handleSave : null,
          ),
        ],
      ),
    );
  }
}
