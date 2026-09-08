import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'tab.dart';

/// A Material-free tab strip and content switcher.
///
/// [LayrzTabView] renders a strip of pill-shaped tabs — one per entry in
/// [tabs] — above the [LayrzTab.child] content of whichever tab is currently
/// selected. Each pill supports an optional leading slot, a label
/// (`labelText` or a custom `label` widget), and an optional trailing
/// (suffix) slot.
///
/// **Layout modes**, controlled by [isScrollable]:
/// - `true` (the default): the strip is a horizontal, start-aligned
///   scrollable row. Pills size to their own content and the strip scrolls
///   when they overflow the available width.
/// - `false`: pills share the strip's width evenly, each wrapped in an
///   `Expanded` inside a `Row` — the same layout
///   `LayrzPickerTabSwitcher` uses internally.
///
/// **Styling** mirrors the internal `_LayrzPickerTab` pill's colour rules
/// exactly: idle pills paint `tokens.colors.sf1`, the selected pill paints
/// `tokens.colors.primary.shade500`, hover/press use `tokens.colors.sf3`/
/// `sf4`, corners use `tokens.radius.br2`, and the label uses
/// `tokens.typography.label` at `FontWeight.w600` when selected or `w400`
/// otherwise. Interaction states vary colour only, never geometry (D15).
///
/// **Sizing diverges from `_LayrzPickerTab`**: pills are button-scale rather
/// than compact — horizontal padding matches [LayrzButton]'s
/// (`tokens.spacing.sp3`) and each pill has a minimum height of
/// `kLayrzButtonHeight`, so a tab pill reads like a button rather than a
/// cramped chip. Leading/trailing icons are sized to `kLayrzButtonIconSize`
/// rather than the label font size, matching button icon scale. The
/// `labelText` path also renders at `kLayrzButtonFontSize` (14px) instead of
/// `tokens.typography.label`'s own size, so the visible text matches
/// [LayrzButton]'s label size; a caller-supplied `label` widget is left
/// entirely untouched.
///
/// **Selection** is tracked internally; [onTabChanged] fires only for a
/// user-initiated tap on a non-selected tab, never for the initial mount or
/// for a tap on the tab that is already selected.
class LayrzTabView extends StatefulWidget {
  /// The tabs to render, in display order. Must contain at least one entry.
  final List<LayrzTab> tabs;

  /// The index into [tabs] selected when this widget first mounts.
  ///
  /// Clamped into the valid `[0, tabs.length - 1]` range if out of bounds —
  /// this never throws, unlike an invalid `selectedIndex` on the internal
  /// picker switcher. Changing this value after the first build has no
  /// effect; selection afterward is owned by this widget's internal state.
  final int initialIndex;

  /// Called with the newly selected index whenever the user taps a
  /// non-selected tab.
  ///
  /// Never called for the initial mount, and never called when tapping the
  /// tab that is already selected.
  final ValueChanged<int>? onTabChanged;

  /// Whether the tab strip scrolls horizontally.
  ///
  /// Defaults to `true`: pills size to their own content in a start-aligned
  /// horizontal scrollable row. When `false`, pills instead share the
  /// strip's width evenly via `Expanded` cells in a `Row` — matching
  /// `LayrzPickerTabSwitcher`'s layout — and the strip never scrolls.
  final bool isScrollable;

  /// Padding applied around the tab strip.
  ///
  /// Defaults to `null`, which applies no padding.
  final EdgeInsets? padding;

  /// The vertical gap between the tab strip and the selected tab's content.
  ///
  /// Defaults to `null`, which resolves to `tokens.spacing.sp3` at build
  /// time — every [LayrzTabView] gets a sensible gap between the strip and
  /// its content out of the box, without every call site having to pad its
  /// own [LayrzTab.child]. Pass `0` to butt the content directly against the
  /// strip, or any other value to override the token default.
  final double? contentGap;

  /// Creates a new [LayrzTabView].
  ///
  /// [tabs] must be non-empty. [initialIndex] is clamped into range rather
  /// than validated by assertion, since an out-of-range index is expected to
  /// be tolerated (e.g. a caller-persisted index from a tab set that shrank).
  LayrzTabView({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.onTabChanged,
    this.isScrollable = true,
    this.padding,
    this.contentGap,
  }) : assert(tabs.isNotEmpty, 'LayrzTabView needs at least one tab.');

  @override
  State<LayrzTabView> createState() => _LayrzTabViewState();
}

