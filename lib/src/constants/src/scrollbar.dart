import 'package:flutter/widgets.dart';

/// Thickness of the [LayrzScrollbar] thumb in logical pixels.
///
/// This is the width of the scrollbar when rendered.
const double kLayrzScrollbarThickness = 8.0;

/// Radius of the [LayrzScrollbar] thumb's corners.
///
/// Provides a fully rounded appearance for the scrollbar thumb.
const Radius kLayrzScrollbarRadius = Radius.circular(4.0);

/// Cross-axis margin from the edge of the container to the scrollbar thumb.
///
/// When the scrollbar is on the right edge, this is the margin from the right edge.
/// When on the left edge, this is the margin from the left edge.
const double kLayrzScrollbarCrossAxisMargin = 0.0;

/// Main-axis margin from the top/bottom edges to the scrollbar thumb.
///
/// Provides vertical insets for the scrollbar thumb at the top and bottom of the scrollable.
const double kLayrzScrollbarMainAxisMargin = 0.0;
