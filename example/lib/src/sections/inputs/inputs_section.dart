import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import 'input_demo.dart';
import 'demos/text_input_demo.dart';
import 'demos/textarea_input_demo.dart';
import 'demos/number_input_demo.dart';
import 'demos/checkbox_input_demo.dart';
import 'demos/switch_input_demo.dart';
import 'demos/radio_input_demo.dart';
import 'demos/search_input_demo.dart';
import 'demos/combobox_input_demo.dart';
import 'demos/stepper_demo.dart';

/// A list-detail showcase of all input components in the layrz_ui design system.
///
/// The left pane displays a searchable list of all input components,
/// ordered by category. The right pane shows all variants of the selected component.
/// On narrow screens, panes toggle via a back affordance.
class InputsSection extends StatefulWidget {
  const InputsSection({super.key});

  @override
  State<InputsSection> createState() => _InputsSectionState();
}

class _InputsSectionState extends State<InputsSection> {
  late LayrzScaffoldController _controller;

  /// The canonical registry of all input component demos.
  /// Ordered by category, then by name within each category.
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

    // TODO(DESIGN-40/DESIGN-44): SelectInput and DurationInput will be added here
    // once they land on development:
    // InputDemo(
    //   id: 'select-input',
    //   name: 'Select Input',
    //   category: 'Choice',
    //   detailsBuilder: buildSelectInputDemo,
    // ),
    // InputDemo(
    //   id: 'duration-input',
    //   name: 'Duration Input',
    //   category: 'Numeric',
    //   detailsBuilder: buildDurationInputDemo,
    // ),

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

  @override
  void initState() {
    super.initState();
    _controller = LayrzScaffoldController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayrzScaffoldShell<InputDemo>(
      title: Text('Inputs Showcase', style: context.tokens.typography.title),
      itemExtent: 56.0,
      items: _allDemos.map((demo) {
        return LayrzScaffoldItem<InputDemo>(
          key: ValueKey(demo.id),
          item: demo,
          tile: _buildTile(demo),
          searchableStrings: {demo.name, demo.category},
        );
      }).toList(),
      controller: _controller,
      searchable: true,
      onDetailsBuild: _buildDetails,
    );
  }

  /// Builds a tile for a single input component in the list.
  /// Title is the component name, subtitle is the category.
  Widget _buildTile(InputDemo demo) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: .start,
      mainAxisAlignment: .start,
      children: [
        Text(demo.name, style: tokens.typography.body.copyWith(fontWeight: .bold)),
        LayrzChip(
          labelText: demo.category,
          color: LayrzColors.blue,
        ),
      ],
    );
  }

  /// Builds the detail pane content for a selected input component.
  /// Renders all meaningful variants of that component.
  Widget _buildDetails(InputDemo demo) {
    return demo.detailsBuilder(context);
  }
}
