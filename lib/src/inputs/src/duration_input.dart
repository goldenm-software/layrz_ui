import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/overlays/overlays.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import 'duration_picker_panel.dart';
import 'duration_unit.dart';
import 'text_input.dart';

/// The default set of visible duration units.
const _kDefaultVisibleUnits = {
  LayrzDurationUnit.day,
  LayrzDurationUnit.hour,
  LayrzDurationUnit.minute,
  LayrzDurationUnit.second,
};

/// A Material-free duration input field in the layrz_ui design system.
///
/// [LayrzDurationInput] captures a [Duration] value through a configurable picker
/// showing day, hour, minute, and second fields. The picker adapts to screen size:
/// - **Desktop/wide** (>= 960px, `!context.isCompact`): anchored panel positioned below the field
/// - **Mobile/compact** (< 960px, `context.isCompact`): bottom sheet covering the lower screen
///
/// **Unit bounds and capping:**
/// - **Day**: no upper bound (0 to infinity)
/// - **Hour**: 0–23 (23 represents the final hour of a day)
/// - **Minute**: 0–59
/// - **Second**: 0–59
///
/// The capping ensures a one-to-one mapping between a [Duration] and its field
/// representation. If a caller stores the result and reopens the picker, the
/// duration re-fills into the same field state with no ambiguity.
///
/// **Visible units:**
/// The [visibleUnits] parameter controls which fields appear in the picker.
/// Defaults to all four. Units not in the set are skipped; at least one unit
/// must be present (enforced by assertion).
///
/// **Summary display:**
/// The anchor displays a humanised summary like "2 days, 3 hours" (omitting
/// zero-valued units and using localized unit names and pluralisation). A null
/// duration shows empty text.
///
/// **Unsupported units:**
/// Year, month, and week are not supported because they are not fixed-length
/// and cannot be reliably mapped to [Duration].
///
/// **Disposal contract:** When `controller` or `focusNode` is null, the widget
/// creates and disposes its own instances. Caller-supplied instances are never disposed.
///
/// **Read-only anchor:** The summary is shown in a read-only text input that opens
/// the picker on tap. The input does not show a lock icon because the picker is
/// interactive, not locked.
class LayrzDurationInput extends StatefulWidget {
  /// The currently selected duration.
  ///
  /// When null, the anchor shows empty text and the picker opens with all fields
  /// at zero (or uninitialized, depending on field visibility).
  final Duration? value;

  /// Callback fired when the duration changes.
  ///
  /// Called with the new [Duration] when the user edits any field or presses reset.
  /// Not called when the picker is opened without changes.
  final ValueChanged<Duration?>? onChanged;

  /// The set of units visible in the picker.
  ///
  /// Defaults to all four ([LayrzDurationUnit.day], [LayrzDurationUnit.hour],
  /// [LayrzDurationUnit.minute], [LayrzDurationUnit.second]). Must be non-empty
  /// (enforced by assertion).
  ///
  /// Units not in the set are omitted from the picker and the summary display.
  final Set<LayrzDurationUnit> visibleUnits;

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

  /// The list of error messages to display below the field.
  final List<String> errors;

  /// Whether to hide the error message block and other detail text.
  final bool hideDetails;

  /// Whether the field is disabled (not interactive).
  final bool disabled;

  /// The text editing controller for the anchor field.
  ///
  /// If null, a controller is created and disposed by the widget.
  final TextEditingController? controller;

  /// The focus node for the anchor field.
  ///
  /// If null, a focus node is created and disposed by the widget.
  final FocusNode? focusNode;

  /// The padding applied inside the anchor field.
  ///
  /// If null, defaults to the value used by [LayrzTextInput].
  final EdgeInsets? padding;

  /// The title text for the help affordance tooltip.
  final String? helpTitleText;

  /// The content text for the help affordance tooltip.
  final String? helpContentText;

  /// Creates a new [LayrzDurationInput].
  LayrzDurationInput({
    super.key,
    this.value,
    this.onChanged,
    this.visibleUnits = _kDefaultVisibleUnits,
    this.labelText,
    this.hintText,
    this.isRequired = false,
    this.errors = const [],
    this.hideDetails = false,
    this.disabled = false,
    this.controller,
    this.focusNode,
    this.padding,
    this.helpTitleText,
    this.helpContentText,
  }) : assert(
         labelText != null || hintText != null,
         'At least one of labelText or hintText must be non-null.',
       ),
       assert(
         visibleUnits.isNotEmpty,
         'visibleUnits must not be empty.',
       );

