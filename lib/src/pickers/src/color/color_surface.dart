import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/sheets/src/modal_route.dart';
import 'package:layrz_ui/src/tabs/tabs.dart';

import '../shared/glyph_grid.dart';
import '../shared/picker_dialog_header.dart';
import 'color_wheel.dart';

/// The desktop/mobile-shared surface content for [LayrzColorInput]: a
/// two-tab (Palette / Wheel) color picker, a HEX readout with a visible
/// paste button beneath the tabs, hosted by [LayrzColorInput] via
/// [LayrzResponsiveModal.show] (a dialog on wide viewports, a
/// [LayrzBottomSheet] below `isCompact`).
///
/// **Staged-with-Save, mirroring [LayrzDateSurface]'s exact contract.**
/// Every tap (a palette swatch, a wheel drag, a successful clipboard paste)
/// only updates this surface's own [_draft] — nothing reaches
/// [LayrzColorInput.onChanged] until [save] is invoked by the hosting
/// surface's Save action. [onDraftChanged] mirrors
/// [LayrzDateSurface.onDraftChanged] exactly: called on every draft
/// mutation so the caller's `ValueNotifier<({bool canSave, bool
/// hasSelection})>` stays in sync.
///
/// **Renders no tab strip at all when the palette is empty (OQ-2).** A
/// caller-supplied empty [palette] means the Palette tab has nothing valid
/// to render — this surface never shows a dead empty grid; it renders the
/// Wheel directly instead of wrapping it in a single-entry [LayrzTabView]
/// (a single, always-available Wheel "tab" would otherwise read as if a
/// developer forgot to supply a palette rather than a deliberate design
/// choice) — see [build].
class LayrzColorSurface extends StatefulWidget {
  /// The currently-selected color the surface seeds its draft from.
  final Color value;

  /// The caller-supplied set of swatches rendered by the Palette tab. An
  /// empty set hides the Palette tab entirely and opens on Wheel — see this
  /// class's own doc.
  final Set<Color> palette;

  /// The title shown in this surface's own [LayrzPickerDialogHeader], normally
  /// [LayrzColorInput.labelText]. `null` renders an empty title slot rather
  /// than no header at all — see that widget's own doc.
  final String? labelText;

  /// Called with the drafted color when the user presses Save. Never
  /// called while [_draft] is `null` — mirrors [LayrzDateSurface.onDateSelected].
  final ValueChanged<Color> onColorSelected;

  /// Called when the user presses Cancel or otherwise dismisses the
  /// surface involuntarily. `null` on the mobile [LayrzBottomSheet] path,
  /// matching [LayrzDateSurface.onCancel]'s own contract.
  final VoidCallback? onCancel;

  /// Called on every draft mutation, so [LayrzColorInput] can refresh the
  /// `actions` it builds outside this surface. Mirrors
  /// [LayrzDateSurface.onDraftChanged] exactly.
  final VoidCallback? onDraftChanged;

  /// Creates a new [LayrzColorSurface].
  const LayrzColorSurface({
    super.key,
    required this.value,
    required this.palette,
    this.labelText,
    required this.onColorSelected,
    this.onCancel,
    this.onDraftChanged,
  });

  @override
  State<LayrzColorSurface> createState() => LayrzColorSurfaceState();
}

