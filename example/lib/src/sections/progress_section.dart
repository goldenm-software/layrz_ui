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
/// - The centered value label (`showLabel`/`decimals`, DESIGN-169): a labeled
///   bar, `decimals` 0/1/2 side by side, a ~50% value where the label crosses
///   the fill/track boundary, and confirmation that indeterminate mode never
///   shows a label since there is no percentage to show
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
          _ValueLabelShowcase(tokens: tokens),
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

/// Showcase of the centered value label added by DESIGN-169
/// ([LayrzProgressBar.showLabel] / [LayrzProgressBar.decimals]).
///
/// Covers, in order:
/// - `showLabel: true` on a linear determinate bar -- the feature itself
/// - `decimals` 0, 1, and 2 at the same value, so the formatting difference
///   between e.g. `'42%'`, `'42.0%'`, and `'42.00%'` is directly comparable
/// - A ~50% value, where the label text crosses the fill/track boundary and
///   the two-tone contrast treatment (a different color over the filled
///   portion versus the unfilled track) is visible
/// - The label suppressed on the indeterminate form, since a percentage is
///   meaningless while progress is unknown -- `showLabel: true` is passed
///   here deliberately, to demonstrate that the widget ignores it rather
///   than merely omitting the flag
///
/// `showLabel` only applies to the linear, determinate form -- see
/// [LayrzProgressBar.showLabel]'s own doc. It is not demonstrated on the
/// circular format here for that reason; the circular showcase below stays
/// label-free.
class _ValueLabelShowcase extends StatelessWidget {
  /// Design tokens used to style the showcase's own text.
  final LayrzTokens tokens;

  /// Creates a new [_ValueLabelShowcase].
  const _ValueLabelShowcase({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp2,
      children: [
        Text('Value Label (showLabel / decimals)', style: tokens.typography.title),
        Text('showLabel: true', style: tokens.typography.label),
        const LayrzProgressBar(
          value: 0.68,
          showLabel: true,
          semanticLabel: 'Labeled progress demo',
        ),
        SizedBox(height: tokens.spacing.sp1),
        Text('decimals: 0, 1, 2 -- same value (0.6789)', style: tokens.typography.label),
        Column(
          spacing: tokens.spacing.sp2,
          children: const [
            LayrzProgressBar(
              value: 0.6789,
              showLabel: true,
              decimals: 0,
              semanticLabel: 'Decimals: 0',
            ),
            LayrzProgressBar(
              value: 0.6789,
              showLabel: true,
              decimals: 1,
              semanticLabel: 'Decimals: 1',
            ),
            LayrzProgressBar(
              value: 0.6789,
              showLabel: true,
              decimals: 2,
              semanticLabel: 'Decimals: 2',
            ),
          ],
        ),
        SizedBox(height: tokens.spacing.sp1),
        Text(
          '~50% -- the label text crosses the fill/track boundary, showing the two-tone '
          'contrast treatment',
          style: tokens.typography.label,
        ),
        const LayrzProgressBar(
          value: 0.5,
          showLabel: true,
          type: LayrzProgressType.success,
          semanticLabel: 'Boundary-crossing label demo',
        ),
        SizedBox(height: tokens.spacing.sp1),
        Text(
          'Indeterminate -- showLabel is ignored, since there is no percentage to show',
          style: tokens.typography.label,
        ),
        const LayrzProgressBar(
          showLabel: true,
          semanticLabel: 'Indeterminate with showLabel ignored',
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
