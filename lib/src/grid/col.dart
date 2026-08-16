import 'package:flutter/widgets.dart';

import 'package:layrz_ui/constants.dart';

/// A responsive column widget that adjusts its span (1–12) based on the viewport width.
///
/// [LayrzCol] is a stateless widget that wraps its child without applying any layout
/// transformations directly. All sizing and positioning is handled by the parent [LayrzRow].
///
/// The column's responsive span is determined by [spanAt], which uses a cascading
/// fallback mechanism: if a span is not explicitly set for the current breakpoint,
/// it uses the span from the next-smaller breakpoint. This ensures sensible defaults
/// across all screen sizes.
class LayrzCol extends StatelessWidget {
  /// The column span for extra-small screens (< 600px).
  ///
  /// Defaults to 12 (full width).
  /// Must be a positive integer between 1 and 12 (inclusive) if set.
  final int xs;

  /// The column span for small screens (600px–959px).
  ///
  /// If not specified, defaults to the value of [xs].
  /// Must be a positive integer between 1 and 12 (inclusive) if set.
  final int? sm;

  /// The column span for medium screens (960px–1263px).
  ///
  /// If not specified, defaults to [sm] if set, otherwise [xs].
  /// Must be a positive integer between 1 and 12 (inclusive) if set.
  final int? md;

  /// The column span for large screens (1264px–1903px).
  ///
  /// If not specified, defaults to [md] if set, otherwise [sm] if set, otherwise [xs].
  /// Must be a positive integer between 1 and 12 (inclusive) if set.
  final int? lg;

  /// The column span for extra-large screens (≥ 1904px).
  ///
  /// If not specified, defaults to [lg] if set, otherwise [md] if set, otherwise [sm] if set, otherwise [xs].
  /// Must be a positive integer between 1 and 12 (inclusive) if set.
  final int? xl;

  /// The child widget to display in this column.
  final Widget child;

  /// Creates a new [LayrzCol] with the given responsive spans and child.
  ///
  /// The [xs] parameter defaults to 12 (full width) and must be between 1 and 12.
  /// All other span parameters are optional and default to cascading values if not specified.
  ///
  /// Every span parameter that is explicitly set must be a positive integer between 1 and 12 (inclusive).
  /// Violating these constraints triggers an assertion error with a clear message naming the offending field.
  const LayrzCol({
    super.key,
    this.xs = 12,
    this.sm,
    this.md,
    this.lg,
    this.xl,
    required this.child,
  }) : assert(xs > 0 && xs <= 12, 'xs must be between 1 and 12, got $xs'),
       assert(sm == null || (sm > 0 && sm <= 12), 'sm must be between 1 and 12, got $sm'),
       assert(md == null || (md > 0 && md <= 12), 'md must be between 1 and 12, got $md'),
       assert(lg == null || (lg > 0 && lg <= 12), 'lg must be between 1 and 12, got $lg'),
       assert(xl == null || (xl > 0 && xl <= 12), 'xl must be between 1 and 12, got $xl');

  /// Resolves the column span (1–12) for the given breakpoint width.
  ///
  /// Uses a cascading fallback mechanism:
  /// - **xs band** (< 600px): uses [xs]
  /// - **sm band** (600–959px): uses [sm] if set, else [xs]
  /// - **md band** (960–1263px): uses [md] if set, else [sm] if set, else [xs]
  /// - **lg band** (1264–1903px): uses [lg] if set, else [md] if set, else [sm] if set, else [xs]
  /// - **xl band** (≥ 1904px): uses [xl] if set, else [lg] if set, else [md] if set, else [sm] if set, else [xs]
  ///
  /// This design ensures that any explicitly set value "sticks" for wider breakpoints
  /// unless overridden by a more specific one. For example, setting only [md] = 6
  /// will make the column span 6 for md, lg, and xl breakpoints.
  int spanAt(double width) {
    if (width < kExtraSmallGrid) {
      return xs;
    } else if (width < kSmallGrid) {
      return sm ?? xs;
    } else if (width < kMediumGrid) {
      return md ?? sm ?? xs;
    } else if (width < kLargeGrid) {
      return lg ?? md ?? sm ?? xs;
    } else {
      return xl ?? lg ?? md ?? sm ?? xs;
    }
  }

  @override
  Widget build(BuildContext context) => child;
}
