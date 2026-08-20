import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/preview/preview.dart';

/// Preview of a [LayrzText] widget displaying plain text.
@Preview(name: 'Plain Text', size: Size(400, 120), theme: layrzPreviewLightTheme)
Widget previewLayrzTextPlain() {
  return const LayrzText(
    'This is a simple text widget. Try selecting the text!',
  );
}

/// Preview of a [LayrzText] widget displaying rich text with [TextSpan] styling.
@Preview(name: 'Rich Text', size: Size(400, 120), theme: layrzPreviewLightTheme)
Widget previewLayrzTextRich() {
  return LayrzText.rich(
    TextSpan(
      text: 'This is ',
      children: [
        TextSpan(
          text: 'rich text',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: ' with mixed '),
        TextSpan(
          text: 'styles',
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            color: Color(0xFFDD0000),
          ),
        ),
        const TextSpan(text: '.'),
      ],
    ),
  );
}

/// Preview of a [LayrzText] widget displaying a long paragraph with soft wrapping.
@Preview(name: 'Paragraph', size: Size(400, 200), theme: layrzPreviewLightTheme)
Widget previewLayrzTextParagraph() {
  return const SizedBox(
    width: 300,
    child: LayrzText(
      'This is a longer paragraph that demonstrates how LayrzText handles text wrapping. '
      'You can select any part of this text and copy it to the clipboard. '
      'Try it out by dragging your cursor across the text!',
    ),
  );
}
