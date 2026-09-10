import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Showcases [LayrzConnectionIndicator] in both of its render modes, plus the
/// connection-state-on-an-avatar composition pattern.
///
/// Demonstrates the full 5-state model (online/idle/offline/disconnected/no
/// data) via a spread of fixed `receivedAt` timestamps against a fixed
/// `clock`, so the showroom renders deterministically rather than depending
/// on wall-clock time — each row's state is fixed at build time and does not
/// drift as real time passes while this page is open.
///
/// - The `.dot` row hovers each dot for its tooltip (state + humanized
///   "time ago").
/// - The `.full` row wraps a small asset-name label with the state's colored
///   chrome, one per state — the pill forces its text/icon color to the
///   state color's contrast color, so every row stays legible regardless of
///   the label `Text`'s own style.
/// - The "`.dot` on an avatar" row demonstrates composing [LayrzBadge] around
///   a [LayrzAvatar.icon] to show a connection-state dot on a user/asset
///   avatar — a real-world placement [LayrzConnectionIndicatorMode.dot]
///   itself does not attempt, since it is a standalone bare dot rather than
///   an overlay.
class ConnectionIndicatorSection extends StatelessWidget {
  /// Creates a new [ConnectionIndicatorSection].
  const ConnectionIndicatorSection({super.key});

  /// A fixed "now" for every indicator on this page, so elapsed-time state
  /// resolution is deterministic across rebuilds rather than depending on
  /// [DateTime.now] while the showroom is open.
  static DateTime get _demoNow => DateTime(2026, 9, 9, 12, 0, 0);

  /// Three representative `receivedAt` timestamps for the avatar-dot
  /// composition demo below, kept to a small spread (online/offline/no-data)
  /// rather than the full 5-state model so that subsection stays simple.
  static List<({String label, DateTime? receivedAt})> get _avatarDotRows => [
    (label: 'Online', receivedAt: _demoNow.subtract(const Duration(minutes: 2))),
    (label: 'Offline', receivedAt: _demoNow.subtract(const Duration(hours: 3))),
    (label: 'No data', receivedAt: null),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final demoRows = <({String label, DateTime? receivedAt})>[
      (label: 'Online (2 minutes ago)', receivedAt: _demoNow.subtract(const Duration(minutes: 2))),
      (label: 'Idle (30 minutes ago)', receivedAt: _demoNow.subtract(const Duration(minutes: 30))),
      (label: 'Offline (3 hours ago)', receivedAt: _demoNow.subtract(const Duration(hours: 3))),
      (label: 'Disconnected (45 days ago)', receivedAt: _demoNow.subtract(const Duration(days: 45))),
      (label: 'No data', receivedAt: null),
    ];

    return ShowroomSection(
      title: 'Connection Indicator',
      description:
          'Live telemetry/connection status — a colored dot with a tooltip, or a colored chrome '
          'wrapping caller-owned content. Both resolve the same 5-state model from elapsed time '
          'since the last received timestamp.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dot mode — hover each dot for its state + time-ago tooltip', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          Row(
            children: [
              for (final row in demoRows) ...[
                Column(
                  children: [
                    LayrzConnectionIndicator(
                      receivedAt: row.receivedAt,
                      mode: LayrzConnectionIndicatorMode.dot,
                      clock: () => _demoNow,
                    ),
                    SizedBox(height: tokens.spacing.sp2),
                    Text(
                      row.label,
                      style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                SizedBox(width: tokens.spacing.sp5),
              ],
            ],
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('Full mode — the state chrome wraps caller-owned content', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          Text(
            'The pill forces its content to the state color\'s contrast color, so every row below stays '
            'legible even on the dark Disconnected pill.',
            style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp2),
          Wrap(
            spacing: tokens.spacing.sp3,
            runSpacing: tokens.spacing.sp3,
            children: [
              for (final row in demoRows)
                LayrzConnectionIndicator(
                  receivedAt: row.receivedAt,
                  mode: LayrzConnectionIndicatorMode.full,
                  clock: () => _demoNow,
                  child: Text(row.label),
                ),
            ],
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text(
            '.dot on an avatar — a connection-state dot composed onto a user avatar',
            style: tokens.typography.title,
          ),
          SizedBox(height: tokens.spacing.sp3),
          Text(
            'The real "dot on an avatar" use case is achieved today by composing LayrzBadge (a bare '
            'corner dot overlay) around a LayrzAvatar, using the same state color the indicator resolves.',
            style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          Row(
            children: [
              for (final row in _avatarDotRows) ...[
                Column(
                  children: [
                    LayrzBadge(
                      label: 'Connection status',
                      color: resolveLayrzConnectionState(
                        receivedAt: row.receivedAt,
                        now: _demoNow,
                      ).colorOf(tokens),
                      alignment: LayrzBadgeAlignment.bottomRight,
                      child: const LayrzAvatar.icon(icon: MdiIcons.account, size: 40),
                    ),
                    SizedBox(height: tokens.spacing.sp2),
                    Text(
                      row.label,
                      style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                SizedBox(width: tokens.spacing.sp5),
              ],
            ],
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('Custom thresholds — a 2-minute online window, 10-minute idle window', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          Row(
            children: [
              LayrzConnectionIndicator(
                receivedAt: _demoNow.subtract(const Duration(minutes: 5)),
                connection: const LayrzConnectionTimes(online: Duration(minutes: 2), idle: Duration(minutes: 10)),
                mode: LayrzConnectionIndicatorMode.dot,
                clock: () => _demoNow,
              ),
              SizedBox(width: tokens.spacing.sp2),
              Text(
                '5 minutes ago -> idle under a 2-minute online threshold',
                style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
