import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Displays all [LayrzButton] styles, semantic factories, and interaction states.
///
/// Demonstrates button styles dynamically generated from [LayrzButtonStyle.values],
/// all six semantic factories with both normal and Fab layouts, loading/cooldown states
/// with live toggle controls, disabled states, custom colors, and tooltips.
Widget buildButtonsSection() {
  return Builder(
    builder: (context) {
      return const _ButtonsSectionContent();
    },
  );
}

/// A stateful widget that owns [ValueNotifier]s for loading and cooldown states.
///
/// This allows the showroom to demonstrate live state changes on buttons with
/// external listenable ownership — the key behavioural difference between buttons
/// in layrz_ui and previous implementations.
class _ButtonsSectionContent extends StatefulWidget {
  /// Creates a new [_ButtonsSectionContent].
  const _ButtonsSectionContent();

  @override
  State<_ButtonsSectionContent> createState() => _ButtonsSectionContentState();
}

class _ButtonsSectionContentState extends State<_ButtonsSectionContent> {
  late ValueNotifier<bool> _isLoading;
  late ValueNotifier<bool> _isCooldown;

  @override
  void initState() {
    super.initState();
    _isLoading = ValueNotifier<bool>(false);
    _isCooldown = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _isLoading.dispose();
    _isCooldown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Buttons',
      description: 'Material-free button component with ten styles, semantic factories, and live state indicators',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. All ten styles
          _StylesDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp32),

          // 2. Semantic factories (normal and mobile)
          _SemanticFactoriesDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp32),

          // 3. Live loading state
          _LoadingDemo(
            tokens: tokens,
            isLoading: _isLoading,
          ),

          SizedBox(height: tokens.spacing.sp32),

          // 4. Live cooldown state
          _CooldownDemo(
            tokens: tokens,
            isCooldown: _isCooldown,
          ),

          SizedBox(height: tokens.spacing.sp32),

          // 5. Disabled states
          _DisabledStatesDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp32),

          // 6. Icon + label vs icon-only vs label-only
          _IconLabelVariantsDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp32),

          // 7. Custom color
          _CustomColorDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp32),

          // 8. Long label with ellipsis
          _LongLabelDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp32),

          // 9. Tooltip demonstration
          _TooltipDemo(tokens: tokens),
        ],
      ),
    );
  }
}

