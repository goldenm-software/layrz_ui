import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Showcases [LayrzBadge] and its bare [LayrzBadgeVisual] building block.
///
/// Demonstrates both API forms (the standalone visual usable inline in a
/// `Row`, and the wrapper that overlays a badge on a child), every content
/// type (number, icon, bare dot), the `99+` overflow boundary, all four
/// corner alignments, and every [LayrzBadgeType] semantic color.
class BadgeSection extends StatelessWidget {
  const BadgeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Badges',
      description: 'Notification badges — number, icon, or bare-dot content, standalone or overlaid',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wrapper form — LayrzBadge overlaid on a child', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          Row(
            children: [
              LayrzBadge(
                label: 'Notifications',
                count: 3,
                child: Icon(MdiIcons.bell, size: 28),
              ),
              SizedBox(width: tokens.spacing.sp5),
              LayrzBadge(
                label: 'Overflowing notifications',
                count: 250,
                child: Icon(MdiIcons.bell, size: 28),
              ),
              SizedBox(width: tokens.spacing.sp5),
              LayrzBadge(
                label: 'Sync pending',
                icon: MdiIcons.sync,
                type: LayrzBadgeType.info,
                child: Icon(MdiIcons.cloud, size: 28),
              ),
              SizedBox(width: tokens.spacing.sp5),
              LayrzBadge(
                label: 'Online status',
                type: LayrzBadgeType.success,
                child: Icon(MdiIcons.account, size: 28),
              ),
            ],
          ),

          SizedBox(height: tokens.spacing.sp4),

          Text('Count overflow boundary — 99 vs 100', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          Row(
            children: [
              LayrzBadge(
                label: 'Below the cap',
                count: 99,
                child: Icon(MdiIcons.bell, size: 28),
              ),
              SizedBox(width: tokens.spacing.sp5),
              LayrzBadge(
                label: 'At the cap',
                count: 100,
                child: Icon(MdiIcons.bell, size: 28),
              ),
            ],
          ),

          SizedBox(height: tokens.spacing.sp4),

          Text('Corner alignments', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          Row(
            children: [
              for (final alignment in LayrzBadgeAlignment.values) ...[
                LayrzBadge(
                  label: alignment.name,
                  count: 1,
                  alignment: alignment,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tokens.colors.sf2,
                        borderRadius: BorderRadius.circular(tokens.radius.r2),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: tokens.spacing.sp4),
              ],
            ],
          ),

          SizedBox(height: tokens.spacing.sp4),

          Text('Semantic color types', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          Row(
            children: [
              for (final type in LayrzBadgeType.values.where((t) => t != LayrzBadgeType.custom)) ...[
                Column(
                  children: [
                    LayrzBadgeVisual(count: 5, type: type),
                    SizedBox(height: tokens.spacing.sp1),
                    Text(type.name, style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
                  ],
                ),
                SizedBox(width: tokens.spacing.sp4),
              ],
            ],
          ),

          SizedBox(height: tokens.spacing.sp4),

          Text('Bare visual form — inline in a Row, like LayrzLayoutRailItem', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Inbox', style: tokens.typography.body),
              SizedBox(width: tokens.spacing.sp2),
              const LayrzBadgeVisual(count: 12),
            ],
          ),
        ],
      ),
    );
  }
}