class _LayrzTabViewState extends State<LayrzTabView> {
  /// The currently selected index into [LayrzTabView.tabs].
  ///
  /// Initialised from [LayrzTabView.initialIndex], clamped into range so an
  /// out-of-bounds value never throws.
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, widget.tabs.length - 1);
  }

  @override
  void didUpdateWidget(LayrzTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the selected index valid if the tab list shrank.
    if (_selectedIndex > widget.tabs.length - 1) {
      _selectedIndex = widget.tabs.length - 1;
    }
  }

  /// Handles a tap on the pill at [index].
  ///
  /// No-op if [index] is already selected. Otherwise updates the internal
  /// selection and notifies [LayrzTabView.onTabChanged].
  void _handleTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    widget.onTabChanged?.call(index);
  }

  /// Builds the scrollable-strip layout: pills sized to content, laid out
  /// start-aligned in a horizontally scrolling row.
  Widget _buildScrollableStrip(LayrzTokens tokens) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, tab) in widget.tabs.indexed) ...[
            if (index > 0) SizedBox(width: tokens.spacing.sp2),
            _LayrzTabPill(
              tab: tab,
              isSelected: index == _selectedIndex,
              onTap: index == _selectedIndex ? null : () => _handleTap(index),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the expanded-strip layout: pills share the strip's width evenly.
  Widget _buildExpandedStrip(LayrzTokens tokens) {
    return Row(
      children: [
        for (final (index, tab) in widget.tabs.indexed) ...[
          if (index > 0) SizedBox(width: tokens.spacing.sp2),
          Expanded(
            child: _LayrzTabPill(
              tab: tab,
              isSelected: index == _selectedIndex,
              onTap: index == _selectedIndex ? null : () => _handleTap(index),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final strip = widget.isScrollable ? _buildScrollableStrip(tokens) : _buildExpandedStrip(tokens);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: widget.padding ?? EdgeInsets.zero,
          child: strip,
        ),
        SizedBox(height: widget.contentGap ?? tokens.spacing.sp3),
        widget.tabs[_selectedIndex].child,
      ],
    );
  }
}

/// A single tab pill within [LayrzTabView] — reproduces the internal
/// `_LayrzPickerTab` styling exactly (idle/selected/hover/press colours,
/// `tokens.radius.br2` corners, `tokens.typography.label` weight/colour
/// rules), extended with optional leading and trailing slots.
///
/// Built on [LayrzTappable] for hover/press feedback, wrapped in a [Focus]
/// for keyboard focus tracking and a [Semantics] node exposing button and
/// selection state. Geometry never changes across selection/hover/press per
/// D15 — only colour changes.
class _LayrzTabPill extends StatefulWidget {
  /// The tab descriptor this pill renders.
  final LayrzTab tab;

  /// Whether this pill is the currently active tab.
  final bool isSelected;

  /// Called on tap. `null` when this pill is already selected, which also
  /// renders it non-interactive.
  final VoidCallback? onTap;

  /// Creates a new [_LayrzTabPill].
  const _LayrzTabPill({required this.tab, required this.isSelected, required this.onTap});

  @override
  State<_LayrzTabPill> createState() => _LayrzTabPillState();
}

class _LayrzTabPillState extends State<_LayrzTabPill> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!mounted) return;
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  /// Resolves the semantic label used for this pill's [Semantics] node and,
  /// when [LayrzTab.labelText] is used, for its visible [Text].
  String? get _semanticLabel => widget.tab.labelText;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tab = widget.tab;

    final idleColor = tokens.colors.sf1;
    final selectedColor = tokens.colors.primary.shade500;
    final labelColor = widget.isSelected
        ? (selectedColor.computeLuminance() > 0.5 ? tokens.colors.fg1 : tokens.colors.sf1)
        : (_isFocused ? tokens.colors.fg1 : tokens.colors.fg2);
    final borderRadius = tokens.radius.br2;

    final labelWidget = tab.labelText != null
        ? Text(
            tab.labelText!,
            textAlign: TextAlign.center,
            style: tokens.typography.label.copyWith(
              color: labelColor,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: kLayrzButtonFontSize,
            ),
          )
        : tab.label!;

    Widget? leadingWidget = tab.leading;
    if (leadingWidget == null && tab.leadingIcon != null) {
      leadingWidget = Icon(tab.leadingIcon, size: kLayrzButtonIconSize, color: labelColor);
    }

    Widget? trailingWidget = tab.trailing;
    if (trailingWidget == null && tab.trailingIcon != null) {
      trailingWidget = Icon(tab.trailingIcon, size: kLayrzButtonIconSize, color: labelColor);
    }

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingWidget != null) ...[
          leadingWidget,
          SizedBox(width: tokens.spacing.sp2),
        ],
        Flexible(child: labelWidget),
        if (trailingWidget != null) ...[
          SizedBox(width: tokens.spacing.sp2),
          trailingWidget,
        ],
      ],
    );

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: _semanticLabel,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: SelectionContainer.disabled(
        child: Focus(
          focusNode: _focusNode,
          child: LayrzTappable(
            onTap: widget.onTap,
            borderRadius: borderRadius,
            color: widget.isSelected ? selectedColor : idleColor,
            hoverColor: widget.isSelected ? selectedColor : tokens.colors.sf3,
            pressedColor: widget.isSelected ? selectedColor : tokens.colors.sf4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kLayrzButtonHeight),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp3),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
