import 'package:flutter/widgets.dart';

import 'package:layrz_ui/constants/constants.dart';
import 'package:layrz_ui/tokens/tokens.dart';

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
InlineSpan buildButtonContentSpan({
  required String labelText,
  required IconData? icon,
  required LayrzButtonStyleSpec spec,
  required LayrzTokens tokens,
}) {
  final labelStyle = tokens.typography.labelLarge.copyWith(
    fontSize: kLayrzButtonFontSize,
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
          padding: const EdgeInsets.only(right: kLayrzButtonIconSeparator),
          child: Icon(
            icon,
            size: kLayrzButtonIconSize,
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
Widget buildButtonContent({
  required String labelText,
  required IconData? icon,
  required LayrzButtonStyleSpec spec,
  required LayrzTokens tokens,
}) {
  final span = buildButtonContentSpan(
    labelText: labelText,
    icon: icon,
    spec: spec,
    tokens: tokens,
  );

  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: kLayrzButtonHorizontalPadding,
    ),
    child: RichText(
      text: span,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    ),
  );
}

/// Builds the content layer (centered icon) for a Fab [LayrzButton] using RichText.
///
/// Renders only the icon widget, centered, via RichText with a single WidgetSpan.
Widget buildFabContent({
  required IconData? icon,
  required LayrzButtonStyleSpec spec,
}) {
  if (icon == null) {
    return const SizedBox.shrink();
  }

  return RichText(
    text: WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Icon(
        icon,
        size: kLayrzButtonIconSize,
        color: spec.contentColor,
      ),
    ),
  );
}
