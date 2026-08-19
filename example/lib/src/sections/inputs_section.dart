import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds a comprehensive showroom section demonstrating all LayrzTextInput features.
///
/// This section displays:
/// - All six interaction states (rest, hover, focus, error, disabled, read-only)
/// - Label and placeholder variations (with/without, isRequired)
/// - Slot forms (prefix/suffix icon, widget, and text variants)
/// - Error display (single, multiple, hidden details)
/// - Help affordance via tooltip
/// - Behavioral differences (readOnly vs disabled, onTap firing)
/// - Dense mode
/// - Shortcut badge
/// - Additional features (obscureText, keyboardType, maxLength)
Widget buildInputsSection() => _InputsSectionWidget();

/// A stateful widget that manages [TextEditingController]s and [FocusNode]s.
///
/// This allows the showroom to demonstrate all interactive states, state changes,
/// and proper resource disposal.
class _InputsSectionWidget extends StatefulWidget {
  @override
  State<_InputsSectionWidget> createState() => _InputsSectionWidgetState();
}

class _InputsSectionWidgetState extends State<_InputsSectionWidget> {
  late TextEditingController _restController;
  late TextEditingController _hoverController;
  late TextEditingController _focusController;
  late TextEditingController _errorController;
  late TextEditingController _disabledController;
  late TextEditingController _readOnlyController;
  late FocusNode _restFocusNode;
  late FocusNode _hoverFocusNode;
  late FocusNode _focusFocusNode;
  late FocusNode _errorFocusNode;
  late FocusNode _disabledFocusNode;
  late FocusNode _readOnlyFocusNode;

  int _readOnlyTapCount = 0;
  int _disabledTapCount = 0;
  int _prefixTapCount = 0;
  int _suffixTapCount = 0;

  @override
  void initState() {
    super.initState();
    _restController = TextEditingController(text: 'Rest state');
    _hoverController = TextEditingController(text: 'Hover state');
    _focusController = TextEditingController(text: '');
    _errorController = TextEditingController(text: 'Invalid input');
    _disabledController = TextEditingController(text: 'Disabled text');
    _readOnlyController = TextEditingController(text: 'Read-only text');
    _restFocusNode = FocusNode();
    _hoverFocusNode = FocusNode();
    _focusFocusNode = FocusNode();
    _errorFocusNode = FocusNode();
    _disabledFocusNode = FocusNode();
    _readOnlyFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _restController.dispose();
    _hoverController.dispose();
    _focusController.dispose();
    _errorController.dispose();
    _disabledController.dispose();
    _readOnlyController.dispose();
    _restFocusNode.dispose();
    _hoverFocusNode.dispose();
    _focusFocusNode.dispose();
    _errorFocusNode.dispose();
    _disabledFocusNode.dispose();
    _readOnlyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Text Input',
      description: 'Single-line text input with optional label, errors, help tooltip, and interactive slots',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spacing.sp32,
        children: [
          // 1. Six-state matrix
          _SixStateMatrixShowcase(
            tokens: tokens,
            restController: _restController,
            restFocusNode: _restFocusNode,
            hoverController: _hoverController,
            hoverFocusNode: _hoverFocusNode,
            focusController: _focusController,
            focusFocusNode: _focusFocusNode,
            errorController: _errorController,
            errorFocusNode: _errorFocusNode,
            disabledController: _disabledController,
            disabledFocusNode: _disabledFocusNode,
            readOnlyController: _readOnlyController,
            readOnlyFocusNode: _readOnlyFocusNode,
          ),

          // 2. Label and placeholder variations
          _LabelAndPlaceholderShowcase(tokens: tokens),

          // 3. Prefix and suffix slot forms
          _PrefixSuffixSlotsShowcase(
            tokens: tokens,
            onPrefixTap: () {
              setState(() {
                _prefixTapCount++;
              });
            },
            onSuffixTap: () {
              setState(() {
                _suffixTapCount++;
              });
            },
            prefixTapCount: _prefixTapCount,
            suffixTapCount: _suffixTapCount,
          ),

          // 4. Error display
          _ErrorsShowcase(tokens: tokens),

          // 5. Help affordance
          _HelpAffordanceShowcase(tokens: tokens),

          // 6. ReadOnly vs Disabled behavior
          _ReadOnlyVsDisabledShowcase(
            tokens: tokens,
            readOnlyTapCount: _readOnlyTapCount,
            disabledTapCount: _disabledTapCount,
            onReadOnlyTap: () {
              setState(() {
                _readOnlyTapCount++;
              });
            },
            onDisabledTap: () {
              setState(() {
                _disabledTapCount++;
              });
            },
          ),

          // 7. Dense mode
          _DenseModeShowcase(tokens: tokens),

          // 8. Label icon
          _LabelIconShowcase(tokens: tokens),

          // 9. Shortcut badge
          _ShortcutBadgeShowcase(tokens: tokens),

          // 10. Additional features
          _AdditionalFeaturesShowcase(tokens: tokens),
        ],
      ),
    );
  }
}

