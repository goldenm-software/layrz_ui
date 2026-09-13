import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';
import '../providers/colorblind_provider.dart';

/// Human-readable labels for every [ColorblindMode], keyed in declaration
/// order so the in-page picker and the layout's user-chrome dropdown describe
/// each mode identically.
const Map<ColorblindMode, String> _kModeLabels = {
  ColorblindMode.normal: 'Typical vision',
  ColorblindMode.protanopia: 'Protanopia (red-blind)',
  ColorblindMode.protanomaly: 'Protanomaly (red-weak)',
  ColorblindMode.deuteranopia: 'Deuteranopia (green-blind)',
  ColorblindMode.deuteranomaly: 'Deuteranomaly (green-weak)',
  ColorblindMode.tritanopia: 'Tritanopia (blue-blind)',
  ColorblindMode.tritanomaly: 'Tritanomaly (blue-weak)',
};

/// Foundation showcase page for the library's colorblind-mode simulation
/// (BETA).
///
/// Demonstrates [ColorblindMode] and the `colorblindMode`/`colorblindStrength`
/// parameters wired into [ShowroomApp]'s [LayrzApp.router] call: picking a
/// mode or dragging the strength slider here re-renders the *entire*
/// showroom app under the simulated color filter, not just this page, since
/// both values are read from [colorblindModeProvider] and
/// [colorblindStrengthProvider] at the app root.
class ColorblindSection extends ConsumerWidget {
  /// Creates a new [ColorblindSection].
  const ColorblindSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final mode = ref.watch(colorblindModeProvider);
    final strength = ref.watch(colorblindStrengthProvider);

    return ShowroomSection(
      title: 'Colorblind Mode (Beta)',
      description: 'Simulates color vision deficiency across the whole app — a preview aid, not a fix',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Colorblind simulation approximates how the app looks to someone with a given form of color '
            'vision deficiency by applying a color matrix filter at the app root, via '
            "LayrzApp's `colorblindMode` and `colorblindStrength` parameters. It affects every page in "
            'this showroom, not just this one — switch modes below, then navigate elsewhere to see it '
            'follow you. This feature is in beta.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp4),

          Text('Simulation Mode', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          LayrzRadioInput<ColorblindMode>(
            labelText: 'Mode',
            items: ColorblindMode.values
                .map((value) => LayrzSelectItem(value: value, child: Text(_kModeLabels[value]!)))
                .toList(),
            value: mode,
            onChanged: (value) {
              if (value != null) ref.read(colorblindModeProvider.notifier).state = value;
            },
          ),

          SizedBox(height: tokens.spacing.sp4),

          Text('Simulation Strength', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          LayrzSlider(
            labelText: 'Strength',
            value: strength,
            min: 0,
            max: 1,
            valueFormatter: (v) => '${(v * 100).round()}%',
            onChanged: (value) => ref.read(colorblindStrengthProvider.notifier).state = value,
          ),

          SizedBox(height: tokens.spacing.sp4),

          Text('Semantic Color Palette', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'These swatches use the same semantic tokens every other component draws from, so the '
            'effect of the simulation above is visible here in one place.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          _PaletteGrid(tokens: tokens),
        ],
      ),
    );
  }
}

/// A wrapping grid of labeled color swatches covering the semantic and
/// foreground/surface tokens most affected by a colorblind simulation.
class _PaletteGrid extends StatelessWidget {
  /// Creates a new [_PaletteGrid].
  const _PaletteGrid({required this.tokens});

  /// The design tokens supplying both the swatch colors and the label styles.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    final swatches = <(String, Color)>[
      ('primary', tokens.colors.primary),
      ('danger', tokens.colors.danger),
      ('success', tokens.colors.success),
      ('warning', tokens.colors.warning),
      ('info', tokens.colors.info),
      ('fg1', tokens.colors.fg1),
      ('fg2', tokens.colors.fg2),
      ('sf2', tokens.colors.sf2),
      ('sf3', tokens.colors.sf3),
    ];

    return Wrap(
      spacing: tokens.spacing.sp3,
      runSpacing: tokens.spacing.sp3,
      children: [
        for (final (label, color) in swatches) _PaletteSwatch(label: label, color: color, tokens: tokens),
      ],
    );
  }
}

/// A single named color swatch tile.
class _PaletteSwatch extends StatelessWidget {
  /// Creates a new [_PaletteSwatch].
  const _PaletteSwatch({required this.label, required this.color, required this.tokens});

  /// The token name shown beneath the swatch.
  final String label;

  /// The color rendered by the swatch.
  final Color color;

  /// The design tokens for consistent styling.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: tokens.radius.br2,
            border: Border.all(color: tokens.colors.divider, width: tokens.border.stroke1),
          ),
        ),
        SizedBox(height: tokens.spacing.sp1),
        Text(label, style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
      ],
    );
  }
}
