import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../common/showroom_section.dart';
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

  /// Drives the desktop table's sort/search/column/selection state.
  late LayrzTableController<InputDemo> _tableController;

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
    _tableController = LayrzTableController<InputDemo>();
  }

  @override
  void dispose() {
    _controller.dispose();
    _tableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayrzScaffoldShell<InputDemo>(
      title: Text('Inputs Showcase', style: context.tokens.typography.title),
      // Row height for a single-line tile (avatar + title).
      itemExtent: 41.0,
      items: _allDemos.map((demo) {
        return LayrzScaffoldItem<InputDemo>(
          key: ValueKey(demo.id),
          item: demo,
          tile: _buildTile(demo),
          searchableStrings: {demo.name, demo.category},
        );
      }).toList(),
      // Desktop opens on this table; opening a row collapses to the list-detail split.
      tableController: _tableController,
      tableColumns: [
        LayrzColumn<InputDemo>(
          key: const ValueKey('name'),
          headerText: 'Name',
          valueBuilder: (demo) => demo.name,
          width: 240,
        ),
        LayrzColumn<InputDemo>(
          key: const ValueKey('category'),
          headerText: 'Category',
          valueBuilder: (demo) => demo.category,
          width: 200,
        ),
      ],
      controller: _controller,
      searchable: true,
      onItemTap: (item) => _controller.open(
        key: item.key,
        builder: (context) => _buildDetails(item.item),
      ),
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
  ///
  /// Wraps [InputDemo.details] in the same [ShowroomSection] scaffold every
  /// other showroom view uses (top-anchored, scrollable, full-width content
  /// inside a [LayrzCard]), so a selected Inputs demo reads structurally
  /// identically to e.g. the Buttons or Alerts section rather than as a bare,
  /// unstyled pane.
  Widget _buildDetails(InputDemo demo) => Stack(
    children: [
      ShowroomSection(
        title: demo.name,
        child: demo.details,
      ),
      // Closing the detail is the app's responsibility (the shell only
      // cross-fades table<->split off the controller's open state), so the
      // showcase overlays its own close affordance here. A Stack overlay keeps
      // ShowroomSection's own SingleChildScrollView as the height-owning child,
      // rather than a Column that would break its bounded-height contract.
      Positioned(
        top: 0,
        right: 0,
        child: LayrzButton(
          icon: MdiIcons.close,
          style: LayrzButtonStyle.textFab,
          labelText: 'Close',
          onTap: _controller.close,
        ),
      ),
    ],
  );
}