/// Demonstrates all ten [LayrzButtonStyle] values.
class _StylesDemo extends StatelessWidget {
  /// Creates a new [_StylesDemo].
  const _StylesDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('All Styles (from LayrzButtonStyle.values)', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Wrap(
          spacing: tokens.spacing.sp12,
          runSpacing: tokens.spacing.sp12,
          children: LayrzButtonStyle.values
              .map(
                (style) => LayrzButton(
                  labelText: style.toString().split('.').last,
                  style: style,
                  onTap: () {},
                  color: tokens.colors.primary,
                  hintText: style.toString().split('.').last,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

/// Demonstrates the six semantic factories with both normal and Fab layouts.
class _SemanticFactoriesDemo extends StatelessWidget {
  /// Creates a new [_SemanticFactoriesDemo].
  const _SemanticFactoriesDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    final semanticButtons = [
      ('Save', () => LayrzButton.save(labelText: 'Save', onTap: () {})),
      ('Cancel', () => LayrzButton.cancel(labelText: 'Cancel', onTap: () {})),
      ('Info', () => LayrzButton.info(labelText: 'Info', onTap: () {})),
      ('Show', () => LayrzButton.show(labelText: 'Show', onTap: () {})),
      ('Edit', () => LayrzButton.edit(labelText: 'Edit', onTap: () {})),
      ('Delete', () => LayrzButton.delete(labelText: 'Delete', onTap: () {})),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Semantic Factories', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),

        // Normal layout
        Text('Normal Layout', style: tokens.typography.labelMedium),
        SizedBox(height: tokens.spacing.sp8),
        Wrap(
          spacing: tokens.spacing.sp12,
          runSpacing: tokens.spacing.sp12,
          children: semanticButtons.map((e) => e.$2()).toList(),
        ),

        SizedBox(height: tokens.spacing.sp16),

        // Mobile (Fab) layout
        Text('Mobile / Fab Layout', style: tokens.typography.labelMedium),
        SizedBox(height: tokens.spacing.sp8),
        Wrap(
          spacing: tokens.spacing.sp12,
          runSpacing: tokens.spacing.sp12,
          children: semanticButtons
              .map(
                (e) => LayrzButton.save(
                  labelText: e.$1,
                  isFab: true,
                  onTap: () {},
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

/// Demonstrates live loading state with an external [ValueNotifier].
class _LoadingDemo extends StatelessWidget {
  /// Creates a new [_LoadingDemo].
  const _LoadingDemo({required this.tokens, required this.isLoading});

  /// The design system tokens.
  final LayrzTokens tokens;

  /// The external [ValueNotifier] that drives the loading state.
  final ValueNotifier<bool> isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Loading State (External Listenable)', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'The button disables itself and shows an indeterminate progress bar when loading. '
          'The loading state is owned externally—the button never ends loading by itself.',
          style: tokens.typography.bodySmall.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.sp16,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, isLoadingValue, _) {
                return LayrzButton(
                  labelText: isLoadingValue ? 'Stop Loading' : 'Start Loading',
                  style: LayrzButtonStyle.filledTonal,
                  onTap: () => isLoading.value = !isLoading.value,
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, isLoadingValue, _) {
                return SizedBox(
                  width: 200,
                  child: LayrzButton(
                    labelText: 'Processing...',
                    icon: LayrzIcons.solarOutlineDownloadSquare,
                    onTap: () {},
                    isLoading: isLoading,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates live cooldown state with an external [ValueNotifier].
class _CooldownDemo extends StatelessWidget {
  /// Creates a new [_CooldownDemo].
  const _CooldownDemo({required this.tokens, required this.isCooldown});

  /// The design system tokens.
  final LayrzTokens tokens;

  /// The external [ValueNotifier] that drives the cooldown state.
  final ValueNotifier<bool> isCooldown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cooldown State (External Listenable)', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'Cooldown is an externally-driven overlay that never completes on its own. '
          'It is tinted with fg3 to visually distinguish it from loading.',
          style: tokens.typography.bodySmall.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.sp16,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: isCooldown,
              builder: (context, isCooldownValue, _) {
                return LayrzButton(
                  labelText: isCooldownValue ? 'Clear Cooldown' : 'Start Cooldown',
                  style: LayrzButtonStyle.outlined,
                  onTap: () => isCooldown.value = !isCooldown.value,
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isCooldown,
              builder: (context, _, _) {
                return SizedBox(
                  width: 200,
                  child: LayrzButton(
                    labelText: 'Try again later',
                    icon: LayrzIcons.solarOutlineClockCircle,
                    onTap: () {},
                    isCooldown: isCooldown,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates disabled button states.
class _DisabledStatesDemo extends StatelessWidget {
  /// Creates a new [_DisabledStatesDemo].
  const _DisabledStatesDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Disabled States', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'Buttons disable via onTap: null or isDisabled: true. Both mechanisms prevent interaction.',
          style: tokens.typography.bodySmall.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp12),
        Row(
          spacing: tokens.spacing.sp16,
          children: [
            LayrzButton(
              labelText: 'Disabled (onTap: null)',
              onTap: null,
            ),
            LayrzButton(
              labelText: 'Disabled (flag)',
              isDisabled: true,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates icon-only, label-only, and combined icon + label variants.
class _IconLabelVariantsDemo extends StatelessWidget {
  /// Creates a new [_IconLabelVariantsDemo].
  const _IconLabelVariantsDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Icon & Label Variants', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Wrap(
          spacing: tokens.spacing.sp12,
          runSpacing: tokens.spacing.sp12,
          children: [
            LayrzButton(
              labelText: 'Icon + Label',
              icon: LayrzIcons.solarOutlineInboxIn,
              onTap: () {},
            ),
            LayrzButton(
              labelText: 'Icon Only',
              icon: LayrzIcons.solarOutlineEyeScan,
              onTap: () {},
              style: LayrzButtonStyle.filledTonal,
            ),
            LayrzButton(
              labelText: 'Label Only',
              onTap: () {},
              style: LayrzButtonStyle.outlined,
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates custom accent color override.
class _CustomColorDemo extends StatelessWidget {
  /// Creates a new [_CustomColorDemo].
  const _CustomColorDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Custom Color', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'The color parameter overrides the default primary or semantic accent.',
          style: tokens.typography.bodySmall.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp12),
        Wrap(
          spacing: tokens.spacing.sp12,
          runSpacing: tokens.spacing.sp12,
          children: [
            LayrzButton(
              labelText: 'Success Color',
              onTap: () {},
              color: tokens.colors.success,
            ),
            LayrzButton(
              labelText: 'Warning Color',
              onTap: () {},
              color: tokens.colors.warning,
            ),
            LayrzButton(
              labelText: 'Danger Color',
              onTap: () {},
              color: tokens.colors.danger,
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates a button with a long label that ellipsises.
class _LongLabelDemo extends StatelessWidget {
  /// Creates a new [_LongLabelDemo].
  const _LongLabelDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Long Label (Constrained Width)', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'When constrained, long labels ellipsize gracefully without breaking the button layout.',
          style: tokens.typography.bodySmall.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp12),
        SizedBox(
          width: 200,
          child: LayrzButton(
            labelText: 'This is a very long button label that should ellipsize',
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

/// Demonstrates the hintText tooltip on a non-Fab button.
class _TooltipDemo extends StatelessWidget {
  /// Creates a new [_TooltipDemo].
  const _TooltipDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tooltip via hintText', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'Non-Fab buttons show hintText as a tooltip on hover/long-press. '
          'Fab buttons always show labelText as a tooltip.',
          style: tokens.typography.bodySmall.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp12),
        Wrap(
          spacing: tokens.spacing.sp12,
          runSpacing: tokens.spacing.sp12,
          children: [
            LayrzButton(
              labelText: 'Hover me',
              icon: LayrzIcons.solarOutlineQuestionSquare,
              onTap: () {},
              hintText: 'This is a helpful tooltip',
              tooltipEnabled: true,
            ),
            LayrzButton(
              labelText: 'No tooltip',
              icon: LayrzIcons.solarOutlineCloseSquare,
              onTap: () {},
              hintText: 'This text is ignored',
              tooltipEnabled: false,
            ),
          ],
        ),
      ],
    );
  }
}
