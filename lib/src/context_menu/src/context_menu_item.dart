import 'package:flutter/widgets.dart';

/// Base class for the entries a [LayrzContextMenu] can render in its panel.
///
/// Only three concrete types exist: [LayrzContextMenuEntry] (an interactive
/// row), [LayrzContextMenuLabel] (a non-interactive section heading), and
/// [LayrzContextMenuDivider] (a thin separator line). The sealed hierarchy
/// makes custom widget types impossible by construction, so every context
/// menu in the design system renders with the exact same visual language.
///
/// This is a fresh, self-contained model — it intentionally does not extend
/// or wrap `LayrzDropdownItem`/`LayrzDropdownEntry` from `lib/src/menus/`,
/// even though the two hierarchies look similar. Keeping them independent
/// means a change to one menu family can never silently ripple into the
/// other.
@immutable
sealed class LayrzContextMenuItem {
  /// Creates a new [LayrzContextMenuItem].
  const LayrzContextMenuItem();
}

/// An interactive, tappable row in a [LayrzContextMenu] panel.
///
/// Renders a single line of text with an optional leading [icon]. When
/// tapped while [enabled] is `true`, [onTap] fires exactly once and the menu
/// closes immediately afterward. When [enabled] is `false`, the entry is
/// visually muted and does not respond to pointer or keyboard input.
@immutable
final class LayrzContextMenuEntry extends LayrzContextMenuItem {
  /// The text displayed on this entry.
  final String labelText;

  /// Called when this entry is tapped while [enabled] is `true`.
  ///
  /// The context menu closes automatically right after this callback runs —
  /// callers never need to close the menu themselves from inside [onTap].
  final VoidCallback onTap;

  /// Optional icon rendered before [labelText].
  ///
  /// When `null` (the default), no icon is reserved or drawn and the label
  /// starts at the entry's leading edge.
  final IconData? icon;

  /// Whether this entry accepts pointer and keyboard input.
  ///
  /// Defaults to `true`. When `false`, the entry is rendered with muted
  /// (`fg3`) text/icon color and [onTap] never fires, regardless of how the
  /// entry is activated.
  final bool enabled;

  /// Optional accent color applied to this entry's label and icon.
  ///
  /// When `null` (the default), the entry uses the neutral foreground colors
  /// from the active theme's tokens for every non-disabled state. When set,
  /// this color replaces those neutral colors so the entry can signal a
  /// semantic meaning (e.g. a destructive action rendered in `tokens.danger`).
  /// This is a paint-only override — it never affects background, geometry,
  /// or spacing (see D15).
  final Color? color;

  /// Creates a new [LayrzContextMenuEntry].
  ///
  /// [labelText] and [onTap] are required. [icon], [enabled], and [color]
  /// are optional.
  const LayrzContextMenuEntry({
    required this.labelText,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzContextMenuEntry &&
          runtimeType == other.runtimeType &&
          labelText == other.labelText &&
          onTap == other.onTap &&
          icon == other.icon &&
          enabled == other.enabled &&
          color == other.color;

  @override
  int get hashCode => Object.hash(labelText, onTap, icon, enabled, color);
}

/// A non-interactive section heading rendered inside a [LayrzContextMenu] panel.
///
/// [LayrzContextMenuLabel] never responds to taps, focus, or keyboard input —
/// it is purely a visual grouping aid for the entries around it. Casing and
/// wording are entirely the caller's responsibility; the widget does not
/// transform [labelText] in any way.
@immutable
final class LayrzContextMenuLabel extends LayrzContextMenuItem {
  /// The text displayed as the section heading.
  final String labelText;

  /// Optional color applied to [labelText].
  ///
  /// When `null` (the default), the label uses the muted `fg3` foreground
  /// token color. When set, this color replaces it.
  final Color? color;

  /// Creates a new [LayrzContextMenuLabel].
  ///
  /// [labelText] is required. [color] is optional.
  const LayrzContextMenuLabel({
    required this.labelText,
    this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzContextMenuLabel &&
          runtimeType == other.runtimeType &&
          labelText == other.labelText &&
          color == other.color;

  @override
  int get hashCode => Object.hash(labelText, color);
}

/// A thin horizontal separator line rendered inside a [LayrzContextMenu] panel.
///
/// [LayrzContextMenuDivider] carries no fields — it exists purely to group
/// entries visually and never responds to input.
@immutable
final class LayrzContextMenuDivider extends LayrzContextMenuItem {
  /// Creates a new [LayrzContextMenuDivider].
  const LayrzContextMenuDivider();

  @override
  bool operator ==(Object other) => identical(this, other) || other is LayrzContextMenuDivider;

  @override
  int get hashCode => runtimeType.hashCode;
}
