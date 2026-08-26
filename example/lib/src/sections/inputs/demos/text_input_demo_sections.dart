import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Widget that renders all sections of the text input demo.
///
/// Stateless by design: every mutable value (controllers, focus node, tap counters)
/// is owned by [TextInputDemo] and threaded in as a parameter, mirroring the
/// `NumberInputDemoSections` reference shape.
class TextInputDemoSections extends StatelessWidget {
  /// Controller backing the "Rest state" field in the Field States section.
  final TextEditingController restController;

  /// Controller backing the "Error state" field in the Field States section.
  final TextEditingController errorController;

  /// Controller backing the "Disabled state" field in the Field States section.
  final TextEditingController disabledController;

  /// Controller backing the "Read-only state" field in the Field States section
  /// and the read-only vs. disabled comparison section.
  final TextEditingController readOnlyController;

  /// Focus node attached to the "Rest state" field, so tabbing into it is
  /// demonstrable from elsewhere in the showroom.
  final FocusNode restFocusNode;

  /// Current number of times a prefix affordance has been tapped.
  ///
  /// Rendered into the hint text of the prefix examples to prove the tap
  /// actually reached the demo's state.
  final int prefixTapCount;

  /// Current number of times a suffix affordance has been tapped.
  ///
  /// Rendered into the hint text of the suffix examples to prove the tap
  /// actually reached the demo's state.
  final int suffixTapCount;

  /// Invoked when a prefix icon or prefix text affordance is tapped.
  final VoidCallback onPrefixTap;

  /// Invoked when a suffix icon or suffix text affordance is tapped.
  final VoidCallback onSuffixTap;

