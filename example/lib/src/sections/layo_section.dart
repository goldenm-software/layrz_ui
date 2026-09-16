import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Showcases [Layo], the "MrLayo" brand mascot, across every implemented
/// [LayoEmotion], plus [AvatarLayo], the cropped head/shoulders framing of
/// the same mascot.
///
/// Demonstrates the widget's size-automatic layout contract: an explicit
/// [Layo.width] pinned inside a fixed-size box, and the default (null width)
/// behaviour filling a bounded parent so it stretches to the available width
/// while its height still derives from the fixed 500:833 aspect ratio. Every
/// multi-[Layo] display in this section uses [LayrzRow]/[LayrzCol] (the
/// responsive 12-column grid) rather than [Wrap] or a plain [Row], so each
/// [Layo] always sits in a bounded-width column and reflows cleanly at any
/// viewport size instead of overflowing on narrow ones.
///
/// The [AvatarLayo] demos further down follow the same grid discipline and
/// cover both [LayoAvatarShape] values and every [LayoEmotion] rendered as an
/// avatar, each showing its own fixed per-emotion background color.
class LayoSection extends StatelessWidget {
  /// Creates a new [LayoSection].
  const LayoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Layo',
      description:
          'The "MrLayo" brand mascot, drawn entirely with CustomPainter — no bundled image or '
          'SVG. Size-automatic: fills the width its parent provides and derives height from '
          'the fixed 500:833 aspect ratio, or pass an explicit width. Renders one of ten '
          'emotions via LayoEmotion. AvatarLayo crops the same mascot into a square '
          'head/shoulders portrait, in either a circle or rounded-box frame.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('All emotions — Layo(emotion: ...)', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          LayrzRow(
            spacing: tokens.spacing.sp4,
            children: LayoEmotion.values.map((emotion) {
              return LayrzCol(
                xs: 12,
                sm: 6,
                md: 3,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 180),
                    child: _EmotionTile(label: emotion.name, emotion: emotion),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: tokens.spacing.sp4),

          Text('Explicit width — Layo(width: 120)', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          const Layo(width: 120),

          SizedBox(height: tokens.spacing.sp4),

          Text('Explicit width — Layo(width: 240)', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          const Layo(width: 240),

          SizedBox(height: tokens.spacing.sp4),

          Text('AvatarLayo — shapes', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          LayrzRow(
            spacing: tokens.spacing.sp4,
            children: [
              LayrzCol(
                xs: 6,
                sm: 4,
                md: 2,
                child: Center(
                  child: _AvatarTile(label: 'circle', shape: LayoAvatarShape.circle),
                ),
              ),
              LayrzCol(
                xs: 6,
                sm: 4,
                md: 2,
                child: Center(
                  child: _AvatarTile(label: 'roundedBox', shape: LayoAvatarShape.roundedBox),
                ),
              ),
            ],
          ),

          SizedBox(height: tokens.spacing.sp4),

          Text('AvatarLayo — all emotions', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          LayrzRow(
            spacing: tokens.spacing.sp4,
            children: LayoEmotion.values.map((emotion) {
              return LayrzCol(
                xs: 6,
                sm: 4,
                md: 2,
                child: Center(
                  child: _AvatarTile(label: emotion.name, emotion: emotion),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: tokens.spacing.sp4),

          Text('TransitionedLayo — LayoController.to(...)', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          const _TransitionDemo(),

          SizedBox(height: tokens.spacing.sp4),

          Text('TransitionedAvatarLayo — bg + ring transition alongside the face', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          const _TransitionedAvatarDemo(),

          SizedBox(height: tokens.spacing.sp4),

          Text('Layo with followCursor', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          const _FollowCursorDemo(),
        ],
      ),
    );
  }
}

/// A single labeled [Layo] tile, used by [LayoSection] to lay out every
/// emotion side by side for visual comparison inside a [LayrzRow]/[LayrzCol]
/// grid.
///
/// Renders its [Layo] with no explicit width, since the enclosing
/// [LayrzCol] already gives this tile a bounded width to fill — [Layo]'s own
/// [AspectRatio] derives its height from that automatically.
class _EmotionTile extends StatelessWidget {
  /// Creates a new [_EmotionTile].
  const _EmotionTile({required this.label, required this.emotion});

  /// The plain-text caption shown above the mascot, naming the
  /// [LayoEmotion] value being demonstrated.
  final String label;

  /// Which [LayoEmotion] this tile's [Layo] renders.
  final LayoEmotion emotion;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tokens.typography.body),
        SizedBox(height: tokens.spacing.sp2),
        Layo(emotion: emotion),
      ],
    );
  }
}

/// A single labeled [AvatarLayo] tile, used by [LayoSection] to lay out
/// several avatars side by side for visual comparison inside a
/// [LayrzRow]/[LayrzCol] grid.
///
/// Gives its [AvatarLayo] an explicit [width] of 120 logical pixels so the
/// square frame renders at a consistent, legible size regardless of how wide
/// the enclosing [LayrzCol] happens to be.
class _AvatarTile extends StatelessWidget {
  /// Creates a new [_AvatarTile].
  const _AvatarTile({
    required this.label,
    this.shape = LayoAvatarShape.circle,
    this.emotion = LayoEmotion.mrLayo,
  });

  /// The plain-text caption shown above the avatar, naming the property
  /// being demonstrated (a shape or an emotion).
  final String label;

  /// Which [LayoAvatarShape] this tile's [AvatarLayo] clips itself to.
  final LayoAvatarShape shape;

  /// Which [LayoEmotion] this tile's [AvatarLayo] renders.
  final LayoEmotion emotion;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tokens.typography.body),
        SizedBox(height: tokens.spacing.sp2),
        AvatarLayo(shape: shape, emotion: emotion, width: 120),
      ],
    );
  }
}

