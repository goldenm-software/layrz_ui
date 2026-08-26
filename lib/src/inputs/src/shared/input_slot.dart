import 'package:flutter/widgets.dart';

/// Common contract for the chrome's prefix and suffix slots.
///
/// Internal to the package: `lib/src/inputs/inputs.dart` exports neither this file nor
/// `input_chrome.dart`, so adding fields here is not a breaking change.
///
/// This is the seam through which meaning about a slot's content travels as data — the
/// concrete subclasses ([LayrzInputPrefixSlot], [LayrzInputSuffixSlot]) carry the
/// rendered content (icon/widget/text), the optional [onTap] interaction, and, per
/// D64, the [semanticLabel] / [isDecorative] pair that tells the chrome (internal
/// `LayrzInputChrome`) how to account for the slot in the semantics tree. The slot
/// never creates a `Semantics` node itself — that remains the chrome's responsibility.
@immutable
abstract class LayrzInputSlot {
  /// The icon to render in this slot, if any.
  final IconData? icon;

  /// The widget to render in this slot, if any.
  final Widget? widget;

  /// The text to render in this slot, if any.
  final String? text;

  /// Callback fired when this slot is tapped.
  ///
  /// Ignored if the input is disabled.
  ///
  /// A slot with a callback but no [semanticLabel] is a **pointer-only** affordance:
  /// it is rendered and tappable but contributes nothing to the semantics tree, and is
  /// never a keyboard focus stop. Supply [semanticLabel] to have it announced as a
  /// named button. See D64.
  final VoidCallback? onTap;

  /// The accessible name announced for this slot's content.
  ///
  /// When combined with [onTap], the slot becomes a named button in the semantics tree,
  /// with its own node distinct from the field's. When non-null on a non-interactive
  /// slot, the slot becomes a named (but non-interactive) node instead of merging into
  /// the field's accessible name. When null on an interactive slot, the slot is
  /// pointer-only. See D64.
  final String? semanticLabel;

  /// Declares that this slot's content carries no information and is intentionally
  /// hidden from assistive technology.
  ///
  /// Mutually exclusive with [semanticLabel] and with [onTap]: a slot cannot be both
  /// decorative and named, and a decorative slot is by definition never interactive.
  final bool isDecorative;

  /// Creates a new [LayrzInputSlot] with the given properties.
  const LayrzInputSlot({
    this.icon,
    this.widget,
    this.text,
    this.onTap,
    this.semanticLabel,
    this.isDecorative = false,
  });

  /// Returns true if this slot has any content.
  bool get hasContent => icon != null || widget != null || text != null;
}

/// Resolved prefix slot configuration for [LayrzTextInput].
///
/// Holds a single prefix element (icon, widget, or text) and an optional callback
/// for when the prefix is tapped. At most one of icon/widget/text may be non-null.
@immutable
class LayrzInputPrefixSlot extends LayrzInputSlot {
  /// Creates a new [LayrzInputPrefixSlot] with the given properties.
  ///
  /// At most one of [icon], [widget], or [text] may be non-null. [isDecorative] cannot
  /// be combined with [semanticLabel] or [onTap].
  const LayrzInputPrefixSlot({
    super.icon,
    super.widget,
    super.text,
    super.onTap,
    super.semanticLabel,
    super.isDecorative,
  }) : assert(
         (icon != null ? 1 : 0) + (widget != null ? 1 : 0) + (text != null ? 1 : 0) <= 1,
         'At most one of icon, widget, or text may be non-null.',
       ),
       assert(
         !(isDecorative && semanticLabel != null),
         'A decorative slot cannot carry a semanticLabel.',
       ),
       assert(
         !(isDecorative && onTap != null),
         'An interactive slot cannot be decorative.',
       );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzInputPrefixSlot &&
          runtimeType == other.runtimeType &&
          icon == other.icon &&
          widget == other.widget &&
          text == other.text &&
          onTap == other.onTap &&
          semanticLabel == other.semanticLabel &&
          isDecorative == other.isDecorative;

  @override
  int get hashCode => Object.hash(icon, widget, text, onTap, semanticLabel, isDecorative);
}

/// Resolved suffix slot configuration for [LayrzTextInput].
///
/// Holds a single suffix element (icon, widget, or text) and an optional callback
/// for when the suffix is tapped. At most one of icon/widget/text may be non-null.
@immutable
class LayrzInputSuffixSlot extends LayrzInputSlot {
  /// Creates a new [LayrzInputSuffixSlot] with the given properties.
  ///
  /// At most one of [icon], [widget], or [text] may be non-null. [isDecorative] cannot
  /// be combined with [semanticLabel] or [onTap].
  const LayrzInputSuffixSlot({
    super.icon,
    super.widget,
    super.text,
    super.onTap,
    super.semanticLabel,
    super.isDecorative,
  }) : assert(
         (icon != null ? 1 : 0) + (widget != null ? 1 : 0) + (text != null ? 1 : 0) <= 1,
         'At most one of icon, widget, or text may be non-null.',
       ),
       assert(
         !(isDecorative && semanticLabel != null),
         'A decorative slot cannot carry a semanticLabel.',
       ),
       assert(
         !(isDecorative && onTap != null),
         'An interactive slot cannot be decorative.',
       );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzInputSuffixSlot &&
          runtimeType == other.runtimeType &&
          icon == other.icon &&
          widget == other.widget &&
          text == other.text &&
          onTap == other.onTap &&
          semanticLabel == other.semanticLabel &&
          isDecorative == other.isDecorative;

  @override
  int get hashCode => Object.hash(icon, widget, text, onTap, semanticLabel, isDecorative);
}

/// Validates and resolves the prefix slot, asserting that at most one prefix type is provided.
///
/// Raises an assertion error in debug mode if more than one prefix parameter is non-null.
LayrzInputPrefixSlot resolvePrefixSlot({
  IconData? prefixIcon,
  Widget? prefix,
  String? prefixText,
  VoidCallback? onPrefixTap,
  String? semanticLabel,
  bool isDecorative = false,
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
    semanticLabel: semanticLabel,
    isDecorative: isDecorative,
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
  String? semanticLabel,
  bool isDecorative = false,
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
    semanticLabel: semanticLabel,
    isDecorative: isDecorative,
  );
}
