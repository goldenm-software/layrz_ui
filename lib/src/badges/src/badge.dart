import 'package:flutter/widgets.dart';

import 'badge_alignment.dart';
import 'badge_type.dart';
import 'badge_visual.dart';

/// Overlays a [LayrzBadge] notification indicator on top of [child].
///
/// This is the wrapper form built on top of [LayrzBadgeVisual] (the bare
/// positioned visual). It positions the badge at a corner of [child] via a
/// [Stack], without changing [child]'s layout footprint — the badge paints
/// on top using [Positioned], so wrapping any widget with a badge never
/// reflows the surrounding layout.
///
/// Content follows [LayrzBadgeVisual]'s rules: a [count], an [icon], or —
/// when both are null — a bare presence dot. Set [isVisible] to `false` to
/// hide the badge entirely while keeping the widget tree stable (useful when
/// toggling badge visibility based on external state, e.g. an unread count
/// dropping to zero).
///
/// **Accessibility**: [label] is mandatory precisely because a bare "3" is
/// meaningless out loud. This widget merges [child]'s semantics with a
/// description built from [label] (and the formatted [count]/dot presence)
/// into a single announced node — "Notifications, 3 unread" rather than a
/// detached "3" read back adjacent to an unlabelled icon. Pass the
/// human-readable description of what the badge signifies, not the raw
/// count — the widget appends the count itself.
@immutable
class LayrzBadge extends StatelessWidget {
  /// Creates a badge overlay on top of [child].
  ///
  /// [label] is required and describes what the badge signifies (e.g.
  /// `'Notifications'`, `'Unread messages'`) so the merged announcement is
  /// meaningful. At most one of [count] or [icon] should be provided; when
  /// both are null the badge renders as a bare presence dot.
  const LayrzBadge({
    required this.child,
    required this.label,
    this.count,
    this.icon,
    this.type = LayrzBadgeType.danger,
    this.color,
    this.alignment = LayrzBadgeAlignment.topRight,
    this.isVisible = true,
    super.key,
  });

  /// The widget the badge is overlaid on.
  ///
  /// The badge is painted on top of [child] via a [Positioned] overlay and
  /// never affects [child]'s layout size.
  final Widget child;

  /// A human-readable description of what the badge signifies, used to build
  /// the merged accessibility announcement (e.g. `'Notifications'`).
  ///
  /// This must describe the semantic meaning, not repeat the raw count —
  /// the widget appends the formatted count or dot presence itself. Required
  /// so a screen reader never announces a detached, meaningless number.
  final String label;

  /// The number to display inside the badge.
  ///
  /// Formatted via [LayrzBadgeVisual.formatCount]. When null and [icon] is
  /// also null, the badge renders as a bare presence dot.
  final int? count;

  /// The icon glyph to display inside the badge.
  ///
  /// Ignored when [count] is non-null. When both [count] and [icon] are
  /// null, the badge renders as a bare presence dot.
  final IconData? icon;

  /// The semantic color type for the badge background.
  ///
  /// Defaults to [LayrzBadgeType.danger]. Ignored (in favor of [color]) only
  /// when [color] is explicitly non-null.
  final LayrzBadgeType type;

  /// An explicit background color overriding [type]'s resolved token.
  final Color? color;

  /// Which corner of [child] the badge is anchored to.
  ///
  /// Defaults to [LayrzBadgeAlignment.topRight], the conventional position
  /// for notification counts.
  final LayrzBadgeAlignment alignment;

  /// Whether the badge is shown at all.
  ///
  /// When `false`, only [child] is rendered (still merged into a plain
  /// semantics node with [label] omitted from the announcement), and no
  /// badge visual or corner overlay is painted. Defaults to `true`.
  final bool isVisible;

  /// Builds the human-readable announcement merged over [child]'s semantics.
  ///
  /// Produces e.g. `"Notifications, 3 unread"` for a count, `"Notifications"`
  /// alone when the badge is a bare dot (the presence of the dot itself is
  /// what needs announcing — the count phrasing does not apply), and no
  /// suffix at all when [isVisible] is `false`.
  String _announcement() {
    if (!isVisible) return label;
    if (count != null) {
      final formatted = LayrzBadgeVisual.formatCount(count!);
      return '$label, $formatted unread';
    }
    // Icon content or a bare dot both signal "there is something to see" —
    // the label alone already carries that meaning once merged.
    return '$label, new';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _announcement(),
      container: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ExcludeSemantics: the merged label above already fully describes
          // this subtree; without it, child's own semantics (and the badge
          // visual's auto-generated Text/Icon semantics) would duplicate into
          // the merged node -- e.g. "Notifications, 3 unread\n3".
          ExcludeSemantics(child: child),
          if (isVisible)
            Positioned.fill(
              child: Align(
                alignment: alignment.alignment,
                child: FractionalTranslation(
                  translation: _translationFor(alignment),
                  child: ExcludeSemantics(
                    child: LayrzBadgeVisual(count: count, icon: icon, type: type, color: color),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Nudges the badge outward past [child]'s edge so it reads as an overlay
  /// sitting on the corner rather than fully inside the bounding box.
  Offset _translationFor(LayrzBadgeAlignment alignment) {
    switch (alignment) {
      case LayrzBadgeAlignment.topRight:
        return const Offset(0.3, -0.3);
      case LayrzBadgeAlignment.topLeft:
        return const Offset(-0.3, -0.3);
      case LayrzBadgeAlignment.bottomRight:
        return const Offset(0.3, 0.3);
      case LayrzBadgeAlignment.bottomLeft:
        return const Offset(-0.3, 0.3);
    }
  }
}
