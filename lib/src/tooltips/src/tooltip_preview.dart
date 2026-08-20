import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/preview/preview.dart';

/// Preview of [LayrzTooltip] in light theme.
///
/// Demonstrates the tooltip surface styling and positioning below the anchor.
@Preview(
  name: 'Light',
  size: Size(300, 200),
  theme: layrzPreviewLightTheme,
)
Widget previewLayrzTooltip() {
  return Overlay(
    initialEntries: [
      OverlayEntry(
        builder: (context) => Center(
          child: LayrzTooltip(
            contentText: 'Tooltip text',
            child: Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Anchor',
                  style: TextStyle(color: Color(0xFFFFFFFF)),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
