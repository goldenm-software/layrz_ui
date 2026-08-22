import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/overlays/overlays.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import 'input_chrome.dart';
import 'input_slot.dart';
import 'select_input_surface.dart';

/// A Material-free, adaptive select input in the layrz_ui design system.
///
/// [LayrzSelectInput] displays a read-only field showing the selected item's label text,
/// with a dropdown chevron affordance. Tapping the field opens a selection surface that
/// adapts to the viewport:
/// - **Desktop / wide (≥ 960px)**: An anchored overlay panel below the field
/// - **Below `md` breakpoint (< 960px)**: A bottom sheet covering the lower portion of the screen
///
/// This follows decision D52 (adaptive surface) and avoids depending on the dialog system
/// (DESIGN-96/99), keeping the component self-contained and lightweight.
///
/// **Keyboard support:** Arrow keys move a highlight in the list, Enter commits the
/// highlighted item, Escape closes without changing the selection.
class LayrzSelectInput<T> extends StatefulWidget {
  /// The list of items to choose from.
  ///
  /// Each item combines a label, a typed value, optional custom rendering,
  /// and search metadata. Use [LayrzSelectItem] to construct items.
  final List<LayrzSelectItem<T>> items;

  /// The currently selected value.
  ///
  /// May be null to represent no selection. If the value matches no item,
  /// the field displays empty.
  final T? value;

  /// Callback fired when the user selects an item or clears the selection.
  ///
  /// Called with the selected [LayrzSelectItem] (or `null` if an item with
  /// `value: null` is selected and [canUnselect] is true).
  /// If no item was selected, this callback is not called.
  final void Function(LayrzSelectItem<T>?)? onChanged;

  /// Whether to show a search field in the selection surface.
  ///
  /// Defaults to `true`. When false, the search field is hidden and all items
  /// are displayed unconditionally.
  final bool enableSearch;

  /// Whether the user can select an item with `value: null` to clear the selection.
  ///
  /// Defaults to `false`. When true, selecting an item with `null` value calls
  /// [onChanged] with `null`.
  final bool canUnselect;

  /// Optional custom filter function for search results.
  ///
  /// If provided, replaces the default [LayrzSelectItem.matches] logic.
  /// Called with the search query and each item; should return `true` if the
  /// item matches. When null, uses [LayrzSelectItem.matches] instead.
  final bool Function(String query, LayrzSelectItem<T> item)? filter;

  /// Text displayed when the search finds no matching items.
  ///
  /// If null, defaults to localized text from [LayrzUiL10n.selectEmpty].
  final String? emptyListText;

  /// The label text displayed above the input field.
  ///
  /// At least one of [labelText] or [hintText] must be non-null.
  final String? labelText;

  /// Hint text displayed as placeholder when the field is empty.
  ///
  /// At least one of [labelText] or [hintText] must be non-null.
  final String? hintText;

  /// Whether the field is marked as required.
  final bool isRequired;

  /// Icon to render as a prefix.
  ///
  /// Mutually exclusive with [prefix] and [prefixText].
  final IconData? prefixIcon;

  /// Widget to render as a prefix.
  ///
  /// Mutually exclusive with [prefixIcon] and [prefixText].
  final Widget? prefix;

  /// Text to render as a prefix.
  ///
  /// Mutually exclusive with [prefixIcon] and [prefix].
  final String? prefixText;

  /// Callback fired when the prefix is tapped.
  final VoidCallback? onPrefixTap;

  /// Icon to render as a suffix (excluding the dropdown chevron).
  ///
  /// Mutually exclusive with [suffix] and [suffixText].
  final IconData? suffixIcon;

  /// Widget to render as a suffix (excluding the dropdown chevron).
  ///
  /// Mutually exclusive with [suffixIcon] and [suffixText].
  final Widget? suffix;

  /// Text to render as a suffix (excluding the dropdown chevron).
  ///
  /// Mutually exclusive with [suffixIcon] and [suffix].
  final String? suffixText;

  /// Callback fired when the suffix is tapped.
  final VoidCallback? onSuffixTap;

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

  /// The focus node for the input field.
  ///
  /// If null, a focus node is created and disposed by the widget.
  final FocusNode? focusNode;

  /// The padding applied inside the input field.
  ///
  /// If null, defaults to `tokens.spacing.pd2` (10px on regular, 14px on compact).
  final EdgeInsets? padding;

