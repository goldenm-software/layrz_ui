import 'package:flutter/widgets.dart';

import 'textarea_input_demo_sections.dart';

/// Stateful widget that manages text editing controllers for the textarea input showcase.
class TextAreaInputDemo extends StatefulWidget {
  const TextAreaInputDemo({super.key});

  @override
  State<TextAreaInputDemo> createState() => _TextAreaInputDemoState();
}

class _TextAreaInputDemoState extends State<TextAreaInputDemo> {
  // Field states
  late TextEditingController _basicController;
  late TextEditingController _requiredController;

  // Disabled and read-only
  late TextEditingController _disabledController;
  late TextEditingController _readOnlyController;

  // Error states
  late TextEditingController _errorController;

  // Character limit
  late TextEditingController _charLimitController;

  // Variable line count
  late TextEditingController _minimalLinesController;
  late TextEditingController _expansiveLinesController;

  // Prefix/suffix slots
  late TextEditingController _prefixIconController;
  late TextEditingController _prefixWidgetController;
  late TextEditingController _prefixTextController;
  late TextEditingController _suffixIconController;
  late TextEditingController _suffixWidgetController;
  late TextEditingController _suffixTextController;

  // Help affordance
  late TextEditingController _helpController;

  // Top alignment demo
  late TextEditingController _topAlignWithContentController;
  late TextEditingController _topAlignEmptyController;

  // Live interaction
  late TextEditingController _liveInteractionController;

  // Input formatters
  late TextEditingController _formatterController;

  // Keyboard behaviour
  late TextEditingController _keyboardController;

  // Padding override
  late TextEditingController _customPaddingController;
  late TextEditingController _defaultPaddingController;

  @override
  void initState() {
    super.initState();
    // Field states
    _basicController = TextEditingController();
    _requiredController = TextEditingController();

    // Disabled and read-only
    _disabledController = TextEditingController(text: 'This field is disabled');
    _readOnlyController = TextEditingController(text: 'This field is read-only');

    // Error states
    _errorController = TextEditingController();

    // Character limit
    _charLimitController = TextEditingController();

    // Variable line count
    _minimalLinesController = TextEditingController();
    _expansiveLinesController = TextEditingController();

    // Prefix/suffix slots
    _prefixIconController = TextEditingController();
    _prefixWidgetController = TextEditingController();
    _prefixTextController = TextEditingController();
    _suffixIconController = TextEditingController();
    _suffixWidgetController = TextEditingController();
    _suffixTextController = TextEditingController();

    // Help affordance
    _helpController = TextEditingController();

    // Top alignment demo
    _topAlignWithContentController = TextEditingController(
      text: 'Line 1\nLine 2\nLine 3',
    );
    _topAlignEmptyController = TextEditingController();

    // Live interaction
    _liveInteractionController = TextEditingController();

    // Input formatters
    _formatterController = TextEditingController();

    // Keyboard behaviour
    _keyboardController = TextEditingController();

    // Padding override
    _customPaddingController = TextEditingController();
    _defaultPaddingController = TextEditingController();
  }

  @override
  void dispose() {
    // Field states
    _basicController.dispose();
    _requiredController.dispose();

    // Disabled and read-only
    _disabledController.dispose();
    _readOnlyController.dispose();

    // Error states
    _errorController.dispose();

    // Character limit
    _charLimitController.dispose();

    // Variable line count
    _minimalLinesController.dispose();
    _expansiveLinesController.dispose();

    // Prefix/suffix slots
    _prefixIconController.dispose();
    _prefixWidgetController.dispose();
    _prefixTextController.dispose();
    _suffixIconController.dispose();
    _suffixWidgetController.dispose();
    _suffixTextController.dispose();

    // Help affordance
    _helpController.dispose();

    // Top alignment demo
    _topAlignWithContentController.dispose();
    _topAlignEmptyController.dispose();

    // Live interaction
    _liveInteractionController.dispose();

    // Input formatters
    _formatterController.dispose();

    // Keyboard behaviour
    _keyboardController.dispose();

    // Padding override
    _customPaddingController.dispose();
    _defaultPaddingController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextAreaInputDemoSections(
      basicController: _basicController,
      requiredController: _requiredController,
      disabledController: _disabledController,
      readOnlyController: _readOnlyController,
      errorController: _errorController,
      charLimitController: _charLimitController,
      minimalLinesController: _minimalLinesController,
      expansiveLinesController: _expansiveLinesController,
      prefixIconController: _prefixIconController,
      prefixWidgetController: _prefixWidgetController,
      prefixTextController: _prefixTextController,
      suffixIconController: _suffixIconController,
      suffixWidgetController: _suffixWidgetController,
      suffixTextController: _suffixTextController,
      helpController: _helpController,
      topAlignWithContentController: _topAlignWithContentController,
      topAlignEmptyController: _topAlignEmptyController,
      liveInteractionController: _liveInteractionController,
      formatterController: _formatterController,
      keyboardController: _keyboardController,
      customPaddingController: _customPaddingController,
      defaultPaddingController: _defaultPaddingController,
      onStateChanged: () => setState(() {}),
    );
  }
}
