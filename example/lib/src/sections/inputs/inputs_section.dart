import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import 'input_demo.dart';
import 'demos/text_input_demo.dart';
import 'demos/textarea_input_demo.dart';
import 'demos/number_input_demo.dart';
import 'demos/slider_demo.dart';
import 'demos/checkbox_input_demo.dart';
import 'demos/switch_input_demo.dart';
import 'demos/radio_input_demo.dart';
import 'demos/search_input_demo.dart';
import 'demos/combobox_input_demo.dart';
import 'demos/select_input_demo.dart';
import 'demos/duration_input_demo.dart';
import 'demos/login_input_demo.dart';

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
      details: TextInputDemo(),
      icon: MdiIcons.textBoxOutline,
    ),
    InputDemo(
      id: 'textarea-input',
      name: 'Text Area Input',
      category: 'Text',
      details: TextAreaInputDemo(),
      icon: MdiIcons.textBoxMultipleOutline,
    ),

    // Numeric category
    InputDemo(
      id: 'number-input',
      name: 'Number Input',
      category: 'Numeric',
      details: NumberInputDemo(),
      icon: MdiIcons.numeric,
    ),
    InputDemo(
      id: 'slider',
      name: 'Slider',
      category: 'Numeric',
      details: SliderDemo(),
      icon: MdiIcons.tuneVariant,
    ),

    // Boolean category
    InputDemo(
      id: 'checkbox-input',
      name: 'Checkbox Input',
      category: 'Boolean',
      details: CheckboxInputDemo(),
      icon: MdiIcons.checkboxMarkedOutline,
    ),
    InputDemo(
      id: 'switch-input',
      name: 'Switch Input',
      category: 'Boolean',
      details: SwitchInputDemo(),
      icon: MdiIcons.toggleSwitchOutline,
    ),

    // Choice category
    InputDemo(
      id: 'radio-input',
      name: 'Radio Input',
      category: 'Choice',
      details: RadioInputDemo(),
      icon: MdiIcons.radioboxMarked,
    ),
    InputDemo(
      id: 'combobox-input',
      name: 'ComboBox Input',
      category: 'Choice',
      details: ComboBoxInputDemo(),
      icon: MdiIcons.menuDown,
    ),
    InputDemo(
      id: 'select-input',
      name: 'Select Input',
      category: 'Choice',
      details: SelectInputDemo(),
      icon: MdiIcons.menuDown,
    ),

    InputDemo(
      id: 'duration-input',
      name: 'Duration Input',
      category: 'Choice',
      details: DurationInputDemo(),
      icon: MdiIcons.timerOutline,
    ),

    // Search category
    InputDemo(
      id: 'search-input',
      name: 'Search Input',
      category: 'Search',
      details: SearchInputDemo(),
      icon: MdiIcons.magnify,
    ),

    // Login category
    InputDemo(
      id: 'login-input',
      name: 'Login Inputs',
      category: 'Login',
      details: LoginInputDemo(),
      icon: MdiIcons.formTextboxPassword,
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
      // 45.0 (LayrzButton FAB height) + 2 * 10.0 (LayrzRow's pd2 vertical padding
      // around the row content) = 65.0 is the minimum extent that fits the two
      // revealed edit/delete FABs without vertical overflow; 68.0 leaves a small
      // margin of breathing room.
      itemExtent: 41.0,
      items: _allDemos.map((demo) {
        return LayrzScaffoldItem<InputDemo>(
          key: ValueKey(demo.id),
          item: demo,
          tile: _buildTile(demo),
          searchableStrings: {demo.name, demo.category},
          actions: [
            LayrzButton.edit(
              labelText: 'Edit ${demo.name}',
              isFab: true,
              style: .text,
              onTap: () {
                LayrzResponsiveModal.show(
                  context,
                  semanticLabel: 'Action fired',
                  builder: (modalContext) {
                    final tokens = modalContext.tokens;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      spacing: tokens.spacing.sp2,
                      children: [
                        Text(
                          'Action fired',
                          style: tokens.typography.title.copyWith(fontWeight: .bold),
                        ),
                        Text(
                          'This is a placeholder for the edit action of the ${demo.name} input component.',
                          style: tokens.typography.body,
                        ),
                      ],
                    );
                  },
                  actions: [
                    Builder(
                      builder: (modalContext) => LayrzButton.cancel(
                        labelText: 'Close',
                        onTap: () => Navigator.of(modalContext, rootNavigator: true).pop(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
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
    return Row(
      mainAxisAlignment: .start,
      crossAxisAlignment: .center,
      spacing: tokens.spacing.sp1,
      children: [
        LayrzAvatar.icon(
          icon: demo.icon,
          size: 30.0,
          borderRadius: tokens.radius.r2,
          elevation: 0,
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: .start,
            mainAxisAlignment: .start,
            children: [
              Text(
                demo.name,
                style: tokens.typography.body.copyWith(fontWeight: .bold),
                overflow: TextOverflow.ellipsis,
              ),
              LayrzChip(
                labelText: demo.category,
                // style: tokens.typography.label,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the detail pane content for a selected input component.
  /// Renders all meaningful variants of that component.
  Widget _buildDetails(InputDemo demo) => demo.details;
}
