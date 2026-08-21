import 'package:flutter/widgets.dart';

/// Sealed hierarchy representing a single item in the [LayrzLayout] navigation.
///
/// [LayrzNavigatorItem] uses a sealed class hierarchy to guarantee exhaustiveness
/// when switching over navigator items — adding a new item type later will be a
/// compile error at every unhandled `switch` statement, not a silent fallthrough.
///
/// The two concrete types are [LayrzNavigatorPage] (a tappable destination) and
/// [LayrzNavigatorLabel] (a non-interactive section caption).
sealed class LayrzNavigatorItem {
  /// Creates a new navigator item.
  const LayrzNavigatorItem();
}

/// A navigable destination in [LayrzLayout].
///
/// [LayrzNavigatorPage] represents a tappable navigation target with an optional
/// icon, a label, and an optional trailing count badge. The page's selection
/// state is determined by the [isSelected] field; when tapped, its optional
/// [onTap] callback is invoked.
final class LayrzNavigatorPage extends LayrzNavigatorItem {
  /// Creates a navigable page item.
  ///
  /// All parameters except [id] and [labelText] are optional and default to null
  /// or false.
  const LayrzNavigatorPage({
    required this.id,
    required this.labelText,
    this.icon,
    this.count,
    this.onTap,
    this.isSelected = false,
  });

  /// A stable identifier for this page.
  ///
  /// The [id] is used as a unique key for this navigation item and is passed
  /// to navigation callbacks, but does not determine selection — that is
  /// controlled by [isSelected].
  final String id;

  /// The label text displayed for this page in the navigation.
  ///
  /// This text appears to the right of the optional [icon] in the navigation rail
  /// or drawer.
  final String labelText;

  /// An optional icon to display alongside the label.
  ///
  /// If null, only the label text is shown. The icon is rendered at the same size
  /// as the label font size (14) in the rail or drawer item.
  final IconData? icon;

  /// An optional count badge displayed to the right of the label.
  ///
  /// If null, no badge is shown. If provided, this number is rendered in a
  /// small badge style at the end of the item row.
  final int? count;

  /// An optional callback fired when the user taps this item.
  ///
  /// If provided, this callback is invoked when the user taps this item.
  /// This allows pages to run local side effects (e.g., logging, analytics)
  /// or to respond to taps without managing selection state elsewhere.
  final VoidCallback? onTap;

  /// Whether this page is currently selected.
  ///
  /// When true, the navigation item is highlighted with primary color
  /// background and bold label text. Defaults to false.
  final bool isSelected;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzNavigatorPage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          labelText == other.labelText &&
          icon == other.icon &&
          count == other.count &&
          onTap == other.onTap &&
          isSelected == other.isSelected;

  @override
  int get hashCode => Object.hash(runtimeType, id, labelText, icon, count, onTap, isSelected);

  /// Returns a copy of this page with the given fields replaced.
  LayrzNavigatorPage copyWith({
    String? id,
    String? labelText,
    IconData? icon,
    int? count,
    VoidCallback? onTap,
    bool? isSelected,
  }) {
    return LayrzNavigatorPage(
      id: id ?? this.id,
      labelText: labelText ?? this.labelText,
      icon: icon ?? this.icon,
      count: count ?? this.count,
      onTap: onTap ?? this.onTap,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// A non-interactive section caption in [LayrzLayout] navigation.
///
/// [LayrzNavigatorLabel] renders as a full-bleed band with optional colour tinting,
/// used to group or separate related [LayrzNavigatorPage] items in the navigation
/// rail or drawer (e.g., "MAIN" or "REFERENCE").
final class LayrzNavigatorLabel extends LayrzNavigatorItem {
  /// Creates a non-interactive section caption.
  ///
  /// The [labelText] parameter is required and defines the text displayed
  /// in uppercase (via CSS text-transform or manual conversion).
  /// The [color] parameter is optional and tints the band background.
  const LayrzNavigatorLabel(
    this.labelText, {
    this.color,
  });

  /// The text displayed for this section caption.
  ///
  /// This label serves to organize and group pages semantically (e.g., "MAIN",
  /// "REFERENCE", "UTILITIES"). It is rendered in a smaller font and muted
  /// colour to distinguish it from interactive pages.
  final String labelText;

  /// Optional colour used to tint the label's band.
  ///
  /// When null, the band defaults to [LayrzColorTokens.primary] at
  /// [LayrzColorTokens.tonalOpacity], flattened over the panel surface. When set,
  /// the band is filled with this colour instead, also at tonal opacity.
  final Color? color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzNavigatorLabel &&
          runtimeType == other.runtimeType &&
          labelText == other.labelText &&
          color == other.color;

  @override
  int get hashCode => Object.hash(runtimeType, labelText, color);

  /// Returns a copy of this label with the given fields replaced.
  LayrzNavigatorLabel copyWith({
    String? labelText,
    Color? color,
  }) {
    return LayrzNavigatorLabel(
      labelText ?? this.labelText,
      color: color ?? this.color,
    );
  }
}
