import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';

/// A single row-level action rendered by a table widget (e.g. `LayrzTable`)
/// for each item, in the row's trailing actions cell.
///
/// The table renders each [LayrzTableAction] as a [LayrzButton] — icon-only
/// (`isFab: true`) on wide viewports, and labeled on compact viewports. This
/// value type only carries the action's data; the table owns how and where
/// the resulting button is laid out.
@immutable
class LayrzTableAction {
  /// The icon shown on the rendered button, in both the icon-only (wide) and
  /// labeled (compact) presentations.
  final IconData icon;

  /// The human-readable label for this action.
  ///
  /// Shown alongside [icon] on compact viewports, and used as the
  /// accessibility/tooltip label when the button renders icon-only.
  final String labelText;

  /// Called when the user activates this action.
  final VoidCallback onTap;

  /// The visual style applied to the rendered button.
  ///
  /// When `null`, the table applies its own default style for row actions.
  final LayrzButtonStyle? style;

  /// An optional accent color override for the rendered button.
  ///
  /// When `null`, the table/button resolve their default accent color.
  final Color? color;

  /// Whether this action is disabled.
  ///
  /// A disabled action renders non-interactive and does not invoke [onTap].
  final bool disabled;

  /// Creates a new [LayrzTableAction].
  const LayrzTableAction({
    required this.icon,
    required this.labelText,
    required this.onTap,
    this.style,
    this.color,
    this.disabled = false,
  });

  /// Returns a copy of this action with the given fields replaced.
  LayrzTableAction copyWith({
    IconData? icon,
    String? labelText,
    VoidCallback? onTap,
    LayrzButtonStyle? style,
    Color? color,
    bool? disabled,
  }) {
    return LayrzTableAction(
      icon: icon ?? this.icon,
      labelText: labelText ?? this.labelText,
      onTap: onTap ?? this.onTap,
      style: style ?? this.style,
      color: color ?? this.color,
      disabled: disabled ?? this.disabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzTableAction &&
          runtimeType == other.runtimeType &&
          icon == other.icon &&
          labelText == other.labelText &&
          onTap == other.onTap &&
          style == other.style &&
          color == other.color &&
          disabled == other.disabled;

  @override
  int get hashCode => Object.hash(icon, labelText, onTap, style, color, disabled);
}
