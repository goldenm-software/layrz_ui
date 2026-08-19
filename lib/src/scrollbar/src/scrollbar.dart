import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

/// A Material-free scrollbar widget built on [RawScrollbar].
///
/// [LayrzScrollbar] wraps a scrollable [child] with a styled scrollbar that integrates
/// with the layrz_ui design system. The scrollbar thumb is always visible and fully rounded,
/// while the track appears only on hover or while dragging.
///
/// ## Visual Behavior
/// - Thumb: always visible, rounded to [kLayrzScrollbarRadius], colored with [LayrzTokens.colors.fg4]
/// - Track: hidden at rest, visible on hover and while dragging, colored with [LayrzTokens.colors.surface3]
/// - Thickness: [kLayrzScrollbarThickness] logical pixels
/// - Hover effect: thumb darkens to [LayrzTokens.colors.fg3] and track becomes visible
///
/// ## Usage
///
/// Wrap a [Scrollable] (like [SingleChildScrollView], [ListView], or [CustomScrollView])
/// with [LayrzScrollbar]:
///
/// ```dart
/// LayrzScrollbar(
///   child: SingleChildScrollView(
///     child: MyContent(),
///   ),
/// )
/// ```
///
/// Typically used via [LayrzScrollBehavior], which automatically decorates all vertical
/// scrollables on pointer platforms (desktop/web) without requiring opt-in at each scrollable.
class LayrzScrollbar extends StatefulWidget {
  /// Creates a [LayrzScrollbar].
  ///
  /// The [child] parameter is required.
  const LayrzScrollbar({
    /// The scrollable widget to decorate with a scrollbar.
    ///
    /// Typically a [SingleChildScrollView], [ListView], or [CustomScrollView].
    required this.child,

    /// The scroll controller attached to the [child].
    ///
    /// If null, the scrollbar falls back to [PrimaryScrollController].
    /// Must be the same controller attached to the child's [Scrollable] widget.
    this.controller,

    super.key,
  });

  /// The scrollable widget to decorate with a scrollbar.
  final Widget child;

  /// The scroll controller attached to the child.
  final ScrollController? controller;

  @override
  State<LayrzScrollbar> createState() => _LayrzScrollbarState();
}

class _LayrzScrollbarState extends State<LayrzScrollbar> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final thumbColor = _isHovering ? tokens.colors.fg3 : tokens.colors.fg4;
    final trackColor = tokens.colors.surface3;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovering = true);
      },
      onExit: (_) {
        setState(() => _isHovering = false);
      },
      child: RawScrollbar(
        controller: widget.controller,
        thumbVisibility: true,
        trackVisibility: _isHovering,
        thickness: kLayrzScrollbarThickness,
        radius: kLayrzScrollbarRadius,
        thumbColor: thumbColor,
        trackColor: trackColor,
        crossAxisMargin: kLayrzScrollbarCrossAxisMargin,
        mainAxisMargin: kLayrzScrollbarMainAxisMargin,
        child: widget.child,
      ),
    );
  }
}
