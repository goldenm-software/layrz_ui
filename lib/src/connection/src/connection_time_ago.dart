import 'package:layrz_ui/src/l10n/l10n.dart';

/// Builds a humanized "time ago" string for [elapsed], e.g. `"5 minutes ago"`
/// or `"just now"` for anything under a minute.
///
/// This deliberately reuses [LayrzUiL10nHelpersMixin]'s existing
/// `helperDuration*` singular/plural helpers (already used throughout
/// layrz_ui for elapsed-time text) rather than inventing new pluralization
/// keys — only the "ago" framing and the state labels are new, added to
/// [LayrzUiL10nConnectionMixin].
///
/// Only the single largest applicable unit is shown (days, then hours, then
/// minutes) — a connection indicator's tooltip is a glance-only affordance,
/// not a precise duration display, so "2 hours ago" is preferred over
/// "2 hours 14 minutes ago".
String humanizeLayrzConnectionTimeAgo(Duration elapsed, LayrzUiL10n l10n) {
  final absElapsed = elapsed.isNegative ? -elapsed : elapsed;

  if (absElapsed.inMinutes < 1) {
    return l10n.connectionTimeAgoJustNow;
  }

  if (absElapsed.inDays >= 1) {
    final days = absElapsed.inDays;
    return l10n.connectionTimeAgo('$days ${l10n.helperDurationDays(days)}');
  }

  if (absElapsed.inHours >= 1) {
    final hours = absElapsed.inHours;
    return l10n.connectionTimeAgo('$hours ${l10n.helperDurationHours(hours)}');
  }

  final minutes = absElapsed.inMinutes;
  return l10n.connectionTimeAgo('$minutes ${l10n.helperDurationMinutes(minutes)}');
}
