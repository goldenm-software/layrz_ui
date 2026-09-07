import 'package:flutter/widgets.dart';

import 'layo.dart';
import 'layo_avatar_shape.dart';
import 'layo_emotion.dart';

/// How much darker the ring is than its own avatar's background color,
/// expressed as the `t` fed to [Color.lerp] toward black.
///
/// Applied by [_resolveAvatarRing] to whatever [_resolveAvatarBackground]
/// returns for the current [LayoEmotion], so every avatar's ring reads as a
/// deeper tone of its OWN background rather than a fixed color that clashes
/// against the non-blue backgrounds. `0.35` was picked so the blue family's
/// derived ring reproduces the original hand-picked navy ring
/// (`0xFF001440`, darkened from the blue background `0xFF042365`) closely,
/// while still reading as clearly darker on every other hue.
const double _kAvatarRingDarkenFactor = 0.35;

/// Resolves the fixed avatar background color for a given [LayoEmotion].
///
/// [AvatarLayo]'s background is never settable from outside — it is fully
/// determined by [emotion], grouped into a small fixed palette so that
/// visually-related emotions (e.g. the whole blue/"standard face" family)
/// share the same backdrop:
///
///  - Blue (`ARGB(255, 27, 52, 108)`): [LayoEmotion.mrLayo],
///    [LayoEmotion.question], [LayoEmotion.searching], [LayoEmotion.thinking],
///    [LayoEmotion.wink], [LayoEmotion.smug], [LayoEmotion.cool].
///  - Teal (`0xFF0E7C77`), matching its own accent: [LayoEmotion.listening].
///  - Orange (`0xFFF57C00`): [LayoEmotion.alert].
///  - Yellow (`0xFFF5B800`): [LayoEmotion.excited], [LayoEmotion.idea].
///  - Grey (`0xFF8A8A8A`): [LayoEmotion.sleep], [LayoEmotion.dead],
///    [LayoEmotion.sad], [LayoEmotion.layo404].
///  - Purple (`0xFF7B1FA2`): [LayoEmotion.mindBlown].
///  - Green (`0xFF1B7A3D`): [LayoEmotion.christmas], [LayoEmotion.money],
///    [LayoEmotion.success].
///  - Deep dark red (`0xFF7A1620`), deliberately darker than the red antenna
///    dot so the antenna still reads against it: [LayoEmotion.comandante],
///    [LayoEmotion.love], [LayoEmotion.angry].
///  - Brown (`0xFF6B4423`): [LayoEmotion.working].
///  - Party pink (`0xFFD81B8C`): [LayoEmotion.party].
///
/// The `switch` is intentionally exhaustive with no `default`/wildcard arm,
/// so adding a new [LayoEmotion] value forces a compile error here until a
/// background color is deliberately assigned to it.
Color _resolveAvatarBackground(LayoEmotion emotion) {
  switch (emotion) {
    case LayoEmotion.mrLayo:
    case LayoEmotion.question:
    case LayoEmotion.searching:
    case LayoEmotion.thinking:
    case LayoEmotion.wink:
    case LayoEmotion.smug:
    case LayoEmotion.cool:
      return const Color.fromARGB(255, 27, 52, 108);
    case LayoEmotion.listening:
      // Teal, matching listening's own accent (the EQ bars / tie), a shade
      // deeper than the accent so the bars still read against it.
      return const Color(0xFF0E7C77);
    case LayoEmotion.alert:
      return const Color(0xFFF57C00);
    case LayoEmotion.excited:
    case LayoEmotion.idea:
      return const Color(0xFFF5B800);
    case LayoEmotion.sleep:
    case LayoEmotion.dead:
    case LayoEmotion.sad:
    case LayoEmotion.layo404:
      return const Color(0xFF8A8A8A);
    case LayoEmotion.mindBlown:
      return const Color(0xFF7B1FA2);
    case LayoEmotion.christmas:
    case LayoEmotion.money:
    case LayoEmotion.success:
      return const Color(0xFF1B7A3D);
    case LayoEmotion.comandante:
    case LayoEmotion.love:
    case LayoEmotion.angry:
      return const Color(0xFF7A1620);
    case LayoEmotion.working:
      return const Color(0xFF6B4423);
    case LayoEmotion.party:
      return const Color(0xFFD81B8C);
  }
}

/// Resolves the fixed avatar ring color for a given [LayoEmotion]: a
/// darkened shade of that same emotion's own [_resolveAvatarBackground],
/// by [_kAvatarRingDarkenFactor], so every avatar reads as "[background]
/// with a deeper-tone-of-the-same-color ring" rather than a ring color that
/// clashes against a differently-hued background.
Color _resolveAvatarRing(LayoEmotion emotion) {
  final background = _resolveAvatarBackground(emotion);
  return Color.lerp(background, const Color(0xFF000000), _kAvatarRingDarkenFactor)!;
}

