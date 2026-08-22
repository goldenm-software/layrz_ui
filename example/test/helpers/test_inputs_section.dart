import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:example/src/sections/inputs/input_demo.dart';
import 'package:example/src/sections/inputs/demos/text_input_demo.dart';
import 'package:example/src/sections/inputs/demos/textarea_input_demo.dart';
import 'package:example/src/sections/inputs/demos/number_input_demo.dart';
import 'package:example/src/sections/inputs/demos/checkbox_input_demo.dart';
import 'package:example/src/sections/inputs/demos/switch_input_demo.dart';
import 'package:example/src/sections/inputs/demos/radio_input_demo.dart';
import 'package:example/src/sections/inputs/demos/search_input_demo.dart';
import 'package:example/src/sections/inputs/demos/combobox_input_demo.dart';
import 'package:example/src/sections/inputs/demos/stepper_demo.dart';

/// A test-friendly wrapper around InputsSection that renders it with proper theming.
class TestInputsSection extends StatefulWidget {
  const TestInputsSection({super.key});

  @override
  State<TestInputsSection> createState() => _TestInputsSectionState();
}

class _TestInputsSectionState extends State<TestInputsSection> {
  late LayrzScaffoldController<InputDemo> _controller;

  /// The canonical registry of all input component demos.
  static const List<InputDemo> _allDemos = [
    // Text category
    InputDemo(
      id: 'text-input',
      name: 'Text Input',
      category: 'Text',
      detailsBuilder: buildTextInputDemo,
    ),
    InputDemo(
      id: 'textarea-input',
      name: 'Text Area Input',
      category: 'Text',
      detailsBuilder: buildTextAreaInputDemo,
    ),

    // Numeric category
    InputDemo(
      id: 'number-input',
      name: 'Number Input',
      category: 'Numeric',
      detailsBuilder: buildNumberInputDemo,
    ),

    // Boolean category
    InputDemo(
      id: 'checkbox-input',
      name: 'Checkbox Input',
      category: 'Boolean',
      detailsBuilder: buildCheckboxInputDemo,
    ),
    InputDemo(
      id: 'switch-input',
      name: 'Switch Input',
      category: 'Boolean',
      detailsBuilder: buildSwitchInputDemo,
    ),

    // Choice category
    InputDemo(
      id: 'radio-input',
      name: 'Radio Input',
      category: 'Choice',
      detailsBuilder: buildRadioInputDemo,
    ),
    InputDemo(
      id: 'combobox-input',
      name: 'ComboBox Input',
      category: 'Choice',
      detailsBuilder: buildComboBoxInputDemo,
    ),

    // Search category
    InputDemo(
      id: 'search-input',
      name: 'Search Input',
      category: 'Search',
      detailsBuilder: buildSearchInputDemo,
    ),

    // Flow category
    InputDemo(
      id: 'stepper',
      name: 'Stepper',
      category: 'Flow',
      detailsBuilder: buildStepperDemo,
    ),
  ];

  late List<InputDemo> _filteredDemos = _allDemos;

  @override
  void initState() {
    super.initState();
    _controller = LayrzScaffoldController<InputDemo>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDemos = _allDemos;
      } else {
        final lowercaseQuery = query.toLowerCase();
        _filteredDemos = _allDemos
            .where(
              (demo) =>
                  demo.name.toLowerCase().contains(lowercaseQuery) ||
                  demo.category.toLowerCase().contains(lowercaseQuery),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayrzScaffoldShell<InputDemo>(
      items: _filteredDemos,
      controller: _controller,
      searchable: true,
      onSearch: _updateSearch,
      onBuild: _buildTile,
      onDetailsBuild: _buildDetails,
    );
  }

  LayrzScaffoldTile _buildTile(BuildContext context, InputDemo demo) {
    final tokens = context.tokens;

    return LayrzScaffoldValueTile(
      title: RichText(
        text: TextSpan(
          text: demo.name,
          style: tokens.typography.body.copyWith(
            color: tokens.colors.fg1,
          ),
        ),
      ),
      subtitle: RichText(
        text: TextSpan(
          text: demo.category,
          style: tokens.typography.label.copyWith(
            color: tokens.colors.fg3,
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, InputDemo demo) {
    return demo.detailsBuilder(context);
  }
}
