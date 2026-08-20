import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/preview/preview.dart';

/// Preview of [LayrzButton] with different style variants.
@Preview(name: 'Styles', size: Size(400, 150), theme: layrzPreviewLightTheme)
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
@Preview(name: 'Semantic', size: Size(400, 150), theme: layrzPreviewLightTheme)
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
