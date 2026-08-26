import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Showroom demo for [LayrzSwitchInput].
///
/// Every non-disabled switch below is wired to state via `onChanged` + `setState`,
/// including the error-state example, whose error message clears interactively once
/// the switch is turned on.
class SwitchInputDemo extends StatefulWidget {
  /// Creates a new [SwitchInputDemo].
  const SwitchInputDemo({super.key});

  @override
  State<SwitchInputDemo> createState() => _SwitchInputDemoState();
}

class _SwitchInputDemoState extends State<SwitchInputDemo> {
  bool _notifications = true;
  bool _darkMode = false;
  bool _analytics = true;
  bool _twoFactor = true;
  bool _agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SizedBox(
      height: double.infinity,
      child: SingleChildScrollView(
        child: Padding(
          padding: tokens.spacing.pd2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic switches
              Text('Basic Switches', style: tokens.typography.title),
              Column(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzSwitchInput(
                    value: _notifications,
                    onChanged: (v) {
                      setState(() {
                        _notifications = v;
                      });
                    },
                    labelText: 'Enable notifications',
                  ),
                  LayrzSwitchInput(
                    value: _darkMode,
                    onChanged: (v) {
                      setState(() {
                        _darkMode = v;
                      });
                    },
                    labelText: 'Dark mode',
                  ),
                ],
              ),

              // More options
              SizedBox(height: tokens.spacing.sp3),
              Text('More Options', style: tokens.typography.title),
              Column(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzSwitchInput(
                    value: _analytics,
                    onChanged: (v) {
                      setState(() {
                        _analytics = v;
                      });
                    },
                    labelText: 'Share analytics',
                  ),
                  LayrzSwitchInput(
                    value: _twoFactor,
                    onChanged: (v) {
                      setState(() {
                        _twoFactor = v;
                      });
                    },
                    labelText: 'Two-factor authentication',
                  ),
                ],
              ),

              // Disabled state
              SizedBox(height: tokens.spacing.sp3),
              Text('Disabled State', style: tokens.typography.title),
              Column(
                spacing: tokens.spacing.sp3,
                children: const [
                  LayrzSwitchInput(
                    value: false,
                    disabled: true,
                    labelText: 'Disabled switch (off)',
                  ),
                  LayrzSwitchInput(
                    value: true,
                    disabled: true,
                    labelText: 'Disabled switch (on)',
                  ),
                ],
              ),

              // With errors
              SizedBox(height: tokens.spacing.sp3),
              Text('Error State', style: tokens.typography.title),
              Text(
                'The error clears as soon as the switch is turned on.',
                style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
              ),
              SizedBox(height: tokens.spacing.sp2),
              Column(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzSwitchInput(
                    value: _agreedToTerms,
                    onChanged: (v) {
                      setState(() {
                        _agreedToTerms = v;
                      });
                    },
                    labelText: 'Agree to terms',
                    errors: _agreedToTerms ? const [] : const ['You must accept the terms to proceed'],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
