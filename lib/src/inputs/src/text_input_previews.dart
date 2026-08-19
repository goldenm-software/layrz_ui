import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/preview/preview.dart';

/// Displays the default [LayrzTextInput] state with label and placeholder.
@Preview(
  name: 'Default',
  theme: LayrzPreviewTheme.light,
)
Widget previewLayrzTextInputDefault() => LayrzTextInput(
  labelText: 'Enter your name',
  hintText: 'John Doe',
);

/// Displays the [LayrzTextInput] in error state with error message.
@Preview(
  name: 'With Error',
  theme: LayrzPreviewTheme.light,
)
Widget previewLayrzTextInputError() => LayrzTextInput(
  labelText: 'Email',
  errors: ['Invalid email format'],
);

/// Displays the disabled [LayrzTextInput] state.
@Preview(
  name: 'Disabled',
  theme: LayrzPreviewTheme.light,
)
Widget previewLayrzTextInputDisabled() => LayrzTextInput(
  labelText: 'Disabled Field',
  hintText: 'Cannot type',
  disabled: true,
);

/// Displays the read-only [LayrzTextInput] state.
@Preview(
  name: 'Read-only',
  theme: LayrzPreviewTheme.light,
)
Widget previewLayrzTextInputReadOnly() => LayrzTextInput(
  labelText: 'Read-only',
  controller: TextEditingController(text: 'Read-only text'),
  readOnly: true,
);

/// Displays the [LayrzTextInput] with required field indicator.
@Preview(
  name: 'Required',
  theme: LayrzPreviewTheme.light,
)
Widget previewLayrzTextInputRequired() => LayrzTextInput(
  labelText: 'Username',
  hintText: 'Your username',
  isRequired: true,
);
