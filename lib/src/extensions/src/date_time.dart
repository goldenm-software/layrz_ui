import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/formatting/formatting.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

/// Ergonomic strftime-style formatting for [DateTime].
///
/// This is a thin wrapper over [formatStrftime]: it resolves a [LayrzUiL10n]
/// (from a [BuildContext] when one is available, or the English
/// [LayrzUiL10nDefault] otherwise) so callers do not have to fetch the
/// localization instance themselves before formatting a date.
extension LayrzDateTimeExtensions on DateTime {
  /// Formats this [DateTime] using a strftime-style [pattern].
  ///
  /// Supports the same directives as [formatStrftime]: `%Y %y %m %d %H %I
  /// %M %S %j %%` (locale-independent) and `%B %b %A %a %p` (localized month
  /// name, abbreviated month name, weekday name, abbreviated weekday name,
  /// and AM/PM meridiem marker, respectively). An unrecognized directive or a
  /// trailing lone `%` passes through literally rather than throwing — see
  /// [formatStrftime] for the full contract.
  ///
  /// [context] supplies the [LayrzUiL10n] used for the localized directives,
  /// resolved via [LayrzUiL10n.of]. It is nullable: when `null` (for example,
  /// when no [BuildContext] is available, such as in a background isolate or
  /// a pure data layer), this falls back to the English
  /// [LayrzUiL10nDefault], so this method never throws for a missing
  /// context.
  ///
  /// [pattern] is the strftime-style format string to render this [DateTime]
  /// with, e.g. `'%Y-%m-%d'` or `'%d %B %Y'`.
  ///
  /// Returns the formatted string.
  String format(BuildContext? context, String pattern) {
    final l10n = context != null ? LayrzUiL10n.of(context) : const LayrzUiL10nDefault();
    return formatStrftime(this, pattern, l10n);
  }
}
