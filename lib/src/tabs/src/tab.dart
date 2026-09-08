import 'package:flutter/widgets.dart';

/// An immutable descriptor for a single tab within a [LayrzTabView].
///
/// A [LayrzTab] carries only the data needed to render one strip pill (label,
/// optional leading/trailing slots) plus the [child] content shown when that
/// tab is the active one. It does not own any interaction state — selection,
/// hover, and focus all live in [LayrzTabView] itself.
///
/// The label can be supplied either as plain text via [labelText] or as an
/// arbitrary [label] widget — exactly one of the two must be provided.
/// Likewise, [leading]/[leadingIcon] are mutually exclusive (at most one may
/// be non-null), and so are [trailing]/[trailingIcon].
@immutable
class LayrzTab {
  /// The plain-text label for this tab.
  ///
  /// Mutually exclusive with [label] — exactly one of the two must be
  /// non-null. Rendered as a `Text` styled with `tokens.typography.label`,
  /// matching the weight/colour rules [LayrzTabView] applies per selection
  /// state.
  final String? labelText;

  /// A custom widget used as this tab's label instead of plain text.
  ///
  /// Mutually exclusive with [labelText] — exactly one of the two must be
  /// non-null. Use this when the label needs styling or content beyond what
  /// [labelText] can express; [LayrzTabView] does not apply its own text
  /// styling to this widget.
  final Widget? label;

  /// A custom widget rendered in the leading slot, before the label.
  ///
  /// Mutually exclusive with [leadingIcon] — at most one of the two may be
  /// non-null. Leave both null to render no leading slot.
  final Widget? leading;

  /// An icon rendered in the leading slot, before the label.
  ///
  /// Mutually exclusive with [leading] — at most one of the two may be
  /// non-null. Rendered via a plain [Icon] widget, coloured to match the
  /// tab's current label colour.
  final IconData? leadingIcon;

  /// A custom widget rendered in the trailing (suffix) slot, after the label.
  ///
  /// Mutually exclusive with [trailingIcon] — at most one of the two may be
  /// non-null. Leave both null to render no trailing slot.
  final Widget? trailing;

  /// An icon rendered in the trailing (suffix) slot, after the label.
  ///
  /// Mutually exclusive with [trailing] — at most one of the two may be
  /// non-null. Rendered via a plain [Icon] widget, coloured to match the
  /// tab's current label colour.
  final IconData? trailingIcon;

  /// The content shown by [LayrzTabView] when this tab is the active one.
  final Widget child;

  /// Creates a new [LayrzTab].
  ///
  /// Exactly one of [labelText] or [label] must be non-null. At most one of
  /// [leading]/[leadingIcon] may be non-null, and at most one of
  /// [trailing]/[trailingIcon] may be non-null.
  const LayrzTab({
    this.labelText,
    this.label,
    this.leading,
    this.leadingIcon,
    this.trailing,
    this.trailingIcon,
    required this.child,
  }) : assert(
         (labelText == null) != (label == null),
         'Provide exactly one of labelText or label, not both and not neither.',
       ),
       assert(
         leading == null || leadingIcon == null,
         'Provide at most one of leading or leadingIcon, not both.',
       ),
       assert(
         trailing == null || trailingIcon == null,
         'Provide at most one of trailing or trailingIcon, not both.',
       );
}
