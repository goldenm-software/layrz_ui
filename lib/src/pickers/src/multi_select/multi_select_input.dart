import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/dialogs/dialogs.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../shared/picker_anchor.dart';
import '../shared/picker_metrics.dart';
import 'multi_select_surface.dart';

/// A Material-free, adaptive multiple-value picker input in the layrz_ui
/// design system.
///
/// [LayrzMultiSelectInput] mirrors [LayrzSelectInput]'s adaptive-surface,
/// searchable-list pattern — opened via [LayrzResponsiveModal.show], which
/// resolves to a dialog on wide viewports (`>= 960px`) or a
/// [LayrzBottomSheet] below `isCompact` (`< 960px`) — but resolves to a
/// **`List<T>`** of selected values instead of a single one. It composes
/// [LayrzInputChrome] directly through the `pickers/shared/picker_anchor.dart`
/// helpers (D63), never `input_chrome.dart` itself, matching every other
/// widget under `lib/src/pickers/`.
///
/// **Closed field display: comma-joined labels, not a count, not chips.**
/// When one or more items are selected, the field renders their
/// [LayrzSelectItem.child] text content joined with `", "` (e.g. `"Apple,
/// Banana, Cherry"`), truncated with an ellipsis when it overflows the
/// field's width — see [_joinedLabels] and its own doc for how the label
/// text is derived from each [LayrzSelectItem.child] without requiring a
/// separate string field on the item. This is a deliberate Decision: a
/// count ("3 selected") loses which three, and per-item chips need
/// unbounded vertical room this field's fixed height does not have.
///
/// **COMMIT MODEL — staged-with-Save (Decision, deliberate divergence from
/// `layrz_theme`'s `ThemedMultiSelectInput`).** `ThemedMultiSelectInput`
/// commits on every tap by default (`waitUntilClosedToSubmit` opts into
/// batching). This widget does the opposite unconditionally: the opened
/// [LayrzMultiSelectInputSurface] carries a Cancel / Select-All
/// (Unselect-All) / Save actions row
/// ([LayrzMultiSelectInput._MultiSelectDrawerActions]), and
/// - tapping a row toggles it in the surface's own internal draft only —
///   [onChanged] is **not** called and the surface does **not** close;
/// - "Select all" / "Unselect all" mutate that same draft only, exactly
///   like a row tap — no callback, no close;
/// - **Save** is the only action that calls [onChanged], with the drafted
///   list, and closes the surface;
/// - **Cancel** closes the surface without calling [onChanged] at all,
///   discarding every tap made since the surface was opened.
///
/// This matches the convention every other `pickers/` widget already
/// follows (date/time/month all commit on Save, not on tap — DESIGN-98),
/// rather than the tap-commits default `LayrzSelectInput` itself uses for a
/// *single* value, where committing on tap is uncontroversial because
/// there is nothing left to also decide afterward. A caller migrating from
/// `ThemedMultiSelectInput`'s default should expect [onChanged] to fire
/// **once**, on Save, with the full drafted list — not once per tap.
///
/// **Self-display**, mirroring [LayrzSelectInput]: the field renders from
/// its own internal `_displayedValues`, updated immediately when Save
/// commits, independent of whether the caller feeds an updated [value]
/// back on the next build. A caller-supplied [value] change is still
/// honored via [didUpdateWidget].
class LayrzMultiSelectInput<T> extends StatefulWidget {
  /// The list of items to choose from.
  ///
  /// Each item combines a typed value, a required presentation widget
  /// ([LayrzSelectItem.child]), and search metadata
  /// ([LayrzSelectItem.searchableStrings]). See [LayrzSelectItem] — read-only
  /// reference from `inputs/`, shared verbatim with [LayrzSelectInput].
  final List<LayrzSelectItem<T>> items;

  /// The currently selected values.
  ///
  /// May be empty to represent no selection. Feeding this back after
  /// [onChanged] fires is not required for the field's own display to
  /// update (see the class doc's self-display note), but a caller-supplied
  /// change is still honored and reconciles the field's internal display
  /// state.
  final List<T> value;

  /// Callback fired once, when the user presses Save in the opened surface,
  /// with the full drafted list of selected values (see the class doc's
  /// COMMIT MODEL section). Never called for a row tap, Select All,
  /// Unselect All, or Cancel.
  final ValueChanged<List<T>>? onChanged;

