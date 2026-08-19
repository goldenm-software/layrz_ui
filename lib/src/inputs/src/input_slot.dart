import 'package:flutter/widgets.dart';

/// Resolved prefix slot configuration for [LayrzTextInput].
///
/// Holds a single prefix element (icon, widget, or text) and an optional callback
/// for when the prefix is tapped. At most one of icon/widget/text may be non-null.
@immutable
class LayrzInputPrefixSlot {
  /// The icon to render as the prefix, if any.
  final IconData? icon;

  /// The widget to render as the prefix, if any.
  final Widget? widget;

  /// The text to render as the prefix, if any.
  final String? text;

  /// Callback fired when the prefix is tapped.
  ///
  /// Ignored if the input is disabled.
  final VoidCallback? onTap;

  /// Creates a new [LayrzInputPrefixSlot] with the given properties.
  ///
  /// At most one of [icon], [widget], or [text] may be non-null.
  const LayrzInputPrefixSlot({
    this.icon,
    this.widget,
    this.text,
    this.onTap,
  }) : assert(
         (icon != null ? 1 : 0) + (widget != null ? 1 : 0) + (text != null ? 1 : 0) <= 1,
         'At most one of icon, widget, or text may be non-null.',
       );

  /// Returns true if this slot has any content.
  bool get hasContent => icon != null || widget != null || text != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzInputPrefixSlot &&
          runtimeType == other.runtimeType &&
          icon == other.icon &&
          widget == other.widget &&
          text == other.text &&
          onTap == other.onTap;

  @override
  int get hashCode => Object.hash(icon, widget, text, onTap);
}

/// Resolved suffix slot configuration for [LayrzTextInput].
///
/// Holds a single suffix element (icon, widget, or text) and an optional callback
/// for when the suffix is tapped. At most one of icon/widget/text may be non-null.
@immutable
class LayrzInputSuffixSlot {
  /// The icon to render as the suffix, if any.
  final IconData? icon;

  /// The widget to render as the suffix, if any.
  final Widget? widget;

  /// The text to render as the suffix, if any.
  final String? text;

  /// Callback fired when the suffix is tapped.
  ///
  /// Ignored if the input is disabled.
  final VoidCallback? onTap;

  /// Creates a new [LayrzInputSuffixSlot] with the given properties.
  ///
  /// At most one of [icon], [widget], or [text] may be non-null.
  const LayrzInputSuffixSlot({
    this.icon,
    this.widget,
    this.text,
    this.onTap,
  })  : assert(
          (icon != null ? 1 : 0) + (widget != null ? 1 : 0) + (text != null ? 1 : 0) <= 1,
          'At most one of icon, widget, or text may be non-null.',
        );

  /// Returns true if this slot has any content.
  bool get hasContent => icon != null || widget != null || text != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzInputSuffixSlot &&
          runtimeType == other.runtimeType &&
          icon == other.icon &&
          widget == other.widget &&
          text == other.text &&
          onTap == other.onTap;

  @override
  int get hashCode => Object.hash(icon, widget, text, onTap);
}

/// Validates and resolves the prefix slot, asserting that at most one prefix type is provided.
///
/// Raises an assertion error in debug mode if more than one prefix parameter is non-null.
LayrzInputPrefixSlot resolvePrefixSlot({
  IconData? prefixIcon,
  Widget? prefix,
  String? prefixText,
  VoidCallback? onPrefixTap,
}) {
  final nonNullCount = [prefixIcon, prefix, prefixText].where((e) => e != null).length;
  assert(
    nonNullCount <= 1,
    'At most one of prefixIcon, prefix, or prefixText may be non-null.',
  );

  return LayrzInputPrefixSlot(
    icon: prefixIcon,
    widget: prefix,
    text: prefixText,
    onTap: onPrefixTap,
  );
}

/// Validates and resolves the suffix slot, asserting that at most one suffix type is provided.
///
/// Raises an assertion error in debug mode if more than one suffix parameter is non-null.
LayrzInputSuffixSlot resolveSuffixSlot({
  IconData? suffixIcon,
  Widget? suffix,
  String? suffixText,
  VoidCallback? onSuffixTap,
}) {
  final nonNullCount = [suffixIcon, suffix, suffixText].where((e) => e != null).length;
  assert(
    nonNullCount <= 1,
    'At most one of suffixIcon, suffix, or suffixText may be non-null.',
  );

  return LayrzInputSuffixSlot(
    icon: suffixIcon,
    widget: suffix,
    text: suffixText,
    onTap: onSuffixTap,
  );
}
