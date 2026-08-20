import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/preview/preview.dart';

/// Preview of [LayrzAlert] with [LayrzAlertStyle.layrz] in light theme.
@Preview(
  name: 'Layrz',
  size: Size(400, 120),
  theme: layrzPreviewLightTheme,
)
Widget previewLayrzAlertLayrz() => LayrzAlert(
  type: LayrzAlertType.success,
  title: 'Success',
  description: 'Your operation completed successfully.',
);

/// Preview of [LayrzAlert] with [LayrzAlertStyle.filledIcon] in light theme.
@Preview(
  name: 'FilledIcon',
  size: Size(400, 120),
  theme: layrzPreviewLightTheme,
)
Widget previewLayrzAlertFilledIcon() => LayrzAlert(
  type: LayrzAlertType.context,
  title: 'Context',
  description: 'This message depends on the surrounding context.',
  style: LayrzAlertStyle.filledIcon,
);
