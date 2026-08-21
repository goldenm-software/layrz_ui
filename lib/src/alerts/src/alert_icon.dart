import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import 'alert_type.dart';

/// A rounded square icon chip for displaying semantic alert icons.
///
/// [LayrzAlertIcon] is a standalone widget that renders a rounded square container
/// with a centred icon. It is NOT used by [LayrzAlert] directly — instead,
/// [LayrzAlert] builds its own icon chips internally. This widget is provided
/// as a reusable building block for other contexts where a semantic icon chip
/// might be needed.
///
/// The chip size is controlled by [size], the icon glyph size by [iconSize],
/// and padding around the icon by [padding]. Colours are resolved from the
/// [type] and tokens unless [color] or [icon] are explicitly provided.
class LayrzAlertIcon extends StatelessWidget {
  /// The semantic type of the alert icon.
  ///
  /// Determines the default icon and colour if [icon] or [color] are not provided.
  /// Defaults to [LayrzAlertType.info].
  final LayrzAlertType type;

  /// The outer size of the icon chip container (width and height in logical pixels).
  ///
  /// Defaults to [kLayrzAlertIconWidgetSize].
  final double size;

  /// The size of the icon glyph inside the chip.
  ///
  /// Defaults to [kLayrzAlertIconWidgetIconSize].
  final double iconSize;

  /// Padding between the chip edge and the icon glyph.
  final EdgeInsetsGeometry? padding;

  /// The colour of the icon chip, used only when [type] is [LayrzAlertType.custom].
  ///
  /// If null and [type] is [LayrzAlertType.custom], defaults to
  /// [LayrzTokens.colors.primary]. Ignored for non-custom types.
  final Color? color;

  /// The icon glyph, used only when [type] is [LayrzAlertType.custom].
  ///
  /// If null and [type] is [LayrzAlertType.custom], defaults to
  /// [MdiIcons.informationBoxOutline]. Ignored for non-custom types.
  final IconData? icon;

  /// Creates a [LayrzAlertIcon].
  const LayrzAlertIcon({
    super.key,
    this.type = LayrzAlertType.info,
    this.size = kLayrzAlertIconWidgetSize,
    this.iconSize = kLayrzAlertIconWidgetIconSize,
    this.padding,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Resolve accent colour.
    Color accentColor;
    if (type == LayrzAlertType.custom) {
      accentColor = color ?? tokens.colors.primary.shade500;
    } else {
      accentColor = type.colorToken(tokens) ?? tokens.colors.primary.shade500;
    }

    // Resolve icon.
    IconData resolvedIcon;
    if (type == LayrzAlertType.custom) {
      resolvedIcon = icon ?? MdiIcons.informationBoxOutline;
    } else {
      resolvedIcon = type.icon ?? MdiIcons.informationBoxOutline;
    }

    final effectivePadding = padding ?? EdgeInsets.all(tokens.spacing.sp1);

    return Container(
      width: size,
      height: size,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: accentColor.withOpacityValue(tokens.colors.tonalOpacity),
        borderRadius: tokens.radius.br2,
      ),
      child: Center(
        child: Icon(
          resolvedIcon,
          color: accentColor,
          size: iconSize,
        ),
      ),
    );
  }
}
