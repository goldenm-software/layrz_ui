import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/badges/badges.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/tooltips/tooltips.dart';

import 'connection_indicator_mode.dart';
import 'connection_state.dart';
import 'connection_time_ago.dart';
import 'connection_times.dart';

/// A live connection/telemetry status indicator with two render modes.
///
/// This is a modernized, Material-free port of `layrz_theme`'s
/// `TelemetryIndicator`. It resolves one of 5 states — online, idle,
/// offline, disconnected, or no-data — from how long ago [receivedAt] was,
/// against the configurable [connection] thresholds (see
/// [LayrzConnectionTimes] and [resolveLayrzConnectionState]).
///
/// **The 5-state model** (elapsed time since [receivedAt]):
/// - **Online** — 0 to [LayrzConnectionTimes.online] (default 15 min) — `tokens.colors.success`.
/// - **Idle** — up to [LayrzConnectionTimes.idle] (default 60 min) — `tokens.colors.warning`.
/// - **Offline** — up to [LayrzConnectionTimes.offline] (default 30 days) — `tokens.colors.danger`.
/// - **Disconnected** — beyond [LayrzConnectionTimes.offline] (a fallthrough with no threshold of
///   its own) — `tokens.colors.fg1`.
/// - **No data** — [receivedAt] is `null` — `tokens.colors.contextual`.
///
/// **Two render modes** ([mode]):
/// - [LayrzConnectionIndicatorMode.dot] — a small colored dot, wrapped in a
///   [LayrzTooltip] announcing the state and a humanized "time ago" string.
///   [child] is **optional** here: with no [child], it renders as a bare
///   [LayrzBadgeVisual]; with a [child], the dot is instead overlaid on the
///   child's bottom-right corner via [LayrzBadge] (e.g. a connection dot on
///   an avatar), and the same announcement becomes the badge's `label`.
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
/// **Clock source — caller-owned and reactive, not self-ticking.** This
/// widget is [StatelessWidget] and owns no `Timer` of its own. Elapsed time
/// is measured against whatever value [clock] currently holds, and the
/// widget rebuilds its state-dependent subtree exactly when [clock] notifies
/// — via an internal [ValueListenableBuilder] — so a caller that wants the
/// indicator to stay live over time drives it by ticking its own
/// [ValueNotifier] (e.g. from a shared app-wide clock, or a lightweight
/// `Timer.periodic` the caller owns and disposes). A caller that only needs
/// a point-in-time snapshot can pass a plain, never-updated
/// `ValueNotifier<DateTime>` and nothing will move.
///
/// This mirrors the "keep the public API `DateTime`-typed and
/// timezone-ignorant" approach used by `calendar_zone.dart`'s
/// `sameZoneDate`/`sameZoneDateTime` helpers: [clock] is typed
/// `ValueListenable<DateTime>`, never `ValueListenable<TZDateTime>`, and this
/// file never imports `package:timezone`. A caller who wants zone-aware
/// resolution can still drive this widget with a
/// `ValueNotifier<TZDateTime>` — `TZDateTime extends DateTime`, so it is
/// accepted here unchanged, and the zone information rides inside the value
/// itself. The widget only ever reads it as a plain [DateTime] and stays
/// completely ignorant of which zone (if any) it carries.
class LayrzConnectionIndicator extends StatelessWidget {
  /// The last time telemetry/data was received for the entity this
  /// indicator represents.
  ///
  /// `null` resolves unconditionally to the no-data state, regardless of
  /// [connection] or [clock].
  final DateTime? receivedAt;

  /// Configurable online/idle/offline elapsed-time thresholds.
  ///
  /// `null` uses [LayrzConnectionTimes.defaults] (15 minutes online, 60
  /// minutes idle, 30 days offline).
  final LayrzConnectionTimes? connection;

  /// Which of the two render modes to use — see the class-level doc for the
  /// visual difference between [LayrzConnectionIndicatorMode.dot] and
  /// [LayrzConnectionIndicatorMode.full].
  final LayrzConnectionIndicatorMode mode;

