import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';

import 'package:layrz_ui/preview.dart';

/// Preview of [LayrzButton] with different style variants.
@Preview(name: 'Styles', theme: LayrzPreviewTheme.light)
Widget previewLayrzButtonStyles() {
  return _PreviewButtonStyles();
}

/// Helper widget displaying [LayrzButton] style variants.
class _PreviewButtonStyles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LayrzButton(
          labelText: 'Elevated',
          icon: LayrzIcons.solarOutlineCheckCircle,
          onTap: () {},
          style: LayrzButtonStyle.elevated,
        ),
        const SizedBox(height: 12),
        LayrzButton(
          labelText: 'Outlined Tonal',
          icon: LayrzIcons.solarOutlineCheckCircle,
          onTap: () {},
          style: LayrzButtonStyle.outlinedTonal,
        ),
      ],
    );
  }
}

/// Preview of [LayrzButton] semantic factories.
@Preview(name: 'Semantic', theme: LayrzPreviewTheme.light)
Widget previewLayrzButtonSemantic() {
  return _PreviewSemantic();
}

/// Helper widget displaying [LayrzButton] semantic factory examples.
class _PreviewSemantic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LayrzButton.save(labelText: 'Save', onTap: () {}),
        const SizedBox(width: 12),
        LayrzButton.cancel(labelText: 'Cancel', onTap: () {}),
      ],
    );
  }
}
