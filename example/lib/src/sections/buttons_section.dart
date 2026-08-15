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

/// A stateful widget that owns [LayrzButtonController]s for loading and cooldown states.
///
/// This allows the showroom to demonstrate live state changes on buttons with
/// controller ownership — the key behavioural difference between buttons
/// in layrz_ui and previous implementations.
class _ButtonsSectionContent extends StatefulWidget {
  /// Creates a new [_ButtonsSectionContent].
  const _ButtonsSectionContent();

  @override
  State<_ButtonsSectionContent> createState() => _ButtonsSectionContentState();
}

class _ButtonsSectionContentState extends State<_ButtonsSectionContent> {
  late LayrzButtonController _loadingController;
  late LayrzButtonController _cooldownController;
  late LayrzButtonController _sharedFormController;

  @override
  void initState() {
    super.initState();
    _loadingController = LayrzButtonController();
    _cooldownController = LayrzButtonController();
    _sharedFormController = LayrzButtonController();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _cooldownController.dispose();
    _sharedFormController.dispose();
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
            controller: _loadingController,
          ),

          SizedBox(height: tokens.spacing.sp32),

          // 4. Live cooldown state
          _CooldownDemo(
            tokens: tokens,
            controller: _cooldownController,
          ),

          SizedBox(height: tokens.spacing.sp32),

          // 5. Shared controller driving multiple buttons
          _SharedControllerDemo(
            tokens: tokens,
            controller: _sharedFormController,
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
                  icon: LayrzIcons.solarOutlineCheckCircle,
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
    /// A list of semantic factory buttons parameterized by isFab.
    /// Each tuple contains a label and a builder function that accepts
    /// an isFab flag, ensuring both normal and Fab layouts are driven
    /// from a single source of truth.
    final semanticButtons = <(String, LayrzButton Function({required bool isFab}))>[
      (
        'Save',
        ({required bool isFab}) => LayrzButton.save(labelText: 'Save', isFab: isFab, onTap: () {}),
      ),
      (
        'Cancel',
        ({required bool isFab}) => LayrzButton.cancel(labelText: 'Cancel', isFab: isFab, onTap: () {}),
      ),
      (
        'Info',
        ({required bool isFab}) => LayrzButton.info(labelText: 'Info', isFab: isFab, onTap: () {}),
      ),
      (
        'Show',
        ({required bool isFab}) => LayrzButton.show(labelText: 'Show', isFab: isFab, onTap: () {}),
      ),
      (
        'Edit',
        ({required bool isFab}) => LayrzButton.edit(labelText: 'Edit', isFab: isFab, onTap: () {}),
      ),
      (
        'Delete',
        ({required bool isFab}) => LayrzButton.delete(labelText: 'Delete', isFab: isFab, onTap: () {}),
      ),
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
          children: semanticButtons.map((e) => e.$2(isFab: false)).toList(),
        ),

        SizedBox(height: tokens.spacing.sp16),

        // Mobile (Fab) layout
        Text('Mobile / Fab Layout', style: tokens.typography.labelMedium),
        SizedBox(height: tokens.spacing.sp8),
        Wrap(
          spacing: tokens.spacing.sp12,
          runSpacing: tokens.spacing.sp12,
          children: semanticButtons.map((e) => e.$2(isFab: true)).toList(),
        ),
      ],
    );
  }
}

/// Demonstrates live loading state with a [LayrzButtonController].
class _LoadingDemo extends StatelessWidget {
  /// Creates a new [_LoadingDemo].
  const _LoadingDemo({required this.tokens, required this.controller});

  /// The design system tokens.
  final LayrzTokens tokens;

