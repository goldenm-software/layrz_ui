import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Showroom demo for [LayrzUsernameInput] and [LayrzPasswordInput].
///
/// The primary section pairs both widgets inside a single `AutofillGroup` -- exactly
/// how a real login form associates the credential pair so a browser/OS password
/// manager offers to save or fill them together (see both widgets' "Grouping with the
/// [...] field" class docs). A [LayrzSwitchInput] above the pair drives
/// [LayrzPasswordInput.showStrengthMeter] live, so the meter can be toggled on and off
/// without leaving the page. Separate sections below exercise the error and disabled
/// states, matching the shape of [SwitchInputDemo] and [DurationInputDemo] (one titled
/// section per variant, scrollable, laid out with design tokens throughout).
class LoginInputDemo extends StatefulWidget {
  /// Creates a new [LoginInputDemo].
  const LoginInputDemo({super.key});

  @override
  State<LoginInputDemo> createState() => _LoginInputDemoState();
}

class _LoginInputDemoState extends State<LoginInputDemo> {
  /// Controller backing the primary section's username field.
  late TextEditingController _usernameController;

  /// Controller backing the primary section's password field.
  ///
  /// Shared with the strength meter toggle below: typing here re-scores the meter live
  /// when [_showStrengthMeter] is enabled.
  late TextEditingController _passwordController;

  /// Controller backing the error-state section's username field.
  late TextEditingController _errorUsernameController;

  /// Controller backing the error-state section's password field.
  late TextEditingController _errorPasswordController;

  /// Whether the primary section's [LayrzPasswordInput] renders its strength meter.
  ///
  /// Defaults to `false`, mirroring [LayrzPasswordInput.showStrengthMeter]'s own
  /// default -- the demo opens on the plain login look and lets the switch opt in.
  bool _showStrengthMeter = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _errorUsernameController = TextEditingController(text: 'not-an-email');
    _errorPasswordController = TextEditingController(text: 'short');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _errorUsernameController.dispose();
    _errorPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      child: Padding(
        padding: tokens.spacing.pd2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primary section: paired login fields + strength-meter toggle.
            Text('Login Form', style: tokens.typography.title),
            Text(
              'LayrzUsernameInput and LayrzPasswordInput wrapped in one AutofillGroup, so '
              'a password manager treats them as a single credential pair. Toggle the '
              'switch below to exercise showStrengthMeter live.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzSwitchInput(
              value: _showStrengthMeter,
              onChanged: (v) {
                setState(() {
                  _showStrengthMeter = v;
                });
              },
              labelText: 'Show password strength meter',
            ),
            SizedBox(height: tokens.spacing.sp3),
            AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzUsernameInput(
                    controller: _usernameController,
                    labelText: 'Username',
                    hintText: 'you@example.com',
                  ),
                  LayrzPasswordInput(
                    controller: _passwordController,
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    showStrengthMeter: _showStrengthMeter,
                  ),
                ],
              ),
            ),

            // Error state
            SizedBox(height: tokens.spacing.sp5),
            Text('Error State', style: tokens.typography.title),
            Text(
              'Both fields report a validation error simultaneously, as they would after '
              'a failed login submission.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp3,
              children: [
                LayrzUsernameInput(
                  controller: _errorUsernameController,
                  labelText: 'Username',
                  errors: const ['Enter a valid email address'],
                ),
                LayrzPasswordInput(
                  controller: _errorPasswordController,
                  labelText: 'Password',
                  errors: const ['Password must be at least 8 characters'],
                ),
              ],
            ),

            // Disabled state
            SizedBox(height: tokens.spacing.sp5),
            Text('Disabled State', style: tokens.typography.title),
            Text(
              'Both fields are locked -- not editable, not focusable, and the password '
              'eye toggle stops responding to taps.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp3,
              children: const [
                LayrzUsernameInput(
                  labelText: 'Username',
                  hintText: 'you@example.com',
                  disabled: true,
                ),
                LayrzPasswordInput(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  disabled: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
