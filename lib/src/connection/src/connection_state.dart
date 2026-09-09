import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'connection_times.dart';

/// The fixed elapsed-time boundary between the offline and disconnected
/// states: 30 days.
///
/// Unlike [LayrzConnectionTimes.online]/[LayrzConnectionTimes.idle], this
/// boundary is not configurable — no caller has asked for it to vary, and a
/// device silent for 30+ days is disconnected under every known deployment.
const Duration kLayrzConnectionOfflineBoundary = Duration(days: 30);

/// The internal 5-state model resolved from a connection's elapsed time
/// since it last reported data.
///
/// This enum (and [resolveLayrzConnectionState]) is the pure, testable core
/// of [LayrzConnectionIndicator] — a small function of `(receivedAt, now,
/// times)` with no widget/BuildContext dependency, so the state logic can be
/// unit-tested directly without pumping a widget tree.
enum LayrzConnectionState {
  /// Telemetry received within [LayrzConnectionTimes.online] of "now".
  ///
  /// Rendered in `tokens.colors.success` (green).
  online,

  /// Telemetry received after [LayrzConnectionTimes.online] but within
  /// [LayrzConnectionTimes.idle] of "now".
  ///
  /// Rendered in `tokens.colors.warning` (orange).
  idle,

  /// Telemetry received after [LayrzConnectionTimes.idle] but within
  /// [kLayrzConnectionOfflineBoundary] (30 days) of "now".
  ///
  /// Rendered in `tokens.colors.danger` (red).
  offline,

  /// Telemetry not received for at least [kLayrzConnectionOfflineBoundary]
  /// (30 days).
  ///
  /// Rendered in `tokens.colors.fg1` (near-black) — the most severe state,
  /// deliberately not a semantic color since it signals "gone", not merely
  /// "in trouble".
  disconnected,

  /// No telemetry has ever been received (`receivedAt == null`).
  ///
  /// Rendered in `tokens.colors.contextual` (grey) — neutral, since this is
  /// an absence-of-information state rather than a severity level.
  noData;

  /// Resolves the token color for this state.
  ///
  /// Every non-[noData] state resolves to its swatch's `shade500`, except
  /// [disconnected] which uses the flat `fg1` foreground token (not a
  /// swatch) and [noData] which uses `contextual.shade500`.
  Color colorOf(LayrzTokens tokens) {
    switch (this) {
      case LayrzConnectionState.online:
        return tokens.colors.success.shade500;
      case LayrzConnectionState.idle:
        return tokens.colors.warning.shade500;
      case LayrzConnectionState.offline:
        return tokens.colors.danger.shade500;
      case LayrzConnectionState.disconnected:
        return tokens.colors.fg1;
      case LayrzConnectionState.noData:
        return tokens.colors.contextual.shade500;
    }
  }
}

/// Resolves the [LayrzConnectionState] for a connection given [receivedAt],
/// the current instant [now], and the configured [times] thresholds.
///
/// This is a pure function with no side effects, deliberately separated from
/// [LayrzConnectionIndicator] so the 5-state boundaries can be unit-tested
/// directly against representative elapsed times without pumping a widget
/// tree.
///
/// - [receivedAt]: the last time telemetry/data was received. `null`
///   resolves unconditionally to [LayrzConnectionState.noData], regardless
///   of [now] or [times].
/// - [now]: the current instant to measure elapsed time against. Callers
///   supply this explicitly (rather than calling `DateTime.now()` here) so
///   the resolver stays a pure, deterministic function — [LayrzConnectionIndicator]
///   is what supplies a live clock.
/// - [times]: the configurable online/idle thresholds. Defaults to
///   [LayrzConnectionTimes.defaults] when not supplied.
LayrzConnectionState resolveLayrzConnectionState({
  required DateTime? receivedAt,
  required DateTime now,
  LayrzConnectionTimes times = const LayrzConnectionTimes.defaults(),
}) {
  if (receivedAt == null) return LayrzConnectionState.noData;

  final elapsed = now.difference(receivedAt).abs();

  if (elapsed <= times.online) return LayrzConnectionState.online;
  if (elapsed <= times.idle) return LayrzConnectionState.idle;
  if (elapsed <= kLayrzConnectionOfflineBoundary) return LayrzConnectionState.offline;
  return LayrzConnectionState.disconnected;
}
