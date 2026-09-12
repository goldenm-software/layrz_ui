import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../common/showroom_section.dart';
import '../inputs/input_demo.dart';
import '../inputs/demos/date_input_demo.dart';
import '../inputs/demos/date_range_input_demo.dart';
import '../inputs/demos/time_input_demo.dart';
import '../inputs/demos/time_range_input_demo.dart';
import '../inputs/demos/datetime_input_demo.dart';
import '../inputs/demos/datetime_range_input_demo.dart';
import '../inputs/demos/month_input_demo.dart';
import '../inputs/demos/month_range_input_demo.dart';
import '../inputs/demos/color_input_demo.dart';
import '../inputs/demos/dual_list_input_demo.dart';
import '../inputs/demos/multi_select_input_demo.dart';
import '../inputs/demos/emoji_input_demo.dart';
import '../inputs/demos/icon_input_demo.dart';
import '../inputs/demos/dynamic_avatar_input_demo.dart';

/// A list-detail showcase of all picker components in the layrz_ui design system.
///
/// The left pane displays a searchable list of all picker components,
/// ordered by category. The right pane shows all variants of the selected component.
/// On narrow screens, panes toggle via a back affordance.
///
/// Mirrors the structure of `InputsSection` exactly, reusing the same [InputDemo]
/// registry entry type and the same demo widgets under `../inputs/demos/`. The two
/// sections were split so that date/time/color/selection pickers get their own
/// dedicated showcase separate from the simpler text/numeric/boolean inputs.
class PickersSection extends StatefulWidget {
  /// Creates a new [PickersSection].
  const PickersSection({super.key});

  @override
  State<PickersSection> createState() => _PickersSectionState();
}

class _PickersSectionState extends State<PickersSection> {
  late LayrzScaffoldController _controller;

  /// The canonical registry of all picker component demos.
  /// Ordered by category, then by name within each category.
  static const List<InputDemo> _allDemos = [
    // Date & Time category
    InputDemo(
      id: 'date-input',
      name: 'Date Input',
      category: 'Date & Time',
      details: DateInputDemo(),
      icon: MdiIcons.calendarOutline,
    ),
    InputDemo(
      id: 'date-range-input',
      name: 'Date Range Input',
      category: 'Date & Time',
      details: DateRangeInputDemo(),
      icon: MdiIcons.calendarRangeOutline,
    ),
    InputDemo(
      id: 'time-input',
      name: 'Time Input',
      category: 'Date & Time',
      details: TimeInputDemo(),
      icon: MdiIcons.clockOutline,
    ),
    InputDemo(
      id: 'time-range-input',
      name: 'Time Range Input',
      category: 'Date & Time',
      details: TimeRangeInputDemo(),
      icon: MdiIcons.clockTimeFourOutline,
    ),
    InputDemo(
      id: 'datetime-input',
      name: 'DateTime Input',
      category: 'Date & Time',
      details: DateTimeInputDemo(),
      icon: MdiIcons.calendarClockOutline,
    ),
    InputDemo(
      id: 'datetime-range-input',
      name: 'DateTime Range Input',
      category: 'Date & Time',
      details: DateTimeRangeInputDemo(),
      icon: MdiIcons.calendarClock,
    ),
    InputDemo(
      id: 'month-input',
      name: 'Month Input',
      category: 'Date & Time',
      details: MonthInputDemo(),
      icon: MdiIcons.calendarMonthOutline,
    ),
    InputDemo(
      id: 'month-range-input',
      name: 'Month Range Input',
      category: 'Date & Time',
      details: MonthRangeInputDemo(),
      icon: MdiIcons.calendarMultiselectOutline,
    ),

    // Pickers category
    InputDemo(
      id: 'color-input',
      name: 'Color Input',
      category: 'Pickers',
      details: ColorInputDemo(),
      icon: MdiIcons.paletteOutline,
    ),
    InputDemo(
      id: 'multi-select-input',
      name: 'Multi-Select Input',
      category: 'Pickers',
      details: MultiSelectInputDemo(),
      icon: MdiIcons.checkboxMultipleMarkedOutline,
    ),
    InputDemo(
      id: 'dual-list-input',
      name: 'Dual-List Input',
      category: 'Pickers',
      details: DualListInputDemo(),
      icon: MdiIcons.swapHorizontal,
    ),
    InputDemo(
      id: 'emoji-input',
      name: 'Emoji Input',
      category: 'Pickers',
      details: EmojiInputDemo(),
      icon: MdiIcons.emoticonOutline,
    ),
    InputDemo(
      id: 'icon-input',
      name: 'Icon Input',
      category: 'Pickers',
      details: IconInputDemo(),
      icon: MdiIcons.shapeOutline,
    ),
    InputDemo(
      id: 'dynamic-avatar-input',
      name: 'Dynamic Avatar Input',
      category: 'Pickers',
      details: DynamicAvatarInputDemo(),
      icon: MdiIcons.accountCircleOutline,
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
      title: Text('Pickers Showcase', style: context.tokens.typography.title),
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
      onItemTap: (item) => _controller.open(
        key: item.key,
        builder: (context) => _buildDetails(item.item),
      ),
    );
  }

  /// Builds a tile for a single picker component in the list.
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

  /// Builds the detail pane content for a selected picker component.
  ///
  /// Wraps [InputDemo.details] in the same [ShowroomSection] scaffold every
  /// other showroom view uses (top-anchored, scrollable, full-width content
  /// inside a [LayrzCard]), so a selected Pickers demo reads structurally
  /// identically to e.g. the Buttons or Alerts section rather than as a bare,
  /// unstyled pane.
  Widget _buildDetails(InputDemo demo) => ShowroomSection(
    title: demo.name,
    child: demo.details,
  );
}
