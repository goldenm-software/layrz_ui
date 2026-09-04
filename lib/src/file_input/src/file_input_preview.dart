import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/images/images.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'file_input_result.dart';

/// Renders a single picked-or-dropped file inside [LayrzFileInput]'s populated
/// state: an image thumbnail for image files (via [LayrzImage]), or a
/// name+icon chip for anything else.
///
/// This widget is presentation-only -- it does not own the clear/replace
/// affordance. [LayrzFileInput] composes that as a sibling control so it can
/// give it its own keyboard focus stop, independent of this preview's layout.
class LayrzFileInputPreview extends StatelessWidget {
  /// The file to render a preview for.
  final LayrzFileInputResult result;

  /// The width and height of the square preview thumbnail/chip icon, in
  /// logical pixels.
  ///
  /// Defaults to 48, matching a standard small-avatar footprint elsewhere in
  /// the design system.
  final double size;

  /// Creates a new [LayrzFileInputPreview] for [result].
  const LayrzFileInputPreview({
    super.key,
    required this.result,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (result.isImage) {
      return ClipRRect(
        borderRadius: tokens.radius.br1,
        child: LayrzImage(
          source: result.dataUri,
          width: size,
          height: size,
          fit: BoxFit.cover,
          fallback: _buildFileChipIcon(tokens),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.colors.sf2,
        borderRadius: tokens.radius.br1,
      ),
      child: _buildFileChipIcon(tokens),
    );
  }

  /// The generic document icon shown for non-image files, and as the
  /// [LayrzImage.fallback] for an image file whose bytes fail to decode.
  Widget _buildFileChipIcon(LayrzTokens tokens) {
    return Icon(
      MdiIcons.fileDocumentOutline,
      size: size * 0.5,
      color: tokens.colors.fg3,
    );
  }
}