/// Frames the existing [Layo] mascot as an avatar — a colored, bordered
/// shape (circle or rounded box) showing a **head-and-shoulders portrait
/// crop** of [Layo], the way a profile photo frames a person's face rather
/// than their whole body.
///
/// [AvatarLayo] is purely compositional: it never repaints or reimplements
/// any of [Layo]'s own artwork. Instead it renders an inner [Layo] at a
/// **larger size than the avatar frame itself**, shifted upward, inside an
/// [OverflowBox] that permits the overflow — then clips the whole thing to
/// [shape] with a [ClipRRect] (a corner radius of exactly half the side
/// length for [LayoAvatarShape.circle], producing a true circle from a
/// square box; a moderate fixed fraction for [LayoAvatarShape.roundedBox]).
/// [Layo] keeps its own unmodified 500:833 aspect ratio throughout (it is
/// scaled uniformly, never stretched); only the portion of it that falls
/// inside the clip — the head, antenna, and upper shoulders/bow-tie — ends
/// up visible, with the rest of the body cropped away below the frame's
/// lower edge, exactly as a portrait photo crops a torso.
///
/// Unlike [Layo] itself, [AvatarLayo] is always **square** (a fixed 1:1
/// aspect ratio) — an avatar frame reads as a portrait slot, not as the
/// mascot's own silhouette.
///
/// **Sizing** follows the same size-automatic contract as [Layo] itself:
/// with no explicit [width], [AvatarLayo] fills whatever width its parent
/// provides (via an inner [AspectRatio] of `1.0`) and derives its height
/// from that same width — this requires a bounded parent width, exactly as
/// [Layo] does. Pass an explicit [width] when the parent imposes no width
/// bound (for example inside a scrolling [Column]).
///
/// **The border is fixed**, not a parameter: every [AvatarLayo] is ringed
/// with a color derived from its own [emotion] — a darker shade of that
/// same emotion's background (see [_resolveAvatarRing]), so the ring always
/// reads as a deeper tone of the avatar's own color rather than a fixed tone
/// that clashes against a differently-hued background. Its width scales
/// proportionally with the avatar's rendered size rather than being a fixed
/// logical-pixel value, so a small chat-list avatar and a large profile
/// avatar both read as "bordered" rather than the border looking
/// disproportionately thick or thin at the extremes.
///
/// **The background is fixed per [emotion]**, not a parameter: there is no
/// way to override it from outside — it is fully determined by which
/// [LayoEmotion] is showing, via [_resolveAvatarBackground]. This is
/// deliberate: the background is part of each emotion's identity, not an
/// independent theming knob.
///
/// See also:
///   - [Layo], the mascot widget this composes.
///   - [LayoAvatarShape], the enum selecting the frame's silhouette.
class AvatarLayo extends StatelessWidget {
  /// Creates a new [AvatarLayo].
  ///
  /// The [shape] parameter is optional and defaults to
  /// [LayoAvatarShape.circle]. The [emotion] parameter is optional and
  /// defaults to [LayoEmotion.mrLayo], passed straight through to the inner
  /// [Layo] and also used to resolve the fixed per-emotion background color.
  /// The [width] parameter is optional; when null, [AvatarLayo] fills the
  /// width its parent provides (see the class doc comment for the sizing
  /// contract this requires). The [animate] parameter is optional and
  /// defaults to `true`, passed straight through to the inner [Layo].
  const AvatarLayo({
    this.shape = LayoAvatarShape.circle,
    this.emotion = LayoEmotion.mrLayo,
    this.width,
    this.animate = true,
    super.key,
  });

  /// Which silhouette [AvatarLayo] clips itself to.
  ///
  /// Defaults to [LayoAvatarShape.circle], matching the reference mailer
  /// avatar. Applies to the background fill, the fixed per-emotion ring, and
  /// the clip boundary alike.
  final LayoAvatarShape shape;

  /// Which face the inner [Layo] renders.
  ///
  /// Passed straight through to [Layo.emotion]; defaults to
  /// [LayoEmotion.mrLayo], the original default face. Also determines the
  /// avatar's fixed background fill color via [_resolveAvatarBackground],
  /// and — derived from that same background — the fixed ring color via
  /// [_resolveAvatarRing]. See [AvatarLayo]'s own class doc comment for the
  /// full color mapping. See [Layo]'s own doc comment for the full
  /// breakdown of what each [LayoEmotion] looks like.
  final LayoEmotion emotion;

