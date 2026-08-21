import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/preview/preview.dart';

/// Preview of [LayrzChip] with different style variants.
@Preview(name: 'Styles', size: Size(500, 150), theme: layrzPreviewLightTheme)
Widget previewChipStyles() {
  return _PreviewChipStyles();
}

/// Helper widget displaying [LayrzChip] style variants.
class _PreviewChipStyles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              LayrzChip(
                labelText: 'Filled',
                style: LayrzChipStyle.filled,
                type: LayrzChipType.info,
              ),
              LayrzChip(
                labelText: 'Outlined',
                style: LayrzChipStyle.outlined,
                type: LayrzChipType.success,
              ),
              LayrzChip(
                labelText: 'Tonal',
                style: LayrzChipStyle.filledTonal,
                type: LayrzChipType.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Preview of [LayrzChip] with different semantic types.
@Preview(name: 'Types', size: Size(500, 250), theme: layrzPreviewLightTheme)
Widget previewChipTypes() {
  return _PreviewChipTypes();
}

/// Helper widget displaying [LayrzChip] type variants.
class _PreviewChipTypes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              LayrzChip(labelText: 'Info', type: LayrzChipType.info),
              LayrzChip(labelText: 'Success', type: LayrzChipType.success),
              LayrzChip(labelText: 'Warning', type: LayrzChipType.warning),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              LayrzChip(labelText: 'Danger', type: LayrzChipType.danger),
              LayrzChip(labelText: 'Context', type: LayrzChipType.context),
              LayrzChip(labelText: 'Custom', type: LayrzChipType.custom),
            ],
          ),
        ],
      ),
    );
  }
}

/// Preview of [LayrzChip] with leading icon and delete affordance.
@Preview(name: 'Features', size: Size(500, 250), theme: layrzPreviewLightTheme)
Widget previewChipFeatures() {
  return _PreviewChipFeatures();
}

/// Helper widget displaying [LayrzChip] with optional features.
class _PreviewChipFeatures extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              LayrzChip(
                labelText: 'With Icon',
                leadingIcon: MdiIcons.checkCircleOutline,
                type: LayrzChipType.success,
              ),
              LayrzChip(
                labelText: 'Deletable',
                onDelete: () {},
                type: LayrzChipType.warning,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              LayrzChip(
                labelText: 'Both',
                leadingIcon: MdiIcons.checkCircleOutline,
                onDelete: () {},
                type: LayrzChipType.info,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Preview of [LayrzChipGroup] with scrollable behavior.
@Preview(name: 'Group Scrollable', size: Size(400, 250), theme: layrzPreviewLightTheme)
Widget previewChipGroupScrollable() {
  return _PreviewChipGroupScrollable();
}

/// Helper widget displaying [LayrzChipGroup] in scrollable mode.
class _PreviewChipGroupScrollable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 16,
      children: [
        Text('Scrollable Group (many chips):'),
        LayrzChipGroup(
          chips: [
            LayrzChip(labelText: 'Chip 1', type: LayrzChipType.info),
            LayrzChip(labelText: 'Chip 2', type: LayrzChipType.success),
            LayrzChip(labelText: 'Chip 3', type: LayrzChipType.warning),
            LayrzChip(labelText: 'Chip 4', type: LayrzChipType.danger),
            LayrzChip(labelText: 'Chip 5', type: LayrzChipType.context),
            LayrzChip(labelText: 'Chip 6', type: LayrzChipType.custom),
            LayrzChip(labelText: 'Chip 7', type: LayrzChipType.info),
            LayrzChip(labelText: 'Chip 8', type: LayrzChipType.success),
          ],
          behavior: LayrzChipGroupBehavior.none,
        ),
      ],
    );
  }
}

/// Preview of [LayrzChipGroup] with compact behavior.
@Preview(name: 'Group Compact', size: Size(400, 200), theme: layrzPreviewLightTheme)
Widget previewChipGroupCompact() {
  return _PreviewChipGroupCompact();
}

/// Helper widget displaying [LayrzChipGroup] in compact mode.
class _PreviewChipGroupCompact extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 16,
      children: [
        Text('Compact Group (constrained width):'),
        SizedBox(
          width: 300,
          child: LayrzChipGroup(
            chips: [
              LayrzChip(labelText: 'Chip 1', type: LayrzChipType.info),
              LayrzChip(labelText: 'Chip 2', type: LayrzChipType.success),
              LayrzChip(labelText: 'Chip 3', type: LayrzChipType.warning),
              LayrzChip(labelText: 'Chip 4', type: LayrzChipType.danger),
              LayrzChip(labelText: 'Chip 5', type: LayrzChipType.context),
              LayrzChip(labelText: 'Chip 6', type: LayrzChipType.custom),
            ],
            behavior: LayrzChipGroupBehavior.compact,
          ),
        ),
      ],
    );
  }
}
