import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

import 'package:layrz_ui/constants.dart';
import 'package:layrz_ui/extensions.dart';
import 'package:layrz_ui/preview.dart';
import 'package:layrz_ui/tokens.dart';
import 'package:layrz_icons/layrz_icons.dart';

import 'alert_style.dart';
import 'alert_style_spec.dart';
import 'alert_type.dart';

/// An inline status callout that communicates information, success, warnings, or errors.
///
/// [LayrzAlert] is a non-interactive widget that displays a semantic message via
/// colour, icon, title text, and body text. It supports multiple styles
/// ([LayrzAlertStyle]) and types ([LayrzAlertType]) to fit different contexts.
///
/// The widget requires both [title] and [description] — there are no optional variants.
/// The [type] parameter controls the semantic colour and icon (info, success, warning,
/// danger, context, or custom). The [style] parameter controls visual appearance
/// (layrz, filledTonal, filled, outlined, or filledIcon).
///
/// Layout:
/// - For all styles except [LayrzAlertStyle.filledIcon]:
///   A single-row container with an icon chip on the left, gap, and a title/description
///   column on the right.
/// - For [LayrzAlertStyle.filledIcon]:
///   A split-panel design with an icon on the left (accent background) and text
///   on the right (neutral surface background).
///
/// Responsive:
/// - No fixed heights on text-bearing elements (supports WCAG 1.4.4 text scaling).
/// - Only the icon chip and filledIcon left panel have fixed dimensions.
class LayrzAlert extends StatelessWidget {
  /// The semantic type of the alert.
  ///
  /// Determines the default icon and colour. Defaults to [LayrzAlertType.info].
  /// If [type] is [LayrzAlertType.custom], the [color] and [icon] parameters
  /// control appearance; otherwise they are ignored.
  final LayrzAlertType type;

  /// The title text of the alert.
  ///
  /// Required. Displays as bold title text. Scales with system text scale factor.
  final String title;

  /// The description text of the alert.
  ///
  /// Required. Displays as body text. Limited to [maxLines] lines before ellipsis.
  /// Scales with system text scale factor.
  final String description;

  /// The maximum number of lines for [description] text.
  ///
  /// If the description exceeds this many lines, it is truncated with an ellipsis.
  /// Defaults to 3.
  final int maxLines;

  /// The visual style of the alert.
  ///
  /// Determines background, border, icon chip, and text colours.
  /// Defaults to [LayrzAlertStyle.layrz].
  final LayrzAlertStyle style;

  /// The custom colour of the alert, used only when [type] is [LayrzAlertType.custom].
  ///
  /// If [type] is not custom, this parameter is ignored.
  /// If null and [type] is custom, defaults to [LayrzTokens.colors.primary].
  final Color? color;

  /// The custom icon glyph, used only when [type] is [LayrzAlertType.custom].
  ///
  /// If [type] is not custom, this parameter is ignored.
  /// If null and [type] is custom, defaults to [LayrzIcons.solarOutlineInfoSquare].
  final IconData? icon;

  /// The size of the icon glyph.
  ///
  /// If null, defaults to [kLayrzAlertFilledIconSize] for [LayrzAlertStyle.filledIcon],
  /// or [kLayrzAlertIconSize] for all other styles.
  final double? iconSize;

