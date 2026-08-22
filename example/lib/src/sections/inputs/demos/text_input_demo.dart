import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Builds a comprehensive showcase of [LayrzTextInput] variants and states.
Widget buildTextInputDemo(BuildContext context) {
  return _TextInputDemo();
}

class _TextInputDemo extends StatefulWidget {
  const _TextInputDemo();

  @override
  State<_TextInputDemo> createState() => _TextInputDemoState();
}

class _TextInputDemoState extends State<_TextInputDemo> {
  late TextEditingController _restController;
  late TextEditingController _errorController;
  late TextEditingController _disabledController;
  late TextEditingController _readOnlyController;
  late FocusNode _restFocusNode;
  late FocusNode _errorFocusNode;
  late FocusNode _disabledFocusNode;
  late FocusNode _readOnlyFocusNode;
  int _prefixTapCount = 0;
  int _suffixTapCount = 0;

  @override
  void initState() {
    super.initState();
    _restController = TextEditingController(text: 'Rest state');
    _errorController = TextEditingController(text: 'Invalid input');
    _disabledController = TextEditingController(text: 'Disabled text');
    _readOnlyController = TextEditingController(text: 'Read-only text');
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
    _restFocusNode.dispose();
    _errorFocusNode.dispose();
    _disabledFocusNode.dispose();
    _readOnlyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spacing.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spacing.sp5,
        children: [
          // 1. Field states
          _buildFieldStates(tokens),

          // 2. Label and placeholder variations
          _buildLabelAndPlaceholder(tokens),

          // 3. Prefix and suffix slot forms
          _buildPrefixSuffixSlots(tokens),

          // 4. Error display
          _buildErrorsShowcase(tokens),

          // 5. Help affordance
          _buildHelpAffordance(tokens),

          // 6. ReadOnly vs Disabled behavior
          _buildReadOnlyVsDisabled(tokens),

          // 7. Widget slot variants
          _buildWidgetSlots(tokens),

          // 8. Shortcut badge
          _buildShortcutBadge(tokens),

          // 9. Additional features
          _buildAdditionalFeatures(tokens),

          // 10. Character counter
          _buildCharacterCounter(tokens),
        ],
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
                controller: _restController,
                focusNode: _restFocusNode,
                labelText: 'Rest state',
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                controller: _errorController,
                labelText: 'Error state',
                errors: ['This is an error'],
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                controller: _disabledController,
                labelText: 'Disabled state',
                disabled: true,
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                controller: _readOnlyController,
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
                onPrefixTap: () {
                  setState(() {
                    _prefixTapCount++;
                  });
                },
                hintText: 'Taps: $_prefixTapCount',
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                labelText: 'Suffix Icon',
                suffixIcon: MdiIcons.eyeOutline,
                onSuffixTap: () {
                  setState(() {
                    _suffixTapCount++;
                  });
                },
                hintText: 'Taps: $_suffixTapCount',
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                labelText: 'Prefix Text',
                prefixText: '@',
                onPrefixTap: () {
                  setState(() {
                    _prefixTapCount++;
                  });
                },
                hintText: 'Taps: $_prefixTapCount',
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzTextInput(
                labelText: 'Suffix Text',
                suffixText: '.com',
                onSuffixTap: () {
                  setState(() {
                    _suffixTapCount++;
                  });
                },
                hintText: 'Taps: $_suffixTapCount',
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
                controller: _readOnlyController,
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
                    borderRadius: BorderRadius.all(Radius.circular(4)),
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