/// State for [LayrzColorSurface].
///
/// **Public, not library-private, so [LayrzColorInput] can reach it through
/// a [GlobalKey]** — mirrors [LayrzDateSurfaceState]'s identical class doc
/// and rationale exactly. [_draft] holds the tapped-but-unsaved color;
/// [canSave] and [save] are the surface [LayrzColorInput] reads and drives
/// from its `actions` row.
class LayrzColorSurfaceState extends State<LayrzColorSurface> {
  /// The tapped-but-unsaved color. Seeded from [LayrzColorSurface.value] and
  /// never `null` after that — unlike [LayrzDateSurfaceState._draft], a
  /// color field always has *some* current value (there is no "nothing
  /// selected" state for a color the way there is for a date), so
  /// [canSave] is not gated on nullability but on whether the draft
  /// actually differs from the seeded value (see [canSave]'s own doc).
  late Color _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.value;
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDraftChanged?.call());
  }

  @override
  void didUpdateWidget(LayrzColorSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Involuntary-close discipline, mirroring LayrzDateSurfaceState's
    // identical didUpdateWidget: re-seed from the caller's value whenever it
    // changes externally, not only in initState.
    if (oldWidget.value != widget.value) {
      _draft = widget.value;
    }
  }

  /// Whether a Save is currently reachable. A color field always carries
  /// *some* value, so this is gated on the draft actually differing from
  /// the value the surface was opened with — pressing Save with no change
  /// made would otherwise re-report the same color as if it were a genuine
  /// edit, which every other picker surface in this module treats as "no
  /// selection yet" (see [LayrzDateSurfaceState.canSave]'s `_draft != null`
  /// for the equivalent gate on a nullable value type).
  bool get canSave => _draft != widget.value;

  /// Commits [_draft] via [LayrzColorSurface.onColorSelected]. Invoked by
  /// [LayrzColorInput] through a [GlobalKey] when the Save action it builds
  /// is pressed. A no-op when [canSave] is `false`, mirroring
  /// [LayrzDateSurfaceState.save]'s own guard.
  void save() {
    if (!canSave) return;
    widget.onColorSelected(_draft);
  }

  void _handleDraftChanged(Color color) {
    setState(() => _draft = color);
    widget.onDraftChanged?.call();
  }

  /// Reads the system clipboard, attempts to parse a `#RRGGBB`/`RRGGBB` hex
  /// color out of its plain-text content via
  /// [LayrzColorExtensions.fromHex], and — only on a successful parse —
  /// applies it as the new draft.
  ///
  /// **Never reads the clipboard except in direct response to this button
  /// press** (Decision D-paste, liliana's usability finding) — there is no
  /// ambient/on-open clipboard read anywhere in this surface. Unparseable
  /// or empty clipboard content is a silent no-op — never a thrown
  /// exception, never a blocking dialog; the draft and the readout simply
  /// stay exactly as they were before the button was pressed.
  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;

    final candidate = text.startsWith('#') ? text.substring(1) : text;
    final isValidHex = RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(candidate);
    if (!isValidHex) return;
    if (!mounted) return;

    _handleDraftChanged(LayrzColorExtensions.fromHex(candidate));
  }

  Widget _buildPaletteTab(BuildContext context) {
    final tokens = context.tokens;
    final palette = widget.palette.toList(growable: false);

    return LayrzGlyphGrid<Color>(
      items: palette,
      columns: 6,
      cellExtent: 36.0,
      itemBuilder: (context, color, index, isFocused) {
        final isSelected = color == _draft;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: tokens.radius.br1,
            border: Border.all(
              color: isSelected ? tokens.colors.fg1 : tokens.colors.divider,
              width: isSelected ? 3.0 : 1.0,
            ),
          ),
          child: const SizedBox.expand(),
        );
      },
      semanticLabelBuilder: (color, index) => color.toHex(),
      onItemActivated: _handleDraftChanged,
    );
  }

  Widget _buildHexReadout(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: _draft,
                borderRadius: tokens.radius.br1,
                border: Border.all(color: tokens.colors.divider),
              ),
              child: SizedBox(width: tokens.spacing.sp5, height: tokens.spacing.sp5),
            ),
            SizedBox(width: tokens.spacing.sp2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.colorPickerHexLabel, style: tokens.typography.label.copyWith(color: tokens.colors.fg2)),
                  Text(_draft.toHex(), style: tokens.typography.body),
                ],
              ),
            ),
            SizedBox(width: tokens.spacing.sp2),
            LayrzButton(
              labelText: l10n.colorPickerPasteButton,
              icon: MdiIcons.contentPaste,
              style: LayrzButtonStyle.outlined,
              onTap: () => unawaited(_handlePaste()),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the wheel tab's content: a centered [LayrzColorWheel].
  Widget _buildWheelTab(BuildContext context) {
    return Center(
      child: LayrzColorWheel(value: _draft, onChanged: _handleDraftChanged),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    // A single-tab (Wheel-only) surface renders the wheel directly with no
    // strip at all -- an always-available Wheel "tab" with nothing to
    // switch between would read as a developer forgetting to supply a
    // palette rather than a deliberate choice (OQ-2). LayrzTabView asserts
    // `tabs.isNotEmpty`, not `>= 2`, so this branch is still required rather
    // than merely an optimization.
    final Widget tabbedOrWheel = widget.palette.isEmpty
        ? _buildWheelTab(context)
        : LayrzTabView(
            isScrollable: false,
            tabs: [
              LayrzTab(
                labelText: l10n.colorPickerPaletteTab,
                child: SizedBox(height: 220.0, child: _buildPaletteTab(context)),
              ),
              LayrzTab(
                labelText: l10n.colorPickerWheelTab,
                child: _buildWheelTab(context),
              ),
            ],
          );

    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayrzPickerDialogHeader(
            labelText: widget.labelText,
            onClose: () => LayrzModalRoute.popIfCurrent(context),
          ),
          tabbedOrWheel,
          SizedBox(height: tokens.spacing.sp3),
          _buildHexReadout(context),
        ],
      ),
    );
  }
}
