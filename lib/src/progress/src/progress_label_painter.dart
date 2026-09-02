import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Paints the value label for [LayrzProgressBar]'s linear, determinate mode.
///
/// **Placement.** The label is right-aligned, inset by [inset] logical
/// pixels, against the leading (filled) portion of the bar — i.e. flush to
/// the right edge of the *bar* (the coloured fill), not the centre of the
/// whole component and not the right edge of the *track* (the unfilled
/// remainder). The fill boundary — the x-offset, in logical pixels, where
/// the fill ends and the track begins — is computed inside [paint] itself,
/// as `size.width * value`, using the [Size] [paint] is actually called
/// with. That size is deliberately not accepted as a precomputed pixel
/// offset from the caller: [LayrzProgressBar] gives this painter's
/// `CustomPaint` a `size:` hint of `Size(double.infinity, height)` for a
/// linear bar (its own width is resolved by its parent's constraints, not
/// known upfront), and `CustomPaint.size` is only a *preferred* size — the
/// authoritative, already-resolved size is the one [paint] receives, so
/// deriving the boundary there is the only way to get a real, finite value.
///
/// **Overflow flip.** When the filled region is too narrow to hold the
/// label — `fillBoundary - inset` is less than the measured text width —
/// the label flips to just outside the bar, landing on the track instead,
/// inset from the fill boundary by the same [inset]. This painter measures
/// the label itself via [TextPainter.layout] to decide; see [_resolvePlacement]
/// for the exact threshold and the near-100% edge case.
///
/// **Colour.** The label's colour is never fixed: it always tracks whichever
/// region it is actually painted over, so it reads as intentional rather than
/// merely readable. While inside the bar it uses [indicatorContrastColor]
/// (the fill colour's contrast colour); once flipped onto the track it uses
/// [trackContrastColor] (the track colour's contrast colour) instead — a
/// label flipped onto a light track in the fill's (often light) contrast
/// colour would be invisible, which is why the two colours are never
/// interchangeable. Both are derived by the caller from
/// `Color.contrastColor` (`lib/src/extensions/src/color.dart`) rather than
/// hardcoded, so a change to either semantic colour (e.g. a darkened warning
/// orange) is picked up automatically.
///
/// This painter deliberately knows nothing about progress semantics
/// (determinate/indeterminate, format) — [LayrzProgressBar] only constructs
/// it for the linear, determinate case, and withholds it entirely for
/// indeterminate mode, where a percentage would be meaningless.
class LayrzProgressLabelPainter extends CustomPainter {
  /// The formatted label text to paint (e.g. `'42%'` or `'3.14%'`).
  final String text;

  /// The text style applied to the label; only [TextStyle.color] is
  /// overridden, to whichever of [indicatorContrastColor] or
  /// [trackContrastColor] applies once placement is resolved.
  final TextStyle style;

  /// The determinate progress fraction, in `[0.0, 1.0]`, used to compute the
  /// fill boundary at paint time (`size.width * value`) against the actual,
  /// resolved paint [Size] — see this class's doc for why that must happen
  /// in [paint] rather than being precomputed by the caller.
  final double value;

  /// The text colour used when the label is placed inside the bar (the
  /// filled/indicator region) — the indicator colour's contrast colour.
  final Color indicatorContrastColor;

  /// The text colour used when the label is flipped outside the bar, onto
  /// the track (the unfilled region) — the track colour's contrast colour.
  final Color trackContrastColor;

  /// The inset, in logical pixels, kept between the label and the fill
  /// boundary in both placements: between the label's right edge and the
  /// boundary when inside the bar, and between the label's left edge and
  /// the boundary when flipped onto the track.
  final double inset;

