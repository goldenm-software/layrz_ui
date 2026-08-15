import 'package:flutter/widgets.dart';

import '../../constants/constants.dart';
import '../../tokens/tokens.dart';
import 'button_style_spec.dart';

/// Builds the text style for a button label.
///
/// Ensures consistent measurement and rendering by using the exact same style.
TextStyle _buildLabelStyle(
  LayrzTokens tokens,
  LayrzButtonStyleSpec spec,
) {
  return tokens.typography.labelLarge.copyWith(
    fontSize: kLayrzButtonFontSize,
    color: spec.contentColor,
  );
}

/// Builds the content layer (icon + label) for a non-Fab [LayrzButton].
Widget buildButtonContent({
  required String labelText,
  required IconData? icon,
  required LayrzButtonStyleSpec spec,
  required LayrzTokens tokens,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: kLayrzButtonHorizontalPadding,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(
            icon,
            size: kLayrzButtonIconSize,
            color: spec.contentColor,
          ),
        if (icon != null) SizedBox(width: kLayrzButtonIconSeparator),
        Flexible(
          child: Text(
            labelText,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: _buildLabelStyle(tokens, spec),
          ),
        ),
      ],
    ),
  );
}

/// Builds the content layer (centered icon) for a Fab [LayrzButton].
Widget buildFabContent({
  required IconData? icon,
  required LayrzButtonStyleSpec spec,
}) {
  return Icon(
    icon,
    size: kLayrzButtonIconSize,
    color: spec.contentColor,
  );
}
