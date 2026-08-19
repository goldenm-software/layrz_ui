import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/preview.dart';

/// Preview of a color swatch showing the primary brand colour.
///
/// This is a proof-of-concept preview demonstrating the @Preview annotation
/// with [LayrzPreviewTheme.light]. The swatch renders identically in preview
/// and in the production app, with full access to design tokens via [LayrzTheme.of].
@Preview(
  name: 'Light',
  theme: LayrzPreviewTheme.light,
)
Widget previewPrimaryColorSwatch() {
  return _PrimaryColorSwatch();
}

/// A simple colour swatch widget showing the primary brand colour.
///
/// This widget demonstrates token access inside a preview. It reads
/// [LayrzTheme.of(context).tokens.colors.primary] to paint a swatch,
/// then displays the hex value below.
class _PrimaryColorSwatch extends StatelessWidget {
  /// Creates a [_PrimaryColorSwatch].
  const _PrimaryColorSwatch();

  @override
  Widget build(BuildContext context) {
    final tokens = LayrzTheme.of(context).tokens;
    final primaryColor = tokens.colors.primary;
    final hexValue = '#${primaryColor.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0')}';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(tokens.radius.base),
            ),
          ),
          SizedBox(height: tokens.spacing.sp12),
          LayrzText(
            'Primary',
            style: tokens.typography.label.copyWith(
              color: tokens.colors.fg2,
            ),
          ),
          SizedBox(height: tokens.spacing.sp4),
          LayrzText(
            hexValue,
            style: tokens.typography.label.copyWith(
              color: tokens.colors.fg3,
            ),
          ),
        ],
      ),
    );
  }
}
