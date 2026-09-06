import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/images/images.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// The live preview shown inside [LayrzImageInput]'s populated state.
///
/// Wraps [LayrzImage] with the calm, plain-language failure state the image
/// input's box-shaped drop target needs (dossier §8c, liliana): a broken or
/// unreachable [source] (a bad URL, a malformed data-URI, unparseable bare
/// base64) renders a visible "couldn't load image" fallback -- an icon plus
/// localized text -- rather than the blank box [LayrzImage.fallback] leaves
/// undecorated by default. A blank box reads as "did my upload even
/// register?" and invites a repeat upload; a visible fallback tells the user
/// unambiguously that the *current* value is the problem, not their action.
///
/// This widget is presentation-only, exactly like `LayrzFileInputPreview` it
/// mirrors: it does not own the clear/replace affordance, which
/// `LayrzImageInput` composes as an independent sibling control so it keeps
/// its own keyboard focus stop.
class LayrzImageInputPreview extends StatelessWidget {
  /// The image source to render: an http(s) URL, a `data:` URI, or bare
  /// base64 -- anything [LayrzImage.source] accepts.
  final String source;

  /// The width and height of the square preview, in logical pixels.
  ///
  /// Defaults to 96, larger than `LayrzFileInputPreview`'s 48 -- this is the
  /// primary content of the box in the populated state, not a small row
  /// thumbnail alongside a file name.
  final double size;

  /// The border radius of the enclosing tile this preview fills.
  ///
  /// Defaults to [LayrzRadiusTokens.br1] for a standalone preview. When this
  /// widget is composed inside [LayrzImageInput]'s tile, the caller passes the
  /// tile's own radius (`tokens.radius.br3`) here so the preview's clip curves
  /// **exactly match** the tile's outer border curve -- a mismatch between the
  /// two (previously this widget hardcoded [LayrzRadiusTokens.br1] regardless
  /// of the tile's radius) is what produced the "broken border" bug: the
  /// image's corners were clipped tighter than the border's corners, leaving
  /// a visible wedge of background between the two curves.
  final BorderRadius borderRadius;

  /// The width of the tile's border, in logical pixels, this preview must be
  /// inset by so its fill never paints over the border stroke.
  ///
  /// Defaults to 0 (no inset) for a standalone preview. When composed inside
  /// the tile, the caller passes the resolved `LayrzFileInputStyleSpec`'s
  /// `borderWidth` so the image is clipped strictly inside the border ring
  /// rather than edge-to-edge with it.
  final double borderWidth;

  /// Creates a new [LayrzImageInputPreview] for [source].
  ///
  /// [borderRadius] defaults to a 6-pixel radius on all corners, matching
  /// [LayrzRadiusTokens.br1]'s value -- this widget cannot reach `context`
  /// (and therefore the live token instance) before [build], so the default
  /// is the token's known constant value rather than a call to `tokens.radius.br1`.
  const LayrzImageInputPreview({
    super.key,
    required this.source,
    this.size = 96,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    final innerRadius = tokens.radius.innerRadius(
      outerRadius: borderRadius.topLeft.x,
      spacer: borderWidth,
    );

    return Padding(
      padding: EdgeInsets.all(borderWidth),
      child: ClipRRect(
        borderRadius: innerRadius,
        child: LayrzImage(
          source: source,
          width: size - (borderWidth * 2),
          height: size - (borderWidth * 2),
          fit: BoxFit.cover,
          fallback: _LoadErrorFallback(
            size: size - (borderWidth * 2),
            tokens: tokens,
            borderRadius: innerRadius,
            message: l10n.imageInputLoadError,
          ),
        ),
      ),
    );
  }
}

/// The "couldn't load image" fallback rendered in place of the preview when
/// [LayrzImage] cannot fetch or decode the current source.
///
/// A broken-image icon plus localized text, laid out to fit within the same
/// square footprint the successful preview would occupy -- so the populated
/// box never changes size between a healthy and a broken value, per D15.
class _LoadErrorFallback extends StatelessWidget {
  /// The square footprint to fill, matching the preview it replaces.
  final double size;

  /// Design tokens, threaded from the parent build.
  final LayrzTokens tokens;

  /// The border radius to clip this fallback's fill to, matching the same
  /// inset radius the healthy-preview [ClipRRect] in [LayrzImageInputPreview]
  /// uses -- so the fallback's rounded corners never diverge from the
  /// tile's border curve either, the same bug this whole fix addresses.
  final BorderRadius borderRadius;

  /// The localized "couldn't load image" message to display.
  final String message;

  /// Creates a new [_LoadErrorFallback].
  const _LoadErrorFallback({
    required this.size,
    required this.tokens,
    required this.borderRadius,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.colors.sf2,
        borderRadius: borderRadius,
      ),
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(MdiIcons.imageOffOutline, size: size * 0.32, color: tokens.colors.fg3),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
          ),
        ],
      ),
    );
  }
}