  /// Whether the opened selection surface renders its own search field.
  ///
  /// Defaults to `true`. When false, the surface has no search field of its
  /// own — arrow keys alone navigate its list, matching
  /// [LayrzSelectInput.enableSearch]'s identical contract.
  final bool enableSearch;

  /// Optional custom filter function for search results.
  ///
  /// If provided, replaces the default [LayrzSelectItem.matches] logic.
  /// Called with the search query and each item; should return `true` if
  /// the item matches. When null, uses [LayrzSelectItem.matches] instead.
  final bool Function(String query, LayrzSelectItem<T> item)? filter;

  /// Text displayed when the search finds no matching items.
  ///
  /// If null, defaults to localized text from [LayrzUiL10n.selectEmpty].
  final String? emptyListText;

  /// The label text displayed above the input field.
  final String? labelText;

  /// Hint text displayed as placeholder when the field has no selection.
  final String? hintText;

  /// Whether the field is marked as required.
  final bool isRequired;

  /// The title text for the help affordance tooltip.
  final String? helpTitleText;

  /// The content text for the help affordance tooltip.
  final String? helpContentText;

  /// Whether the field is disabled.
  ///
  /// Disabled fields do not open the selection surface on tap.
  final bool disabled;

  /// The list of error messages to display below the field.
  final List<String> errors;

  /// Whether to hide the error message block and other detail text.
  final bool hideDetails;

  /// The text editing controller for the anchor field's chrome. If null, one
  /// is created and disposed by the widget. Never fed the joined label text
  /// — the chrome reads it only for its own hint-visibility bookkeeping,
  /// mirroring [LayrzDateInput.controller]'s identical role.
  final TextEditingController? controller;

  /// The focus node for the anchor field. If null, one is created and
  /// disposed by the widget.
  final FocusNode? focusNode;

  /// Whether the field uses the dense density variant.
  final bool dense;

  /// Defines the expected height of each item in the opened surface's list.
  ///
  /// Must be at least [kLayrzPickerMinItemExtent] (52px) — every row renders
  /// a full [LayrzCheckboxInput] as its reflective selection indicator,
  /// which is 40px tall on its own, plus the row's own vertical padding; a
  /// smaller extent overflows the row (see [kLayrzPickerMinItemExtent]'s own
  /// doc for the full accounting). Enforced by an assertion in the
  /// constructor rather than left as a silent overflow.
  final double itemExtent;

  /// Creates a new [LayrzMultiSelectInput].
  const LayrzMultiSelectInput({
    super.key,
    required this.items,
    this.value = const [],
    this.onChanged,
    this.enableSearch = true,
    this.filter,
    this.emptyListText,
    this.labelText,
    this.hintText,
    this.isRequired = false,
    this.helpTitleText,
    this.helpContentText,
    this.disabled = false,
    this.errors = const [],
    this.hideDetails = false,
    this.controller,
    this.focusNode,
    this.dense = false,
    required this.itemExtent,
  }) : assert(
         labelText != null || hintText != null,
         'At least one of labelText or hintText must be non-null.',
       ),
       assert(
         itemExtent >= kLayrzPickerMinItemExtent,
         'itemExtent must be >= $kLayrzPickerMinItemExtent to fit the row content (checkbox + padding) '
         'without a vertical overflow.',
       );

  @override
  State<LayrzMultiSelectInput<T>> createState() => _LayrzMultiSelectInputState<T>();
}

