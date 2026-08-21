import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'button_style_spec.dart';

/// Builds the InlineSpan for button content (icon + label or label alone).
///
/// This span is used for both measurement (via TextPainter) and rendering (via RichText).
/// Using a single shared span ensures consistent width calculations and eliminates
/// hand-summing of icon, separator, and label widths.
///
/// **Icon representation**: The icon is rendered as a `WidgetSpan` with `PlaceholderAlignment.middle`
/// and the Icon widget, which centres the icon vertically with the label and delegates font
/// resolution to the Icon widget (eliminating manual font string building).
///
/// **Separator**: The gap between icon and label is implemented via `Padding(right:)` on the icon,
/// keeping placeholder dimensions predictable for measurement.
///
/// **Parameters**:
/// - [buttonFontSize]: The font size for the label text, allowing for responsive sizing on compact viewports.
/// - [buttonIconSize]: The icon size, allowing for responsive sizing on compact viewports.
InlineSpan buildButtonContentSpan({
  required String labelText,
  required IconData? icon,
  required LayrzButtonStyleSpec spec,
  required LayrzTokens tokens,
  required double buttonFontSize,
  required double buttonIconSize,
}) {
  final labelStyle = tokens.typography.label.copyWith(
    fontSize: buttonFontSize,
    color: spec.contentColor,
  );

  // If no icon, return just the label span.
  if (icon == null) {
    return TextSpan(
      text: labelText,
      style: labelStyle,
    );
  }

  // With icon: icon widget (as WidgetSpan) + label text.
  return TextSpan(
    children: [
      // Icon as a WidgetSpan with middle alignment for vertical centering.
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: EdgeInsets.only(right: tokens.spacing.sp2),
          child: Icon(
            icon,
            size: buttonIconSize,
            color: spec.contentColor,
          ),
        ),
      ),
      // Label text.
      TextSpan(
        text: labelText,
        style: labelStyle,
      ),
    ],
  );
}

/// Builds the content layer (icon + label) for a non-Fab [LayrzButton] using RichText.
///
/// Uses the shared [buildButtonContentSpan] to measure and render the same span,
/// ensuring consistent width calculations without hand-summing component widths.
///
/// **Text scaling**: The [textScaler] parameter ensures the rendered text is scaled
/// consistently with how it was measured in [_measureButtonContentWidth].
/// Both paths must use the same scaler to prevent width mismatches at non-standard
/// text scales.
///
/// **Parameters**:
/// - [buttonFontSize]: The font size for the label text, allowing for responsive sizing on compact viewports.
/// - [buttonIconSize]: The icon size, allowing for responsive sizing on compact viewports.
Widget buildButtonContent({
  required String labelText,
  required IconData? icon,
  required LayrzButtonStyleSpec spec,
  required LayrzTokens tokens,
  required TextScaler textScaler,
  required double buttonFontSize,
  required double buttonIconSize,
}) {
  final span = buildButtonContentSpan(
    labelText: labelText,
    icon: icon,
    spec: spec,
    tokens: tokens,
    buttonFontSize: buttonFontSize,
    buttonIconSize: buttonIconSize,
  );

  return Padding(
    padding: EdgeInsets.symmetric(
      horizontal: tokens.spacing.sp3,
    ),
    child: RichText(
      text: span,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textScaler: textScaler,
    ),
  );
}

/// Builds the content layer (centered icon) for a Fab [LayrzButton] using RichText.
///
/// Renders only the icon widget, centered, via RichText with a single WidgetSpan.
///
/// **Parameters**:
/// - [buttonIconSize]: The icon size, allowing for responsive sizing on compact viewports.
Widget buildFabContent({
  required IconData? icon,
  required LayrzButtonStyleSpec spec,
  required double buttonIconSize,
}) {
  if (icon == null) {
    return const SizedBox.shrink();
  }

  return RichText(
    text: WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Icon(
        icon,
        size: buttonIconSize,
        color: spec.contentColor,
      ),
    ),
  );
}
