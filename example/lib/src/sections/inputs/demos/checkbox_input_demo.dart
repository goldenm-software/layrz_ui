import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

class CheckboxInputDemo extends StatefulWidget {
  const CheckboxInputDemo({super.key});

  @override
  State<CheckboxInputDemo> createState() => _CheckboxInputDemoState();
}

class _CheckboxInputDemoState extends State<CheckboxInputDemo> {
  bool _unchecked = false;
  bool _checked = true;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      color: LayrzColors.red,
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
                  debugPrint('Unchecked checkbox changed to: $v');
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
