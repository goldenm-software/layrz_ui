import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// A stateful widget that manages [TextEditingController]s and [FocusNode]s.
///
/// This allows the showroom to demonstrate all interactive states, state changes,
/// and proper resource disposal.
class InputsSection extends StatefulWidget {
  const InputsSection({super.key});

  @override
  State<InputsSection> createState() => _InputsSectionState();
}

class _InputsSectionState extends State<InputsSection> {
  late TextEditingController _restController;
  late TextEditingController _errorController;
  late TextEditingController _disabledController;
  late TextEditingController _readOnlyController;
  late TextEditingController _numericController;
  late FocusNode _restFocusNode;
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
    _errorController = TextEditingController(text: 'Invalid input');
    _disabledController = TextEditingController(text: 'Disabled text');
    _readOnlyController = TextEditingController(text: 'Read-only text');
    _numericController = TextEditingController();
    _restFocusNode = FocusNode();
    _errorFocusNode = FocusNode();
    _disabledFocusNode = FocusNode();
    _readOnlyFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _restController.dispose();
    _errorController.dispose();
    _disabledController.dispose();
    _readOnlyController.dispose();
    _numericController.dispose();
    _restFocusNode.dispose();
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
          // 1. Field states
          _FieldStatesShowcase(
            tokens: tokens,
            restController: _restController,
            restFocusNode: _restFocusNode,
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

          // 8. Widget slot variants
          _WidgetSlotsShowcase(
            tokens: tokens,
            numericController: _numericController,
          ),

          // 9. Shortcut badge
          _ShortcutBadgeShowcase(tokens: tokens),

          // 10. Additional features
          _AdditionalFeaturesShowcase(tokens: tokens),

          // 11. Character counter
          _CharacterCounterShowcase(tokens: tokens),
        ],
      ),
    );
  }
}

/// Demonstrates field states side by side.
///
/// Shows: rest, error, disabled, and read-only states.
/// Hover and focus effects are live — hover or tab into any field to see them.
class _FieldStatesShowcase extends StatelessWidget {
  final LayrzTokens tokens;
  final TextEditingController restController;
  final FocusNode restFocusNode;
  final TextEditingController errorController;
  final FocusNode errorFocusNode;
  final TextEditingController disabledController;
  final FocusNode disabledFocusNode;
  final TextEditingController readOnlyController;
  final FocusNode readOnlyFocusNode;