  @override
  State<LayrzDurationInput> createState() => _LayrzDurationInputState();
}

class _LayrzDurationInputState extends State<LayrzDurationInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Duration? _lastValue;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(LayrzDurationInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
    }
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _updateSummary() {
    final l10n = context.l10n;
    final duration = widget.value;

    if (duration == null) {
      _controller.text = '';
      return;
    }

    final parts = <String>[];

    if (widget.visibleUnits.contains(LayrzDurationUnit.day)) {
      final days = duration.inDays;
      if (days > 0) {
        final unit = days == 1 ? l10n.durationUnitDaySingular : l10n.durationUnitDayPlural;
        parts.add('$days $unit');
      }
    }

    if (widget.visibleUnits.contains(LayrzDurationUnit.hour)) {
      final hours = (duration.inHours % 24);
      if (hours > 0) {
        final unit = hours == 1 ? l10n.durationUnitHourSingular : l10n.durationUnitHourPlural;
        parts.add('$hours $unit');
      }
    }

    if (widget.visibleUnits.contains(LayrzDurationUnit.minute)) {
      final minutes = (duration.inMinutes % 60);
      if (minutes > 0) {
        final unit = minutes == 1 ? l10n.durationUnitMinuteSingular : l10n.durationUnitMinutePlural;
        parts.add('$minutes $unit');
      }
    }

    if (widget.visibleUnits.contains(LayrzDurationUnit.second)) {
      final seconds = (duration.inSeconds % 60);
      if (seconds > 0) {
        final unit = seconds == 1 ? l10n.durationUnitSecondSingular : l10n.durationUnitSecondPlural;
        parts.add('$seconds $unit');
      }
    }

    _controller.text = parts.isEmpty ? '' : parts.join(', ');
  }

  Future<void> _openPicker() async {
    if (widget.disabled) return;

    final isCompact = context.isCompact;
    Duration? result;

    if (isCompact) {
      result = await _showBottomSheet();
    } else {
      result = await _showAnchoredPanel();
    }

    if (result != null && mounted) {
      widget.onChanged?.call(result);
      _updateSummary();
    }
  }

  Future<Duration?> _showBottomSheet() async {
    return LayrzBottomSheet.show<Duration?>(
      context,
      builder: (context) => LayrzDurationPickerPanel(
        initialValue: widget.value,
        visibleUnits: widget.visibleUnits,
        onChanged: (duration) {
          Navigator.pop(context, duration);
        },
      ),
      initialSize: 0.5,
      maxSize: 0.9,
    );
  }

  Future<Duration?> _showAnchoredPanel() async {
    final controller = MenuController();
    Duration? result;

    if (!mounted) return null;

    await Navigator.of(context).push(
      _DurationPickerDialogRoute(
        builder: (context) => LayrzAnchoredPanel(
          controller: controller,
          widthPolicy: LayrzAnchoredPanelWidthPolicy.contentSized,
          widthBounds: const LayrzAnchoredPanelWidthBounds(
            minWidth: 320.0,
            maxWidth: 400.0,
          ),
          maxHeight: 400.0,
          builder: (context, panelController) => const SizedBox.shrink(),
          child: LayrzDurationPickerPanel(
            initialValue: widget.value,
            visibleUnits: widget.visibleUnits,
            onChanged: (duration) {
              result = duration;
              controller.close();
            },
          ),
        ),
      ),
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value != _lastValue) {
      _lastValue = widget.value;
      _updateSummary();
    }

    return LayrzTextInput(
      labelText: widget.labelText,
      hintText: widget.hintText,
      isRequired: widget.isRequired,
      controller: _controller,
      focusNode: _focusNode,
      readOnly: true,
      disabled: widget.disabled,
      errors: widget.errors,
      hideDetails: widget.hideDetails,
      padding: widget.padding,
      helpTitleText: widget.helpTitleText,
      helpContentText: widget.helpContentText,
      onTap: widget.disabled ? null : _openPicker,
      suppressReadOnlyLock: true,
    );
  }
}

/// Internal route for displaying the duration picker panel without a barrier.
class _DurationPickerDialogRoute extends Route<void> {
  /// Builds the picker panel content.
  final WidgetBuilder builder;

  /// Creates a new [_DurationPickerDialogRoute].
  _DurationPickerDialogRoute({
    required this.builder,
  });

  Color? get barrierColor => null;

  bool get barrierDismissible => true;

  bool get maintainState => true;

  bool get opaque => false;

  Duration get transitionDuration => Duration.zero;

  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
