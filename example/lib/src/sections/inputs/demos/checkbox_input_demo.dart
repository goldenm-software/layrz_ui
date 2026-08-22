import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Builds a comprehensive showcase of [LayrzCheckboxInput] variants.
Widget buildCheckboxInputDemo(BuildContext context) {
  return _CheckboxInputDemo();
}

class _CheckboxInputDemo extends StatefulWidget {
  const _CheckboxInputDemo();

  @override
  State<_CheckboxInputDemo> createState() => _CheckboxInputDemoState();
}

class _CheckboxInputDemoState extends State<_CheckboxInputDemo> {
  bool _unchecked = false;
  bool _checked = true;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spacing.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spacing.sp5,
        children: [
          // Basic states
          Text('Checkbox States', style: tokens.typography.title),
          Column(
            spacing: tokens.spacing.sp2,
            children: [
              LayrzCheckboxInput(
                value: _unchecked,
                onChanged: (v) {
                  setState(() {
                    _unchecked = v;
                  });
                },
                labelText: 'Unchecked checkbox',
              ),
              LayrzCheckboxInput(
                value: _checked,
                onChanged: (v) {
                  setState(() {
                    _checked = v;
                  });
                },
                labelText: 'Checked checkbox',
              ),
              const LayrzCheckboxInput(
                value: false,
                disabled: true,
                labelText: 'Disabled checkbox',
              ),
            ],
          ),

          // With errors
          SizedBox(height: tokens.spacing.sp3),
          Text('Error State', style: tokens.typography.title),
          Column(
            spacing: tokens.spacing.sp2,
            children: [
              const LayrzCheckboxInput(
                value: false,
                labelText: 'Required field',
                errors: ['You must accept this'],
              ),
            ],
          ),

          // Different states
          SizedBox(height: tokens.spacing.sp3),
          Text('Various States', style: tokens.typography.title),
          Column(
            spacing: tokens.spacing.sp2,
            children: [
              const LayrzCheckboxInput(
                value: true,
                labelText: 'Feature enabled',
              ),
              const LayrzCheckboxInput(
                value: false,
                labelText: 'Feature disabled',
              ),
              const LayrzCheckboxInput(
                value: false,
                disabled: true,
                labelText: 'Cannot toggle',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
