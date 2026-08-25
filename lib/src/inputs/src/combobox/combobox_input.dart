import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/selection/selection.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../shared/editable_field.dart';
import '../shared/input_chrome.dart';
import '../shared/input_slot.dart';
import 'combobox_layout.dart';
import 'combobox_surface.dart';

/// Maximum height, in logical pixels, of the desktop overlay's option list.
///
/// Fixed, not caller-configurable: the overlay renders [DesktopOverlay]'s content up
/// to this height and scrolls past it. This replaces the former `maxOptionsToDisplay`
/// parameter, which let a caller size the panel by row count using a row-height
/// constant (`48.0`) that did not match the actual rendered row height (~36px) — the
/// panel it produced was already wrong for any count other than the default.
const double _kComboBoxOverlayMaxHeight = 300.0;

/// A Material-free combobox input in the layrz_ui design system.
///
/// [LayrzComboBoxInput] is an editable input field with a dropdown list of options.
/// It composes [LayrzInputChrome] and the shared editable field primitive directly,
/// adding suggestion filtering and intelligent overlay positioning on top.
///
/// **Desktop vs. Mobile behavior**:
/// - **Desktop (>= 960px)**: Displays a dropdown overlay that flips above/below based on
///   available space, using [RawMenuAnchor]-like positioning logic.
/// - **Mobile (< 960px)**: Opens a bottom sheet instead, allowing touch-friendly interaction
///   with better use of screen space.
///
/// **Field focus**: The text field retains focus while the overlay is open, allowing
/// the user to continue typing to filter options. Arrow keys move a highlight through
/// options; Enter commits the highlighted option; Escape closes without committing.
///
/// **Free-form entry** (default): When [allowFreeForm] is true, any text the user types
/// is a valid value. On blur or Enter, the field commits whatever is typed. When false,
/// the field reverts to the last matching option on blur.
///
/// **Filtering**: Options are matched case-insensitively from the start of each option.
/// The [enableAutocomplete] flag controls whether filtering is applied (when true, default)
/// or all options are shown unfiltered (when false).
///
/// **Slot exclusivity**: At most one of `prefixIcon` / `prefix` / `prefixText` may be
/// non-null; the same rule applies to the suffix trio. Providing multiple slot values
/// triggers an assertion error in debug mode.
///
/// **Disposal contract**: When `controller` or `focusNode` is null, the widget creates
/// and disposes its own instances. Caller-supplied instances are never disposed.
class LayrzComboBoxInput extends StatefulWidget {
  /// The list of available options to display in the dropdown.
  final List<String> options;

  /// The current value of the input field.
  ///
  /// When set, the field is initialized to this value.
  final String? value;

  /// Callback fired when the input value changes.
  ///
  /// Fires once per genuine keystroke-driven text change while typing, once per
  /// external [value] update, and exactly once per committed selection —
  /// tapping an option in the desktop overlay or bottom sheet, or pressing
  /// Enter on a highlighted option — **even when the committed value is
  /// identical to the text already shown** (for example, typing an option's
  /// full text and then tapping that same option, or re-selecting the option
  /// already displayed). A commit is always reported, regardless of how many
  /// `TextEditingValue` notifications the resulting controller assignment
  /// produces underneath (see `_lastNotifiedText` in the implementation for how
  /// those extra echoes are deduped without swallowing the commit itself).
  final ValueChanged<String>? onChanged;

  /// Callback fired when the user submits the input (e.g., presses Enter or picks
  /// an option from the overlay or bottom sheet).
  ///
  /// Fires exactly once per commit, unconditionally — including when the
  /// committed value is identical to the text already shown. [onChanged] fires
  /// on every commit too, but also fires on every intermediate keystroke while
  /// typing; a caller that only cares about a deliberate commit — not each
  /// keystroke along the way — should prefer this one.
  final ValueChanged<String>? onSubmit;

  /// Whether free-form text entry is allowed.
  ///
  /// When true (default), any typed text is a valid value. When false, the field
  /// reverts to the last matching option on blur.
  final bool allowFreeForm;

  /// Text to display when no options match the current filter.
  ///
  /// If null, defaults to [LayrzUiL10n.comboboxEmpty].
  final String? emptyOptionsText;

  /// Whether autocomplete filtering is enabled.
  ///
  /// When true (default), options are filtered to match the typed text.
  /// When false, all options are shown regardless of the text.
  final bool enableAutocomplete;

  /// The label text displayed above the input field.
  final String? labelText;

  /// Hint text displayed as placeholder when the field is empty.
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
  ///
  /// Ignored if the field is disabled.
  final VoidCallback? onPrefixTap;

