import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Builds a comprehensive showcase of [LayrzNumberInput] variants.
Widget buildNumberInputDemo(BuildContext context) {
  return _NumberInputDemo();
}

class _NumberInputDemo extends StatefulWidget {
  const _NumberInputDemo();

  @override
  State<_NumberInputDemo> createState() => _NumberInputDemoState();
}

class _NumberInputDemoState extends State<_NumberInputDemo> {
  late TextEditingController _intController;
  late TextEditingController _decimalController;
  late TextEditingController _rangeController;

  @override
  void initState() {
    super.initState();
    _intController = TextEditingController(text: '5');
    _decimalController = TextEditingController(text: '3.14');
    _rangeController = TextEditingController(text: '50');
  }

  @override
  void dispose() {
    _intController.dispose();
    _decimalController.dispose();
    _rangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp5,
      children: [
        // Basic input
        Text('Basic Number Inputs', style: tokens.typography.title),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzNumberInput(
                labelText: 'Integer',
                hintText: 'Enter a whole number',
                controller: _intController,
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzNumberInput(
                labelText: 'Decimal',
                hintText: 'Enter a decimal',
                controller: _decimalController,
                maximumDecimalDigits: 2,
              ),
            ),
          ],
        ),

        // With step buttons (hideStepButtons = false is the default)
        SizedBox(height: tokens.spacing.sp3),
        Text('With Step Buttons', style: tokens.typography.title),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzNumberInput(
                labelText: 'Quantity',
                hintText: 'Use +/- buttons',
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzNumberInput(
                labelText: 'Step Size',
                hintText: 'Step by 5',
                step: 5,
              ),
            ),
          ],
        ),

        // Without step buttons
        SizedBox(height: tokens.spacing.sp3),
        Text('Without Step Buttons', style: tokens.typography.title),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzNumberInput(
                labelText: 'No Buttons',
                hintText: 'Type manually',
                hideStepButtons: true,
              ),
            ),
          ],
        ),

        // With range constraints
        SizedBox(height: tokens.spacing.sp3),
        Text('With Min/Max Range', style: tokens.typography.title),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzNumberInput(
                labelText: 'Age (0-120)',
                hintText: 'Enter your age',
                controller: _rangeController,
                minimum: 0,
                maximum: 120,
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzNumberInput(
                labelText: 'Percentage (0-100)',
                hintText: 'Enter percentage',
                minimum: 0,
                maximum: 100,
              ),
            ),
          ],
        ),

        // Disabled state
        SizedBox(height: tokens.spacing.sp3),
        Text('States', style: tokens.typography.title),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzNumberInput(
                labelText: 'Disabled',
                disabled: true,
                hintText: 'Cannot edit',
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: const LayrzNumberInput(
                labelText: 'Read-only',
                readOnly: true,
                hintText: 'View only',
              ),
            ),
          ],
        ),

        // With errors
        SizedBox(height: tokens.spacing.sp3),
        Text('Error State', style: tokens.typography.title),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 12,
              child: const LayrzNumberInput(
                labelText: 'Amount',
                hintText: 'Enter a valid amount',
                errors: ['Amount must be greater than 0', 'Maximum is 1000'],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
