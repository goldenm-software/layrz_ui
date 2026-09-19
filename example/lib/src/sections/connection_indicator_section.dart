import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Showcases [LayrzConnectionIndicator] in both of its render modes, plus the
/// `.dot`-mode-with-a-child badge-overlay presentation.
///
/// Demonstrates the full 5-state model (online/idle/offline/disconnected/no
/// data) via a spread of fixed `receivedAt` timestamps against a shared
/// caller-owned [_clock] notifier, so the showroom renders deterministically
/// rather than depending on wall-clock time — each row's state is fixed
/// relative to [_clock]'s value and does not drift on its own.
///
/// [_clock] is ticked by a `Timer.periodic` owned and disposed by this
/// section — demonstrating the caller-owns-the-ticker model
/// [LayrzConnectionIndicator] now expects: the widget itself never starts a
/// timer, it only rebuilds its state-dependent subtree in response to the
/// notifier the caller drives.
///
/// - The `.dot` row hovers each dot for its tooltip (state + humanized
///   "time ago").
/// - The `.full` row wraps a small asset-name label with the state's colored
///   chrome, one per state — the pill forces its text/icon color to the
///   state color's contrast color, so every row stays legible regardless of
///   the label `Text`'s own style.
/// - The "`.dot` on an avatar" row passes a [LayrzAvatar.icon] as `.dot`
///   mode's `child`, overlaying the status dot on the avatar's bottom-right
///   corner directly — the widget's own badge-overlay support, rather than
///   composing [LayrzBadge] around it by hand.
class ConnectionIndicatorSection extends StatefulWidget {
  /// Creates a new [ConnectionIndicatorSection].
  const ConnectionIndicatorSection({super.key});

  @override
  State<ConnectionIndicatorSection> createState() => _ConnectionIndicatorSectionState();
}

class _ConnectionIndicatorSectionState extends State<ConnectionIndicatorSection> {
  /// The fixed starting "now" every demo row's `receivedAt` is offset from.
  static DateTime get _initialNow => DateTime(2026, 9, 9, 12, 0, 0);

  /// The caller-owned clock driving every [LayrzConnectionIndicator] on this
  /// page — created in [initState], ticked by [_ticker], and disposed in
  /// [dispose]. This is the section acting as the "caller" in the
  /// caller-owns-the-ticker model: [LayrzConnectionIndicator] itself starts
  /// no timer of its own.
  late final ValueNotifier<DateTime> _clock;

  /// Advances [_clock] once a minute so the showroom visibly demonstrates
  /// live reactivity, without [LayrzConnectionIndicator] owning any timer.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _clock = ValueNotifier<DateTime>(_initialNow);
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      _clock.value = _clock.value.add(const Duration(minutes: 1));
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    _clock.dispose();
    super.dispose();
  }

  /// Three representative `receivedAt` timestamps for the avatar-dot
  /// composition demo below, kept to a small spread (online/offline/no-data)
  /// rather than the full 5-state model so that subsection stays simple.
  List<({String label, DateTime? receivedAt})> get _avatarDotRows => [
    (label: 'Online', receivedAt: _initialNow.subtract(const Duration(minutes: 2))),
    (label: 'Offline', receivedAt: _initialNow.subtract(const Duration(hours: 3))),
    (label: 'No data', receivedAt: null),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final demoRows = <({String label, DateTime? receivedAt})>[
      (label: 'Online (2 minutes ago)', receivedAt: _initialNow.subtract(const Duration(minutes: 2))),
      (label: 'Idle (30 minutes ago)', receivedAt: _initialNow.subtract(const Duration(minutes: 30))),
      (label: 'Offline (3 hours ago)', receivedAt: _initialNow.subtract(const Duration(hours: 3))),
      (label: 'Disconnected (45 days ago)', receivedAt: _initialNow.subtract(const Duration(days: 45))),
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
          Wrap(
            spacing: tokens.spacing.sp5,
            runSpacing: tokens.spacing.sp3,
            children: [
              for (final row in demoRows)
                Column(
                  children: [
                    LayrzConnectionIndicator(
                      receivedAt: row.receivedAt,
                      mode: LayrzConnectionIndicatorMode.dot,
                      clock: _clock,
                    ),
                    SizedBox(height: tokens.spacing.sp2),
                    Text(
                      row.label,
                      style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
                  clock: _clock,
                  child: Text(row.label),
                ),
            ],
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text(
            '.dot on an avatar — a connection-state dot overlaid directly on caller content',
            style: tokens.typography.title,
          ),
          SizedBox(height: tokens.spacing.sp3),
          Text(
            'Passing a child to .dot mode overlays the status dot on its bottom-right corner via '
            'LayrzBadge internally, rather than composing LayrzBadge by hand around the content.',
            style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          Wrap(
            spacing: tokens.spacing.sp5,
            runSpacing: tokens.spacing.sp3,
            children: [
              for (final row in _avatarDotRows)
                Column(
                  children: [
                    LayrzConnectionIndicator(
                      receivedAt: row.receivedAt,
                      mode: LayrzConnectionIndicatorMode.dot,
                      clock: _clock,
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
            ],
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('Custom thresholds — a 2-minute online window, 10-minute idle window', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          Row(
            children: [
              LayrzConnectionIndicator(
                receivedAt: _initialNow.subtract(const Duration(minutes: 5)),
                connection: const LayrzConnectionTimes(
                  online: Duration(minutes: 2),
                  idle: Duration(minutes: 10),
                  offline: Duration(days: 30),
                ),
                mode: LayrzConnectionIndicatorMode.dot,
                clock: _clock,
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
