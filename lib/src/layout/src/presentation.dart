import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// The two presentation modes for [LayrzLayout].
///
/// [LayrzLayoutPresentation] determines whether the layout displays as a wide-screen
/// design with a fixed navigation rail (expanded) or as a mobile design with a
/// compact top bar and off-canvas drawer (drawer).
enum LayrzLayoutPresentation {
  /// Expanded presentation with a fixed navigation rail.
  ///
  /// The layout displays a 178-pixel navigation rail on the left side alongside
  /// the body content. This presentation is used for md, lg, and xl viewport widths.
  /// In the xl band, the body content is additionally capped at 1440 pixels wide
  /// and centered horizontally.
  expanded,

  /// Drawer presentation with a top bar and off-canvas navigation.
  ///
  /// The layout displays a compact top bar with a drawer trigger and the body content.
  /// The navigation is hidden in an off-canvas drawer that slides in from the left.
  /// This presentation is used for xs and sm viewport widths.
  drawer,
}

/// Determines which presentation should be used for a given constraint width.
///
/// This resolver uses [LayrzBreakpointTokens.bandAt] to map container widths
/// to presentation modes. It is called from [LayoutBuilder] constraints, not
/// from viewport width, to support the layout component operating within
/// constrained containers (not just full-screen layouts).
///
/// The mapping is:
/// - xs, sm bands → [LayrzLayoutPresentation.drawer]
/// - md, lg, xl bands → [LayrzLayoutPresentation.expanded]
///
/// The [tokens] are read from [LayrzTheme.of] to allow apps to customize
/// breakpoint thresholds if needed.
LayrzLayoutPresentation resolveLayrzLayoutPresentation({
  required double width,
  required LayrzTokens tokens,
}) {
  final band = tokens.breakpoints.bandAt(width);

  switch (band) {
    case LayrzBreakpoint.xs || LayrzBreakpoint.sm:
      return LayrzLayoutPresentation.drawer;
    case LayrzBreakpoint.md || LayrzBreakpoint.lg || LayrzBreakpoint.xl:
      return LayrzLayoutPresentation.expanded;
  }
}
