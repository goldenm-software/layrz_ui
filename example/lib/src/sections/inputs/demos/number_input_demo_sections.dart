import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Widget that renders all sections of the number input demo.
class NumberInputDemoSections extends StatelessWidget {
  final TextEditingController basicIntController;
  final TextEditingController basicDecimalController;
  final TextEditingController quantityController;
  final TextEditingController ageController;
  final TextEditingController percentageController;
  final TextEditingController currencyController;
  final TextEditingController weightController;
  final TextEditingController temperatureController;
  final TextEditingController volumeController;
  final TextEditingController suffixOnlyController;
  final TextEditingController intervalController;
  final TextEditingController dotSeparatorController;
  final TextEditingController commaSeparatorController;
  final TextEditingController precisionZeroController;
  final TextEditingController precisionTwoController;
  final TextEditingController nonNegativeController;
  final TextEditingController allowNegativeController;
  final TextEditingController customFormatterController;
  final VoidCallback onStateChanged;

  const NumberInputDemoSections({
    super.key,
    required this.basicIntController,
    required this.basicDecimalController,
    required this.quantityController,
    required this.ageController,
    required this.percentageController,
    required this.currencyController,
    required this.weightController,
    required this.temperatureController,
    required this.volumeController,
    required this.suffixOnlyController,
    required this.intervalController,
    required this.dotSeparatorController,
    required this.commaSeparatorController,
    required this.precisionZeroController,
    required this.precisionTwoController,
    required this.nonNegativeController,
    required this.allowNegativeController,
    required this.customFormatterController,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SizedBox(
      height: double.infinity,
      child: SingleChildScrollView(
        child: Container(
          padding: tokens.spacing.pd2,
          child: Column(
            crossAxisAlignment: .start,
            mainAxisAlignment: .start,
            spacing: tokens.spacing.sp1,
            children: [
              // Basic Number Inputs
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
                      controller: basicIntController,
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzNumberInput(
                      labelText: 'Decimal',
                      hintText: 'Enter a decimal',
                      controller: basicDecimalController,
                      maximumDecimalDigits: 2,
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('With Step Buttons', style: tokens.typography.title),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzNumberInput(
                      labelText: 'Quantity',
                      hintText: 'Use +/− buttons',
                      controller: quantityController,
                      onChanged: (value) {
                        onStateChanged();
                      },
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: const LayrzNumberInput(
                      labelText: 'Step by 5',
                      hintText: 'Increment by 5',
                      step: 5,
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('Without Step Buttons', style: tokens.typography.title),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: const LayrzNumberInput(
                      labelText: 'Manual Entry Only',
                      hintText: 'Type to enter values',
                      hideStepButtons: true,
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('With Min/Max Range', style: tokens.typography.title),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzNumberInput(
                      labelText: 'Age (0−120)',
                      hintText: 'Enter your age',
                      controller: ageController,
                      minimum: 0,
                      maximum: 120,
                      onChanged: (value) {
                        onStateChanged();
                      },
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzNumberInput(
                      labelText: 'Percentage (0−100)',
                      hintText: 'Enter percentage',
                      controller: percentageController,
                      minimum: 0,
                      maximum: 100,
                      onChanged: (value) {
                        onStateChanged();
                      },
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
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
                      value: 42,
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
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

              tokens.spacing.sb3,
              Text('Prefix and Suffix Variants', style: tokens.typography.title),
              Text('Currency with prefix text', style: tokens.typography.label),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzNumberInput(
                      labelText: 'Price',
                      hintText: 'Enter amount',
                      controller: currencyController,
                      prefixText: '\$',
                      maximumDecimalDigits: 2,
                      onChanged: (value) {
                        onStateChanged();
                      },
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzNumberInput(
                      labelText: 'Amount in USD',
                      hintText: 'Enter amount',
                      controller: temperatureController,
                      suffixText: 'USD',
                      onChanged: (value) {
                        onStateChanged();
                      },
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb2,
              Text('Prefix and suffix together', style: tokens.typography.label),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzNumberInput(
                      labelText: 'Weight',
                      hintText: 'Enter weight',
                      controller: weightController,
                      prefixText: '🔺',
                      suffixText: 'kg',
                      maximumDecimalDigits: 1,
                      onChanged: (value) {
                        onStateChanged();
                      },
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzNumberInput(
                      labelText: 'Volume',
                      hintText: 'Enter volume',
                      controller: volumeController,
                      prefixIcon: MdiIcons.flask,
                      suffixText: 'mL',
                      onChanged: (value) {
                        onStateChanged();
                      },
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb2,
              Text('Suffix only (without step buttons)', style: tokens.typography.label),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzNumberInput(
                      labelText: 'Reporting Interval',
                      hintText: 'Enter interval',
                      controller: suffixOnlyController,
                      suffixText: 's',
                      hideStepButtons: true,
                      onChanged: (value) {
                        onStateChanged();
                      },
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('Helper Text', style: tokens.typography.title),
              Text('With contextual helper line', style: tokens.typography.label),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzNumberInput(
                      labelText: 'Reporting Interval',
                      hintText: 'Enter interval',
                      controller: intervalController,
                      value: 60,
                      helperText: 'Stored as 60 s · ↑↓ to step, PgUp/PgDn ×10',
                      onChanged: (value) {
                        onStateChanged();
                      },
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('Decimal Separators', style: tokens.typography.title),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzNumberInput(
                      labelText: 'Dot Separator',
                      hintText: 'e.g. 3.14',
                      controller: dotSeparatorController,
                      decimalSeparator: LayrzDecimalSeparator.dot,
                      maximumDecimalDigits: 2,
                      onChanged: (value) {
                        onStateChanged();
                      },
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzNumberInput(
                      labelText: 'Comma Separator',
                      hintText: 'e.g. 3,14',
                      controller: commaSeparatorController,
                      decimalSeparator: LayrzDecimalSeparator.comma,
                      maximumDecimalDigits: 2,
                      onChanged: (value) {
                        onStateChanged();
                      },
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('Decimal Precision', style: tokens.typography.title),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzNumberInput(
                      labelText: 'Integer Only',
                      hintText: 'No decimals allowed',
                      controller: precisionZeroController,
                      maximumDecimalDigits: 0,
                      onChanged: (value) {
                        onStateChanged();
                      },
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzNumberInput(
                      labelText: 'Two Decimal Places',
                      hintText: 'e.g. 3.14',
                      controller: precisionTwoController,
                      maximumDecimalDigits: 2,
                      onChanged: (value) {
                        onStateChanged();
                      },
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('Negative Values', style: tokens.typography.title),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzNumberInput(
                      labelText: 'Non-negative Only',
                      hintText: 'Minus button disabled at 0',
                      controller: nonNegativeController,
                      minimum: 0,
                      onChanged: (value) {
                        onStateChanged();
                      },
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzNumberInput(
                      labelText: 'Allows Negatives',
                      hintText: 'Can go negative',
                      controller: allowNegativeController,
                      onChanged: (value) {
                        onStateChanged();
                      },
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('Custom Input Formatters', style: tokens.typography.title),
              Text('Replaces built-in numeric guard entirely', style: tokens.typography.label),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    child: LayrzNumberInput(
                      labelText: 'Custom Formatter Example',
                      hintText: 'Caller-defined keystroke rules',
                      controller: customFormatterController,
                      // Supply custom formatters to override built-in numeric enforcement.
                      // These formatters take complete responsibility for keystroke filtering.
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        LengthLimitingTextInputFormatter(5),
                      ],
                      onChanged: (value) {
                        onStateChanged();
                      },
                    ),
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
