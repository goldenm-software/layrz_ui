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

/// Font size used for the badge's numeric content ("count" / `99+` form).
///
/// DESIGN-167: the design system's `label` typography token defaults to 12px,
/// which is itself the modest bump this change asked for over the previous
/// hardcoded 11px. This constant exists only as a documented fallback for the
/// rare case a caller supplies a [LayrzTextTheme] whose `label` carries no
/// explicit [TextStyle.fontSize] (fontSize is nullable on [TextStyle]) — the
/// badge's numeral must never end up unsized. In the normal path the badge
/// uses `tokens.typography.label`'s own resolved size unmodified, so a theme
/// that intentionally sets a different label size is honored instead of
/// being silently overridden here.
const double kLayrzBadgeCountFontSize = 12;

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
    // DESIGN-167: bumped from `sp3` (14) to `sp4` (20) -- the next step up on
    // the spacing scale (`lib/src/tokens/src/spacing.dart`). The maintainer's
    // note was explicit that the icon and count sizes are coupled through
    // this single knob, so both grow together from this one change rather
    // than being tuned independently.
    final diameter = tokens.spacing.sp4;

    Widget? content;
    if (count != null) {
      content = Text(
        formatCount(count!),
        style: tokens.typography.label.copyWith(
          color: spec.contentColor,
          fontSize: tokens.typography.label.fontSize ?? kLayrzBadgeCountFontSize,
          height: 1.0,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.clip,
        textAlign: TextAlign.center,
      );
    } else if (icon != null) {
      content = Icon(icon, size: diameter * 0.7, color: spec.contentColor);
    }

    // DESIGN-167: `content` is wrapped in a shrink-wrapped `Center` (below)
    // rather than reaching for `Container.alignment`. This is NOT the same
    // fix that was rejected before, and the distinction matters:
    //
    // `Container.build` inserts its `alignment`-driven `Align` as the
    // OUTERMOST widget in the composed chain -- outside `ConstrainedBox`,
    // `DecoratedBox` and `Padding` -- so that `Align` receives the *ambient*
    // incoming constraints completely unfiltered by `diameter`. Under
    // `LayrzBadge`'s overlay (`Positioned.fill` -> `Align` ->
    // `FractionalTranslation`), those ambient constraints are loosened to the
    // size of whatever this badge decorates, and a factor-less `Align` sizes
    // itself to fill loose-but-bounded constraints -- which is exactly how
    // the badge ballooned out to the decorated child's own box.
    //
    // The `Center` added below sits INSIDE that chain, as `Padding`'s child --
    // it only ever sees constraints already lower-bounded by
    // `ConstrainedBox(minWidth/minHeight: diameter)` and then deflated by
    // `Padding`. Passing `widthFactor: 1.0, heightFactor: 1.0` makes it
    // shrink-wrap to `content`'s own size instead of filling those
    // (unbounded-above) constraints -- verified: a factor-less `Center` here
    // reproduces the exact same ballooning as `Container.alignment` did,
    // which is why the factors are mandatory, not stylistic.
    //
    // The centering bug this fixes (DESIGN-167 follow-up): symmetric padding
    // alone only centers content when the padded content is exactly
    // `diameter` wide/tall. Whenever `ConstrainedBox`'s `minWidth`/`minHeight`
    // forces the box larger than `padding + content` (true for every count
    // form at this diameter, and doubly true for single digits, which also
    // fall short horizontally), `RenderPadding.performLayout` still offsets
    // its child by exactly `(padding.left, padding.top)` and dumps *all* of
    // the extra slack on the right/bottom (see
    // `flutter/rendering/shifted_box.dart`'s `RenderPadding.performLayout`).
    // That is a fixed top/left bias, not a centering effect -- measured at
    // this diameter/padding it was +2.0lp low vertically for every form, plus
    // +0.8lp right-biased horizontally for single-digit counts only. The
    // `Center` re-centers within whatever box `ConstrainedBox` ultimately
    // produces, so the bias cancels regardless of how much slack there is.
    return Container(
      constraints: BoxConstraints(minWidth: diameter, minHeight: diameter),
      padding: isDot
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(horizontal: tokens.spacing.sp1 * 0.6, vertical: tokens.spacing.sp1 / 2),
      decoration: BoxDecoration(
        color: spec.backgroundColor,
        borderRadius: BorderRadius.circular(tokens.radius.full),
      ),
      // The dot form passes a zero-size `SizedBox.shrink()` rather than a
      // literal `null` here. `Container.build` special-cases `child == null`
      // together with non-tight constraints by substituting
      // `LimitedBox(maxWidth: 0, maxHeight: 0) -> ConstrainedBox.expand()` --
      // a widget that (by design, for *that* call site's own use case
      // elsewhere in the framework) fills whatever bounded space it is
      // handed. This badge's `constraints` are exactly non-tight
      // (`minWidth`/`minHeight` only, `maxWidth`/`maxHeight` left at
      // infinity), so a bare dot rendered with a literal `null` child
      // ballooned to fill its ambient host -- the same class of "badge is
      // too big" defect as the alignment/centering issue above, just
      // triggered by the dot form specifically. A real (if empty) child
      // widget keeps `Container` on its ordinary sizing path, so the dot
      // clamps to `diameter` like every other content form.
      child: content == null ? const SizedBox.shrink() : Center(widthFactor: 1.0, heightFactor: 1.0, child: content),
    );
  }
}
