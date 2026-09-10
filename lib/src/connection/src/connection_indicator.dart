import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/badges/badges.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/tooltips/tooltips.dart';

import 'connection_indicator_mode.dart';
import 'connection_state.dart';
import 'connection_time_ago.dart';
import 'connection_times.dart';

/// How often [LayrzConnectionIndicator] re-evaluates its resolved state.
///
/// A 1-minute tick is sufficient: the tightest boundary in the 5-state model
/// (the online/idle threshold) defaults to 15 minutes, and even a caller
/// supplying a much smaller [LayrzConnectionTimes.online] does not need
/// sub-minute precision for a glance-level status dot.
const Duration kLayrzConnectionIndicatorTickInterval = Duration(minutes: 1);

/// A live connection/telemetry status indicator with two render modes.
///
/// This is a modernized, Material-free port of `layrz_theme`'s
/// `TelemetryIndicator`. It resolves one of 5 states — online, idle,
/// offline, disconnected, or no-data — from how long ago [receivedAt] was,
/// against the configurable [connection] thresholds (see
/// [LayrzConnectionTimes] and [resolveLayrzConnectionState]), and re-renders
/// itself once a minute so the indicator stays live without the caller
/// having to poll or rebuild it.
///
/// **The 5-state model** (elapsed time since [receivedAt]):
/// - **Online** — 0 to [LayrzConnectionTimes.online] (default 15 min) — `tokens.colors.success`.
/// - **Idle** — up to [LayrzConnectionTimes.idle] (default 60 min) — `tokens.colors.warning`.
/// - **Offline** — up to 30 days — `tokens.colors.danger`.
/// - **Disconnected** — 30 days or more — `tokens.colors.fg1`.
/// - **No data** — [receivedAt] is `null` — `tokens.colors.contextual`.
///
/// **Two render modes** ([mode]):
/// - [LayrzConnectionIndicatorMode.dot] — a small colored dot
///   ([LayrzBadgeVisual]) wrapped in a [LayrzTooltip] announcing the state
///   and a humanized "time ago" string. Must **not** receive a [child].
/// - [LayrzConnectionIndicatorMode.full] — the state color wraps the
///   caller-supplied [child] as a pill-shaped chrome (background tinted to
///   the resolved state color, foreground/border derived via
///   [LayrzColorExtensions.contrastColor] for contrast). Requires a non-null
///   [child]; the widget never invents its own label/timestamp content here
///   — the state color alone conveys status, and [child] is entirely
///   caller-owned content (e.g. an asset name). **The content's text and
///   icon color is forced to the state color's contrast color for
///   legibility**: a hard `DefaultTextStyle`/`IconTheme` is applied (not a
///   `.merge`), so a caller-supplied `Text` carrying its own explicit color
///   still renders in the contrast color — this guarantees every `.full`
///   pill stays readable regardless of what color the caller's content
///   asks for, most notably on the dark `fg1` Disconnected pill.
///
/// **Clock source**: elapsed time is measured against [clock] (defaults to
/// `DateTime.now`), never a timezone-database dependency — this mirrors the
/// old `TelemetryIndicator`'s intent without pulling in the `timezone`
/// package, since only elapsed wall-clock duration matters for the 5-state
/// boundaries, not calendar-local wall time. Tests can inject a fixed
/// [clock] for determinism.
///
/// **Live updates**: a `Timer.periodic` ticking every
/// [kLayrzConnectionIndicatorTickInterval] re-resolves the state and
/// rebuilds. The timer is created in `initState` and unconditionally
/// cancelled in `dispose`, following the same discipline as
/// `LayrzButtonController`'s timer handling — no path leaves it running
/// past this widget's lifetime.
class LayrzConnectionIndicator extends StatefulWidget {
  /// The last time telemetry/data was received for the entity this
  /// indicator represents.
  ///
  /// `null` resolves unconditionally to the no-data state, regardless of
  /// [connection] or [clock].
  final DateTime? receivedAt;

  /// Configurable online/idle elapsed-time thresholds.
  ///
  /// `null` uses [LayrzConnectionTimes.defaults] (15 minutes online, 60
  /// minutes idle).
  final LayrzConnectionTimes? connection;

  /// Which of the two render modes to use — see the class-level doc for the
  /// visual difference between [LayrzConnectionIndicatorMode.dot] and
  /// [LayrzConnectionIndicatorMode.full].
  final LayrzConnectionIndicatorMode mode;

