import 'package:flutter/widgets.dart';

import '../../constants/constants.dart';
import '../../tokens/tokens.dart';
import 'button_style_spec.dart';

/// Builds the content layer (icon + label) for a non-Fab [LayrzButton].
Widget buildButtonContent({
  required String labelText,
  required IconData? icon,
  required double iconSize,
  required double iconSeparatorSize,
  required double fontSize,
  required LayrzButtonStyleSpec spec,
  required LayrzTokens tokens,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(
      horizontal: kLayrzButtonHorizontalPadding,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(
            icon,
            size: iconSize,
            color: spec.contentColor,
          ),
        if (icon != null) SizedBox(width: iconSeparatorSize),
        Flexible(
          child: Text(
            labelText,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: tokens.typography.labelLarge.copyWith(
              fontSize: fontSize,
              color: spec.contentColor,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Builds the content layer (centered icon) for a Fab [LayrzButton].
Widget buildFabContent({
  required IconData? icon,
  required double iconSize,
  required LayrzButtonStyleSpec spec,
}) {
  return Icon(
    icon,
    size: iconSize,
    color: spec.contentColor,
  );
}
