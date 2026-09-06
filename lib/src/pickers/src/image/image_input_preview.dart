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

  /// Creates a new [LayrzImageInputPreview] for [source].
  const LayrzImageInputPreview({
    super.key,
    required this.source,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return ClipRRect(
      borderRadius: tokens.radius.br1,
      child: LayrzImage(
        source: source,
        width: size,
        height: size,
        fit: BoxFit.cover,
        fallback: _LoadErrorFallback(size: size, tokens: tokens, message: l10n.imageInputLoadError),
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

  /// The localized "couldn't load image" message to display.
  final String message;

  /// Creates a new [_LoadErrorFallback].
  const _LoadErrorFallback({
    required this.size,
    required this.tokens,
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
        borderRadius: tokens.radius.br1,
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
