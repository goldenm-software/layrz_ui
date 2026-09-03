import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import '../models/time_of_day.dart';
import '../shared/picker_inline_footer.dart';
import '../shared/time_fields_panel.dart';

/// The surface content for [LayrzTimeInput]: [LayrzPickersTimeFieldsPanel]
/// plus this widget's own live-draft state.
///
/// **DESIGN-98: Cancel/Save, not live commit.** Before DESIGN-98,
/// [onTimeChanged] fired [LayrzTimeInput.onChanged] directly on every field
/// edit and the surface never closed on its own — see decision D75
/// (`engineering/milestone-4.md`) for that original "the surface has no
/// discrete commit gesture, so every edit is the commit" ruling. The
/// maintainer's DESIGN-98 instruction moves this widget onto [LayrzEndDrawer]
/// **with actions**, which supersedes that: field edits now only update this
/// surface's own [_draft], and [LayrzTimeInput.onChanged] fires once, on
/// Save. [onTimeChanged] is retained as the plumbing [LayrzTimeInput] reads
/// draft mutations through (see [onDraftChanged]), not as a live-commit path.
class LayrzTimeSurface extends StatefulWidget {
  /// The current time value.
  final LayrzTimeOfDay value;

  /// Whether the seconds field is shown.
  final bool showSeconds;

  /// Whether the hour field uses 24-hour form.
  final bool use24HourFormat;

  /// Called with the drafted time when the user presses Save.
  final ValueChanged<LayrzTimeOfDay> onTimeChanged;

  /// Called when the user presses Cancel or otherwise dismisses the surface
  /// involuntarily. `null` on the mobile [LayrzBottomSheet] path, which has
  /// no Cancel action of its own.
  final VoidCallback? onCancel;

  /// Called on every draft mutation (a field edit), so [LayrzTimeInput] can
  /// refresh the `actions` it builds outside this surface. Ignored when
  /// [showInlineFooter] is `true`.
  final VoidCallback? onDraftChanged;

  /// Whether this surface renders its own Cancel/Save footer inline, as the
  /// last child of its scrolling body.
  ///
  /// Defaults to `false` — see [LayrzDateSurface.showInlineFooter]'s
  /// identical doc for why every commit-on-tap-turned-Save-carrying surface
  /// defaults this to `false` rather than `true`.
  final bool showInlineFooter;

  /// Creates a new [LayrzTimeSurface].
  const LayrzTimeSurface({
    super.key,
    required this.value,
    this.showSeconds = false,
    this.use24HourFormat = true,
    required this.onTimeChanged,
    this.onCancel,
    this.onDraftChanged,
    this.showInlineFooter = false,
  });

  @override
  State<LayrzTimeSurface> createState() => LayrzTimeSurfaceState();
}

/// State for [LayrzTimeSurface].
///
/// **Public, not library-private, so [LayrzTimeInput] can reach it through a
/// [GlobalKey]** (DESIGN-98) — see [LayrzDateRangeSurfaceState]'s identical
/// class doc for the full rationale. Unlike the other seven surfaces, [save]
/// here is always reachable once the surface is mounted: a time field always
/// holds *some* value (there is no "nothing chosen yet" state for a live
/// field cluster the way a tap-to-select grid has), so [canSave] is always
/// `true`.
class LayrzTimeSurfaceState extends State<LayrzTimeSurface> {
  late LayrzTimeOfDay _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.value;
    // Syncs the caller's external draft-state mirror immediately -- see
    // LayrzDateRangeSurfaceState's identical initState comment for why.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDraftChanged?.call());
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

  /// Always `true`: a time-fields cluster always holds some value once
  /// mounted (see this class's own doc). Read by [LayrzTimeInput] through a
  /// [GlobalKey] for API symmetry with the other seven surfaces.
  bool get canSave => true;

  /// Commits the draft via [LayrzTimeSurface.onTimeChanged]. Invoked by
  /// [LayrzTimeInput] through a [GlobalKey] when the Save action it builds
  /// is pressed.
  void save() => widget.onTimeChanged(_draft);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayrzPickersTimeFieldsPanel(
            value: _draft,
            showSeconds: widget.showSeconds,
            use24HourFormat: widget.use24HourFormat,
            onChanged: (time) {
              setState(() => _draft = time);
              widget.onDraftChanged?.call();
            },
          ),
          if (widget.showInlineFooter && widget.onCancel != null) ...[
            SizedBox(height: tokens.spacing.sp3),
            LayrzPickerInlineFooter(
              onCancel: widget.onCancel!,
              onSave: save,
            ),
          ],
        ],
      ),
    );
  }
}
