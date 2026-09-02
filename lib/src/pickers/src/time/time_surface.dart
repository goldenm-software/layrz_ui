import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import '../models/time_of_day.dart';
import '../shared/time_fields_panel.dart';

/// The surface content for [LayrzTimeInput]: [LayrzPickersTimeFieldsPanel]
/// plus this widget's own live-draft state.
///
/// **Trap 4 discipline**: [onTimeChanged] fires on every field edit and
/// never closes anything — only [LayrzTimeInput] itself decides when to
/// close its hosting surface, and it does so from a deliberate terminal
/// action, never from this callback. See
/// `lib/src/inputs/src/duration/duration_input.dart`'s comments for the two
/// real regressions this discipline exists to prevent.
class LayrzTimeSurface extends StatefulWidget {
  /// The current time value.
  final LayrzTimeOfDay value;

  /// Whether the seconds field is shown.
  final bool showSeconds;

  /// Whether the hour field uses 24-hour form.
  final bool use24HourFormat;

  /// Called with the new time on every field edit.
  final ValueChanged<LayrzTimeOfDay> onTimeChanged;

  /// Creates a new [LayrzTimeSurface].
  const LayrzTimeSurface({
    super.key,
    required this.value,
    this.showSeconds = false,
    this.use24HourFormat = true,
    required this.onTimeChanged,
  });

  @override
  State<LayrzTimeSurface> createState() => _LayrzTimeSurfaceState();
}

class _LayrzTimeSurfaceState extends State<LayrzTimeSurface> {
  late LayrzTimeOfDay _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.value;
  }

  @override
  void didUpdateWidget(LayrzTimeSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Involuntary-close discipline: re-seed on every incoming update, not
    // only in initState -- see the implementation plan's "Involuntary
    // close" section.
    if (oldWidget.value != widget.value) {
      _draft = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: LayrzPickersTimeFieldsPanel(
        value: _draft,
        showSeconds: widget.showSeconds,
        use24HourFormat: widget.use24HourFormat,
        onChanged: (time) {
          setState(() => _draft = time);
          widget.onTimeChanged(time);
        },
      ),
    );
  }
}
