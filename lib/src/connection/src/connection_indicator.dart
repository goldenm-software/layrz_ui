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
/// - [LayrzConnectionIndicatorMode.full] — a **self-contained chip**: it
///   renders the resolved state's localized label (e.g. "Online", "Idle",
///   "Offline", "Disconnected", "No data") on a state-colored chip-like
///   chrome. [child] is **ignored** in this mode — `.full` never wraps or
///   displays caller content; it is a standalone status chip, not a
///   decorator. The label text color is derived via
///   [LayrzColorExtensions.contrastColor] against the resolved state color
///   for legibility on every state background, most notably the dark `fg1`
///   Disconnected chip.
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

  /// The content this indicator decorates, used only by
  /// [LayrzConnectionIndicatorMode.dot].
  ///
  /// In [LayrzConnectionIndicatorMode.dot] mode this is optional: `null`
  /// renders the classic bare dot, while a non-null [child] overlays the dot
  /// on its bottom-right corner via [LayrzBadge] instead (e.g. a connection
  /// dot on an avatar).
  ///
  /// In [LayrzConnectionIndicatorMode.full] mode this is **ignored** — that
  /// mode is a self-contained chip that renders the resolved state's label
  /// on its own and never displays caller content. It is accepted (rather
  /// than forbidden by an assertion) so a caller switching a widget between
  /// modes at runtime does not need to conditionally omit it.
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

  /// A strftime-style pattern used to format [value] for display, when
  /// [formatter] is not supplied. Defaults to `'%Y-%m-%d %H:%M'`.
  final String pattern;

  /// Creates a new [LayrzConnectionIndicator].
  ///
  /// [child] places no restriction in either mode: it is optional in
  /// [LayrzConnectionIndicatorMode.dot] (see the class-level doc) and simply
  /// ignored in [LayrzConnectionIndicatorMode.full], which renders its own
  /// state-label chip regardless of what (if anything) is passed.
  const LayrzConnectionIndicator({
    super.key,
    required this.receivedAt,
    this.connection,
    required this.mode,
    this.child,
    required this.clock,
    this.pattern = '%Y-%m-%d %I:%M %p',
  });

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

        // No outer `Semantics` wrapper is added here: the `Text` below already
        // contributes `stateLabel` as its own semantics label, so wrapping it
        // would merge into a duplicated "label\nlabel" announcement instead
        // of a single clean one.
        return DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            // Chip-like chrome (matching LayrzChip): a rounded-box `r1` radius and
            // the same compact padding, rather than a tall fully-rounded pill.
            borderRadius: BorderRadius.circular(tokens.radius.r1),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2, vertical: tokens.spacing.sp1 / 2),
            // `color.contrastColor` guarantees the label stays legible on every
            // state color, most notably the dark `fg1` Disconnected chip.
            child: RichText(
              text: TextSpan(
                style: tokens.typography.body.copyWith(color: color.contrastColor),
                children: [
                  TextSpan(text: stateLabel),
                  if (receivedAt != null)
                    TextSpan(
                      text: ' (${receivedAt?.format(context, pattern)})',
                      style: tokens.typography.label.copyWith(color: color.contrastColor),
                    ),
                ],
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