  const _FieldStatesShowcase({
    required this.tokens,
    required this.restController,
    required this.restFocusNode,
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
        Text('Field States', style: tokens.typography.title),
        Text(
          'Rest, error, disabled and read-only. Hover and focus are live — hover or tab into any field to see them.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        Column(
          spacing: tokens.spacing.sp16,
          children: [
            // Row 1: Rest and Error
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp16,
              children: [
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      Text('Rest', style: tokens.typography.label),
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
                      Text('Error', style: tokens.typography.label),
                      LayrzTextInput(
                        controller: errorController,
                        labelText: 'Error state',
                        errors: ['This is an error'],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Row 2: Disabled and Read-only
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp16,
              children: [
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      Text('Disabled', style: tokens.typography.label),
                      LayrzTextInput(
                        controller: disabledController,
                        labelText: 'Disabled state',
                        disabled: true,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      Text('Read-only', style: tokens.typography.label),
                      LayrzTextInput(
                        controller: readOnlyController,
                        labelText: 'Read-only state',
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
        Text('Label and Placeholder Variations', style: tokens.typography.title),
        Column(
          spacing: tokens.spacing.sp16,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp16,
              children: [
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      Text('With Label', style: tokens.typography.label),
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
                      Text('Without Label', style: tokens.typography.label),
                      const LayrzTextInput(
                        hintText: 'No label here',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp16,
              children: [
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      Text('Required Indicator', style: tokens.typography.label),
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
                      Text('No Placeholder', style: tokens.typography.label),
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
        Text('Prefix and Suffix Slot Forms', style: tokens.typography.title),
        Text(
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
                Text('Prefix Variants', style: tokens.typography.label),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                Text('Suffix Variants', style: tokens.typography.label),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
        Text('Error Display', style: tokens.typography.title),
        Column(
          spacing: tokens.spacing.sp16,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp16,
              children: [
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      Text('Single Error', style: tokens.typography.label),
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
                      Text('Multiple Errors', style: tokens.typography.label),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp16,
              children: [
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      Text('hideDetails: true', style: tokens.typography.label),
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
                      Text('Error + Suffix', style: tokens.typography.label),
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
        Text('Help Affordance', style: tokens.typography.title),
        Text(
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
        Text('Read-only vs Disabled Behavior', style: widget.tokens.typography.title),
        Text(
          'Read-only fires onTap (used by pickers); disabled does not. Tap each field to see the difference.',
          style: widget.tokens.typography.body.copyWith(color: widget.tokens.colors.fg3),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: widget.tokens.spacing.sp16,
          children: [
            Expanded(
              child: Column(
                spacing: widget.tokens.spacing.sp8,
                children: [
                  Text('Read-only (fires onTap)', style: widget.tokens.typography.label),
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
                  Text('Disabled (no onTap)', style: widget.tokens.typography.label),
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
        Text('Dense Mode', style: tokens.typography.title),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.sp16,
          children: [
            Expanded(
              child: Column(
                spacing: tokens.spacing.sp8,
                children: [
                  Text('Default', style: tokens.typography.label),
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
                  Text('Dense: true', style: tokens.typography.label),
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
/// Demonstrates widget slot variants for prefix and suffix.
///
/// Shows: custom widget in prefix slot (color swatch), custom widget in suffix slot (tall widget
/// demonstrating height constraint), and numeric input with formatter.
class _WidgetSlotsShowcase extends StatelessWidget {
  final LayrzTokens tokens;
  final TextEditingController numericController;

  const _WidgetSlotsShowcase({
    required this.tokens,
    required this.numericController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp16,
      children: [
        Text('Widget Slot Variants', style: tokens.typography.title),
        Text(
          'Prefix and suffix can be arbitrary widgets. The field constrains widgets to match the content height.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.sp16,
          children: [
            Expanded(
              child: Column(
                spacing: tokens.spacing.sp8,
                children: [
                  Text('Prefix Widget (Color Swatch)', style: tokens.typography.label),
                  LayrzTextInput(
                    labelText: 'Color Picker',
                    hintText: 'Select a color',
                    prefix: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                spacing: tokens.spacing.sp8,
                children: [
                  Text('Suffix Widget (Height Constraint)', style: tokens.typography.label),
                  LayrzTextInput(
                    labelText: 'Field with Tall Suffix',
                    hintText: 'Type or observe the suffix',
                    suffix: Container(
                      width: 64,
                      height: 100,
                      decoration: BoxDecoration(
                        color: tokens.colors.surface2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '100px tall\nfield ≈24px',
                          style: tokens.typography.body.copyWith(
                            fontSize: 10,
                            color: tokens.colors.fg3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.sp16,
          children: [
            Expanded(
              child: Column(
                spacing: tokens.spacing.sp8,
                children: [
                  Text('Numeric Input', style: tokens.typography.label),
                  LayrzTextInput(
                    labelText: 'Age',
                    hintText: 'Enter digits only',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    controller: numericController,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SizedBox(),
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
        Text('Shortcut Badge', style: tokens.typography.title),
        Text(
          'Keyboard shortcut displayed as a muted badge. Hidden on mobile devices.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
        Text('Additional Features', style: tokens.typography.title),
        Column(
          spacing: tokens.spacing.sp16,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp16,
              children: [
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      Text('Password (obscureText)', style: tokens.typography.label),
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
                      Text('Email Keyboard', style: tokens.typography.label),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp16,
              children: [
                Expanded(
                  child: Column(
                    spacing: tokens.spacing.sp8,
                    children: [
                      Text('Phone Keyboard', style: tokens.typography.label),
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
                      Text('Max Length (20 chars)', style: tokens.typography.label),
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

/// Demonstrates character counter functionality.
///
/// Shows: character counter alone, and character counter combined with error messages.
class _CharacterCounterShowcase extends StatelessWidget {
  final LayrzTokens tokens;

  const _CharacterCounterShowcase({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp16,
      children: [
        Text('Character Counter', style: tokens.typography.title),
        Text(
          'Character counter displays current/max without focus or content threshold. Stays fg3 even when errors are present.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.sp16,
          children: [
            Expanded(
              child: Column(
                spacing: tokens.spacing.sp8,
                children: [
                  Text('Counter alone (50 chars)', style: tokens.typography.label),
                  const LayrzTextInput(
                    labelText: 'Bio',
                    hintText: 'Tell us about yourself',
                    maxLength: 50,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                spacing: tokens.spacing.sp8,
                children: [
                  Text('Counter with error (30 chars)', style: tokens.typography.label),
                  const LayrzTextInput(
                    labelText: 'Username',
                    hintText: 'Enter username',
                    maxLength: 30,
                    errors: ['Username contains invalid characters'],
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
