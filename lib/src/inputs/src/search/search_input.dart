import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/overlays/overlays.dart';

import 'search_input_mode.dart';
import '../shared/editable_field.dart';
import '../shared/input_chrome.dart';
import '../shared/input_slot.dart';
import '../shared/input_style_spec.dart';

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
/// Both presentation forms (field and icon button) provide semantic labels. In field mode, the
/// widget owns exactly one [Semantics] node carrying [labelText] (falling back to a localized
/// default); the trigger button in icon mode provides its own semantic label, and the panel field
/// it opens is deliberately unlabelled so the button's label is not announced twice.
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

  /// Whether the field is marked as required.
  ///
  /// When true, a required marker (`*`) is rendered next to [labelText] in field mode.
  /// Has no visible effect in icon mode, where the panel field renders no label.
  final bool isRequired;

  /// Whether the input field is disabled.
  final bool disabled;

  /// Whether the input field is read-only.
  ///
  /// A read-only field is not editable but still fires tap callbacks, and renders a
  /// lock affordance in the trailing icon cluster. Does not affect the clear button,
  /// which remains driven solely by whether the field currently has text.
  final bool readOnly;

  /// The list of error messages to display below the field.
  ///
  /// When non-empty, the field renders a danger-colored border, a trailing error icon,
  /// and the error messages themselves below the field.
  final List<String> errors;

  /// The title text for the help affordance tooltip.
  ///
  /// Ignored unless [helpContentText] is also provided.
  final String? helpTitleText;

  /// The content text for the help affordance tooltip.
  ///
  /// When non-null and non-empty, a help icon is rendered in the trailing icon cluster.
  final String? helpContentText;

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
    this.isRequired = false,
    this.disabled = false,
    this.readOnly = false,
    this.errors = const [],
    this.helpTitleText,
    this.helpContentText,
    this.controller,
    this.focusNode,
    this.padding,
    this.maxWidth,
  });

  @override
  State<LayrzSearchInput> createState() => _LayrzSearchInputState();
}

