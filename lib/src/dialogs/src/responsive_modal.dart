import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/dialogs/src/dialog.dart';
import 'package:layrz_ui/src/dialogs/src/modal_presentation.dart';
import 'package:layrz_ui/src/sheets/src/bottom_sheet.dart';

/// Dialog-only configuration for [LayrzResponsiveModal.show].
///
/// Groups the parameters that are only meaningful when [LayrzResponsiveModal]
/// resolves to [LayrzModalPresentation.dialog] and forwards to
/// [LayrzDialog.show]. Kept as its own object (rather than flattening every
/// branch's parameters onto the wrapper) so a caller configuring the dialog
/// branch is never shown parameters — such as [LayrzBottomSheetConfig.snapSizes]
/// or [LayrzBottomSheetConfig.showDragHandle] — that mean nothing for a dialog.
@immutable
class LayrzDialogConfig {
  /// The maximum width the dialog's panel may occupy, in logical pixels.
  ///
  /// Forwarded verbatim to [LayrzDialog.show]'s `maxWidth`. Defaults to `480`.
  final double maxWidth;

  /// The maximum height the dialog's panel may occupy, in logical pixels.
  ///
  /// Forwarded verbatim to [LayrzDialog.show]'s `maxHeight`. Defaults to `640`.
  final double maxHeight;

  /// Creates dialog-branch configuration for [LayrzResponsiveModal.show].
  const LayrzDialogConfig({
    this.maxWidth = 480,
    this.maxHeight = 640,
  });
}

/// Sheet-only configuration for [LayrzResponsiveModal.show].
///
/// Groups the parameters that are only meaningful when [LayrzResponsiveModal]
/// resolves to [LayrzModalPresentation.sheet] and forwards to
/// [LayrzBottomSheet.show]. Kept as its own object (rather than flattening
/// every branch's parameters onto the wrapper) so a caller configuring the
/// sheet branch is never shown parameters — such as [LayrzDialogConfig.maxWidth]
/// or [LayrzDialogConfig.maxHeight] — that mean nothing for a sheet.
@immutable
class LayrzBottomSheetConfig {
  /// Optional list of snap point fractions (0.0 to 1.0) in ascending order.
  ///
  /// Forwarded verbatim to [LayrzBottomSheet.show]'s `snapSizes`. If null,
  /// the sheet defaults to `[0.5, 0.95]`.
  final List<double>? snapSizes;

  /// The fraction of the screen height the sheet initially occupies.
  ///
  /// Forwarded verbatim to [LayrzBottomSheet.show]'s `initialSize`. Defaults
  /// to `0.5` (half the screen).
  final double initialSize;

  /// The minimum fraction of screen height the sheet can be dragged down to.
  ///
  /// Forwarded verbatim to [LayrzBottomSheet.show]'s `minSize`. Defaults to
  /// `0.25` (a quarter of the screen).
  final double minSize;

  /// The maximum fraction of screen height the sheet can occupy.
  ///
  /// Forwarded verbatim to [LayrzBottomSheet.show]'s `maxSize`. Defaults to
  /// `0.95` (leaving minimal space for status bar / app bar).
  final double maxSize;

  /// Whether to render a visual drag handle above the content.
  ///
  /// Forwarded verbatim to [LayrzBottomSheet.show]'s `showDragHandle`.
  /// Defaults to `true`.
  final bool showDragHandle;

  /// Whether the sheet wraps its content in its own scroll view.
  ///
  /// Forwarded verbatim to [LayrzBottomSheet.show]'s `scrollable`. Defaults
  /// to `true`. Set to `false` when the content builder returns its own
  /// scrollable (e.g. a `ListView` or `GridView`).
  final bool scrollable;

  /// Creates sheet-branch configuration for [LayrzResponsiveModal.show].
  const LayrzBottomSheetConfig({
    this.snapSizes,
    this.initialSize = 0.5,
    this.minSize = 0.25,
    this.maxSize = 0.95,
    this.showDragHandle = true,
    this.scrollable = true,
  });
}

/// A responsive chooser that presents its content as a [LayrzDialog] on wide
/// viewports and a [LayrzBottomSheet] on narrow ones.
///
/// [LayrzResponsiveModal] adds no behaviour of its own — it resolves a
/// presentation once (see [show]) and delegates entirely to whichever
/// underlying surface was chosen. Both branches return `Future<T?>`, where
/// `null` means the modal was dismissed without a value, so the wrapper's
/// contract is identical to either branch on its own.
///
/// **Name.** Deliberately `LayrzResponsiveModal`, not `LayrzAdaptiveModal`.
/// Flutter reserves "adaptive" for platform-switching (e.g. `Switch.adaptive`),
/// whereas this chooses its surface from viewport *breakpoint* — the same
/// vocabulary already used by [LayrzBreakpoint] and `LayrzRow`.
///
/// **Presentation is decided once, at [show] call time, and is never
/// re-evaluated.** This is an explicit non-goal, not an oversight: there is no
/// [LayoutBuilder], no [MediaQuery] listener, and nothing installed in the
/// widget tree that could rebuild across the breakpoint. A modal opened on a
/// wide window and then resized narrow **stays on the surface it opened
/// with** for the life of that route — neither [LayrzDialog] nor
/// [LayrzBottomSheet] supports being swapped for the other mid-flight, and
/// attempting to re-resolve mid-route is itself a behaviour this component
/// deliberately does not have. This matters more under the name "responsive"
/// than it did under "adaptive", because "responsive" invites the live-resize
/// assumption even harder. There is shipped precedent for the failure this
/// avoids: version 0.0.14 fixed `LayrzScaffoldShell` throwing
/// `setState() or markNeedsBuild() called during build` when the viewport
/// crossed the compact breakpoint while its detail sheet was open — a
/// re-evaluate-on-resize design is exactly the shape of bug that produced.
class LayrzResponsiveModal {
  LayrzResponsiveModal._();