class _LayrzMultiSelectInputState<T> extends State<LayrzMultiSelectInput<T>> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  /// The values the field currently displays, independent of
  /// [LayrzMultiSelectInput.value] once a Save has committed locally — see
  /// the class doc's self-display note.
  late List<T> _displayedValues;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _displayedValues = List.of(widget.value);
  }

  @override
  void didUpdateWidget(LayrzMultiSelectInput<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) _controller.dispose();
      _controller = widget.controller ?? TextEditingController();
    }
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (!_listEquals(widget.value, oldWidget.value)) {
      _displayedValues = List.of(widget.value);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  bool _listEquals(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Commits [values] as the current selection (Save only — see the class
  /// doc's COMMIT MODEL section). Updates [_displayedValues] immediately,
  /// then notifies [LayrzMultiSelectInput.onChanged].
  void _commitSelection(List<T> values) {
    setState(() {
      _displayedValues = values;
    });
    widget.onChanged?.call(values);
  }

  /// Extracts each selected item's plain-text label from its
  /// [LayrzSelectItem.child], joined with `", "`, for the closed field's
  /// comma-joined display (see the class doc).
  ///
  /// [LayrzSelectItem.child] is an arbitrary [Widget] with no separate
  /// label string — this walks it looking for [Text]/[RichText], mirroring
  /// how [LayrzSelectItem.searchableStrings] is the item's *only* other
  /// string surface. A [child] that renders no text at all (a bare icon or
  /// color swatch with no [Semantics] label) contributes an empty string,
  /// which reads as an extra `", "` in the joined output rather than
  /// silently dropping the item — a caller relying on this display for a
  /// non-textual item should supply `searchableStrings` with the intended
  /// label text instead, or accept the visual gap.
  String _labelFor(LayrzSelectItem<T> item) {
    final widgetToInspect = item.child;
    if (widgetToInspect is Text) {
      return widgetToInspect.data ?? widgetToInspect.textSpan?.toPlainText() ?? '';
    }
    if (widgetToInspect is RichText) {
      return widgetToInspect.text.toPlainText();
    }
    return '';
  }

  /// Builds the comma-joined label string for [_displayedValues], in
  /// [LayrzMultiSelectInput.items]' own order (not selection order) —
  /// matches [LayrzMultiSelectInputSurfaceState.save]'s identical ordering
  /// convention, so the closed field's order never disagrees with what the
  /// surface would show pre-selected on reopen.
  String _joinedLabels() {
    final selectedSet = _displayedValues.toSet();
    final labels = <String>[
      for (final item in widget.items)
        if (item.value != null && selectedSet.contains(item.value)) _labelFor(item),
    ];
    return labels.join(', ');
  }

  /// Opens [LayrzMultiSelectInputSurface] via [LayrzResponsiveModal.show],
  /// which resolves to a dialog on wide viewports or a [LayrzBottomSheet]
  /// below `isCompact`.
  ///
  /// **Bigger dialog + pinned header/search, scrolling list only (maintainer
  /// review).** [LayrzMultiSelectInputSurface] no longer needs a
  /// `ConstrainedBox`/`SingleChildScrollView` pairing imposed by this caller:
  /// its own root `Column` now pins the header (title, inline search, close)
  /// and lets only its `Expanded`-wrapped `ListView` scroll — see that
  /// widget's own [LayrzMultiSelectInputSurface.build] doc for the full
  /// layout. That `Expanded` needs a genuinely bounded incoming height,
  /// which it gets here from [LayrzDialogConfig]'s enlarged `maxWidth`/
  /// `maxHeight` (roomier than the 480×640 default, per the maintainer's
  /// request) flowing down through [LayrzResponsiveModal.show]'s dialog
  /// branch exactly the way every other pinned-`actions` picker
  /// (`LayrzPickerDrawerActions` siblings) already relies on a bounded
  /// `Flexible` around its own builder content — no `SizedBox`/
  /// `ConstrainedBox` of this widget's own is needed to force that bound.
  Future<void> _openPicker() async {
    if (widget.disabled) return;
    final draftState = ValueNotifier<({bool canSave, bool hasSelection})>((
      canSave: true,
      hasSelection: _displayedValues.isNotEmpty,
    ));
    final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<T>>();

    void syncDraftState() {
      final state = surfaceKey.currentState;
      draftState.value = (canSave: state!.canSave, hasSelection: state.hasSelection);
    }

    await LayrzResponsiveModal.show<void>(
      context,
      // [LayrzResponsiveModal.show] has no `title:` slot -- matches the
      // mobile bottom sheet path's own contract exactly: no visible title
      // anywhere, only a screen-reader `semanticLabel`.
      semanticLabel: widget.labelText ?? widget.hintText,
      canDismiss: true,
      // The surface's own header (LayrzPickerDialogHeader) already renders a
      // close X next to the title, so the dialog branch's floating X would
      // be a redundant second X -- suppressing only the icon's render here
      // does not affect canDismiss: true above -- barrier tap, Escape, and
      // the back gesture still close the modal with no value.
      showCloseIcon: false,
      dialog: const LayrzDialogConfig(maxWidth: 600, maxHeight: 760),
      builder: (context) => LayrzMultiSelectInputSurface<T>(
        key: surfaceKey,
        items: widget.items,
        initialValues: _displayedValues,
        enableSearch: widget.enableSearch,
        filter: widget.filter,
        emptyListText: widget.emptyListText,
        labelText: widget.labelText,
        itemExtent: widget.itemExtent,
        onDraftChanged: syncDraftState,
        onDraftCommitted: (values) {
          _commitSelection(values);
          LayrzModalRoute.popIfCurrent(context);
        },
      ),
      sheet: const LayrzBottomSheetConfig(
        initialSize: 0.6,
        maxSize: 0.9,
        snapSizes: [0.6, 0.9],
        // The surface's own root now lays out a pinned header plus an
        // `Expanded`-wrapped `ListView` (see
        // [LayrzMultiSelectInputSurface.build]'s own doc) -- a same-axis
        // scrollable nested inside the sheet's default `SingleChildScrollView`
        // would receive unbounded height and assert. `scrollable: false`
        // hands the surface the sheet's own bounded `Expanded` region
        // directly, mirroring `LayrzComboBoxInput._openPicker`'s identical
        // fix for the same shape of content.
        scrollable: false,
      ),
      actions: [
        _MultiSelectDrawerActions(
          draftState: draftState,
          onCancel: (drawerContext) => LayrzModalRoute.popIfCurrent(drawerContext),
          onSelectAll: (_) => surfaceKey.currentState?.selectAll(),
          onUnselectAll: (_) => surfaceKey.currentState?.unselectAll(),
          onSave: (_) => surfaceKey.currentState?.save(),
        ),
      ],
    );

    draftState.dispose();
  }

  Widget _buildInteractiveField({required BuildContext context, required VoidCallback? onTap}) {
    final tokens = context.tokens;
    final joined = _joinedLabels();
    final displayText = joined.isEmpty ? (widget.hintText ?? '') : joined;

    final contentChild = SizedBox(
      width: double.infinity,
      child: Text(displayText, style: tokens.typography.body, maxLines: 1, overflow: TextOverflow.ellipsis),
    );

    final states = <WidgetState>{if (widget.disabled) WidgetState.disabled};
    final hasErrors = widget.errors.isNotEmpty;
    final spec = LayrzInputStyleSpec.resolve(states: states, tokens: tokens, hasErrors: hasErrors);

    final fieldRow = buildPickerFieldRow(
      context: context,
      tokens: tokens,
      contentChild: contentChild,
      states: states,
      errors: widget.errors,
      disabled: widget.disabled,
      isRequired: widget.isRequired,
      hintText: widget.hintText,
      controller: _controller,
      dense: widget.dense,
      helpTitleText: widget.helpTitleText,
      helpContentText: widget.helpContentText,
      affordanceIcon: buildPickerAffordanceIcon(
        tokens: tokens,
        spec: spec,
        hasErrors: hasErrors,
        icon: MdiIcons.formatListCheckbox,
      ),
    );

    return buildPickerAnchorColumn(
      context: context,
      tokens: tokens,
      labelText: widget.labelText,
      isRequired: widget.isRequired,
      fieldRow: fieldRow,
      errors: widget.errors,
      hideDetails: widget.hideDetails,
      controller: _controller,
      focusNode: _focusNode,
      onTap: onTap,
      disabled: widget.disabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildInteractiveField(context: context, onTap: widget.disabled ? null : _openPicker);
  }
}

/// The Cancel / Select-All(Unselect-All) / Save actions row for
/// [LayrzMultiSelectInput]'s opened surface.
///
/// Mirrors [LayrzPickerDrawerActions]'s [ValueListenableBuilder]-driven
/// shape exactly (see that class's own doc for the full rationale on why
/// this must be a single reactive widget rather than three independently
/// conditional list entries), but the **middle button toggles between
/// "Select all" and "Unselect all" based on [draftState.hasSelection]**
/// rather than a Clear button that only appears once a selection exists —
/// this widget's own Decision, distinct from [LayrzPickerDrawerActions]'s
/// Cancel/Clear/Save shape, which is why multi-select does not reuse that
/// class directly.
class _MultiSelectDrawerActions extends StatelessWidget {
  /// The surface's live draft state, updated on every mutation. `hasSelection`
  /// decides whether the middle button reads "Select all" (nothing selected)
  /// or "Unselect all" (something selected); `canSave` gates Save, and is
  /// always `true` for this surface (see
  /// [LayrzMultiSelectInputSurfaceState.canSave]'s own doc for why).
  final ValueListenable<({bool canSave, bool hasSelection})> draftState;

  /// Called when Cancel is pressed, with this widget's own (route-scoped)
  /// [BuildContext]. Always shown. Discards the draft entirely — see
  /// [LayrzMultiSelectInput]'s class doc.
  final ValueChanged<BuildContext> onCancel;

  /// Called when the middle button is pressed while `hasSelection` is
  /// `false` (labeled "Select all"). Mutates the surface's draft only — see
  /// [LayrzMultiSelectInputSurfaceState.selectAll].
  final ValueChanged<BuildContext> onSelectAll;

  /// Called when the middle button is pressed while `hasSelection` is
  /// `true` (labeled "Unselect all"). Mutates the surface's draft only — see
  /// [LayrzMultiSelectInputSurfaceState.unselectAll].
  final ValueChanged<BuildContext> onUnselectAll;

  /// Called when Save is pressed, with this widget's own (route-scoped)
  /// [BuildContext], while `draftState.canSave` is `true`. Commits the
  /// draft via [LayrzMultiSelectInputSurfaceState.save].
  final ValueChanged<BuildContext> onSave;

  /// Creates a new [_MultiSelectDrawerActions].
  const _MultiSelectDrawerActions({
    required this.draftState,
    required this.onCancel,
    required this.onSelectAll,
    required this.onUnselectAll,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ValueListenableBuilder<({bool canSave, bool hasSelection})>(
      valueListenable: draftState,
      builder: (context, state, _) {
        final l10n = context.l10n;

        final actions = <Widget>[
          LayrzButton.cancel(
            labelText: l10n.actionCancel,
            onTap: () => onCancel(context),
            style: LayrzButtonStyle.text,
          ),
          LayrzButton(
            labelText: state.hasSelection ? l10n.selectUnselectAll : l10n.selectSelectAll,
            onTap: state.hasSelection ? () => onUnselectAll(context) : () => onSelectAll(context),
            type: LayrzButtonType.info,
            style: LayrzButtonStyle.text,
          ),
          LayrzButton.save(
            labelText: l10n.actionSave,
            onTap: state.canSave ? () => onSave(context) : () {},
            isDisabled: !state.canSave,
          ),
        ];

        // Each button is wrapped in Expanded inside a bounded-width
        // LayoutBuilder measurement -- see the class doc's own note on why
        // this differs from LayrzPickerDrawerActions's Flexible-only
        // layout: three *always-visible* buttons (unlike Cancel/Save, where
        // Clear only renders once a selection exists) can together exceed
        // the row's available width once the middle label reads "Unselect
        // all", and a bare Flexible does not force an oversized child to
        // actually shrink to its allotted share. Expanded's tight fit does,
        // forcing each button into an equal third that LayrzButton then
        // clamps its own content to (see `_computeButtonWidth`'s
        // `constraints.maxWidth.isFinite` branch), ellipsizing the label
        // rather than overflowing the row. `LayoutBuilder` supplies the
        // explicit bounded width `Expanded` requires even when this widget
        // is placed directly into an unbounded-width host row (confirmed:
        // BOTH `LayrzResponsiveModal.show` branches' own `actions` rows do
        // this -- see the fallback comment below for why the dialog branch
        // is not the bounded exception this used to assume).
        return LayoutBuilder(
          builder: (context, constraints) {
            // Neither `LayrzResponsiveModal.show` branch's own `actions` row
            // bounds a single non-flex entry's width -- Flutter's flex
            // layout gives a non-flex child an UNBOUNDED main-axis
            // constraint regardless of the `Row`'s own (bounded) width
            // (confirmed: a real "RenderFlex children have non-zero flex but
            // incoming width constraints are unbounded" assertion without
            // this fallback, and a 1000+px overflow into the full device
            // width via the naive `MediaQuery.sizeOf` fallback before this
            // fix, since that fallback assumed the dialog branch never hit
            // it at all). `context.isCompact` reads which branch
            // [LayrzResponsiveModal.show] actually resolved to (this widget
            // never overrides `isCompact`, so the default -- resolved from
            // the same `context.isCompact` -- is what decided it), and each
            // branch's own known content-area formula reconstructs the real
            // bounded width natively: the dialog's [LayrzDialogConfig.maxWidth]
            // default (480) minus its own `2*sp3` panel padding, or the
            // sheet's full device width minus its own `2*sp3` padding.
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : context.isCompact
                ? MediaQuery.sizeOf(context).width - (tokens.spacing.sp3 * 2)
                : 480.0 - (tokens.spacing.sp3 * 2);
            return SizedBox(
              width: width,
              child: Row(
                children: [
                  for (final (i, action) in actions.indexed) ...[
                    if (i > 0) SizedBox(width: tokens.spacing.sp2),
                    Expanded(child: action),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