  /// Optional explicit width (and, since [AvatarLayo] is always square,
  /// height) in logical pixels.
  ///
  /// When null, [AvatarLayo] fills the width its parent provides and derives
  /// its height from that same width via a `1.0` [AspectRatio]; provide it
  /// when [AvatarLayo] sits in an unbounded context (e.g. inside a scrolling
  /// [Column]) where the parent imposes no width, exactly as [Layo.width]
  /// does for the unframed mascot.
  final double? width;

  /// Whether the inner [Layo] plays its [emotion]-appropriate idle
  /// animations.
  ///
  /// Passed straight through to [Layo.animate]; defaults to `true`. See
  /// [Layo]'s own doc comment for the full animation contract, including how
  /// [TickerMode] and the platform's reduced-motion preference interact with
  /// this flag.
  final bool animate;

  /// Fraction of the avatar's rendered side length used as the fixed border
  /// stroke width, so the ring scales with the avatar instead of staying a
  /// constant logical-pixel thickness at every size.
  static const double _kBorderWidthFraction = 0.05;

  /// Fraction of the avatar's rendered side length used as the corner radius
  /// for [LayoAvatarShape.roundedBox].
  static const double _kRoundedBoxRadiusFraction = 0.22;

  /// The inner [Layo]'s width as a fraction of the avatar's content side.
  /// At 70% the head fills the frame nicely with the body running off the
  /// bottom (cropped by the clip).
  static const double _kLayoWidthFraction = 0.70;

  /// The inner [Layo]'s top offset, as a fraction of ITS OWN width, from the
  /// top of the content area — positions the head in the frame.
  static const double _kLayoTopFraction = 0.20;

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        return _buildFrame(side, context);
      },
    );

    if (width case final explicitWidth?) {
      return SizedBox(
        width: explicitWidth,
        height: explicitWidth,
        child: content,
      );
    }

    return AspectRatio(
      aspectRatio: 1.0,
      child: content,
    );
  }

  /// Builds the shaped, bordered, colored frame at the resolved [side]
  /// length, showing a head-and-shoulders crop of the inner [Layo].
  ///
  /// The oversized [Layo] (see [_kLayoWidthFraction]) is placed inside an
  /// [OverflowBox] sized to its own full, unclipped bounding box and shifted
  /// upward via [Transform.translate], so the excess spills both above and
  /// below the visible frame; the surrounding [ClipRRect] then crops that
  /// excess away, leaving only the head, antenna, and upper
  /// shoulders/bow-tie visible. The [emotion]'s resolved fixed ring color
  /// (see [_resolveAvatarRing], a darkened shade of the background) is
  /// painted by the outer [Container]'s [BoxDecoration], and the [emotion]'s
  /// resolved fixed background color (see [_resolveAvatarBackground]) fills
  /// the inner [Container] the clip wraps, so the ring sits exactly on the
  /// shape's outline with no gap or overlap against the clipped fill.
  Widget _buildFrame(double side, BuildContext context) {
    final borderWidth = side * _kBorderWidthFraction;
    final fillColor = _resolveAvatarBackground(emotion);
    final ringColor = _resolveAvatarRing(emotion);

    // The clipped portrait: fixed per-emotion background with Layo sized
    // to 70% of the shape's side and its TOP placed 20% of that width down
    // from the top of the content — this frames the head, with the body
    // running off the bottom where the clip crops it.
    final contentSide = side - borderWidth * 2;
    final layoWidth = contentSide * _kLayoWidthFraction;
    final layoTop = layoWidth * _kLayoTopFraction;
    final layoLeft = (contentSide - layoWidth) / 2;

    BorderRadius radiusFor(double s) => shape == LayoAvatarShape.circle
        ? BorderRadius.circular(s / 2)
        : BorderRadius.circular(s * _kRoundedBoxRadiusFraction);

    final portrait = ClipRRect(
      borderRadius: radiusFor(contentSide),
      child: Container(
        width: contentSide,
        height: contentSide,
        color: fillColor,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: layoLeft,
              top: layoTop,
              width: layoWidth,
              child: Layo(width: layoWidth, emotion: emotion, animate: animate),
            ),
          ],
        ),
      ),
    );

    // Ring directly around the clipped content (no white inset ring) --
    // a darkened shade of this same emotion's own background, so it never
    // clashes against a differently-hued fill.
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        borderRadius: radiusFor(side),
        color: ringColor,
      ),
      padding: EdgeInsets.all(borderWidth),
      child: portrait,
    );
  }
}