  /// Icon to render as a suffix.
  ///
  /// Mutually exclusive with [suffix] and [suffixText].
  final IconData? suffixIcon;

  /// Widget to render as a suffix.
  ///
  /// Mutually exclusive with [suffixIcon] and [suffixText].
  final Widget? suffix;

  /// Text to render as a suffix.
  ///
  /// Mutually exclusive with [suffixIcon] and [suffix].
  final String? suffixText;

  /// Callback fired when the suffix is tapped.
  ///
  /// Ignored if the field is disabled.
  final VoidCallback? onSuffixTap;

  /// The title text for the help affordance tooltip.
  final String? helpTitleText;

  /// The content text for the help affordance tooltip.
  final String? helpContentText;

  /// Whether the field is disabled.
  final bool disabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// The list of error messages to display below the field.
  final List<String> errors;

  /// Whether to hide the error message block and other detail text.
  final bool hideDetails;

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

  /// The keyboard type for the input field.
  final TextInputType keyboardType;

  /// The text input action (e.g., 'go', 'search', 'send').
  final TextInputAction? textInputAction;

  /// List of input formatters to apply to the input.
  final List<TextInputFormatter> inputFormatters;

  /// The set of text selection actions available in the context menu.
  ///
  /// When null, all four built-in actions (copy, cut, paste, selectAll) are offered.
  /// Pass an explicit set to narrow the list, or `const {}` to suppress the toolbar entirely.
  final Set<LayrzSelectableAction>? actions;

  /// Creates a new [LayrzComboBoxInput] with the given properties.
  const LayrzComboBoxInput({
    required this.options,
    super.key,
    this.value,
    this.onChanged,
    this.onSubmit,
    this.allowFreeForm = true,
    this.emptyOptionsText,
    this.enableAutocomplete = true,
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
    this.readOnly = false,
    this.errors = const [],
    this.hideDetails = false,
    this.controller,
    this.focusNode,
    this.padding,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.inputFormatters = const [],
    this.actions,
  }) : assert(
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
  State<LayrzComboBoxInput> createState() => _LayrzComboBoxInputState();
}

class _LayrzComboBoxInputState extends State<LayrzComboBoxInput> {
  late TextEditingController _controller;
  late FocusNode _fieldFocusNode;
  late MenuController _menuController;
  String? _lastValidOption;
  int _highlightedIndex = -1;

  /// The text last reported to [LayrzComboBoxInput.onChanged].
  ///
  /// `TextEditingController`'s notifications fire on any change to its
  /// `TextEditingValue` — not just the text itself. A bare cursor tap changes only
  /// the selection and still notifies; more subtly, `EditableText` resyncs its own
  /// selection immediately after a programmatic `controller.text =` assignment
  /// (to keep the cursor within the new text's bounds), which notifies a *second*
  /// time with the text unchanged from the first notification. [_handleTextChange]
  /// compares against this field so [_LayrzComboBoxInputState] reports a change to
  /// [LayrzComboBoxInput.onChanged] only when the text itself actually moved,
  /// exactly once per genuine change — regardless of how many `TextEditingValue`
  /// notifications that change happens to produce underneath.
  ///
  /// [_commitValue] also writes to this field directly, *before* it assigns
  /// `_controller.text`. That write-ahead is what lets a commit notify
  /// [LayrzComboBoxInput.onChanged] itself (unconditionally, exactly once) while
  /// still using this same dedupe to swallow the assignment's own echo
  /// notifications — rather than, as a prior version did, using the dedupe as the
  /// *only* path to `onChanged` and having it silently swallow the commit whenever
  /// the committed value already matched the displayed text.
  String _lastNotifiedText = '';

  /// The current interaction states fed to [LayrzInputChrome].
  ///
  /// Carries only [WidgetState.disabled] and [WidgetState.focused] — set in [build]
  /// for disabled, and in the editable field config's `onFocusChanged` callback for
  /// focused. Hover and press live inside [LayrzEditableField]'s own private state.
  final Set<WidgetState> _states = {};

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _fieldFocusNode = widget.focusNode ?? FocusNode();
    _menuController = MenuController();

    // Initialize with the provided value if any
    if (widget.value != null) {
      _controller.text = widget.value!;
      _lastValidOption = widget.value;
    }

    _lastNotifiedText = _controller.text;
    _fieldFocusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(LayrzComboBoxInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle controller changes
    if (widget.controller != oldWidget.controller) {
      // The listener must always be removed from the outgoing controller,
      // regardless of ownership: an externally-supplied controller survives
      // this swap, so leaving the listener attached leaks it onto a
      // controller this state no longer tracks.
      _controller.removeListener(_handleTextChange);
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_handleTextChange);
      _lastNotifiedText = _controller.text;
    }

