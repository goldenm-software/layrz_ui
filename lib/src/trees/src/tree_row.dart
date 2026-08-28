import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'tree_indent_guide.dart';
import 'tree_node.dart';
import 'tree_style_spec.dart';

/// The default row content for [LayrzTreeView] and [LayrzSliverTreeView],
/// used whenever the caller does not supply its own [LayrzTreeNodeBuilder].
///
/// Composes, left to right: [LayrzTreeIndentGuide] (decorative, no
/// semantics), an expand/collapse chevron (only for non-leaf nodes, wired to
/// [onToggle]), an optional selection checkbox affordance (only when
/// [onSelect] is non-null), and the caller's [child].
///
/// **Accessibility is composed here, not bolted on** (per the batch's
/// cross-cutting semantics rule): the whole row is wrapped in a single merged
/// [Semantics] node stating role, expansion state, depth, and selection
/// state, so a screen-reader user gets the announcement sighted users read
/// for free from the chevron and indentation alone.
class LayrzTreeRow<T> extends StatefulWidget {
  /// Creates a [LayrzTreeRow].
  const LayrzTreeRow({
    required this.node,
    required this.depth,
    required this.isExpanded,
    required this.isLeaf,
    required this.isSelected,
    required this.isPartiallySelected,
    required this.totalDepth,
    required this.child,
    this.onToggle,
    this.onSelect,
    this.isActive = false,
    super.key,
  });

  /// The node this row represents.
  final LayrzTreeNode<T> node;

  /// The zero-based nesting depth of [node] within the tree.
  final int depth;

  /// Whether [node] is currently expanded. Meaningless for a leaf node.
  final bool isExpanded;

  /// Whether [node] has no children.
  final bool isLeaf;

  /// Whether [node] is currently fully selected.
  final bool isSelected;

  /// Whether [node] is a cascading-mode parent with only some descendants
  /// selected. Always `false` under independent selection.
  final bool isPartiallySelected;

  /// The greatest depth present anywhere in the tree, used to compose the
  /// "level X of Y" fragment of this row's semantics announcement.
  final int totalDepth;

  /// The caller-supplied row content, placed after the chevron/checkbox.
  final Widget child;

  /// Called when the row's expand/collapse affordance is activated. `null`
  /// for a leaf row, which renders no chevron.
  final VoidCallback? onToggle;

  /// Called when the row's selection affordance (or the row itself) is
  /// activated for selection. `null` when selection is disabled for the
  /// tree, in which case no checkbox is rendered and the row carries no
  /// selection semantics.
  final VoidCallback? onSelect;

  /// Whether this row is currently the keyboard-navigation active row (see
  /// [LayrzTreeController.activeId]).
  ///
  /// Rendered as a constant-width outline whose colour changes with this
  /// flag, per D15 — never as a change to the row's size or padding.
  /// Defaults to `false`.
  final bool isActive;

  @override
  State<LayrzTreeRow<T>> createState() => _LayrzTreeRowState<T>();
}

class _LayrzTreeRowState<T> extends State<LayrzTreeRow<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final style = LayrzTreeRowStyleSpec.resolve(
      tokens,
      isHovered: _isHovered,
      isSelected: widget.isSelected,
      isPartiallySelected: widget.isPartiallySelected,
      isActive: widget.isActive,
    );

    final label = 'Level ${widget.depth + 1} of ${widget.totalDepth + 1}';
    final semanticsHint = widget.isLeaf
        ? null
        : (widget.isExpanded ? 'Double tap to collapse' : 'Double tap to expand');

    return Semantics(
      label: label,
      hint: semanticsHint,
      selected: widget.onSelect != null ? widget.isSelected : null,
      expanded: widget.isLeaf ? null : widget.isExpanded,
      // Passing `false` here (rather than `null`) would still set the
      // isFocusable flag -- Semantics.focused implicitly sets focusable
      // whenever it is non-null, per SemanticsProperties.focused's own doc
      // comment. A row not currently active must carry no focus concept at
      // all, matching how `selected`/`expanded` are only set when meaningful.
      focused: widget.isActive ? true : null,
      onTap: widget.onToggle,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.backgroundColor,
            border: Border.all(color: style.activeBorderColor, width: tokens.border.stroke1),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spacing.sp1, horizontal: tokens.spacing.sp2),
            child: Row(
              children: [
                LayrzTreeIndentGuide(depth: widget.depth, color: style.indentGuideColor),
                _buildChevron(tokens, style),
                if (widget.onSelect != null) _buildCheckbox(tokens, style),
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: style.foregroundColor),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChevron(LayrzTokens tokens, LayrzTreeRowStyleSpec style) {
    if (widget.isLeaf) {
      return SizedBox(width: tokens.spacing.sp4);
    }
    return LayrzTappable(
      onTap: widget.onToggle,
      borderRadius: BorderRadius.circular(tokens.radius.r1),
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.sp1),
        child: AnimatedRotation(
          turns: widget.isExpanded ? 0.25 : 0.0,
          duration: tokens.motion.dHover,
          child: Icon(
            MdiIcons.chevronRight,
            size: 18,
            color: style.chevronColor,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(LayrzTokens tokens, LayrzTreeRowStyleSpec style) {
    final isFilled = widget.isSelected || widget.isPartiallySelected;
    return LayrzTappable(
      onTap: widget.onSelect,
      borderRadius: BorderRadius.circular(tokens.radius.r1),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1 / 2),
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isFilled ? style.checkboxFillColor : null,
            border: Border.all(color: style.checkboxBorderColor, width: 1.5),
            borderRadius: BorderRadius.circular(tokens.radius.r1),
          ),
          child: isFilled
              ? Icon(
                  widget.isPartiallySelected ? MdiIcons.minus : MdiIcons.check,
                  size: 14,
                  color: style.checkboxGlyphColor,
                )
              : null,
        ),
      ),
    );
  }
}