/// Demonstrates all six interaction states side by side.
///
/// Shows: rest, hover, focus, error, disabled, and read-only states
/// with all colors read from design tokens and state labels for clarity.
class _SixStateMatrixShowcase extends StatelessWidget {
  final LayrzTokens tokens;
  final TextEditingController restController;
  final FocusNode restFocusNode;
  final TextEditingController hoverController;
  final FocusNode hoverFocusNode;
  final TextEditingController focusController;
  final FocusNode focusFocusNode;
  final TextEditingController errorController;
  final FocusNode errorFocusNode;
  final TextEditingController disabledController;
  final FocusNode disabledFocusNode;
  final TextEditingController readOnlyController;
  final FocusNode readOnlyFocusNode;

  const _SixStateMatrixShowcase({
    required this.tokens,
    required this.restController,
    required this.restFocusNode,
    required this.hoverController,
    required this.hoverFocusNode,
    required this.focusController,
    required this.focusFocusNode,
    required this.errorController,
    required this.errorFocusNode,
    required this.disabledController,
    required this.disabledFocusNode,
    required this.readOnlyController,
    required this.readOnlyFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp16,
      children: [
        LayrzText('Six Interaction States', style: tokens.typography.title),
        LayrzText(
          'Rest, Hover, Focus, Error, Disabled, and Read-only. Focus with autofocus; Hover requires pointer interaction.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        Column(
          spacing: tokens.spacing.sp16,
          children: [
            // Row 1: Rest, Hover, Focus
            Row(
              spacing: tokens.spacing.sp16,
              children: [
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      LayrzText('Rest', style: tokens.typography.label),
                      LayrzTextInput(
                        controller: restController,
                        labelText: 'Rest state',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      LayrzText('Hover', style: tokens.typography.label),
                      LayrzTextInput(
                        controller: hoverController,
                        hintText: 'Hover (move pointer over)',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      LayrzText('Focus', style: tokens.typography.label),
                      LayrzTextInput(
                        controller: focusController,
                        focusNode: focusFocusNode,
                        autofocus: true,
                        hintText: 'Focus (autofocus)',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Row 2: Error, Disabled, Read-only
            Row(
              spacing: tokens.spacing.sp16,
              children: [
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      LayrzText('Error', style: tokens.typography.label),
                      LayrzTextInput(
                        controller: errorController,
                        hintText: 'Error state',
                        errors: ['This is an error'],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      LayrzText('Disabled', style: tokens.typography.label),
                      LayrzTextInput(
                        controller: disabledController,
                        hintText: 'Disabled state',
                        disabled: true,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      LayrzText('Read-only', style: tokens.typography.label),
                      LayrzTextInput(
                        controller: readOnlyController,
                        hintText: 'Read-only state',
                        readOnly: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates label and placeholder variations.
///
/// Shows: with/without label, isRequired indicator, and placeholder text.
class _LabelAndPlaceholderShowcase extends StatelessWidget {
  final LayrzTokens tokens;

  const _LabelAndPlaceholderShowcase({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp16,
      children: [
        LayrzText('Label and Placeholder Variations', style: tokens.typography.title),
        Column(
          spacing: tokens.spacing.sp16,
          children: [
            Row(
              spacing: tokens.spacing.sp16,
              children: [
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      LayrzText('With Label', style: tokens.typography.label),
                      const LayrzTextInput(
                        labelText: 'Username',
                        hintText: 'Enter your username',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      LayrzText('Without Label', style: tokens.typography.label),
                      const LayrzTextInput(
                        hintText: 'No label here',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              spacing: tokens.spacing.sp16,
              children: [
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      LayrzText('Required Indicator', style: tokens.typography.label),
                      const LayrzTextInput(
                        labelText: 'Email',
                        isRequired: true,
                        hintText: 'your@email.com',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      LayrzText('No Placeholder', style: tokens.typography.label),
                      const LayrzTextInput(
                        labelText: 'Optional field',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates all prefix and suffix slot forms.
///
/// Shows: icon, widget, and text variants for both prefix and suffix,
/// with tap callbacks wired to visible counters.
class _PrefixSuffixSlotsShowcase extends StatelessWidget {
  final LayrzTokens tokens;
  final VoidCallback onPrefixTap;
  final VoidCallback onSuffixTap;
  final int prefixTapCount;
  final int suffixTapCount;

  const _PrefixSuffixSlotsShowcase({
    required this.tokens,
    required this.onPrefixTap,
    required this.onSuffixTap,
    required this.prefixTapCount,
    required this.suffixTapCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp16,
      children: [
        LayrzText('Prefix and Suffix Slot Forms', style: tokens.typography.title),
        LayrzText(
          'Prefix and suffix are mutually exclusive variants. Click prefix/suffix to increment the tap counter.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        Column(
          spacing: tokens.spacing.sp16,
          children: [
            // Prefix forms
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp8,
              children: [
                LayrzText('Prefix Variants', style: tokens.typography.label),
                Row(
                  spacing: tokens.spacing.sp16,
                  children: [
                    Expanded(
                      child: LayrzTextInput(
                        labelText: 'prefixIcon',
                        prefixIcon: LayrzIcons.solarOutlineCheckCircle,
                        onPrefixTap: onPrefixTap,
                        hintText: 'Taps: $prefixTapCount',
                      ),
                    ),
                    Expanded(
                      child: LayrzTextInput(
                        labelText: 'prefixText',
                        prefixText: '@',
                        onPrefixTap: onPrefixTap,
                        hintText: 'Taps: $prefixTapCount',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Suffix forms
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp8,
              children: [
                LayrzText('Suffix Variants', style: tokens.typography.label),
                Row(
                  spacing: tokens.spacing.sp16,
                  children: [
                    Expanded(
                      child: LayrzTextInput(
                        labelText: 'suffixIcon',
                        suffixIcon: LayrzIcons.solarOutlineEyeScan,
                        onSuffixTap: onSuffixTap,
                        hintText: 'Taps: $suffixTapCount',
                      ),
                    ),
                    Expanded(
                      child: LayrzTextInput(
                        labelText: 'suffixText',
                        suffixText: '.com',
                        onSuffixTap: onSuffixTap,
                        hintText: 'Taps: $suffixTapCount',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates error display variations.
///
/// Shows: single error, multiple errors, hideDetails suppressing the message block,
/// and error combined with a custom suffix.
class _ErrorsShowcase extends StatelessWidget {
  final LayrzTokens tokens;

  const _ErrorsShowcase({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp16,
      children: [
        LayrzText('Error Display', style: tokens.typography.title),
        Column(
          spacing: tokens.spacing.sp16,
          children: [
            Row(
              spacing: tokens.spacing.sp16,
              children: [
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      LayrzText('Single Error', style: tokens.typography.label),
                      const LayrzTextInput(
                        labelText: 'Email',
                        hintText: 'your@email.com',
                        errors: ['Invalid email format'],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      LayrzText('Multiple Errors', style: tokens.typography.label),
                      const LayrzTextInput(
                        labelText: 'Password',
                        errors: [
                          'Must be at least 8 characters',
                          'Must contain uppercase letter',
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              spacing: tokens.spacing.sp16,
              children: [
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      LayrzText('hideDetails: true', style: tokens.typography.label),
                      const LayrzTextInput(
                        labelText: 'Field',
                        hintText: 'Error hidden',
                        errors: ['Error message is suppressed'],
                        hideDetails: true,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      LayrzText('Error + Suffix', style: tokens.typography.label),
                      LayrzTextInput(
                        labelText: 'Username',
                        suffixIcon: LayrzIcons.solarOutlineCheckCircle,
                        errors: const ['Already taken'],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates the help affordance via tooltip.
///
/// Shows: help tooltip that renders on hover with title and content text.
class _HelpAffordanceShowcase extends StatelessWidget {
  final LayrzTokens tokens;

  const _HelpAffordanceShowcase({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp16,
      children: [
        LayrzText('Help Affordance', style: tokens.typography.title),
        LayrzText(
          'Hover over the input or the help icon to see the tooltip.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        const LayrzTextInput(
          labelText: 'API Key',
          hintText: 'Enter your API key',
          helpTitleText: 'What is an API Key?',
          helpContentText: 'An API key is a unique identifier used to authenticate requests to the API. Keep it secret and never share it publicly.',
        ),
      ],
    );
  }
}

/// Demonstrates the behavioral difference between readOnly and disabled.
///
/// Shows: readOnly state (fires onTap, shows lock icon, allows focus) vs
/// disabled state (does not fire onTap, no icon, no focus), with tap counters.
class _ReadOnlyVsDisabledShowcase extends StatefulWidget {
  /// Creates a new [_ReadOnlyVsDisabledShowcase].
  const _ReadOnlyVsDisabledShowcase({
    required this.tokens,
    required this.readOnlyTapCount,
    required this.disabledTapCount,
    required this.onReadOnlyTap,
    required this.onDisabledTap,
  });

  /// The design system tokens.
  final LayrzTokens tokens;

  /// The number of times the read-only field was tapped.
  final int readOnlyTapCount;

  /// The number of times the disabled field was tapped.
  final int disabledTapCount;

  /// Callback fired when the read-only field is tapped.
  final VoidCallback onReadOnlyTap;

  /// Callback fired when the disabled field is tapped.
  final VoidCallback onDisabledTap;

  @override
  State<_ReadOnlyVsDisabledShowcase> createState() => _ReadOnlyVsDisabledShowcaseState();
}

class _ReadOnlyVsDisabledShowcaseState extends State<_ReadOnlyVsDisabledShowcase> {
  late TextEditingController _readOnlyController;
  late TextEditingController _disabledController;

  @override
  void initState() {
    super.initState();
    _readOnlyController = TextEditingController(text: '2024-08-18');
    _disabledController = TextEditingController(text: '2024-08-18');
  }

  @override
  void dispose() {
    _readOnlyController.dispose();
    _disabledController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: widget.tokens.spacing.sp16,
      children: [
        LayrzText('Read-only vs Disabled Behavior', style: widget.tokens.typography.title),
        LayrzText(
          'Read-only fires onTap (used by pickers); disabled does not. Tap each field to see the difference.',
          style: widget.tokens.typography.body.copyWith(color: widget.tokens.colors.fg3),
        ),
        Row(
          spacing: widget.tokens.spacing.sp16,
          children: [
            Expanded(
              child: Column(
                spacing: widget.tokens.spacing.sp8,
                children: [
                  LayrzText('Read-only (fires onTap)', style: widget.tokens.typography.label),
                  LayrzTextInput(
                    labelText: 'Date Picker',
                    controller: _readOnlyController,
                    readOnly: true,
                    onTap: widget.onReadOnlyTap,
                    hintText: 'Taps: ${widget.readOnlyTapCount}',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                spacing: widget.tokens.spacing.sp8,
                children: [
                  LayrzText('Disabled (no onTap)', style: widget.tokens.typography.label),
                  LayrzTextInput(
                    labelText: 'Disabled Field',
                    controller: _disabledController,
                    disabled: true,
                    onTap: widget.onDisabledTap,
                    hintText: 'Taps: ${widget.disabledTapCount}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates dense mode (compact layout).
///
/// Shows: default vs dense side by side to highlight the spacing difference.
class _DenseModeShowcase extends StatelessWidget {
  final LayrzTokens tokens;

  const _DenseModeShowcase({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp16,
      children: [
        LayrzText('Dense Mode', style: tokens.typography.title),
        Row(
          spacing: tokens.spacing.sp16,
          children: [
            Expanded(
              child: Column(
                spacing: tokens.spacing.sp8,
                children: [
                  LayrzText('Default', style: tokens.typography.label),
                  const LayrzTextInput(
                    labelText: 'Regular size',
                    hintText: 'Normal padding',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                spacing: tokens.spacing.sp8,
                children: [
                  LayrzText('Dense: true', style: tokens.typography.label),
                  const LayrzTextInput(
                    labelText: 'Compact size',
                    hintText: 'Reduced padding',
                    dense: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates the label icon feature.
///
/// Shows: optional icon rendered before label text, inheriting the label's color and size.
class _LabelIconShowcase extends StatelessWidget {
  final LayrzTokens tokens;

  const _LabelIconShowcase({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp16,
      children: [
        LayrzText('Label Icon', style: tokens.typography.title),
        LayrzText(
          'Optional icon rendered before label text. Icon inherits label color and typography sizing.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        Row(
          spacing: tokens.spacing.sp16,
          children: [
            Expanded(
              child: Column(
                spacing: tokens.spacing.sp8,
                children: [
                  LayrzText('With Label Icon', style: tokens.typography.label),
                  LayrzTextInput(
                    labelText: 'Username',
                    labelIcon: LayrzIcons.solarOutlineUser,
                    hintText: 'Enter your username',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                spacing: tokens.spacing.sp8,
                children: [
                  LayrzText('Without Icon', style: tokens.typography.label),
                  const LayrzTextInput(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates the shortcut badge display.
///
/// Shows: keyboard shortcut displayed as a muted badge (hidden on mobile).
class _ShortcutBadgeShowcase extends StatelessWidget {
  final LayrzTokens tokens;

  const _ShortcutBadgeShowcase({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp16,
      children: [
        LayrzText('Shortcut Badge', style: tokens.typography.title),
        LayrzText(
          'Keyboard shortcut displayed as a muted badge. Hidden on mobile devices.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        Row(
          spacing: tokens.spacing.sp16,
          children: [
            Expanded(
              child: LayrzTextInput(
                labelText: 'Search',
                hintText: 'Try Cmd+K',
                shortcut: {LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK},
              ),
            ),
            Expanded(
              child: LayrzTextInput(
                labelText: 'Command',
                hintText: 'Try Ctrl+Shift+P',
                shortcut: {LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyP},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates additional input features.
///
/// Shows: obscureText (password), keyboardType variations, and maxLength with counter.
class _AdditionalFeaturesShowcase extends StatelessWidget {
  final LayrzTokens tokens;

  const _AdditionalFeaturesShowcase({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp16,
      children: [
        LayrzText('Additional Features', style: tokens.typography.title),
        Column(
          spacing: tokens.spacing.sp16,
          children: [
            Row(
              spacing: tokens.spacing.sp16,
              children: [
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      LayrzText('Password (obscureText)', style: tokens.typography.label),
                      const LayrzTextInput(
                        labelText: 'Password',
                        hintText: '••••••••',
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      LayrzText('Email Keyboard', style: tokens.typography.label),
                      const LayrzTextInput(
                        labelText: 'Email',
                        hintText: 'user@example.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              spacing: tokens.spacing.sp16,
              children: [
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      LayrzText('Phone Keyboard', style: tokens.typography.label),
                      const LayrzTextInput(
                        labelText: 'Phone Number',
                        hintText: '+1 (555) 123-4567',
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      LayrzText('Max Length (20 chars)', style: tokens.typography.label),
                      const LayrzTextInput(
                        labelText: 'Limited',
                        hintText: 'Type to see counter',
                        maxLength: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