  /// The content this indicator decorates or wraps.
  ///
  /// In [LayrzConnectionIndicatorMode.full] mode this is required — the
  /// state chrome has nothing to wrap without it (see the constructor's
  /// assert). In [LayrzConnectionIndicatorMode.dot] mode this is optional:
  /// `null` renders the classic bare dot, while a non-null [child] overlays
  /// the dot on its bottom-right corner via [LayrzBadge] instead.
  final Widget? child;

  /// The caller-owned "now" source used to resolve elapsed time against
  /// [receivedAt].
  ///
  /// Required — there is no `DateTime.now` fallback. The widget wraps its
  /// state-dependent subtree in a [ValueListenableBuilder] listening to this
  /// notifier, so only that subtree rebuilds on each tick, never the rest of
  /// the caller's tree. Pass a plain, never-updated
  /// `ValueNotifier<DateTime>(DateTime.now())` for a static snapshot, or a
  /// notifier a caller-owned `Timer.periodic` updates for a live indicator.
  ///
  /// A `ValueNotifier<TZDateTime>` (from `package:timezone`) also works
  /// unchanged, since `TZDateTime extends DateTime` — see the class-level
  /// doc for why this type stays `DateTime`-based rather than importing
  /// `package:timezone` itself.
  final ValueListenable<DateTime> clock;

  /// Creates a new [LayrzConnectionIndicator].
  ///
  /// Asserts:
  /// - [mode] is [LayrzConnectionIndicatorMode.full] implies [child] is
  ///   non-null — full mode has nothing to render without caller content.
  ///   [LayrzConnectionIndicatorMode.dot] places no restriction on [child]:
  ///   it is optional there (see the class-level doc).
  const LayrzConnectionIndicator({
    super.key,
    required this.receivedAt,
    this.connection,
    required this.mode,
    this.child,
    required this.clock,
  }) : assert(
         mode != LayrzConnectionIndicatorMode.full || child != null,
         'LayrzConnectionIndicator.full requires a non-null child to wrap with the state chrome.',
       );

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final times = connection ?? const LayrzConnectionTimes.defaults();

    return ValueListenableBuilder<DateTime>(
      valueListenable: clock,
      builder: (context, now, _) {
        final state = resolveLayrzConnectionState(
          receivedAt: receivedAt,
          now: now,
          times: times,
        );
        final color = state.colorOf(tokens);
        final stateLabel = _labelFor(state, l10n);

        if (mode == LayrzConnectionIndicatorMode.dot) {
          final timeAgo = receivedAt == null
              ? l10n.connectionStateNoData
              : humanizeLayrzConnectionTimeAgo(now.difference(receivedAt!), l10n);
          final announcement = receivedAt == null
              ? stateLabel
              : l10n.connectionStateWithTimeAgo(
                  stateLabel,
                  timeAgo,
                );

          if (child == null) {
            return LayrzTooltip(
              contentText: announcement,
              child: Semantics(
                label: announcement,
                child: LayrzBadgeVisual(color: color),
              ),
            );
          }

          // Dot-over-child: overlay the status dot on the child's
          // bottom-right corner via LayrzBadge instead of the bare
          // LayrzBadgeVisual. LayrzBadge already merges its own Semantics
          // node from `label` and excludes both the child's and the dot's
          // own semantics from the tree — so `announcement` is passed
          // straight through as that merged label, and no separate outer
          // `Semantics` wrapper is added here, which would otherwise
          // duplicate the announcement into two nodes.
          return LayrzTooltip(
            contentText: announcement,
            child: LayrzBadge(
              label: announcement,
              type: LayrzBadgeType.custom,
              color: color,
              alignment: LayrzBadgeAlignment.bottomRight,
              child: child!,
            ),
          );
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            // Chip-like chrome (matching LayrzChip): a rounded-box `r1` radius and
            // the same compact padding, rather than a tall fully-rounded pill.
            borderRadius: BorderRadius.circular(tokens.radius.r1),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2, vertical: tokens.spacing.sp1 / 2),
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
                child: child!,
              ),
            ),
          ),
        );
      },
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