  /// Creates a new [LayrzSelectInput] with the given properties.
  const LayrzSelectInput({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.enableSearch = true,
    this.canUnselect = false,
    this.filter,
    this.emptyListText,
    this.labelText,
    this.hintText,
    this.isRequired = false,
    this.prefixIcon,
    this.prefix,
    this.prefixText,
    this.onPrefixTap,
    this.suffixIcon,
    this.suffix,
    this.suffixText,
    this.onSuffixTap,
    this.helpTitleText,
    this.helpContentText,
    this.disabled = false,
    this.errors = const [],
    this.hideDetails = false,
    this.focusNode,
    this.padding,
  }) : assert(
         labelText != null || hintText != null,
         'At least one of labelText or hintText must be non-null.',
       ),
       assert(
         (prefixIcon == null || prefix == null) &&
             (prefix == null || prefixText == null) &&
             (prefixIcon == null || prefixText == null),
         'At most one of prefixIcon, prefix, or prefixText may be non-null.',
       ),
       assert(
         (suffixIcon == null || suffix == null) &&
             (suffix == null || suffixText == null) &&
             (suffixIcon == null || suffixText == null),
         'At most one of suffixIcon, suffix, or suffixText may be non-null.',
       );

  @override
  State<LayrzSelectInput<T>> createState() => _LayrzSelectInputState<T>();
}

