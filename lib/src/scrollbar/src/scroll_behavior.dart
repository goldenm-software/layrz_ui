import 'package:flutter/widgets.dart';

import 'scrollbar.dart';

/// A [ScrollBehavior] that installs [LayrzScrollbar] globally.
///
/// [LayrzScrollBehavior] overrides [buildScrollbar] to decorate every
/// [Scrollable] with a [LayrzScrollbar], providing consistent scrollbar
/// styling across the entire app without requiring opt-in at every scrollable.
///
/// ## Platform Gating
///
/// The scrollbar appears on pointer platforms (desktop and web) only.
/// Touch platforms fall back to the default behavior (no persistent scrollbar).
/// Horizontal scrollables are never decorated, only vertical ones.
///
/// ## Usage
///
/// Pass [LayrzScrollBehavior] to [ScrollConfiguration] or install it globally
/// in [LayrzApp]:
///
/// ```dart
/// LayrzApp(
///   home: MyHomePage(),
///   // No need to supply scrollBehavior — LayrzApp installs LayrzScrollBehavior by default
/// )
/// ```
///
/// Or wrap a specific subtree:
///
/// ```dart
/// ScrollConfiguration(
///   behavior: const LayrzScrollBehavior(),
///   child: MyScrollableContent(),
/// )
/// ```
class LayrzScrollBehavior extends ScrollBehavior {
  /// Creates a [LayrzScrollBehavior].
  const LayrzScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Determine if the scrollable is vertical based on AxisDirection
    final isVertical = details.direction == AxisDirection.down || details.direction == AxisDirection.up;

    // Gate on platform: only show persistent scrollbar on pointer platforms (desktop/web)
    final platform = getPlatform(context);
    final isPointerPlatform =
        platform == TargetPlatform.windows || platform == TargetPlatform.linux || platform == TargetPlatform.macOS;

    // Touch platforms (iOS, Android, fuchsia) do not show persistent scrollbars
    if (!isPointerPlatform) {
      return child;
    }

    // Horizontal scrollables are not decorated; return child unchanged
    if (!isVertical) {
      return child;
    }

    // Wrap vertical scrollables on pointer platforms with LayrzScrollbar
    return LayrzScrollbar(
      controller: details.controller,
      child: child,
    );
  }
}
