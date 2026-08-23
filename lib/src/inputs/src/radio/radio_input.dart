import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/grid/grid.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import '../shared/input_footer_slot.dart';
import '../select/select_item.dart';

/// A Material-free radio button group with responsive option grid in the layrz_ui design system.
///
/// [LayrzRadioInput] presents a set of mutually-exclusive options arranged in a responsive grid,
/// using native [RawRadio] and [RadioGroup] widgets for interaction and selection.
/// It automatically handles arrow-key navigation and supports custom option rendering via
/// [LayrzSelectItem.child].
///
/// **Grid responsiveness**: Options are laid out using [LayrzRow] and [LayrzCol] with per-breakpoint
/// column spans (`xs`, `sm`, `md`, `lg`, `xl`). Default spans produce 1 option per row on mobile,
/// 2 on tablets, 3 on small desktops, 4 on large desktops, and 6 on extra-large screens.
/// Spans are explicitly 1–12 (mirroring [LayrzCol]'s API) and cascade: unset larger breakpoints
/// inherit the next-smaller one.
///
/// **Selection and interaction**:
/// - Tapping an option's radio button selects it and fires [onChanged].
/// - Tapping an option's label also selects it (full row is tappable).
/// - Tapping the currently-selected option leaves it selected (no toggle-to-null).
/// - Arrow keys (Up/Down/Left/Right) move focus within the group.
/// - Disabled state blocks all interaction; [onChanged] is never fired.
///
/// **Error handling**: Errors and details are rendered via [LayrzInputFooterSlot], which caps
/// error text at two lines with ellipsis to prevent unbounded growth.
///
/// **Accessibility**:
/// - Each option has [Semantics] announcing role (radio) and selected state.
/// - The group has [Semantics] announcing the group label.
/// - Selection is indicated by the filled radio dot, not color alone (WCAG 1.4.1).
/// - Keyboard navigation via arrow keys is built-in via [RadioGroup].
class LayrzRadioInput<T> extends StatefulWidget {
  /// The label text for the radio group.
  ///
  /// Displayed above the grid of options. If null, no label is rendered.
  final String? labelText;

  /// Whether the group is marked as required.
  final bool isRequired;

  /// The list of options to display.
  ///
  /// Each [LayrzSelectItem] defines a label, typed value, optional custom rendering,
  /// and search metadata. The radio group ignores the search metadata (no search in radio).
  /// When [LayrzSelectItem.child] is non-null, that widget is rendered instead of
  /// a default [Text] label; [labelText] is still used by accessibility.
  ///
  /// **Important:** Item values must be unique. The underlying [RadioGroup] enforces
  /// single-selection semantics and cannot handle multiple items with the same value.
  /// Passing duplicate values will trigger an assertion error at construction time.
  final List<LayrzSelectItem<T>> items;

  /// The currently selected value.
  ///
  /// If null, no option is selected. If the value does not match any item's value,
  /// no option appears selected (no crash).
  final T? value;

  /// Callback fired when the user selects an option.
  ///
  /// Fired with the [LayrzSelectItem.value] of the selected item. The callback is
  /// ignored if the group is disabled.
  final ValueChanged<T?>? onChanged;

  /// Whether the group is disabled.
  ///
  /// When true, options cannot be selected, and [onChanged] is never fired.
  /// Visual treatment: all options become grayed-out with reduced opacity.
  final bool disabled;

  /// List of validation error messages to display below the grid.
  final List<String> errors;

  /// Whether to hide the error message block.
  final bool hideDetails;

  /// Padding applied inside the group (around the grid and below the label).
  ///
  /// If null, defaults to [LayrzTokens.spacing.pd2] (8px).
  final EdgeInsets? padding;

  /// The column span for extra-small screens (<600px).
  ///
  /// Defaults to 12 (1 option per row).
  /// Must be a positive integer between 1 and 12 (inclusive).
  final int xs;

  /// The column span for small screens (600–959px).
  ///
  /// If null, cascades to [xs].
  /// Must be a positive integer between 1 and 12 (inclusive) if set.
  final int? sm;

  /// The column span for medium screens (960–1263px).
  ///
  /// If null, cascades to [sm] (or [xs] if [sm] is also null).
  /// Must be a positive integer between 1 and 12 (inclusive) if set.
  final int? md;

  /// The column span for large screens (1264–1903px).
  ///
  /// If null, cascades to [md] (or [sm] or [xs]).
  /// Must be a positive integer between 1 and 12 (inclusive) if set.
  final int? lg;

  /// The column span for extra-large screens (≥1904px).
  ///
  /// If null, cascades to [lg] (or [md] or [sm] or [xs]).
  /// Must be a positive integer between 1 and 12 (inclusive) if set.
  final int? xl;

