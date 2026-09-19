import 'package:flutter/widgets.dart';

/// The `online` threshold used by [LayrzConnectionTimes.defaults].
///
/// Telemetry received within this window of "now" resolves to the online
/// state. Kept as a named constant (rather than inlined in the factory) so
/// it can be referenced from documentation and tests without duplicating the
/// literal.
const Duration kLayrzConnectionDefaultOnline = Duration(minutes: 15);

/// The `idle` threshold used by [LayrzConnectionTimes.defaults].
///
/// Telemetry received within this window (but outside [kLayrzConnectionDefaultOnline])
/// resolves to the idle state.
const Duration kLayrzConnectionDefaultIdle = Duration(minutes: 60);

/// The `offline` threshold used by [LayrzConnectionTimes.defaults].
///
/// Telemetry received within this window (but outside [kLayrzConnectionDefaultIdle])
/// resolves to the offline state; beyond it, resolution falls through to the
/// disconnected state.
const Duration kLayrzConnectionDefaultOffline = Duration(days: 30);

/// Configurable elapsed-time thresholds for [LayrzConnectionIndicator]'s
/// 5-state resolution.
///
/// `layrz_ui` deliberately defines its own, independent config type here
/// instead of depending on `layrz_models`' `Connection` class — this package
/// has no `layrz_models` dependency and must not gain one. Downstream
/// packages that already model connection thresholds via `layrz_models` are
/// expected to bind their own type to this one (e.g. via an extension
/// method that reads a `Connection` and produces a [LayrzConnectionTimes]),
/// which is outside this package's concern.
///
/// **The band model** ([resolveLayrzConnectionState]'s resolution order):
/// ```
/// receivedAt == null       -> noData
/// elapsed <= times.online  -> online
/// elapsed <= times.idle    -> idle
/// elapsed <= times.offline -> offline
/// otherwise                -> disconnected   (fallthrough — no threshold of its own)
/// ```
/// `disconnected` is deliberately not a configurable band: it is whatever
/// doesn't fit under [offline], so there is nothing to set for it.
@immutable
class LayrzConnectionTimes {
  /// The maximum elapsed time since `receivedAt` for which the connection is
  /// still considered online (green).
  ///
  /// Must be less than [idle] — see the class-level "why" for how the two
  /// compose. Defaults to 15 minutes via [LayrzConnectionTimes.defaults].
  final Duration online;

  /// The maximum elapsed time since `receivedAt` for which the connection is
  /// considered idle (orange) rather than offline.
  ///
  /// Elapsed time greater than [online] but at most [idle] resolves to the
  /// idle state; beyond [idle] (and within [offline]) resolves to offline.
  /// Defaults to 60 minutes via [LayrzConnectionTimes.defaults].
  final Duration idle;

  /// The maximum elapsed time since `receivedAt` for which the connection is
  /// still considered offline (red) rather than disconnected.
  ///
  /// Elapsed time greater than [idle] but at most this value resolves to the
  /// offline state; beyond it, resolution falls through to the disconnected
  /// state — `disconnected` has no threshold field of its own, it is simply
  /// "everything past [offline]". Defaults to 30 days via
  /// [LayrzConnectionTimes.defaults].
  final Duration offline;

  /// Creates a new [LayrzConnectionTimes] with explicit thresholds.
  ///
  /// Most callers should prefer [LayrzConnectionTimes.defaults], which
  /// matches the values documented on [LayrzConnectionIndicator]'s 5-state
  /// model. Use this constructor directly only when the online/idle/offline
  /// boundaries genuinely differ from that default.
  const LayrzConnectionTimes({
    required this.online,
    required this.idle,
    required this.offline,
  });

  /// The default thresholds: 15 minutes online, 60 minutes idle, 30 days
  /// offline.
  ///
  /// This is the config [LayrzConnectionIndicator] uses when its own
  /// `connection` field is null.
  const LayrzConnectionTimes.defaults()
    : online = kLayrzConnectionDefaultOnline,
      idle = kLayrzConnectionDefaultIdle,
      offline = kLayrzConnectionDefaultOffline;

  /// Returns a copy of this config with the given fields replaced.
  LayrzConnectionTimes copyWith({
    Duration? online,
    Duration? idle,
    Duration? offline,
  }) {
    return LayrzConnectionTimes(
      online: online ?? this.online,
      idle: idle ?? this.idle,
      offline: offline ?? this.offline,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzConnectionTimes &&
          runtimeType == other.runtimeType &&
          online == other.online &&
          idle == other.idle &&
          offline == other.offline;

  @override
  int get hashCode => Object.hash(online, idle, offline);

  @override
  String toString() => 'LayrzConnectionTimes(online: $online, idle: $idle, offline: $offline)';
}