/// Demonstrates [TransitionedLayo] driven by a [LayoController]: a mascot
/// that cross-fades between emotions as the maintainer taps each chip below
/// it, rather than jumping straight to the new face the way a plain [Layo]
/// with a changing [Layo.emotion] would.
///
/// Owns the [LayoController] itself (constructed once in [initState] and
/// disposed in [dispose], matching this design system's usual
/// caller-owns-the-controller convention) so every chip's [LayoController.to]
/// call targets the same controller instance the [TransitionedLayo] above it
/// is listening to.
class _TransitionDemo extends StatefulWidget {
  /// Creates a new [_TransitionDemo].
  const _TransitionDemo();

  @override
  State<_TransitionDemo> createState() => _TransitionDemoState();
}

/// State for [_TransitionDemo]: owns the [LayoController] every chip and the
/// [TransitionedLayo] itself share.
class _TransitionDemoState extends State<_TransitionDemo> {
  /// Drives which [LayoEmotion] transition is currently playing. Constructed
  /// once and disposed with this widget; every chip's `onTap` calls
  /// [LayoController.to] on this same instance.
  late final LayoController _controller;

  /// A representative sample of [LayoEmotion] values shown as tappable chips
  /// below the mascot — not every emotion, so the demo's own row of buttons
  /// stays legible rather than repeating the full 24-value grid already
  /// shown above in this section.
  static const _sampleEmotions = [
    LayoEmotion.mrLayo,
    LayoEmotion.excited,
    LayoEmotion.sad,
    LayoEmotion.angry,
    LayoEmotion.comandante,
    LayoEmotion.christmas,
    LayoEmotion.party,
    LayoEmotion.mindBlown,
  ];