  /// Creates a new [LayrzProgressLabelPainter].
  LayrzProgressLabelPainter({
    required this.text,
    required this.style,
    required this.value,
    required this.indicatorContrastColor,
    required this.trackContrastColor,
    required this.inset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boundary = (size.width * value.clamp(0.0, 1.0)).clamp(0.0, size.width);

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final placement = _resolvePlacement(
      boundary: boundary,
      totalWidth: size.width,
      labelWidth: textPainter.width,
    );

    final color = placement.insideBar ? indicatorContrastColor : trackContrastColor;
    final resolvedPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dy = (size.height - resolvedPainter.height) / 2;
    resolvedPainter.paint(canvas, Offset(placement.x, dy));
  }

  /// Decides where the label lands — inside the bar (right-aligned against
  /// [boundary], inset by [inset]) or flipped onto the track (left-aligned
  /// just past [boundary], inset by [inset]) — and returns the resolved
  /// x-offset alongside which region it ended up in.
  ///
  /// **Threshold.** The label stays inside the bar when the space available
  /// there — `boundary - inset` — is at least [labelWidth]; otherwise it does
  /// not fit and the label flips onto the track. This directly measures the
  /// real rendered text (via [TextPainter.layout] in [paint]) rather than
  /// guessing from character count or a fixed percentage, so it stays
  /// correct across [style] changes, locales, and decimal counts.
  ///
  /// **Symmetric edge case — near 100%.** At high values the track can be
  /// too narrow to hold the label if it flipped (mirroring the low-value
  /// case), most extremely at `value == 1.0`, where the track has zero width
  /// and flipping is impossible. Rather than special-casing "does the track
  /// fit" as a second, competing threshold, the bar's fill width almost
  /// always dwarfs the label at these values (a 68% or wider bar has ample
  /// room even after the inset), so **fitting inside the bar always wins
  /// when it fits** — the track-fit check only matters as a fallback for
  /// when the bar does not fit either, and in that case staying inside the
  /// bar (clamped to the available width) is still preferable to painting a
  /// label into zero or near-zero space on the track. In short: the bar is
  /// checked first, and wins its own check; the track is only ever chosen
  /// when the bar's check fails.
  _LabelPlacement _resolvePlacement({
    required double boundary,
    required double totalWidth,
    required double labelWidth,
  }) {
    final fitsInsideBar = (boundary - inset) >= labelWidth;
    if (fitsInsideBar) {
      return _LabelPlacement(x: boundary - inset - labelWidth, insideBar: true);
    }

    final trackAvailable = totalWidth - boundary - inset;
    final fitsOnTrack = trackAvailable >= labelWidth;
    if (fitsOnTrack) {
      return _LabelPlacement(x: boundary + inset, insideBar: false);
    }

    // Neither region has room (a very narrow bar with a small enough track
    // too, or value == 1.0 where there is no track at all). Stay inside the
    // bar rather than painting onto a track with even less space, clamping
    // so the label never paints past either edge of the box. The upper
    // clamp bound can itself be negative when the label is wider than the
    // entire box (an extreme, pathological case — a huge custom style on a
    // very narrow bar) — `math.max` guards against `clamp`'s lower bound
    // then exceeding its upper bound, which throws.
    final maxX = math.max(0.0, totalWidth - labelWidth);
    final clampedX = (boundary - inset - labelWidth).clamp(0.0, maxX);
    return _LabelPlacement(x: clampedX, insideBar: true);
  }

  @override
  bool shouldRepaint(LayrzProgressLabelPainter oldDelegate) {
    return text != oldDelegate.text ||
        style != oldDelegate.style ||
        value != oldDelegate.value ||
        indicatorContrastColor != oldDelegate.indicatorContrastColor ||
        trackContrastColor != oldDelegate.trackContrastColor ||
        inset != oldDelegate.inset;
  }
}

/// The resolved x-offset and region for a painted label, computed once per
/// paint by [LayrzProgressLabelPainter._resolvePlacement].
class _LabelPlacement {
  /// The x-offset, in logical pixels, at which the label's left edge is painted.
  final double x;

  /// Whether the label landed inside the bar (`true`) or flipped onto the
  /// track (`false`). Selects which contrast colour applies.
  final bool insideBar;

  /// Creates a new [_LabelPlacement].
  const _LabelPlacement({required this.x, required this.insideBar});
}
