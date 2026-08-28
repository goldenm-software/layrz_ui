import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import 'badge_style_spec.dart';
import 'badge_type.dart';

/// Maximum count [LayrzBadgeVisual] renders as a literal number before
/// collapsing to the `99+` overflow form.
///
/// Ratified by Kenny (§5.6 of the batch's implementation plan): counts above
/// 99 render as exactly `99+`, never a raw large number and never a
/// configurable cap. Two digits keeps the badge narrow enough to sit over an
/// icon without distorting it.
const int kLayrzBadgeMaxCount = 99;

/// The bare, positioned visual for a notification badge.
///
/// This is a small rounded-square (in practice, pill-shaped for numbers and
/// circular for a bare dot) surface painted with a semantic accent color. It
/// renders one of three content forms:
/// - a [count] (formatted per [formatCount]),
/// - an [icon] glyph, or
/// - nothing at all — a bare presence dot — when both are null.
///
/// This widget is the standalone building block: it does not overlay
/// anything and does not size itself relative to a host. Use it directly
/// inside a `Row`/`Stack` the caller already controls (for example, inline
/// next to a label), or use [LayrzBadge] to overlay it on a child widget.
/// Ship-both is deliberate: `LayrzLayoutRailItem` (`rail_item.dart:113-125`)
/// needs the badge inline in a `Row`, not overlapping anything, so a
/// wrapper-only API could not serve that shape.
///
/// **Accessibility**: this widget intentionally does *not* attach its own
/// [Semantics] node. A badge is only meaningful in the context of what it
/// decorates ("3 unread", "Notifications, 3 unread") — a detached "3" read
/// out loud next to an unlabelled icon is meaningless. [LayrzBadge] composes
/// the merged announcement; a caller placing [LayrzBadgeVisual] directly in
/// a `Row` is responsible for merging its own semantics the same way.
@immutable
class LayrzBadgeVisual extends StatelessWidget {
  /// Creates a bare badge visual.
  ///
  /// At most one of [count] or [icon] should be provided; when both are
  /// null the badge renders as a bare presence dot. If both are provided,
  /// [count] takes precedence and [icon] is ignored.
  const LayrzBadgeVisual({
    this.count,
    this.icon,
    this.type = LayrzBadgeType.danger,
    this.color,
    super.key,
  });

  /// The number to display inside the badge.
  ///
  /// Formatted via [formatCount]: values from 0–99 render as-is, values above
  /// 99 render as `99+`. When null and [icon] is also null, the badge renders
  /// as a bare presence dot with no content.
  final int? count;

  /// The icon glyph to display inside the badge.
  ///
  /// Ignored when [count] is non-null. When both [count] and [icon] are
  /// null, the badge renders as a bare presence dot.
  final IconData? icon;

  /// The semantic color type for the badge background.
  ///
  /// Defaults to [LayrzBadgeType.danger], the conventional color for
  /// notification counts. Ignored (in favor of [color]) only when [color] is
  /// explicitly non-null.
  final LayrzBadgeType type;

  /// An explicit background color overriding [type]'s resolved token.
  ///
  /// When null, the color is resolved from [type] via
  /// [LayrzBadgeStyleSpec.resolve]. When non-null, this color is used
  /// regardless of [type].
  final Color? color;

  /// Formats [count] into the badge's display string.
  ///
  /// Values from 0 to [kLayrzBadgeMaxCount] inclusive render as their literal
  /// decimal form (e.g. `3`, `42`, `99`). Values above [kLayrzBadgeMaxCount]
  /// render as `99+`. Negative values are clamped to `0` — a badge has no
  /// concept of a negative count.
  static String formatCount(int count) {
    if (count < 0) return '0';
    if (count > kLayrzBadgeMaxCount) return '$kLayrzBadgeMaxCount+';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final spec = LayrzBadgeStyleSpec.resolve(type: type, color: color, tokens: tokens);

    final isDot = count == null && icon == null;
    final diameter = tokens.spacing.sp3;

    Widget? content;
    if (count != null) {
      content = Text(
        formatCount(count!),
        style: tokens.typography.label.copyWith(
          color: spec.contentColor,
          fontSize: 11,
          height: 1.0,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.clip,
      );
    } else if (icon != null) {
      content = Icon(icon, size: diameter * 0.7, color: spec.contentColor);
    }

    return Container(
      constraints: BoxConstraints(minWidth: diameter, minHeight: diameter),
      padding: isDot ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: tokens.spacing.sp1 * 0.6),
      decoration: BoxDecoration(
        color: spec.backgroundColor,
        borderRadius: BorderRadius.circular(tokens.radius.full),
      ),
      alignment: Alignment.center,
      child: content,
    );
  }
}