  /// Shows the content as a dialog or a bottom sheet, chosen once at call time.
  ///
  /// Returns `Future<T?>` that completes with the value passed to
  /// [Navigator.pop] in whichever surface was presented, or `null` if it was
  /// dismissed without a value (barrier tap, Escape, or a close action that
  /// pops with no value). This matches both [LayrzDialog.show] and
  /// [LayrzBottomSheet.show] exactly, so callers do not need to branch on
  /// which surface was actually used.
  ///
  /// **Navigator**: both branches always push on the root navigator — see
  /// [LayrzDialog]'s and [LayrzBottomSheet]'s own class docs. This is
  /// intrinsic to each branch, not a choice this wrapper makes or forwards.
  ///
  /// **Parameters:**
  /// - [context]: the build context from which to show the modal. Must
  ///   contain a Navigator.
  /// - [builder]: a builder function that constructs the modal's content. The
  ///   builder receives the surface's own context as an argument, matching
  ///   [LayrzBottomSheet.show]'s `builder` shape. For the dialog branch, the
  ///   built widget is passed as [LayrzDialog.show]'s `child` escape hatch —
  ///   [LayrzResponsiveModal] does not compose the dialog's `title`/`content`/
  ///   `actions` slots, since a single [builder] must describe one piece of
  ///   content usable on both surfaces. **This is a deliberate API limitation,
  ///   not an oversight**: a caller that wants the dialog branch's structured
  ///   `title`/`content`/`actions` slots — rather than one freeform widget —
  ///   cannot get them through this wrapper, because the same [builder] result
  ///   is also handed to [LayrzBottomSheet.show], which has no equivalent
  ///   slotted shape to receive them. Call [LayrzDialog.show] directly when
  ///   those slots matter more than responsive presentation.
  /// - [isCompact]: overrides which surface is chosen, regardless of viewport
  ///   width. Defaults to `context.isCompact` (`true` below the `sm`/`md`
  ///   breakpoint boundary at 960 logical pixels — see
  ///   [resolveLayrzModalPresentation]). Pass `true` to force
  ///   [LayrzModalPresentation.sheet] or `false` to force
  ///   [LayrzModalPresentation.dialog] regardless of the actual viewport —
  ///   useful, for example, when a picker with a long option list wants the
  ///   sheet even at a wider breakpoint than a two-button confirm would.
  /// - [canDismiss]: whether the modal can be dismissed by any route other than an
  ///   explicit action (barrier tap, Escape, the X icon, and the system/Android back
  ///   gesture). Only meaningful for the dialog branch — forwarded verbatim to
  ///   [LayrzDialog.show]'s `canDismiss`, where a null value falls back to that
  ///   method's own default (conservative when actions are present). [LayrzBottomSheet.show]
  ///   has no equivalent parameter: a modal sheet's barrier is always dismissible, so this
  ///   value is ignored entirely when the sheet branch is chosen. See [LayrzDialog.show]'s
  ///   own `canDismiss` doc for the full four-route contract.
  /// - [semanticLabel]: semantic label describing the modal's purpose for
  ///   screen readers, forwarded to whichever branch is chosen. Must be
  ///   equivalent regardless of which surface is presented, since an
  ///   assistive-technology user must hear the same description whether the
  ///   breakpoint put them on a dialog or a sheet.
  /// - [dialog]: dialog-branch-only configuration (max width/height). Ignored
  ///   when the sheet branch is chosen. Defaults to `const LayrzDialogConfig()`.
  /// - [sheet]: sheet-branch-only configuration (snap sizes, initial/min/max
  ///   size, drag handle, scrollable). Ignored when the dialog branch is
  ///   chosen. Defaults to `const LayrzBottomSheetConfig()`.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool? isCompact,
    bool? canDismiss,
    String? semanticLabel,
    LayrzDialogConfig dialog = const LayrzDialogConfig(),
    LayrzBottomSheetConfig sheet = const LayrzBottomSheetConfig(),
  }) {
    final effectiveIsCompact = isCompact ?? context.isCompact;

    if (effectiveIsCompact) {
      return LayrzBottomSheet.show<T>(
        context,
        builder: builder,
        semanticLabel: semanticLabel,
        snapSizes: sheet.snapSizes,
        initialSize: sheet.initialSize,
        minSize: sheet.minSize,
        maxSize: sheet.maxSize,
        showDragHandle: sheet.showDragHandle,
        scrollable: sheet.scrollable,
        isPersistent: false,
      );
    }

    return LayrzDialog.show<T>(
      context,
      child: Builder(builder: builder),
      canDismiss: canDismiss,
      semanticLabel: semanticLabel,
      maxWidth: dialog.maxWidth,
      maxHeight: dialog.maxHeight,
    );
  }
}