  /// The controller that drives the loading state.
  final LayrzButtonController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Loading State (Controller)', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'The button disables itself and shows an indeterminate progress bar when loading. '
          'The loading state is driven by the controller.',
          style: tokens.typography.bodySmall.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.sp16,
          children: [
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return LayrzButton(
                  labelText: controller.isLoading ? 'Stop Loading' : 'Start Loading',
                  style: LayrzButtonStyle.filledTonal,
                  onTap: () {
                    if (controller.isLoading) {
                      controller.stopLoading();
                    } else {
                      controller.startLoading();
                    }
                  },
                );
              },
            ),
            SizedBox(
              width: 200,
              child: LayrzButton(
                labelText: 'Processing...',
                icon: LayrzIcons.solarOutlineDownloadSquare,
                onTap: () {},
                controller: controller,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates live cooldown state with a [LayrzButtonController].
class _CooldownDemo extends StatelessWidget {
  /// Creates a new [_CooldownDemo].
  const _CooldownDemo({required this.tokens, required this.controller});

  /// The design system tokens.
  final LayrzTokens tokens;

  /// The controller that drives the cooldown state.
  final LayrzButtonController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cooldown State (Controller)', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'Cooldown runs a countdown over a Duration. When the countdown finishes, '
          'it auto-clears and the button re-enables. The controller manages the timing.',
          style: tokens.typography.bodySmall.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.sp16,
          children: [
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final isActive = controller.cooldownTotal != null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: tokens.spacing.sp8,
                  children: [
                    LayrzButton(
                      labelText: isActive ? 'Clear Cooldown' : 'Start 5s Cooldown',
                      style: LayrzButtonStyle.outlined,
                      onTap: () {
                        if (isActive) {
                          controller.clearCooldown();
                        } else {
                          controller.startCooldown(const Duration(seconds: 5));
                        }
                      },
                    ),
                  ],
                );
              },
            ),
            SizedBox(
              width: 200,
              child: LayrzButton(
                labelText: 'Try again later',
                icon: LayrzIcons.solarOutlineClockCircle,
                onTap: () {},
                controller: controller,
              ),
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
              labelText: 'With tooltip',
              icon: LayrzIcons.solarOutlineQuestionSquare,
              onTap: () {},
              hintText: 'This is a helpful hint',
            ),
            LayrzButton(
              labelText: 'No tooltip',
              icon: LayrzIcons.solarOutlineCloseSquare,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates one controller driving three buttons in lockstep.
///
/// This is the headline feature: all three buttons move together, with no frame-by-frame drift.
class _SharedControllerDemo extends StatelessWidget {
  /// Creates a new [_SharedControllerDemo].
  const _SharedControllerDemo({required this.tokens, required this.controller});

  /// The design system tokens.
  final LayrzTokens tokens;

  /// The single controller shared by all three buttons.
  final LayrzButtonController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('One Controller, Three Buttons (Lockstep Busy State)', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'All three buttons share the same controller. When you activate loading or cooldown, '
          'all three respond together—no drift, no flicker. Perfect for form groups where all actions '
          'should disable together.',
          style: tokens.typography.bodySmall.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.sp16,
          children: [
            // Control buttons
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return Row(
                  spacing: tokens.spacing.sp12,
                  children: [
                    LayrzButton(
                      labelText: controller.isLoading ? 'Stop Loading' : 'Start Loading',
                      style: LayrzButtonStyle.outlined,
                      onTap: () {
                        if (controller.isLoading) {
                          controller.stopLoading();
                        } else {
                          controller.startLoading();
                        }
                      },
                    ),
                    LayrzButton(
                      labelText: controller.cooldownTotal != null ? 'Clear Cooldown' : 'Start 3s Cooldown',
                      style: LayrzButtonStyle.outlined,
                      onTap: () {
                        if (controller.cooldownTotal != null) {
                          controller.clearCooldown();
                        } else {
                          controller.startCooldown(const Duration(seconds: 3));
                        }
                      },
                    ),
                  ],
                );
              },
            ),
            // Shared buttons (all three use the same controller)
            Row(
              spacing: tokens.spacing.sp12,
              children: [
                LayrzButton.save(
                  labelText: 'Save',
                  controller: controller,
                  onTap: () {},
                ),
                LayrzButton.cancel(
                  labelText: 'Cancel',
                  controller: controller,
                  onTap: () {},
                ),
                LayrzButton.delete(
                  labelText: 'Delete',
                  controller: controller,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