  /// Creates a new [TextInputDemoSections].
  const TextInputDemoSections({
    super.key,
    required this.restController,
    required this.errorController,
    required this.disabledController,
    required this.readOnlyController,
    required this.restFocusNode,
    required this.prefixTapCount,
    required this.suffixTapCount,
    required this.onPrefixTap,
    required this.onSuffixTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      child: Padding(
        padding: tokens.spacing.pd2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.sp5,
          children: [
            _buildFieldStates(tokens),
            _buildLabelAndPlaceholder(tokens),
            _buildPrefixSuffixSlots(tokens),
            _buildErrorsShowcase(tokens),
            _buildHelpAffordance(tokens),
            _buildReadOnlyVsDisabled(tokens),
            _buildWidgetSlots(tokens),
            _buildShortcutBadge(tokens),
            _buildAdditionalFeatures(tokens),
            _buildCharacterCounter(tokens),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldStates(LayrzTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp3,
      children: [
        Text('Field States', style: tokens.typography.title),
        Text(
          'Rest, error, disabled and read-only. Hover and focus are live — hover or tab into any field to see them.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                controller: restController,
                focusNode: restFocusNode,
                labelText: 'Rest state',
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                controller: errorController,
                labelText: 'Error state',
                errors: const ['This is an error'],
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                controller: disabledController,
                labelText: 'Disabled state',
                disabled: true,
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                controller: readOnlyController,
                labelText: 'Read-only state',
                readOnly: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabelAndPlaceholder(LayrzTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp3,
      children: [
        Text('Label and Placeholder Variations', style: tokens.typography.title),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzTextInput(
                labelText: 'Username',
                hintText: 'Enter your username',
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzTextInput(hintText: 'No label here'),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzTextInput(
                labelText: 'Email',
                isRequired: true,
                hintText: 'your@email.com',
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzTextInput(labelText: 'Optional field'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrefixSuffixSlots(LayrzTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp3,
      children: [
        Text('Prefix and Suffix Slot Forms', style: tokens.typography.title),
        Text(
          'Prefix and suffix are mutually exclusive variants. Click prefix/suffix to increment the tap counter.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                labelText: 'Prefix Icon',
                prefixIcon: MdiIcons.checkCircleOutline,
                onPrefixTap: onPrefixTap,
                hintText: 'Taps: $prefixTapCount',
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                labelText: 'Suffix Icon',
                suffixIcon: MdiIcons.eyeOutline,
                onSuffixTap: onSuffixTap,
                hintText: 'Taps: $suffixTapCount',
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                labelText: 'Prefix Text',
                prefixText: '@',
                onPrefixTap: onPrefixTap,
                hintText: 'Taps: $prefixTapCount',
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                labelText: 'Suffix Text',
                suffixText: '.com',
                onSuffixTap: onSuffixTap,
                hintText: 'Taps: $suffixTapCount',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorsShowcase(LayrzTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp3,
      children: [
        Text('Error Display', style: tokens.typography.title),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzTextInput(
                labelText: 'Email',
                hintText: 'your@email.com',
                errors: ['Invalid email format'],
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzTextInput(
                labelText: 'Password',
                errors: [
                  'Must be at least 8 characters',
                  'Must contain uppercase letter',
                ],
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzTextInput(
                labelText: 'Field',
                hintText: 'Error hidden',
                errors: ['Error message is suppressed'],
                hideDetails: true,
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                labelText: 'Username',
                suffixIcon: MdiIcons.checkCircleOutline,
                errors: const ['Already taken'],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHelpAffordance(LayrzTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp3,
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

  Widget _buildReadOnlyVsDisabled(LayrzTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp3,
      children: [
        Text('Read-only vs Disabled Behavior', style: tokens.typography.title),
        Text(
          'Read-only fires onTap (used by pickers); disabled does not. Tap each field to see the difference.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                labelText: 'Date Picker',
                controller: readOnlyController,
                readOnly: true,
                hintText: 'Tap to interact',
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzTextInput(
                labelText: 'Disabled Field',
                disabled: true,
                hintText: 'No interaction',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWidgetSlots(LayrzTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp3,
      children: [
        Text('Widget Slot Variants', style: tokens.typography.title),
        Text(
          'Prefix and suffix can be arbitrary widgets. The field constrains widgets to match the content height.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzTextInput(
                labelText: 'Color Picker',
                hintText: 'Select a color',
                prefix: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF3B82F6),
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  child: SizedBox(width: 24, height: 24),
                ),
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                labelText: 'Field with Tall Suffix',
                hintText: 'Type or observe the suffix',
                suffix: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.colors.sf2,
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                  child: SizedBox(
                    width: 64,
                    height: 100,
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
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShortcutBadge(LayrzTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp3,
      children: [
        Text('Shortcut Badge', style: tokens.typography.title),
        Text(
          'Keyboard shortcut displayed as a muted badge. Hidden on mobile devices.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                labelText: 'Search',
                hintText: 'Try Cmd+K',
                shortcut: {
                  LogicalKeyboardKey.meta,
                  LogicalKeyboardKey.keyK,
                },
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                labelText: 'Command',
                hintText: 'Try Ctrl+Shift+P',
                shortcut: {
                  LogicalKeyboardKey.control,
                  LogicalKeyboardKey.shift,
                  LogicalKeyboardKey.keyP,
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalFeatures(LayrzTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp3,
      children: [
        Text('Additional Features', style: tokens.typography.title),
        Column(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzTextInput(
                labelText: 'Phone Number',
                hintText: '+1 (555) 123-4567',
                keyboardType: TextInputType.phone,
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzTextInput(
                labelText: 'Limited',
                hintText: 'Type to see counter',
                maxLength: 20,
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzTextInput(
                labelText: 'Password',
                hintText: '••••••••',
                obscureText: true,
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzTextInput(
                labelText: 'Email',
                hintText: 'user@example.com',
                keyboardType: TextInputType.emailAddress,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCharacterCounter(LayrzTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp3,
      children: [
        Text('Character Counter', style: tokens.typography.title),
        Text(
          'Character counter displays current/max without focus or content threshold. Stays fg3 even when errors are present.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzTextInput(
                labelText: 'Bio',
                hintText: 'Tell us about yourself',
                maxLength: 50,
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzTextInput(
                labelText: 'Username',
                hintText: 'Enter username',
                maxLength: 30,
                errors: ['Username contains invalid characters'],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