  /// Creates a [LayrzAlert].
  const LayrzAlert({
    super.key,
    this.type = LayrzAlertType.info,
    required this.title,
    required this.description,
    this.maxLines = 3,
    this.style = LayrzAlertStyle.layrz,
    this.color,
    this.icon,
    this.iconSize,
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
      resolvedIcon = icon ?? LayrzIcons.solarOutlineInfoSquare;
    } else {
      resolvedIcon = type.icon ?? LayrzIcons.solarOutlineInfoSquare;
    }

    // Resolve icon size.
    final effectiveIconSize =
        iconSize ?? (style == LayrzAlertStyle.filledIcon ? kLayrzAlertFilledIconSize : kLayrzAlertIconSize);

    // Resolve spec.
    final spec = LayrzAlertStyleSpec.resolve(
      style: style,
      accent: accentColor,
      tokens: tokens,
    );

    // For filledIcon style, use a split-panel layout.
    if (style == LayrzAlertStyle.filledIcon) {
      return Semantics(
        label: '$title. $description',
        container: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radius.r12),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left panel: accent background with icon.
                ExcludeSemantics(
                  child: Container(
                    color: accentColor,
                    padding: EdgeInsets.all(tokens.spacing.sp16),
                    child: Center(
                      child: Icon(
                        resolvedIcon,
                        color: spec.iconColor,
                        size: effectiveIconSize,
                      ),
                    ),
                  ),
                ),
                // Right panel: neutral surface with title and description.
                Expanded(
                  child: Container(
                    color: spec.backgroundColor,
                    padding: EdgeInsets.all(tokens.spacing.sp16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: tokens.typography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: spec.titleColor,
                          ),
                        ),
                        SizedBox(height: tokens.spacing.sp4),
                        Text(
                          description,
                          style: tokens.typography.bodyMedium.copyWith(
                            color: spec.bodyColor,
                          ),
                          maxLines: maxLines,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // For all other styles: single container with icon chip, gap, and text column.
    return Semantics(
      label: '$title. $description',
      container: true,
      child: Container(
        padding: EdgeInsets.all(tokens.spacing.sp16),
        decoration: BoxDecoration(
          color: spec.backgroundColor,
          border: spec.borderWidth > 0
              ? Border.all(
                  color: spec.borderColor,
                  width: spec.borderWidth,
                )
              : null,
          borderRadius: BorderRadius.circular(tokens.radius.r12),
        ),
        child: Row(
          children: [
            // Icon chip.
            ExcludeSemantics(
              child: Container(
                width: kLayrzAlertIconBoxSize,
                height: kLayrzAlertIconBoxSize,
                decoration: BoxDecoration(
                  color: spec.iconChipBackground.a > 0.0 ? spec.iconChipBackground : null,
                  borderRadius: BorderRadius.circular(tokens.radius.r10),
                ),
                child: Center(
                  child: Icon(
                    resolvedIcon,
                    color: spec.iconColor,
                    size: effectiveIconSize,
                  ),
                ),
              ),
            ),
            // Gap.
            SizedBox(width: tokens.spacing.sp12),
            // Text column.
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tokens.typography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: spec.titleColor,
                    ),
                  ),
                  SizedBox(height: tokens.spacing.sp4),
                  Text(
                    description,
                    style: tokens.typography.bodyMedium.copyWith(
                      color: spec.bodyColor,
                    ),
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview of [LayrzAlert] with [LayrzAlertStyle.layrz] in light theme.
@Preview(name: 'Layrz', theme: LayrzPreviewTheme.light)
Widget previewLayrzAlertLayrz() => LayrzAlert(
  type: LayrzAlertType.success,
  title: 'Success',
  description: 'Your operation completed successfully.',
);

/// Preview of [LayrzAlert] with [LayrzAlertStyle.filledTonal] in light theme.
@Preview(name: 'FilledTonal', theme: LayrzPreviewTheme.light)
Widget previewLayrzAlertFilledTonal() => LayrzAlert(
  type: LayrzAlertType.warning,
  title: 'Warning',
  description: 'Please check your input before proceeding.',
  style: LayrzAlertStyle.filledTonal,
);

/// Preview of [LayrzAlert] with [LayrzAlertStyle.filled] in light theme.
@Preview(name: 'Filled', theme: LayrzPreviewTheme.light)
Widget previewLayrzAlertFilled() => LayrzAlert(
  type: LayrzAlertType.danger,
  title: 'Error',
  description: 'An error occurred while processing your request.',
  style: LayrzAlertStyle.filled,
);

/// Preview of [LayrzAlert] with [LayrzAlertStyle.outlined] in light theme.
@Preview(name: 'Outlined', theme: LayrzPreviewTheme.light)
Widget previewLayrzAlertOutlined() => LayrzAlert(
  type: LayrzAlertType.info,
  title: 'Information',
  description: 'This is an informational message for the user.',
  style: LayrzAlertStyle.outlined,
);

/// Preview of [LayrzAlert] with [LayrzAlertStyle.filledIcon] in light theme.
@Preview(name: 'FilledIcon', theme: LayrzPreviewTheme.light)
Widget previewLayrzAlertFilledIcon() => LayrzAlert(
  type: LayrzAlertType.context,
  title: 'Context',
  description: 'This message depends on the surrounding context.',
  style: LayrzAlertStyle.filledIcon,
);
