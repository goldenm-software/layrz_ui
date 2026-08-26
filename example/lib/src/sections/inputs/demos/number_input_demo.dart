import 'package:flutter/widgets.dart';

import 'number_input_demo_sections.dart';

class NumberInputDemo extends StatefulWidget {
  const NumberInputDemo({super.key});

  @override
  State<NumberInputDemo> createState() => _NumberInputDemoState();
}

class _NumberInputDemoState extends State<NumberInputDemo> {
  // Basic and standard inputs
  late TextEditingController _basicIntController;
  late TextEditingController _basicDecimalController;

  // Interactive examples
  late TextEditingController _quantityController;
  late TextEditingController _ageController;
  late TextEditingController _percentageController;

  // Prefix/suffix variants
  late TextEditingController _currencyController;
  late TextEditingController _weightController;
  late TextEditingController _temperatureController;
  late TextEditingController _volumeController;
  late TextEditingController _suffixOnlyController;

  // Helper text example
  late TextEditingController _intervalController;

  // Decimal separator examples
  late TextEditingController _dotSeparatorController;
  late TextEditingController _commaSeparatorController;

  // Decimal precision examples
  late TextEditingController _precisionZeroController;
  late TextEditingController _precisionTwoController;

  // Negative values examples
  late TextEditingController _nonNegativeController;
  late TextEditingController _allowNegativeController;

  // Custom formatters example
  late TextEditingController _customFormatterController;

  @override
  void initState() {
    super.initState();
    _basicIntController = TextEditingController(text: '5');
    _basicDecimalController = TextEditingController(text: '3.14');
    _quantityController = TextEditingController(text: '1');
    _ageController = TextEditingController(text: '25');
    _percentageController = TextEditingController(text: '50');
    _currencyController = TextEditingController(text: '99.99');
    _weightController = TextEditingController(text: '75.5');
    _temperatureController = TextEditingController(text: '22');
    _volumeController = TextEditingController(text: '500');
    _suffixOnlyController = TextEditingController(text: '60');
    _intervalController = TextEditingController(text: '60');
    _dotSeparatorController = TextEditingController(text: '3.14');
    _commaSeparatorController = TextEditingController(text: '3,14');
    _precisionZeroController = TextEditingController(text: '42');
    _precisionTwoController = TextEditingController(text: '3.14');
    _nonNegativeController = TextEditingController(text: '10');
    _allowNegativeController = TextEditingController(text: '-5');
    _customFormatterController = TextEditingController(text: '123');
  }

  @override
  void dispose() {
    _basicIntController.dispose();
    _basicDecimalController.dispose();
    _quantityController.dispose();
    _ageController.dispose();
    _percentageController.dispose();
    _currencyController.dispose();
    _weightController.dispose();
    _temperatureController.dispose();
    _volumeController.dispose();
    _suffixOnlyController.dispose();
    _intervalController.dispose();
    _dotSeparatorController.dispose();
    _commaSeparatorController.dispose();
    _precisionZeroController.dispose();
    _precisionTwoController.dispose();
    _nonNegativeController.dispose();
    _allowNegativeController.dispose();
    _customFormatterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NumberInputDemoSections(
      basicIntController: _basicIntController,
      basicDecimalController: _basicDecimalController,
      quantityController: _quantityController,
      ageController: _ageController,
      percentageController: _percentageController,
      currencyController: _currencyController,
      weightController: _weightController,
      temperatureController: _temperatureController,
      volumeController: _volumeController,
      suffixOnlyController: _suffixOnlyController,
      intervalController: _intervalController,
      dotSeparatorController: _dotSeparatorController,
      commaSeparatorController: _commaSeparatorController,
      precisionZeroController: _precisionZeroController,
      precisionTwoController: _precisionTwoController,
      nonNegativeController: _nonNegativeController,
      allowNegativeController: _allowNegativeController,
      customFormatterController: _customFormatterController,
      onStateChanged: () => setState(() {}),
    );
  }
}
