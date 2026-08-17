import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/preview.dart';

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
