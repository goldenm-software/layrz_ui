import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Builds a comprehensive showcase of [LayrzSwitchInput] variants.
Widget buildSwitchInputDemo(BuildContext context) {
  return _SwitchInputDemo();
}

class _SwitchInputDemo extends StatefulWidget {
  const _SwitchInputDemo();

  @override
  State<_SwitchInputDemo> createState() => _SwitchInputDemoState();
}

class _SwitchInputDemoState extends State<_SwitchInputDemo> {
  bool _notifications = true;
  bool _darkMode = false;
  bool _analytics = true;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spacing.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spacing.sp5,
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
              const LayrzSwitchInput(
                value: true,
                labelText: 'Two-factor authentication',
              ),
            ],
          ),

          // Disabled state
          SizedBox(height: tokens.spacing.sp3),
          Text('Disabled State', style: tokens.typography.title),
          Column(
            spacing: tokens.spacing.sp3,
            children: [
              const LayrzSwitchInput(
                value: false,
                disabled: true,
                labelText: 'Disabled switch (off)',
              ),
              const LayrzSwitchInput(
                value: true,
                disabled: true,
                labelText: 'Disabled switch (on)',
              ),
            ],
          ),

          // With errors
          SizedBox(height: tokens.spacing.sp3),
          Text('Error State', style: tokens.typography.title),
          Column(
            spacing: tokens.spacing.sp3,
            children: [
              const LayrzSwitchInput(
                value: false,
                labelText: 'Agree to terms',
                errors: ['You must accept the terms to proceed'],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
