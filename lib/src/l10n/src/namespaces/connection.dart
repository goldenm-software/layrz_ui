/// Connection — LayrzConnectionIndicator namespace.
///
/// Holds the 5 state labels resolved by `resolveLayrzConnectionState` and the
/// glue text used to build the "time ago" string shown in `.dot` mode's
/// tooltip. Duration-unit pluralization itself is **not** duplicated here —
/// it reuses [LayrzUiL10nHelpersMixin]'s existing `helperDurationMinutes`
/// (and friends), consistent with how every other namespace in this package
/// composes elapsed-time text.
mixin LayrzUiL10nConnectionMixin {
  /// Localized label for the online state (data received recently).
  String get connectionStateOnline => 'Connected';

  /// Localized label for the idle state (data received a while ago, but not
  /// yet considered offline).
  String get connectionStateIdle => 'Idle';

  /// Localized label for the offline state (no data for a while, but not yet
  /// considered disconnected).
  String get connectionStateOffline => 'Offline';

  /// Localized label for the disconnected state (no data for 30+ days).
  String get connectionStateDisconnected => 'Disconnected';

  /// Localized label for the no-data state (telemetry never received).
  String get connectionStateNoData => 'No data';

  /// Localized template combining a state label with a humanized "time ago"
  /// suffix, e.g. "Connected (2 minutes ago)".
  ///
  /// [stateLabel] is one of the `connectionState*` getters above.
  /// [timeAgo] is the humanized duration text (see [connectionTimeAgoJustNow]
  /// and the `helperDuration*` family on [LayrzUiL10nHelpersMixin]).
  String connectionStateWithTimeAgo(String stateLabel, String timeAgo) => '$stateLabel ($timeAgo)';

  /// Localized "time ago" text for an elapsed duration under a minute.
  String get connectionTimeAgoJustNow => 'just now';

  /// Localized template for a humanized "N `unit` ago" string, e.g.
  /// "5 minutes ago".
  ///
  /// [value] is the pre-formatted "count unit" text (e.g. "5 minutes"),
  /// already produced via the `helperDuration*` singular/plural helpers.
  String connectionTimeAgo(String value) => '$value ago';
}