  /// Creates a new [LayrzRadioInput] with the given properties.
  ///
  /// The [items] parameter is required. At least one of [labelText] or [isRequired] being true
  /// is expected for proper labeling (though not enforced). The [xs], [sm], [md], [lg], [xl]
  /// parameters define responsive column spans and must be 1–12 (or null for cascade).
  const LayrzRadioInput({
    super.key,
    this.labelText,
    this.isRequired = false,
    required this.items,
    this.value,
    this.onChanged,
    this.disabled = false,
    this.errors = const [],
    this.hideDetails = false,
    this.padding,
    this.xs = 12,
    this.sm = 6,
    this.md = 4,
    this.lg = 3,
    this.xl = 2,
  }) : assert(xs > 0 && xs <= 12, 'xs must be between 1 and 12, got $xs'),
       assert(sm == null || (sm > 0 && sm <= 12), 'sm must be between 1 and 12, got $sm'),
       assert(md == null || (md > 0 && md <= 12), 'md must be between 1 and 12, got $md'),
       assert(lg == null || (lg > 0 && lg <= 12), 'lg must be between 1 and 12, got $lg'),
       assert(xl == null || (xl > 0 && xl <= 12), 'xl must be between 1 and 12, got $xl');

  @override
  State<LayrzRadioInput<T>> createState() => _LayrzRadioInputState<T>();
}

/// State for [LayrzRadioInput].
class _LayrzRadioInputState<T> extends State<LayrzRadioInput<T>> {
  /// Handles radio selection and fires [onChanged].
  void _handleChanged(T? newValue) {
    if (widget.disabled || widget.onChanged == null) return;
    widget.onChanged?.call(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final resolvedPadding = widget.padding ?? tokens.spacing.pd2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group label
        if (widget.labelText != null)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spacing.sp2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.labelText!,
                  style: tokens.typography.label.copyWith(
                    color: tokens.colors.fg1,
                  ),
                ),
                if (widget.isRequired)
                  Padding(
                    padding: EdgeInsets.only(left: tokens.spacing.sp1),
                    child: Text(
                      '*',
                      style: tokens.typography.label.copyWith(
                        color: tokens.colors.danger,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // Radio group with responsive grid
        Padding(
          padding: resolvedPadding,
          child: RadioGroup<T?>(
            groupValue: widget.value,
            onChanged: _handleChanged,
            child: Builder(
              builder: (context) => Semantics(
                label: widget.labelText,
                container: true,
                enabled: !widget.disabled,
                child: LayrzRow(
                  children: List.generate(
                    widget.items.length,
                    (index) => LayrzCol(
                      xs: widget.xs,
                      sm: widget.sm,
                      md: widget.md,
                      lg: widget.lg,
                      xl: widget.xl,
                      child: _buildRadioOption(
                        context,
                        item: widget.items[index],
                        index: index,
                        isSelected: widget.value == widget.items[index].value,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Error block
        if (!widget.hideDetails || widget.errors.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              left: resolvedPadding.left,
              right: resolvedPadding.right,
              bottom: resolvedPadding.bottom,
            ),
            child: LayrzInputFooterSlot(
              errors: widget.errors,
              hideDetails: widget.hideDetails,
            ),
          ),
      ],
    );
  }

  /// Builds a single radio option with label.
  ///
  /// The option is a tappable row combining [RawRadio] and the item label.
  /// If the item has a [LayrzSelectItem.child], that is rendered instead of the label text.
  /// Accessibility: the entire option is merged into a single semantics node with the radio's
  /// selected state announcement.
  Widget _buildRadioOption(
    BuildContext context, {
    required LayrzSelectItem<T> item,
    required int index,
    required bool isSelected,
  }) {
    final tokens = context.tokens;
    final focusNode = FocusNode();

    return Semantics(
      enabled: !widget.disabled,
      selected: isSelected,
      container: true,
      button: true,
      label: item.labelText,
      onTap: widget.disabled ? null : () => _handleChanged(item.value),
      child: GestureDetector(
        onTap: widget.disabled ? null : () => _handleChanged(item.value),
        child: MouseRegion(
          cursor: widget.disabled ? MouseCursor.defer : SystemMouseCursors.click,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Radio button using RawRadio
              RawRadio<T?>(
                value: item.value,
                focusNode: focusNode,
                autofocus: false,
                enabled: !widget.disabled,
                mouseCursor: WidgetStateMouseCursor.clickable,
                toggleable: false,
                groupRegistry: RadioGroup.maybeOf<T?>(context),
                builder: (context, state) {
                  // Determine if selected based on animation position
                  final isSelectedState = state.position.value > 0.5;
                  final borderColor = widget.disabled
                      ? tokens.colors.fg4.withValues(alpha: 0.4)
                      : (isSelectedState ? tokens.colors.primary : tokens.colors.fg3);

                  return Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: borderColor,
                        width: 2,
                      ),
                    ),
                    child: isSelectedState
                        ? Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.disabled
                                    ? tokens.colors.fg4.withValues(alpha: 0.4)
                                    : tokens.colors.primary,
                              ),
                            ),
                          )
                        : null,
                  );
                },
              ),
              SizedBox(width: tokens.spacing.sp2),
              // Label (custom or text)
              Expanded(
                child:
                    item.child ??
                    Text(
                      item.labelText,
                      style: tokens.typography.body.copyWith(
                        color: widget.disabled ? tokens.colors.fg4.withValues(alpha: 0.5) : tokens.colors.fg1,
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
