import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds a comprehensive showroom section demonstrating [LayrzProgressBar].
///
/// This section displays:
/// - Determinate mode with a slider-free, timer-driven demo value
/// - Indeterminate mode (a permanent loading sweep)
/// - All six semantic types (info, success, warning, danger, context, custom)
/// - A custom height and border radius override
/// - Circular mode: determinate and indeterminate rings, a couple of
///   semantic colors, and a size/thickness override
class ProgressSection extends StatefulWidget {
  /// Creates a new [ProgressSection].
  const ProgressSection({super.key});

  @override
  State<ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<ProgressSection> {
  double _demoValue = 0.35;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Progress Bar',
      description: 'Determinate and indeterminate linear progress indicators',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spacing.sp4,
        children: [
          _DeterminateShowcase(
            tokens: tokens,
            value: _demoValue,
            onValueChanged: (value) => setState(() => _demoValue = value),
          ),
          _IndeterminateShowcase(tokens: tokens),
          _TypesShowcase(tokens: tokens),
          const _CustomizationShowcase(),
          _CircularShowcase(
            tokens: tokens,
            value: _demoValue,
            onValueChanged: (value) => setState(() => _demoValue = value),
          ),
        ],
      ),
    );
  }
}

/// Showcase of determinate mode, with buttons to step the demo value.
class _DeterminateShowcase extends StatelessWidget {
  /// Design tokens used to style the showcase's own text.
  final LayrzTokens tokens;

  /// The current demo progress value, in `[0.0, 1.0]`.
  final double value;

  /// Invoked with a new demo progress value when a step button is tapped.
  final ValueChanged<double> onValueChanged;

  const _DeterminateShowcase({
    required this.tokens,
    required this.value,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp2,
      children: [
        Text('Determinate', style: tokens.typography.title),
        LayrzProgressBar(value: value, semanticLabel: 'Demo progress'),
        Row(
          spacing: tokens.spacing.sp2,
          children: [
            LayrzButton(
              labelText: '-10%',
              onTap: () => onValueChanged((value - 0.1).clamp(0.0, 1.0)),
            ),
            LayrzButton(
              labelText: '+10%',
              onTap: () => onValueChanged((value + 0.1).clamp(0.0, 1.0)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Showcase of indeterminate mode, looping for as long as this section is mounted.
class _IndeterminateShowcase extends StatelessWidget {
  final LayrzTokens tokens;

  const _IndeterminateShowcase({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp2,
      children: [
        Text('Indeterminate (value: null)', style: tokens.typography.title),
        const LayrzProgressBar(),
      ],
    );
  }
}

/// Showcase of the six semantic types.
class _TypesShowcase extends StatelessWidget {
  final LayrzTokens tokens;

  const _TypesShowcase({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp2,
      children: [
        Text('Semantic Types', style: tokens.typography.title),
        Column(
          spacing: tokens.spacing.sp2,
          children: [
            for (final progressType in LayrzProgressType.values)
              LayrzProgressBar(
                value: 0.6,
                type: progressType,
                color: progressType == LayrzProgressType.custom ? tokens.colors.primary.shade700 : null,
                semanticLabel: progressType.name,
              ),
          ],
        ),
      ],
    );
  }
}

/// Showcase of a custom height and border radius.
class _CustomizationShowcase extends StatelessWidget {
  const _CustomizationShowcase();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp2,
      children: [
        Text('Custom Height & Border Radius', style: tokens.typography.title),
        LayrzProgressBar(
          value: 0.5,
          height: 20.0,
          borderRadius: tokens.radius.r1,
          type: LayrzProgressType.success,
          semanticLabel: 'Custom style demo',
        ),
      ],
    );
  }
}

/// Showcase of circular mode: determinate and indeterminate rings, a couple
/// of semantic colors, and a size/thickness override.
class _CircularShowcase extends StatelessWidget {
  /// Design tokens used to style the showcase's own text.
  final LayrzTokens tokens;

  /// The current demo progress value, in `[0.0, 1.0]`, shared with the linear
  /// determinate showcase above.
  final double value;

  /// Invoked with a new demo progress value when a step button is tapped.
  final ValueChanged<double> onValueChanged;

  /// Creates a new [_CircularShowcase].
  const _CircularShowcase({
    required this.tokens,
    required this.value,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp2,
      children: [
        Text('Circular Mode', style: tokens.typography.title),
        Row(
          spacing: tokens.spacing.sp4,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              spacing: tokens.spacing.sp2,
              children: [
                LayrzProgressBar(
                  value: value,
                  format: LayrzProgressFormat.circular,
                  semanticLabel: 'Demo circular progress',
                ),
                Text('Determinate', style: tokens.typography.label),
              ],
            ),
            Column(
              spacing: tokens.spacing.sp2,
              children: [
                const LayrzProgressBar(format: LayrzProgressFormat.circular),
                Text('Indeterminate', style: tokens.typography.label),
              ],
            ),
            Column(
              spacing: tokens.spacing.sp2,
              children: [
                LayrzProgressBar(
                  value: 0.7,
                  format: LayrzProgressFormat.circular,
                  type: LayrzProgressType.success,
                  semanticLabel: 'Success circular progress',
                ),
                Text('Success', style: tokens.typography.label),
              ],
            ),
            Column(
              spacing: tokens.spacing.sp2,
              children: [
                LayrzProgressBar(
                  value: 0.4,
                  format: LayrzProgressFormat.circular,
                  type: LayrzProgressType.danger,
                  semanticLabel: 'Danger circular progress',
                ),
                Text('Danger', style: tokens.typography.label),
              ],
            ),
            Column(
              spacing: tokens.spacing.sp2,
              children: [
                LayrzProgressBar(
                  value: 0.6,
                  format: LayrzProgressFormat.circular,
                  size: 90.0,
                  strokeWidth: 10.0,
                  type: LayrzProgressType.custom,
                  color: tokens.colors.primary.shade700,
                  semanticLabel: 'Custom size circular progress',
                ),
                Text('Size 90 / stroke 10', style: tokens.typography.label),
              ],
            ),
          ],
        ),
        Row(
          spacing: tokens.spacing.sp2,
          children: [
            LayrzButton(
              labelText: '-10%',
              onTap: () => onValueChanged((value - 0.1).clamp(0.0, 1.0)),
            ),
            LayrzButton(
              labelText: '+10%',
              onTap: () => onValueChanged((value + 0.1).clamp(0.0, 1.0)),
            ),
          ],
        ),
      ],
    );
  }
}
