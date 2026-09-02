import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Showcases [LayrzBadge] and its bare [LayrzBadgeVisual] building block.
///
/// Demonstrates both API forms (the standalone visual usable inline in a
/// `Row`, and the wrapper that overlays a badge on a child), every content
/// type (number, icon, bare dot), the `99+` overflow boundary, all four
/// corner alignments, every [LayrzBadgeType] semantic color, and (DESIGN-172)
/// a dedicated section for the bare/contentless indicator used to represent
/// connection or presence state (online/away/busy/offline), both standalone
/// and overlaid on an avatar.
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

          SizedBox(height: tokens.spacing.sp4),

          Text('Bare indicator — connection/presence state, no content (DESIGN-172)', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          Text(
            'When both count and icon are omitted, the badge renders as a plain dot — the '
            'conventional online/offline/away/busy presence indicator. LayrzBadge.label is '
            'still required in this form and drives the announced accessibility label (e.g. '
            '"Status, new") since a bare dot has no text of its own for a screen reader to read.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),

          Text('Standalone, by semantic state', style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
          SizedBox(height: tokens.spacing.sp2),
          Row(
            children: [
              for (final state in _ConnectionState.values) ...[
                Column(
                  children: [
                    LayrzBadgeVisual(type: state.type),
                    SizedBox(height: tokens.spacing.sp1),
                    Text(state.label, style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
                  ],
                ),
                SizedBox(width: tokens.spacing.sp4),
              ],
            ],
          ),

          SizedBox(height: tokens.spacing.sp4),

          Text(
            'Overlaid on an avatar — the real use case',
            style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp2),
          Row(
            children: [
              for (final state in _ConnectionState.values) ...[
                Column(
                  children: [
                    LayrzBadge(
                      label: '${state.label} contact',
                      type: state.type,
                      alignment: LayrzBadgeAlignment.bottomRight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: tokens.colors.sf2,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(MdiIcons.account, color: tokens.colors.fg3),
                        ),
                      ),
                    ),
                    SizedBox(height: tokens.spacing.sp1),
                    Text(state.label, style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
                  ],
                ),
                SizedBox(width: tokens.spacing.sp4),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The connection/presence states demonstrated by the bare-indicator section.
///
/// Each maps to one of [LayrzBadgeType]'s semantic colors — the conventional
/// vocabulary for presence dots (green for online, grey for offline, and so
/// on) reusing the same accent tokens every other badge form draws from.
enum _ConnectionState {
  /// The contact is online and reachable — mapped to [LayrzBadgeType.success].
  online(label: 'Online', type: LayrzBadgeType.success),

  /// The contact is away from their device — mapped to [LayrzBadgeType.warning].
  away(label: 'Away', type: LayrzBadgeType.warning),

  /// The contact has marked themselves unavailable — mapped to [LayrzBadgeType.danger].
  busy(label: 'Busy', type: LayrzBadgeType.danger),

  /// The contact is offline — mapped to [LayrzBadgeType.context], a neutral
  /// accent rather than [LayrzBadgeType.info] since "offline" carries no
  /// informational urgency.
  offline(label: 'Offline', type: LayrzBadgeType.context);

  /// Creates a connection state demo entry.
  const _ConnectionState({required this.label, required this.type});

  /// The human-readable caption shown under each demo swatch.
  final String label;

  /// The [LayrzBadgeType] semantic color this state maps to.
  final LayrzBadgeType type;
}
