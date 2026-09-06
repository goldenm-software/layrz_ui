import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

/// A private, minimal labeled tab switcher for a picker surface — currently
/// consumed only by the color picker's Palette/Wheel tabs, but built as a
/// generic 2-or-more-item switcher (not hardcoded to two) since emoji-group
/// filtering and any future icon categorization are also tab-shaped.
///
/// **Not a public `LayrzTabView`.** Per OQ-13 (see the implementation plan),
/// this is scoped deliberately small: an internal `pickers/shared/`
/// primitive, not exported from the module barrel, and not a general-purpose
/// N-item scrollable tab strip. If a public tab widget is ever wanted, it is
/// a separate, later component — this one exists only to satisfy pickers
/// that need a small label switcher today.
///
/// **Material-free**, built on [LayrzTappable] for hover/press feedback and
/// a plain [Text] label — no `TabBar`, no `Material`. The selected tab
/// paints a full [LayrzColorTokens.primary] pill; an unselected tab paints
/// the background surface token solidly (never transparent — see
/// `_LayrzPickerTab`'s own doc for the user-testing finding behind that).
/// Interaction states (hover, press, focus, selection) vary only
/// colour/opacity/border per D15 — this widget's own geometry (tab height,
/// padding, corner radius) never changes across states.
class LayrzPickerTabSwitcher extends StatelessWidget {
  /// The label shown for each tab, in display order. Must contain at least
  /// two entries — a one-item switcher has nothing to switch between.
  final List<String> tabs;

  /// The index into [tabs] currently selected.
  final int selectedIndex;

  /// Called with the tapped index when a non-selected tab is activated.
  /// Never called for the already-selected tab.
  final ValueChanged<int> onTabSelected;

  /// Creates a new [LayrzPickerTabSwitcher].
  const LayrzPickerTabSwitcher({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  }) : assert(tabs.length >= 2, 'LayrzPickerTabSwitcher needs at least two tabs, got ${tabs.length}.'),
       assert(
         selectedIndex >= 0 && selectedIndex < tabs.length,
         'selectedIndex ($selectedIndex) must be a valid index into tabs (length ${tabs.length}).',
       );

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Row(
      children: [
        for (final (index, label) in tabs.indexed) ...[
          if (index > 0) SizedBox(width: tokens.spacing.sp2),
          Expanded(
            child: _LayrzPickerTab(
              label: label,
              isSelected: index == selectedIndex,
              onTap: index == selectedIndex ? null : () => onTabSelected(index),
            ),
          ),
        ],
      ],
    );
  }
}

/// A single tab within [LayrzPickerTabSwitcher] — a rounded pill that
/// paints [LayrzColorTokens.primary] as a full background while
/// [isSelected] is `true`, and the theme's background surface token
/// otherwise.
///
/// **Solid, never transparent, when unselected** — an unselected tab used
/// to paint at zero opacity, which read as a flicker/transition artifact
/// during the selected-pill hand-off (user testing finding); painting
/// [LayrzColorTokens.sf1] underneath every tab, selected or not, means the
/// only thing that changes on selection is which solid colour is drawn,
/// never an opacity ramp against the page behind it.
///
/// **Geometry never changes with selection (D15).** The pill's rounded
/// corners, height, and padding are identical whether or not [isSelected]
/// is `true` — only [LayrzTappable]'s own `color` is swapped, and that
/// swap is itself colour-animated by [LayrzTappable]'s internal
/// `AnimatedContainer`, so selecting a tab never changes this widget's
/// bounds.
class _LayrzPickerTab extends StatefulWidget {
  /// This tab's visible label.
  final String label;

  /// Whether this tab is the currently active one.
  final bool isSelected;

  /// Called on tap. `null` when this tab is already selected (nothing to
  /// activate), which also renders it non-interactive.
  final VoidCallback? onTap;

  const _LayrzPickerTab({required this.label, required this.isSelected, required this.onTap});

  @override
  State<_LayrzPickerTab> createState() => _LayrzPickerTabState();
}

class _LayrzPickerTabState extends State<_LayrzPickerTab> {
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

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Selected: full primary fill, label contrasts against it (mirrors the
    // marker-outline luminance check in color_wheel_painter.dart). Unselected:
    // the background surface token, painted solidly -- never transparent, per
    // the user-testing finding that a transparent idle tab produced a visible
    // flicker during the selected-pill hand-off.
    final idleColor = tokens.colors.sf1;
    final selectedColor = tokens.colors.primary.shade500;
    final labelColor = widget.isSelected
        ? (selectedColor.computeLuminance() > 0.5 ? tokens.colors.fg1 : tokens.colors.sf1)
        : (_isFocused ? tokens.colors.fg1 : tokens.colors.fg2);
    final borderRadius = tokens.radius.br2;

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.label,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: Focus(
        focusNode: _focusNode,
        child: LayrzTappable(
          onTap: widget.onTap,
          borderRadius: borderRadius,
          color: widget.isSelected ? selectedColor : idleColor,
          hoverColor: widget.isSelected ? selectedColor : tokens.colors.sf3,
          pressedColor: widget.isSelected ? selectedColor : tokens.colors.sf4,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spacing.sp2),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: tokens.typography.label.copyWith(
                color: labelColor,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