  /// The content wrapped by the state chrome in
  /// [LayrzConnectionIndicatorMode.full] mode.
  ///
  /// Must be `null` in [LayrzConnectionIndicatorMode.dot] mode and non-null
  /// in [LayrzConnectionIndicatorMode.full] mode — see the constructor's
  /// asserts.
  final Widget? child;

  /// The clock used to resolve "now" against [receivedAt].
  ///
  /// Null resolves to [DateTime.now] at build time. Tests inject a fixed
  /// closure (e.g. `() => DateTime(2026, 1, 1)`) for deterministic state
  /// resolution.
  final DateTime Function()? clock;

  /// Creates a new [LayrzConnectionIndicator].
  ///
  /// Asserts (mirroring [mode]'s two shapes exactly):
  /// - [mode] is [LayrzConnectionIndicatorMode.dot] implies [child] is null —
  ///   the dot mode renders its own bare visual and never wraps content.
  /// - [mode] is [LayrzConnectionIndicatorMode.full] implies [child] is
  ///   non-null — full mode has nothing to render without caller content.
  const LayrzConnectionIndicator({
    super.key,
    required this.receivedAt,
    this.connection,
    required this.mode,
    this.child,
    this.clock,
  }) : assert(
         mode != LayrzConnectionIndicatorMode.dot || child == null,
         'LayrzConnectionIndicator.dot must not be given a child — it always renders its own bare '
         'dot visual. Use LayrzConnectionIndicatorMode.full to wrap custom content.',
       ),
       assert(
         mode != LayrzConnectionIndicatorMode.full || child != null,
         'LayrzConnectionIndicator.full requires a non-null child to wrap with the state chrome.',
       );

  @override
  State<LayrzConnectionIndicator> createState() => _LayrzConnectionIndicatorState();
}

class _LayrzConnectionIndicatorState extends State<LayrzConnectionIndicator> {
  /// Ticks every [kLayrzConnectionIndicatorTickInterval] so the resolved
  /// state stays live without the caller polling or rebuilding this widget.
  ///
  /// Created in [initState], unconditionally cancelled in [dispose] — no
  /// code path leaves this running past the widget's lifetime.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(kLayrzConnectionIndicatorTickInterval, (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final now = (widget.clock ?? DateTime.now)();
    final times = widget.connection ?? const LayrzConnectionTimes.defaults();
    final state = resolveLayrzConnectionState(
      receivedAt: widget.receivedAt,
      now: now,
      times: times,
    );
    final color = state.colorOf(tokens);
    final stateLabel = _labelFor(state, l10n);

    if (widget.mode == LayrzConnectionIndicatorMode.dot) {
      final timeAgo = widget.receivedAt == null
          ? l10n.connectionStateNoData
          : humanizeLayrzConnectionTimeAgo(now.difference(widget.receivedAt!), l10n);
      final announcement = widget.receivedAt == null
          ? stateLabel
          : l10n.connectionStateWithTimeAgo(
              stateLabel,
              timeAgo,
            );

      return LayrzTooltip(
        contentText: announcement,
        child: Semantics(
          label: announcement,
          child: LayrzBadgeVisual(color: color),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(tokens.radius.full),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2, vertical: tokens.spacing.sp1),
        // Deliberately a hard `DefaultTextStyle`/`IconTheme`, not `.merge`:
        // `.merge` only fills in style fields the descendant left unset, so
        // a caller-supplied `Text(..., style: someStyleWithAColor)` keeps its
        // own explicit color and can win over `color.contrastColor` — on the
        // dark `fg1` Disconnected pill that produced unreadable dark-on-dark
        // text. Forcing the style here guarantees legibility on every state
        // color regardless of what color the caller's content specifies.
        child: DefaultTextStyle(
          style: tokens.typography.label.copyWith(color: color.contrastColor),
          child: IconTheme(
            data: IconThemeData(color: color.contrastColor),
            child: widget.child!,
          ),
        ),
      ),
    );
  }

  /// Maps [state] to its localized label via [l10n].
  String _labelFor(LayrzConnectionState state, LayrzUiL10n l10n) {
    switch (state) {
      case LayrzConnectionState.online:
        return l10n.connectionStateOnline;
      case LayrzConnectionState.idle:
        return l10n.connectionStateIdle;
      case LayrzConnectionState.offline:
        return l10n.connectionStateOffline;
      case LayrzConnectionState.disconnected:
        return l10n.connectionStateDisconnected;
      case LayrzConnectionState.noData:
        return l10n.connectionStateNoData;
    }
  }
}
