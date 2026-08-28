import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds the timelines section for the showroom.
///
/// Demonstrates [LayrzTimeline] in its two-sided form (the default above the
/// compact breakpoint) and its one-sided form, plus the automatic collapse
/// that switches between them at `context.isCompact` -- resize this page's
/// window below 960px to see the two-sided demo collapse on its own, with no
/// extra configuration.
///
/// [LayrzTimeline.isCompactOverride] is demonstrated separately: a toggle
/// forces the one-sided layout regardless of the current viewport, showing
/// that the override is available for callers who need it without lying
/// about the window's actual size elsewhere.
class TimelineSection extends StatefulWidget {
  /// Creates a new [TimelineSection].
  const TimelineSection({super.key});

  @override
  State<TimelineSection> createState() => _TimelineSectionState();
}

class _TimelineSectionState extends State<TimelineSection> {
  /// Whether the "force one-sided" override toggle is on.
  bool _forceOneSided = false;

  /// Sample entries for the two-sided demo, alternating sides automatically.
  List<LayrzTimelineEntry> get _orderEntries => [
    const LayrzTimelineEntry(
      labelText: 'Order placed',
      descriptionText: 'Payment confirmed and order queued for fulfilment.',
      timestampText: 'Aug 26, 09:14',
      icon: MdiIcons.cartOutline,
    ),
    const LayrzTimelineEntry(
      labelText: 'Payment failed',
      descriptionText: 'The card issuer declined the first attempt.',
      timestampText: 'Aug 26, 09:15',
      icon: MdiIcons.alertCircleOutline,
      accentColor: Color(0xFFD32F2F),
    ),
    const LayrzTimelineEntry(
      labelText: 'Payment retried',
      descriptionText: 'A second attempt with a different card succeeded.',
      timestampText: 'Aug 26, 09:20',
      icon: MdiIcons.creditCardCheckOutline,
      accentColor: Color(0xFF2E7D32),
    ),
    const LayrzTimelineEntry(
      labelText: 'Shipped',
      descriptionText: 'Package handed to the carrier.',
      timestampText: 'Aug 27, 14:02',
      icon: MdiIcons.truckOutline,
    ),
    const LayrzTimelineEntry(
      labelText: 'Delivered',
      descriptionText: 'Package left at the front desk.',
      timestampText: 'Aug 28, 11:47',
      icon: MdiIcons.packageVariantClosedCheck,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Timelines',
      description:
          'A vertical spine of dated events. Two-sided by default above 960px, collapsing to '
          'one-sided automatically below it -- try resizing this window.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Automatic layout', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'Resize the window below 960px to see this collapse to one-sided on its own.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzTimeline(entries: _orderEntries),
          SizedBox(height: tokens.spacing.sp4),
          Text('Forced one-sided via isCompactOverride', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'This toggle passes isCompactOverride explicitly, independent of the real viewport '
            'width -- for callers embedding the timeline in a narrow pane on an otherwise wide window.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp2),
          Row(
            children: [
              LayrzButton(
                labelText: _forceOneSided ? 'Showing one-sided (forced)' : 'Showing automatic layout',
                style: _forceOneSided ? LayrzButtonStyle.elevated : LayrzButtonStyle.outlined,
                onTap: () => setState(() => _forceOneSided = !_forceOneSided),
              ),
            ],
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzTimeline(
            entries: _orderEntries,
            isCompactOverride: _forceOneSided ? true : null,
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('One-sided only (twoSided: false)', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'twoSided: false always renders the one-sided layout, regardless of viewport width.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzTimeline(entries: _orderEntries, twoSided: false),
        ],
      ),
    );
  }
}
