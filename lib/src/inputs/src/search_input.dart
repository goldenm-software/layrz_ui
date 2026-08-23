import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/overlays/overlays.dart';

import 'search_input_mode.dart';
import 'text_input.dart';

/// A Material-free search input in the layrz_ui design system.
///
/// [LayrzSearchInput] provides a responsive search field with support for three presentation
/// modes: [LayrzSearchInputMode.auto] (responsive), [LayrzSearchInputMode.field] (always inline),
/// and [LayrzSearchInputMode.icon] (collapsed into a button, opens panel when tapped).
///
/// **Modes:**
/// - **auto (default)**: Picks between field and icon based on viewport width (< 960px = icon mode).
/// - **field**: Always renders as an inline field with magnifier prefix and clear suffix.
/// - **icon**: Renders as a magnifier button that opens an anchored panel containing the field.
///
/// **Debouncing:**
/// The [debounce] parameter controls callback timing (default 300ms):
/// - When set: onSearch fires once after the specified delay, regardless of keystroke count.
/// - When null: onSearch fires on every keystroke.
/// A pending debounce timer is always cancelled in `dispose` to prevent fires after unmount.
///
/// **Disposal contract:**
/// When [controller] or [focusNode] is null, the widget creates and disposes its own instances.
/// Caller-supplied instances are never disposed by this widget.
///
/// **Accessibility:**
/// Both presentation forms (field and icon button) provide semantic labels. The field is labelled
/// via its hintText, and the trigger button provides tooltip and semantic labels via its label.
/// Focus properly traverses into the panel when it opens.
class LayrzSearchInput extends StatefulWidget {
  /// The presentation mode for the search input.
  ///
  /// Defaults to [LayrzSearchInputMode.auto].
  final LayrzSearchInputMode mode;

  /// The current search query value.
  ///
  /// When null or not provided, the field starts empty.
  final String? value;

  /// Callback fired when the user searches.
  ///
  /// Timing is controlled by [debounce]:
  /// - When [debounce] is non-null, fires once after the specified duration.
  /// - When [debounce] is null, fires on every keystroke.
  ///
  /// Ignored if the field is disabled.
  final ValueChanged<String>? onSearch;

  /// The duration to debounce search callbacks (default 300 ms).
  ///
  /// When set, [onSearch] fires once after this delay, regardless of how many times
  /// the field text changes. When null, [onSearch] fires immediately on every keystroke.
  /// A pending debounce timer is always cancelled in `dispose`.
  final Duration? debounce;

  /// The label text for the input field (field and icon modes).
  final String? labelText;

  /// The hint text displayed when the field is empty.
  ///
  /// Defaults to a localized "Search" string if not provided.
  final String? hintText;

  /// Whether the input field is disabled.
  final bool disabled;

  /// The text editing controller for the input field.
  ///
  /// If null, a controller is created and disposed by the widget.
  final TextEditingController? controller;

  /// The focus node for the input field.
  ///
  /// If null, a focus node is created and disposed by the widget.
  final FocusNode? focusNode;

  /// The padding applied inside the input field.
  ///
  /// If null, defaults to `tokens.spacing.pd2` (8px all sides).
  final EdgeInsets? padding;

  /// The maximum width of the input field.
  ///
  /// When in field mode, the field is constrained to this width (clamped to 0).
  /// In icon mode, this parameter is ignored.
  final double? maxWidth;

  /// Creates a new [LayrzSearchInput] with the given properties.
  const LayrzSearchInput({
    super.key,
    this.mode = LayrzSearchInputMode.auto,
    this.value,
    this.onSearch,
    this.debounce = const Duration(milliseconds: 300),
    this.labelText,
    this.hintText,
    this.disabled = false,
    this.controller,
    this.focusNode,
    this.padding,
    this.maxWidth,
  });

  @override
  State<LayrzSearchInput> createState() => _LayrzSearchInputState();
}

class _LayrzSearchInputState extends State<LayrzSearchInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      if (widget.value != null) {
        _controller.text = widget.value!;
      }
    } else {
      _controller = TextEditingController(text: widget.value);
    }
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(LayrzSearchInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null && widget.value != _controller.text) {
      _controller.text = widget.value!;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleSearchChanged(String newValue) {
    if (widget.disabled) {
      return;
    }

    _debounceTimer?.cancel();

    if (widget.onSearch == null) {
      return;
    }

    if (widget.debounce == null) {
      widget.onSearch!(newValue);
    } else {
      _debounceTimer = Timer(widget.debounce!, () {
        if (mounted) {
          widget.onSearch!(newValue);
        }
      });
    }
  }

  void _clearSearch() {
    if (widget.disabled) {
      return;
    }

    _controller.clear();
    _handleSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final mode = _resolveMode(context);

    switch (mode) {
      case LayrzSearchInputMode.field:
        return _buildFieldMode(context);
      case LayrzSearchInputMode.icon:
        return _buildIconMode(context);
      case LayrzSearchInputMode.auto:
        // Unreachable; _resolveMode always resolves auto to field or icon
        throw StateError('auto mode should have been resolved');
    }
  }

  /// Resolves the mode to either field or icon.
  ///
  /// When [widget.mode] is [LayrzSearchInputMode.auto], picks based on [context.isCompact].
  /// Otherwise, returns the specified mode.
  LayrzSearchInputMode _resolveMode(BuildContext context) {
    if (widget.mode == LayrzSearchInputMode.auto) {
      return context.isCompact ? LayrzSearchInputMode.icon : LayrzSearchInputMode.field;
    }
    return widget.mode;
  }

  /// Builds the field mode: inline text input with magnifier prefix and clear suffix.
  Widget _buildFieldMode(BuildContext context) {
    final hintText = widget.hintText ?? context.l10n.inputsSearchHint;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: (widget.maxWidth ?? double.infinity).clamp(0.0, double.infinity),
      ),
      child: LayrzTextInput(
        labelText: widget.labelText ?? context.l10n.helperSearch,
        hintText: hintText,
        controller: _controller,
        focusNode: _focusNode,
        disabled: widget.disabled,
        padding: widget.padding,
        prefixIcon: MdiIcons.magnify,
        suffixIcon: _controller.text.isNotEmpty ? MdiIcons.close : null,
        onChanged: _handleSearchChanged,
        onSuffixTap: _controller.text.isNotEmpty ? _clearSearch : null,
      ),
    );
  }

  /// Builds the icon mode: magnifier button that opens a panel with the field.
  Widget _buildIconMode(BuildContext context) {
    final hintText = widget.hintText ?? context.l10n.inputsSearchHint;

    return LayrzAnchoredPanel(
      widthPolicy: LayrzAnchoredPanelWidthPolicy.contentSized,
      widthBounds: const LayrzAnchoredPanelWidthBounds(minWidth: 280.0, maxWidth: 480.0),
      builder: (context, controller) {
        return LayrzButton(
          labelText: widget.labelText ?? context.l10n.helperSearch,
          icon: MdiIcons.magnify,
          onTap: widget.disabled ? null : controller.open,
          isDisabled: widget.disabled,
          style: LayrzButtonStyle.elevatedFab,
        );
      },
      child: LayrzTextInput(
        hintText: hintText,
        controller: _controller,
        focusNode: _focusNode,
        disabled: widget.disabled,
        padding: widget.padding,
        prefixIcon: MdiIcons.magnify,
        suffixIcon: _controller.text.isNotEmpty ? MdiIcons.close : null,
        onChanged: _handleSearchChanged,
        onSuffixTap: _controller.text.isNotEmpty ? _clearSearch : null,
        autofocus: true,
      ),
    );
  }
}