  @override
  void initState() {
    super.initState();
    _controller = LayoController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: TransitionedLayo(controller: _controller),
        ),
        SizedBox(height: tokens.spacing.sp3),
        LayrzRow(
          spacing: tokens.spacing.sp2,
          children: _sampleEmotions.map((emotion) {
            return LayrzCol(
              xs: 6,
              sm: 3,
              md: 2,
              child: LayrzButton(
                labelText: emotion.name,
                onTap: () => _controller.to(emotion),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Demonstrates [TransitionedAvatarLayo] driven by a [LayoController]: an
/// avatar-framed mascot whose face, background, AND ring all cross-fade
/// together as the maintainer taps each chip below it — most visibly on a
/// jump between two very differently-hued emotions (e.g. `love`'s deep red
/// to `success`'s green), which shows the frame's own color smoothly lerping
/// rather than snapping the instant the face starts to change.
///
/// Owns the [LayoController] itself, matching [_TransitionDemoState]'s own
/// caller-owns-the-controller convention.
class _TransitionedAvatarDemo extends StatefulWidget {
  /// Creates a new [_TransitionedAvatarDemo].
  const _TransitionedAvatarDemo();

  @override
  State<_TransitionedAvatarDemo> createState() => _TransitionedAvatarDemoState();
}

/// State for [_TransitionedAvatarDemo]: owns the [LayoController] every chip
/// and the [TransitionedAvatarLayo] itself share.
class _TransitionedAvatarDemoState extends State<_TransitionedAvatarDemo> {
  /// Drives which [LayoEmotion] transition is currently playing. Constructed
  /// once and disposed with this widget; every chip's `onTap` calls
  /// [LayoController.to] on this same instance.
  late final LayoController _controller;

  /// A sample of [LayoEmotion] values chosen specifically to span several
  /// distinct avatar background colors (blue, red, green, yellow, pink) so
  /// tapping between them visibly demonstrates the background/ring lerp, not
  /// just the face crossfade.
  static const _sampleEmotions = [
    LayoEmotion.mrLayo,
    LayoEmotion.love,
    LayoEmotion.success,
    LayoEmotion.excited,
    LayoEmotion.party,
  ];

  @override
  void initState() {
    super.initState();
    _controller = LayoController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: TransitionedAvatarLayo(controller: _controller),
        ),
        SizedBox(height: tokens.spacing.sp3),
        LayrzRow(
          spacing: tokens.spacing.sp2,
          children: _sampleEmotions.map((emotion) {
            return LayrzCol(
              xs: 6,
              sm: 3,
              md: 2,
              child: LayrzButton(
                labelText: emotion.name,
                onTap: () => _controller.to(emotion),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Demonstrates [Layo.followCursor]: the mascot's facial features shift
/// toward the mouse pointer anywhere on the page (this app's [LayrzApp] sets
/// `enableLayoCursorTracking: true`), rather than staying in its fixed idle
/// pose.
///
/// [Layo.followCursor] is only supported for [LayoEmotion.mrLayo],
/// [LayoEmotion.angry], and [LayoEmotion.question] — passing `true` alongside
/// any other emotion trips a debug assertion in [Layo] itself. This demo's
/// emotion selector therefore offers only those three values, which makes
/// `followCursor: true` unconditionally safe here: there is no way for
/// [_emotion] to ever hold an unsupported value, so the two never pair up
/// incorrectly.
///
/// Starts with the effect already turned on (rather than defaulting to off,
/// as [Layo.followCursor] itself does) since the whole point of opening this
/// demo is to see the head-tilt in action without an extra tap first.
class _FollowCursorDemo extends StatefulWidget {
  /// Creates a new [_FollowCursorDemo].
  const _FollowCursorDemo();

  @override
  State<_FollowCursorDemo> createState() => _FollowCursorDemoState();
}

/// State for [_FollowCursorDemo]: tracks the selected [LayoEmotion] and
/// whether [Layo.followCursor] is currently enabled.
class _FollowCursorDemoState extends State<_FollowCursorDemo> {
  /// Which [LayoEmotion] the demo's [Layo] renders. Restricted by the chip
  /// row below to the three emotions [Layo.followCursor] supports, so this
  /// can never drift into a value that would trip [Layo]'s own assertion.
  LayoEmotion _emotion = LayoEmotion.mrLayo;

  /// Whether the demo's [Layo] is currently built with `followCursor: true`.
  /// Starts `true` so the effect is visible immediately, since
  /// [_emotion]'s default ([LayoEmotion.mrLayo]) always supports it.
  bool _followCursor = true;

  /// The only [LayoEmotion] values [Layo.followCursor] supports — mirrors
  /// `_kFollowCursorSupportedEmotions` in `lib/src/layo/src/layo.dart`. Kept
  /// as the complete set of chips offered below on purpose: offering any
  /// other emotion here would let the demo construct an unsupported
  /// `emotion`/`followCursor: true` pairing.
  static const _supportedEmotions = [LayoEmotion.mrLayo, LayoEmotion.angry, LayoEmotion.question];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spacing.sp4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Layo(emotion: _emotion, followCursor: _followCursor),
                ),
                SizedBox(width: tokens.spacing.sp4),
                // Same followCursor effect, shown cropped inside an
                // AvatarLayo frame — the feature shift is identical in
                // absolute terms but reads larger here since the crop
                // magnifies the head relative to the full-body Layo above.
                AvatarLayo(width: 96, emotion: _emotion, followCursor: _followCursor),
              ],
            ),
          ),
        ),
        SizedBox(height: tokens.spacing.sp3),
        LayrzRow(
          spacing: tokens.spacing.sp2,
          children: _supportedEmotions.map((emotion) {
            return LayrzCol(
              xs: 6,
              sm: 3,
              md: 2,
              child: LayrzButton(
                labelText: emotion.name,
                style: _emotion == emotion ? LayrzButtonStyle.filled : LayrzButtonStyle.outlined,
                onTap: () => setState(() => _emotion = emotion),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: tokens.spacing.sp2),
        LayrzRow(
          spacing: tokens.spacing.sp2,
          children: [
            LayrzCol(
              xs: 12,
              sm: 6,
              md: 3,
              child: LayrzButton(
                labelText: _followCursor ? 'Follow cursor: on' : 'Follow cursor: off',
                style: _followCursor ? LayrzButtonStyle.filled : LayrzButtonStyle.outlined,
                onTap: () => setState(() => _followCursor = !_followCursor),
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spacing.sp2),
        Text(
          'Move your mouse anywhere — desktop only.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
      ],
    );
  }
}
