import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/tokens/tokens.dart';

/// The two surfaces [LayrzResponsiveModal] can present its content on.
///
/// [LayrzLayoutPresentation] (from `lib/src/layout/`) is deliberately not reused
/// here: it means navigation chrome — a fixed rail versus an off-canvas drawer —
/// and neither of its members, `expanded` or `drawer`, can be repurposed to mean
/// "dialog" or "sheet" without redefining what the enum stands for elsewhere in
/// the codebase. A modal surface is a different concept from navigation chrome,
/// so it gets its own enum rather than overloading that one.
enum LayrzModalPresentation {
  /// Present the content as a [LayrzDialog] — a centered, size-bounded panel
  /// appropriate for a page-relative interruption on a wide viewport.
  dialog,

  /// Present the content as a [LayrzBottomSheet] — a surface that drops in
  /// from the bottom edge, sized to the viewport height, appropriate for a
  /// narrow viewport where a centered panel would crowd the screen.
  sheet,
}

/// Determines which modal surface [LayrzResponsiveModal.show] should use for a
/// given viewport width.
///
/// This resolver borrows its shape from `resolveLayrzLayoutPresentation`
/// (`lib/src/layout/src/presentation.dart`) — a free function, testable without
/// pumping a widget — but deliberately feeds it a different width source.
///
/// **[width] must be viewport width, not container/constraint width.**
/// `resolveLayrzLayoutPresentation` is fed [LayoutBuilder] constraint width on
/// purpose, because [LayrzLayout] can operate inside a constrained container
/// (an embedded shell, for instance) and its presentation should respond to the
/// space it is actually given. A modal is different: it is presented over the
/// whole screen regardless of where [LayrzResponsiveModal.show] was called
/// from, so the honest input is the viewport itself — matching
/// [BuildContext.isCompact], whose own docstring states it is "always
/// viewport-driven, not container-driven". Feeding this resolver a constrained
/// container's width would make the dialog-vs-sheet choice depend on an
/// accident of where the calling widget happens to sit in the tree, rather
/// than on the screen the user is actually looking at.
///
/// The mapping mirrors decision D52, which already uses this exact boundary
/// for the same dialog-vs-sheet choice in the M3 picker family:
/// - `width` < 960 (xs, sm bands) → [LayrzModalPresentation.sheet]
/// - `width` >= 960 (md, lg, xl bands) → [LayrzModalPresentation.dialog]
///
/// The [tokens] are read from [LayrzTheme.of] to allow apps to customize
/// breakpoint thresholds if needed, exactly as `resolveLayrzLayoutPresentation`
/// does.
LayrzModalPresentation resolveLayrzModalPresentation({
  required double width,
  required LayrzTokens tokens,
}) {
  final band = tokens.breakpoints.bandAt(width);

  switch (band) {
    case LayrzBreakpoint.xs || LayrzBreakpoint.sm:
      return LayrzModalPresentation.sheet;
    case LayrzBreakpoint.md || LayrzBreakpoint.lg || LayrzBreakpoint.xl:
      return LayrzModalPresentation.dialog;
  }
}
