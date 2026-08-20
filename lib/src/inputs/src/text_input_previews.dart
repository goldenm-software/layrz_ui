import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/preview/preview.dart';

/// Displays the default [LayrzTextInput] state with label and placeholder.
@Preview(
  name: 'Default',
  size: Size(400, 120),
  theme: layrzPreviewLightTheme,
)
Widget previewLayrzTextInputDefault() => LayrzTextInput(
  labelText: 'Enter your name',
  hintText: 'John Doe',
);

/// Displays the [LayrzTextInput] in error state with error message.
@Preview(
  name: 'With Error',
  size: Size(400, 150),
  theme: layrzPreviewLightTheme,
)
Widget previewLayrzTextInputError() => LayrzTextInput(
  labelText: 'Email',
  errors: ['Invalid email format'],
);

/// Displays the disabled [LayrzTextInput] state.
@Preview(
  name: 'Disabled',
  size: Size(400, 120),
  theme: layrzPreviewLightTheme,
)
Widget previewLayrzTextInputDisabled() => LayrzTextInput(
  labelText: 'Disabled Field',
  hintText: 'Cannot type',
  disabled: true,
);

/// Displays the read-only [LayrzTextInput] state.
@Preview(
  name: 'Read-only',
  size: Size(400, 120),
  theme: layrzPreviewLightTheme,
)
Widget previewLayrzTextInputReadOnly() => LayrzTextInput(
  labelText: 'Read-only',
  controller: TextEditingController(text: 'Read-only text'),
  readOnly: true,
);

/// Displays the [LayrzTextInput] with required field indicator.
@Preview(
  name: 'Required',
  size: Size(400, 120),
  theme: layrzPreviewLightTheme,
)
Widget previewLayrzTextInputRequired() => LayrzTextInput(
  labelText: 'Username',
  hintText: 'Your username',
  isRequired: true,
);
