import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../common/showroom_section.dart';

/// The content widget for the tab view section.
///
/// Shows multiple demo subsections illustrating [LayrzTabView]'s scrollable
/// (overflowing) strip, its expanded (evenly-shared-width) strip, and tabs
/// using leading/trailing icon slots.
class TabViewSection extends StatelessWidget {
  /// Creates a new [TabViewSection].
  const TabViewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Tab View',
      description: 'Material-free tab strip and content switcher with scrollable and expanded layout modes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScrollableDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp5),

          _ExpandedDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp5),

          _IconSlotsDemo(tokens: tokens),
        ],
      ),
    );
  }
}

/// Demonstrates the default scrollable strip with enough tabs to overflow.
///
/// [LayrzTabView.isScrollable] defaults to `true`: pills size to their own
/// content in a start-aligned horizontal row that scrolls when the tabs
/// overflow the available width.
class _ScrollableDemo extends StatelessWidget {
  /// Creates a new [_ScrollableDemo].
  const _ScrollableDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Scrollable Strip', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'The default layout. Pills size to their own content and the strip scrolls '
          'horizontally when there are enough tabs to overflow the available width.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        LayrzTabView(
          tabs: [
            for (final label in const [
              'Overview',
              'Details',
              'Specifications',
              'Documents',
              'History',
              'Maintenance',
              'Settings',
            ])
              LayrzTab(
                labelText: label,
                child: _DemoPanel(text: '$label panel content', tokens: tokens),
              ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates the expanded strip, where pills share the available width
/// evenly instead of scrolling.
///
/// Passing `isScrollable: false` lays each pill out in an `Expanded` cell of
/// a `Row`, so a small, fixed set of tabs fills the strip's full width.
class _ExpandedDemo extends StatelessWidget {
  /// Creates a new [_ExpandedDemo].
  const _ExpandedDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Expanded Strip', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'With isScrollable set to false, tabs share the strip\'s width evenly '
          'instead of scrolling — a good fit for a small, fixed number of tabs.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        LayrzTabView(
          isScrollable: false,
          tabs: [
            LayrzTab(
              labelText: 'Daily',
              child: _DemoPanel(text: 'Daily panel content', tokens: tokens),
            ),
            LayrzTab(
              labelText: 'Weekly',
              child: _DemoPanel(text: 'Weekly panel content', tokens: tokens),
            ),
            LayrzTab(
              labelText: 'Monthly',
              child: _DemoPanel(text: 'Monthly panel content', tokens: tokens),
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates tabs using the leading and trailing icon slots.
///
/// [LayrzTab.leadingIcon] and [LayrzTab.trailingIcon] render an [Icon] before
/// and after the label respectively, coloured to match the tab's current
/// label colour.
class _IconSlotsDemo extends StatefulWidget {
  /// Creates a new [_IconSlotsDemo].
  const _IconSlotsDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  State<_IconSlotsDemo> createState() => _IconSlotsDemoState();
}

class _IconSlotsDemoState extends State<_IconSlotsDemo> {
  /// The index most recently reported by [LayrzTabView.onTabChanged].
  int _lastChangedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Leading & Trailing Icons', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'Tabs can carry a leading icon, a trailing icon, or both, alongside the label. '
          'Switching tabs updates the panel below and the last-changed index.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        LayrzTabView(
          onTabChanged: (index) => setState(() => _lastChangedIndex = index),
          tabs: [
            LayrzTab(
              labelText: 'Inbox',
              leadingIcon: MdiIcons.emailOutline,
              child: _DemoPanel(text: 'Inbox panel content', tokens: tokens),
            ),
            LayrzTab(
              labelText: 'Starred',
              leadingIcon: MdiIcons.starOutline,
              child: _DemoPanel(text: 'Starred panel content', tokens: tokens),
            ),
            LayrzTab(
              labelText: 'Alerts',
              trailingIcon: MdiIcons.bellOutline,
              child: _DemoPanel(text: 'Alerts panel content', tokens: tokens),
            ),
          ],
        ),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'Last onTabChanged index: $_lastChangedIndex',
          style: tokens.typography.label.copyWith(color: tokens.colors.success[500]),
        ),
      ],
    );
  }
}

/// A simple bordered panel used as a tab's [LayrzTab.child] content, so
/// switching between tabs is visibly demonstrated.
class _DemoPanel extends StatelessWidget {
  /// Creates a new [_DemoPanel].
  const _DemoPanel({required this.text, required this.tokens});

  /// The text displayed inside the panel.
  final String text;

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: tokens.spacing.sp3),
      padding: EdgeInsets.all(tokens.spacing.sp4),
      decoration: BoxDecoration(
        color: tokens.colors.sf2,
        border: Border.all(color: tokens.colors.divider, width: 1),
        borderRadius: tokens.radius.br2,
      ),
      child: Text(
        text,
        style: tokens.typography.body.copyWith(color: tokens.colors.fg2),
      ),
    );
  }
}