class _LayrzSearchInputState extends State<LayrzSearchInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _debounceTimer;

  /// The widget states (disabled, focused) fed to [LayrzInputChrome].
  ///
  /// Hover and press are owned internally by [LayrzEditableField] and are not
  /// replicated here.
  final Set<WidgetState> _states = {};

  /// Tracks the controller's emptiness so the clear affordance is only rebuilt
  /// on an isEmpty transition, not on every keystroke.
  bool _wasEmpty = true;

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
    _wasEmpty = _controller.text.isEmpty;
    _controller.addListener(_handleControllerTextChanged);
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(LayrzSearchInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle controller identity changes across all four ownership
    // transitions (null->null is a no-op since both sides are identical):
    // - null -> external: the listener must move off the internally-created
    //   controller before it is disposed, or it leaks onto a controller this
    //   state no longer tracks.
    // - external -> null: the outgoing (caller-owned) controller must never
    //   be disposed here; a fresh internal controller is created instead.
    // - external -> a different external: neither instance is owned, so
    //   only the listener moves.
    // Mirrors [LayrzComboBoxInput]'s reference handling of the same four
    // transitions.
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_handleControllerTextChanged);
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
      _wasEmpty = _controller.text.isEmpty;
      _controller.addListener(_handleControllerTextChanged);
    }

    if (widget.value != null && widget.value != _controller.text) {
      _controller.text = widget.value!;
    }

    // Handle focus node identity changes across the same four ownership
    // transitions as [_controller] above. Unlike [_controller], this state
    // never attaches its own listener to [_focusNode] -- it only hands the
    // node to [LayrzEditableFieldConfig.focusNode], and [LayrzEditableField]
    // manages its own listener on whatever node it is given, independently.
    // So there is no listener to move here; only the dispose-then-adopt
    // ownership handling applies.
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_handleControllerTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  /// Rebuilds the field only when the controller's emptiness changes.
  ///
  /// [_buildFieldMode] and [_buildIconMode] read `_controller.text.isNotEmpty` to
  /// decide whether to show the clear affordance. Without this listener, that
  /// affordance never appeared while the user typed — only once the widget was
  /// rebuilt for an unrelated reason. Guarding on the isEmpty transition, rather
  /// than calling `setState` on every keystroke, avoids rebuilding the field on
  /// each character typed.
  void _handleControllerTextChanged() {
    final isEmpty = _controller.text.isEmpty;
    if (isEmpty != _wasEmpty) {
      setState(() {
        _wasEmpty = isEmpty;
      });
    }
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

  /// Clears the search field and returns focus to it.
  ///
  /// Focus is always requested after clearing, even if the field was not focused
  /// beforehand -- clicking "clear" is almost always immediately followed by typing
  /// a new query, so refocusing regardless of prior state is the more useful default.
  /// In icon mode this also doubles as the recovery path when the panel's own
  /// internal focus node ends up holding focus instead of the field (see
  /// [_handlePanelOpened]).
  void _clearSearch() {
    if (widget.disabled) {
      return;
    }

    _controller.clear();
    _handleSearchChanged('');
    _focusNode.requestFocus();
  }

  /// Re-requests focus onto the search field once [LayrzAnchoredPanel] has finished opening.
  ///
  /// [LayrzAnchoredPanel] moves focus to its own internal node in a post-frame callback
  /// registered when the panel opens (`anchored_panel.dart`), which runs *after* this
  /// field's [LayrzEditableFieldConfig.autofocus] has already acted -- overriding it.
  /// Nesting a second [WidgetsBinding.addPostFrameCallback] defers this request to the
  /// frame *after* that one, guaranteeing it runs last and wins the race. This mirrors
  /// the equivalent fix in [LayrzComboBoxInput]'s `_handleMenuOpenRequested`, adapted for
  /// the extra frame of delay [LayrzAnchoredPanel]'s own focus grab introduces.
  void _handlePanelOpened() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    });
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

  /// Updates [_states] for the current disabled state.
  void _syncDisabledState() {
    if (widget.disabled) {
      _states.add(WidgetState.disabled);
    } else {
      _states.remove(WidgetState.disabled);
    }
  }

  /// Builds the [LayrzEditableFieldConfig] shared by field and icon mode.
  ///
  /// [labelText] and [autofocus] differ between the two call sites; every other value
  /// is identical, so it is factored out to avoid the two modes drifting apart.
  LayrzEditableFieldConfig _buildFieldConfig({
    required String? labelText,
    required String hintText,
    required bool autofocus,
  }) {
    return LayrzEditableFieldConfig(
      labelText: labelText,
      hintText: hintText,
      disabled: widget.disabled,
      readOnly: widget.readOnly,
      controller: _controller,
      focusNode: _focusNode,
      onChanged: _handleSearchChanged,
      onSubmit: null,
      onFocusChanged: (isFocused) {
        setState(() {
          if (isFocused) {
            _states.add(WidgetState.focused);
          } else {
            _states.remove(WidgetState.focused);
          }
        });
      },
      onTap: null,
      keyboardType: TextInputType.text,
      textInputAction: null,
      inputFormatters: const [],
      maxLength: null,
      autofocus: autofocus,
      textCapitalization: TextCapitalization.none,
      autofillHints: const [],
      obscureText: false,
      autocorrect: true,
      enableSuggestions: true,
      actions: null,
      minLines: 1,
      maxLines: 1,
      expands: false,
      textAlign: TextAlign.start,
    );
  }

  /// Builds the field mode: inline text input with magnifier prefix and clear suffix.
  Widget _buildFieldMode(BuildContext context) {
    final hintText = widget.hintText ?? context.l10n.inputsSearchHint;
    final resolvedLabel = widget.labelText ?? context.l10n.helperSearch;

    _syncDisabledState();

    final prefixSlot = resolvePrefixSlot(prefixIcon: MdiIcons.magnify, isDecorative: true);
    final suffixSlot = resolveSuffixSlot(
      suffixIcon: _controller.text.isNotEmpty ? MdiIcons.close : null,
      onSuffixTap: _controller.text.isNotEmpty ? _clearSearch : null,
      semanticLabel: context.l10n.inputsSearchClear,
    );

    final fieldConfig = _buildFieldConfig(
      labelText: resolvedLabel,
      hintText: hintText,
      autofocus: false,
    );

    return Semantics(
      label: resolvedLabel,
      enabled: !widget.disabled,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (widget.maxWidth ?? double.infinity).clamp(0.0, double.infinity),
        ),
        child: LayrzInputChrome(
          labelText: resolvedLabel,
          hintText: hintText,
          isRequired: widget.isRequired,
          prefixSlot: prefixSlot,
          suffixSlot: suffixSlot,
          disabled: widget.disabled,
          readOnly: widget.readOnly,
          errors: widget.errors,
          hideDetails: false,
          states: _states,
          helpTitleText: widget.helpTitleText,
          helpContentText: widget.helpContentText,
          controller: _controller,
          padding: widget.padding,
          child: LayrzEditableField(config: fieldConfig),
        ),
      ),
    );
  }

  /// Builds the icon mode: magnifier button that opens a panel with the field.
  ///
  /// [LayrzAnchoredPanel] is the single visual container here: it already draws the
  /// background, shadow, and rounded corners (`tokens.radius.br3`). The chrome is told
  /// `showBorder: false` and given a matching `borderRadius` so it never draws a second,
  /// differently-rounded rectangle inside the panel (the "double rounded rectangle" bug).
  ///
  /// That removes the chrome's only carrier of the focused/error visual states, so this
  /// method wraps the chrome in its own [Container] that paints a border -- at the exact
  /// same radius as the panel -- only while [_states] is focused or [LayrzSearchInput.errors]
  /// is non-empty. In every other state (rest, hover, disabled, plain read-only) that
  /// wrapper paints nothing, preserving the "one floating surface" look; the moment the
  /// field is focused or errored, the whole panel reads as carrying a colored ring instead
  /// of the field growing a mismatched inner border.
  Widget _buildIconMode(BuildContext context) {
    final tokens = context.tokens;
    final hintText = widget.hintText ?? context.l10n.inputsSearchHint;
    final hasErrors = widget.errors.isNotEmpty;

    _syncDisabledState();

    final prefixSlot = resolvePrefixSlot(prefixIcon: MdiIcons.magnify, isDecorative: true);
    final suffixSlot = resolveSuffixSlot(
      suffixIcon: _controller.text.isNotEmpty ? MdiIcons.close : null,
      onSuffixTap: _controller.text.isNotEmpty ? _clearSearch : null,
      semanticLabel: context.l10n.inputsSearchClear,
    );

    // No labelText here: the panel field must not inherit the trigger button's
    // label, or the label would be announced twice (button + panel field).
    final fieldConfig = _buildFieldConfig(
      labelText: null,
      hintText: hintText,
      autofocus: true,
    );

    final spec = LayrzInputStyleSpec.resolve(
      states: _states,
      tokens: tokens,
      hasErrors: hasErrors,
      readOnly: widget.readOnly,
    );
    final showFocusRing = !widget.disabled && (_states.contains(WidgetState.focused) || hasErrors);

    return LayrzAnchoredPanel(
      widthPolicy: LayrzAnchoredPanelWidthPolicy.contentSized,
      widthBounds: const LayrzAnchoredPanelWidthBounds(minWidth: 280.0, maxWidth: 480.0),
      onOpen: _handlePanelOpened,
      builder: (context, controller) {
        return LayrzButton(
          labelText: widget.labelText ?? context.l10n.helperSearch,
          icon: MdiIcons.magnify,
          onTap: widget.disabled ? null : controller.open,
          isDisabled: widget.disabled,
          style: LayrzButtonStyle.elevatedFab,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: tokens.radius.br3,
          border: showFocusRing
              ? Border.all(
                  color: spec.borderColor,
                  width: spec.borderWidth,
                )
              : null,
        ),
        child: LayrzInputChrome(
          labelText: null,
          hintText: hintText,
          isRequired: widget.isRequired,
          prefixSlot: prefixSlot,
          suffixSlot: suffixSlot,
          disabled: widget.disabled,
          readOnly: widget.readOnly,
          errors: widget.errors,
          hideDetails: false,
          states: _states,
          helpTitleText: widget.helpTitleText,
          helpContentText: widget.helpContentText,
          controller: _controller,
          padding: widget.padding,
          borderRadius: tokens.radius.br3,
          showBorder: false,
          child: LayrzEditableField(config: fieldConfig),
        ),
      ),
    );
  }
}