    // Handle focus node changes
    if (widget.focusNode != oldWidget.focusNode) {
      _fieldFocusNode.removeListener(_handleFocusChange);
      if (oldWidget.focusNode == null) {
        _fieldFocusNode.dispose();
      }
      _fieldFocusNode = widget.focusNode ?? FocusNode();
      _fieldFocusNode.addListener(_handleFocusChange);
    }

    // If value changed externally, update
    if (widget.value != oldWidget.value && widget.value != null) {
      _controller.text = widget.value!;
      _lastValidOption = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _fieldFocusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _fieldFocusNode.dispose();
    }
    _menuController.close();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_fieldFocusNode.hasFocus) {
      _handleBlur();
    }
  }

  void _handleTextChange() {
    setState(() {
      _highlightedIndex = -1;
    });

    final currentText = _controller.text;
    if (currentText == _lastNotifiedText) {
      // See [_lastNotifiedText]: this notification's text is identical to the one
      // already reported, so it is a selection-only echo, not a real change.
      return;
    }
    _lastNotifiedText = currentText;
    widget.onChanged?.call(currentText);
  }

  void _handleBlur() {
    _menuController.close();

    // If allowFreeForm is false, revert to last valid option
    if (!widget.allowFreeForm && _lastValidOption != null) {
      _controller.text = _lastValidOption!;
    }
  }

  /// Filters options based on current text.
  List<String> _getFilteredOptions() {
    if (!widget.enableAutocomplete) {
      return widget.options;
    }

    final text = _controller.text.toLowerCase();
    if (text.isEmpty) {
      return widget.options;
    }

    return widget.options.where((option) => option.toLowerCase().startsWith(text)).toList();
  }

  void _openOverlay() {
    if (context.isCompact) {
      _openBottomSheet();
    } else {
      _menuController.open();
    }
  }

  Future<void> _openBottomSheet() async {
    final filtered = _getFilteredOptions();
    final selected = await LayrzBottomSheet.show<String?>(
      context,
      builder: (context) => BottomSheetContent(
        options: filtered,
        emptyText: widget.emptyOptionsText ?? context.l10n.comboboxEmpty,
      ),
      useRootNavigator: true,
      // BottomSheetContent renders a plain Column, never a same-axis ListView, so
      // it needs no lazy-loading scrollable of its own — but it still needs a
      // *bounded* incoming height to scroll within. scrollable: false hands it the
      // sheet's own ScrollController via an ambient PrimaryScrollController instead
      // of nesting it inside the sheet's SingleChildScrollView, so this content's
      // own SingleChildScrollView receives a real bound directly from the sheet's
      // Expanded region and shares the sheet's drag/scroll handoff.
      scrollable: false,
    );

    // The sheet reports the selection solely by popping with a value — see
    // BottomSheetContent's doc comment for why there is no second, callback-based
    // commit path here.
    if (selected != null) {
      _commitValue(selected);
    }
  }

  void _commitValue(String value) {
    // A commit (tapping an option, pressing Enter on a highlighted option, or
    // picking from the bottom sheet) always reports `onChanged`, exactly once —
    // including when `value` already matches the field's current text (typing
    // an option's full text and then tapping it, or re-selecting the option
    // already shown). Writing `_lastNotifiedText` and calling `onChanged`
    // *before* touching the controller is what makes that hold: the assignment
    // below still routes through `_handleTextChange`, but by the time it fires,
    // `_lastNotifiedText` already equals `value`, so that notification — and the
    // second one from `EditableText`'s post-assignment selection resync — are
    // both deduped as echoes of the call just made here, rather than the sole
    // source of the notification. A prior version skipped this explicit call
    // and relied only on the assignment, which meant a commit whose value
    // already matched the displayed text produced no `onChanged` call at all:
    // `_handleTextChange`'s own dedupe had nothing to compare against but
    // itself.
    _lastNotifiedText = value;
    widget.onChanged?.call(value);

    _controller.text = value;
    _lastValidOption = value;
    widget.onSubmit?.call(value);
    _menuController.close();
  }

  void _handleMenuOpenRequested(Offset? position, VoidCallback showOverlay) {
    showOverlay();
    setState(() {
      _highlightedIndex = -1;
    });

    // Keep focus in the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        _fieldFocusNode.requestFocus();
      }
    });
  }

  void _handleMenuCloseRequested(VoidCallback hideOverlay) {
    hideOverlay();
    setState(() {
      _highlightedIndex = -1;
    });
  }

  /// Builds an empty overlay for mobile (compact) mode.
  ///
  /// On mobile, the overlay is not shown; the bottom sheet is used instead.
  /// This is a no-op builder that returns an empty container.
  Widget buildEmptyOverlay(BuildContext context, RawMenuOverlayInfo info) {
    return const SizedBox.shrink();
  }

  Widget _buildMenuOverlay(BuildContext context, RawMenuOverlayInfo info) {
    final tokens = context.tokens;
    final filtered = _getFilteredOptions();
    final emptyText = widget.emptyOptionsText ?? context.l10n.comboboxEmpty;

    return TapRegion(
      groupId: info.tapRegionGroupId,
      onTapOutside: (PointerDownEvent event) {
        MenuController.maybeOf(context)?.close();
      },
      child: CustomSingleChildLayout(
        delegate: ComboBoxLayoutDelegate(
          anchorRect: info.anchorRect,
          overlaySize: info.overlaySize,
          tokens: tokens,
          maxHeight: _kComboBoxOverlayMaxHeight,
        ),
        child: DesktopOverlay(
          options: filtered,
          highlightedIndex: _highlightedIndex,
          onSelected: _commitValue,
          emptyText: emptyText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;

    return Semantics(
      label: widget.labelText,
      button: true,
      enabled: !widget.disabled && !widget.readOnly,
      expanded: _menuController.isOpen,
      onTap: (widget.disabled || widget.readOnly) ? null : _openOverlay,
      child: Focus(
        onKeyEvent: (node, event) {
          if (!_menuController.isOpen) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (!isCompact) {
                _openOverlay();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          }

          final filtered = _getFilteredOptions();
          if (filtered.isEmpty) {
            return KeyEventResult.ignored;
          }

          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            setState(() {
              _highlightedIndex = (_highlightedIndex + 1) % filtered.length;
            });
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            setState(() {
              _highlightedIndex = (_highlightedIndex - 1 + filtered.length) % filtered.length;
            });
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (_highlightedIndex >= 0 && _highlightedIndex < filtered.length) {
              _commitValue(filtered[_highlightedIndex]);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            _menuController.close();
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        child: RawMenuAnchor(
          controller: _menuController,
          onOpenRequested: isCompact ? (offset, callback) {} : _handleMenuOpenRequested,
          onCloseRequested: isCompact ? (callback) {} : _handleMenuCloseRequested,
          useRootOverlay: true,
          consumeOutsideTaps: false,
          childFocusNode: isCompact ? null : _fieldFocusNode,
          overlayBuilder: isCompact ? buildEmptyOverlay : _buildMenuOverlay,
          builder: (context, menuController, child) {
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

            // Compute states
            if (widget.disabled) {
              _states.add(WidgetState.disabled);
            } else {
              _states.remove(WidgetState.disabled);
            }

            // Create the editable field configuration.
            //
            // `onChanged` is deliberately null: `_handleTextChange` is already
            // registered as a listener on `_controller` and wiring `onChanged` too
            // would fire the callback twice.
            final fieldConfig = LayrzEditableFieldConfig(
              labelText: widget.labelText,
              hintText: widget.hintText,
              disabled: widget.disabled,
              readOnly: widget.readOnly,
              controller: _controller,
              focusNode: _fieldFocusNode,
              onChanged: null,
              onSubmit: widget.onSubmit,
              onFocusChanged: (isFocused) {
                setState(() {
                  if (isFocused) {
                    _states.add(WidgetState.focused);
                  } else {
                    _states.remove(WidgetState.focused);
                  }
                });
              },
              onTap: () {
                if (!widget.disabled && !widget.readOnly) {
                  _openOverlay();
                }
              },
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              inputFormatters: widget.inputFormatters,
              maxLength: null,
              autofocus: false,
              textCapitalization: TextCapitalization.none,
              autofillHints: const [],
              obscureText: false,
              autocorrect: true,
              enableSuggestions: true,
              actions: widget.actions,
              minLines: 1,
              maxLines: 1,
              expands: false,
            );

            return LayrzInputChrome(
              labelText: widget.labelText,
              hintText: widget.hintText,
              isRequired: widget.isRequired,
              prefixSlot: prefixSlot,
              suffixSlot: suffixSlot,
              disabled: widget.disabled,
              readOnly: widget.readOnly,
              errors: widget.errors,
              hideDetails: widget.hideDetails,
              states: _states,
              helpTitleText: widget.helpTitleText,
              helpContentText: widget.helpContentText,
              controller: _controller,
              padding: widget.padding,
              child: LayrzEditableField(config: fieldConfig),
            );
          },
        ),
      ),
    );
  }
}