class _LayrzSelectInputState<T> extends State<LayrzSelectInput<T>> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  final Set<WidgetState> _states = {};
  MenuController? _panelController;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = TextEditingController();
    _updateControllerText();
  }

  @override
  void didUpdateWidget(LayrzSelectInput<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _updateControllerText();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  /// Finds the item matching the current value, or null if not found.
  LayrzSelectItem<T>? _findSelectedItem() {
    try {
      return widget.items.firstWhere(
        (item) => item.value == widget.value,
      );
    } catch (e) {
      return null;
    }
  }

  /// Updates the controller text to match the selected item's label.
  void _updateControllerText() {
    final selectedItem = _findSelectedItem();
    _controller.text = selectedItem?.labelText ?? '';
  }

  /// Opens the selection surface on mobile via bottom sheet.
  Future<void> _openMobileSurface() async {
    final result = await LayrzBottomSheet.show<LayrzSelectItem<T>?>(
      context,
      builder: (context) => SizedBox(
        child: LayrzSelectInputSurface(
          items: widget.items,
          selectedItem: _findSelectedItem(),
          enableSearch: widget.enableSearch,
          canUnselect: widget.canUnselect,
          filter: widget.filter,
          emptyListText: widget.emptyListText,
          onItemSelected: (item) {
            Navigator.pop(context, item);
          },
        ),
      ),
    );

    if (result != null || widget.canUnselect) {
      widget.onChanged?.call(result);
    }
  }

  /// Builds the anchor widget for desktop anchored panel.
  ///
  /// The anchor is built from LayrzInputChrome with suppressReadOnlyLock=true
  /// to hide the read-only lock icon and show the dropdown chevron instead.
  Widget _buildAnchor(BuildContext context, MenuController controller) {
    final tokens = context.tokens;
    final isExpanded = controller.isOpen;

    // Resolve slots
    final prefixSlot = resolvePrefixSlot(
      prefixIcon: widget.prefixIcon,
      prefix: widget.prefix,
      prefixText: widget.prefixText,
      onPrefixTap: widget.onPrefixTap,
    );

    final suffixSlot = resolveSuffixSlot(
      suffixIcon: widget.suffixIcon,
      suffix: widget.suffix,
      suffixText: widget.suffixText,
      onSuffixTap: widget.onSuffixTap,
    );

    // Add dropdown chevron to the suffix slot if not provided
    final finalSuffixSlot = suffixSlot.hasContent
        ? suffixSlot
        : LayrzInputSuffixSlot(
            icon: MdiIcons.chevronDown,
          );

    // Compute states
    if (widget.disabled) {
      _states.add(WidgetState.disabled);
    } else {
      _states.remove(WidgetState.disabled);
    }

    // Find the selected item's label text
    String? selectedLabel;
    if (widget.value != null) {
      for (final item in widget.items) {
        if (item.value == widget.value) {
          selectedLabel = item.labelText;
          break;
        }
      }
    }

    // Build the content display widget with full width
    final contentChild = Padding(
      padding: tokens.spacing.pd2,
      child: SizedBox(
        width: double.infinity,
        child: Text(
          selectedLabel ?? '',
          style: tokens.typography.body,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    return Semantics(
      label: widget.labelText,
      button: true,
      enabled: !widget.disabled,
      expanded: isExpanded,
      onTap: widget.disabled ? null : controller.open,
      child: GestureDetector(
        onTap: widget.disabled ? null : controller.open,
        behavior: HitTestBehavior.opaque,
        child: LayrzInputChrome(
          labelText: widget.labelText,
          hintText: widget.hintText,
          isRequired: widget.isRequired,
          prefixSlot: prefixSlot,
          suffixSlot: finalSuffixSlot,
          disabled: widget.disabled,
          readOnly: true,
          errors: widget.errors,
          hideDetails: widget.hideDetails,
          states: _states,
          helpTitleText: widget.helpTitleText,
          helpContentText: widget.helpContentText,
          controller: _controller,
          padding: widget.padding,
          suppressReadOnlyLock: true,
          child: contentChild,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;

    if (isCompact) {
      // Mobile: build anchor that opens bottom sheet on tap
      // Note: Mobile bottom sheet does not expose expanded state since it is not
      // connected to a controller that can be queried. This is acceptable because
      // the bottom sheet itself is its own modal navigation layer.
      final tokens = context.tokens;

      // Resolve slots
      final prefixSlot = resolvePrefixSlot(
        prefixIcon: widget.prefixIcon,
        prefix: widget.prefix,
        prefixText: widget.prefixText,
        onPrefixTap: widget.onPrefixTap,
      );

      final suffixSlot = resolveSuffixSlot(
        suffixIcon: widget.suffixIcon,
        suffix: widget.suffix,
        suffixText: widget.suffixText,
        onSuffixTap: widget.onSuffixTap,
      );

      // Add dropdown chevron to the suffix slot if not provided
      final finalSuffixSlot = suffixSlot.hasContent
          ? suffixSlot
          : LayrzInputSuffixSlot(
              icon: MdiIcons.chevronDown,
            );

      // Compute states
      if (widget.disabled) {
        _states.add(WidgetState.disabled);
      } else {
        _states.remove(WidgetState.disabled);
      }

      // Find the selected item's label text
      String? selectedLabel;
      if (widget.value != null) {
        for (final item in widget.items) {
          if (item.value == widget.value) {
            selectedLabel = item.labelText;
            break;
          }
        }
      }

      // Build the content display widget with full width
      final contentChild = Padding(
        padding: tokens.spacing.pd2,
        child: SizedBox(
          width: double.infinity,
          child: Text(
            selectedLabel ?? '',
            style: tokens.typography.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );

      return Semantics(
        label: widget.labelText,
        button: true,
        enabled: !widget.disabled,
        onTap: widget.disabled ? null : _openMobileSurface,
        child: GestureDetector(
          onTap: widget.disabled ? null : _openMobileSurface,
          behavior: HitTestBehavior.opaque,
          child: LayrzInputChrome(
            labelText: widget.labelText,
            hintText: widget.hintText,
            isRequired: widget.isRequired,
            prefixSlot: prefixSlot,
            suffixSlot: finalSuffixSlot,
            disabled: widget.disabled,
            readOnly: true,
            errors: widget.errors,
            hideDetails: widget.hideDetails,
            states: _states,
            helpTitleText: widget.helpTitleText,
            helpContentText: widget.helpContentText,
            controller: _controller,
            padding: widget.padding,
            suppressReadOnlyLock: true,
            child: contentChild,
          ),
        ),
      );
    } else {
      // Desktop: return anchored panel with selection surface
      return LayrzAnchoredPanel(
        widthPolicy: LayrzAnchoredPanelWidthPolicy.matchAnchor,
        builder: (context, controller) {
          _panelController = controller;
          return _buildAnchor(context, controller);
        },
        child: SizedBox(
          height: 300,
          child: LayrzSelectInputSurface(
            items: widget.items,
            selectedItem: _findSelectedItem(),
            enableSearch: widget.enableSearch,
            canUnselect: widget.canUnselect,
            filter: widget.filter,
            emptyListText: widget.emptyListText,
            panelController: _panelController,
            onItemSelected: (item) {
              widget.onChanged?.call(item);
            },
          ),
        ),
      );
    }
  }
}
