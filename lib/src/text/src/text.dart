import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// A Material-free, Cupertino-free text widget that wraps [Text] in [SelectableRegion].
///
/// [LayrzText] is a drop-in replacement for Flutter's [Text] widget that allows users
/// to select and copy displayed text. Unlike [Text], it wraps the rendered content
/// in a [SelectableRegion] that provides text selection and clipboard functionality.
///
/// **Selection behavior:**
/// - When [selectable] is `true` (default), the text is wrapped in a [SelectableRegion]
///   and users can drag-select the text and use Ctrl+A / Ctrl+C to copy.
/// - When [selectable] is `false`, the widget renders as a plain [Text] with no
///   [SelectableRegion] in the tree, useful for performance in hot lists.
///
/// **Style resolution:**
/// Unlike [Text], when [style] is `null`, [LayrzText] defaults to
/// [LayrzTokens.typography.body] instead of inheriting from [DefaultTextStyle].
/// This is a deliberate departure from Flutter's [Text], ensuring consistent
/// styling across the design system. Pass an explicit style to override.
///
/// **Focus management:**
/// - When [focusNode] is **null**, [SelectableRegion] creates and manages its own
///   [FocusNode] internally. This node is owned by [SelectableRegion], not by [LayrzText].
/// - When [focusNode] is **non-null**, the caller retains ownership and is
///   responsible for disposal. [LayrzText] and [SelectableRegion] do not dispose
///   the supplied node. The supplied node remains usable after the widget is removed
///   from the tree.
///
/// **Text content:**
/// Exactly one of [data] or [textSpan] must be non-null at construction time,
/// mirroring the contract of Flutter's [Text]. An assertion fires if both are null
/// or both are non-null.
///
/// **API compatibility:**
/// All parameters mirror those of Flutter's [Text] and [Text.rich], including
/// [data], [style], [strutStyle], [textAlign], [textDirection], [locale],
/// [softWrap], [overflow], [textScaler], [maxLines], [semanticsLabel],
/// [semanticsIdentifier], [textWidthBasis], and [textHeightBehavior].
class LayrzText extends StatelessWidget {
  /// Creates a [LayrzText] widget to display a single line of text.
  ///
  /// The [data] must be non-null; use [LayrzText.rich] instead when you need
  /// to display an [InlineSpan] with mixed styles.
  ///
  /// One of [data] or [textSpan] (via [LayrzText.rich]) must be provided.
  /// Passing both or neither triggers an assertion.
  ///
  /// When [style] is null, the widget resolves to [LayrzTokens.typography.body]
  /// from the active theme.
  const LayrzText(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.selectable = true,
    this.focusNode,
    this.onSelectionChanged,
  }) : textSpan = null;

  /// Creates a [LayrzText] widget from an [InlineSpan] tree.
  ///
  /// Use this constructor when you need to style different parts of the text
  /// with different styles. The [textSpan] tree must be non-null.
  ///
  /// All parameters match those of the default constructor and [Text.rich],
  /// except [data] is replaced by [textSpan].
  const LayrzText.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.selectable = true,
    this.focusNode,
    this.onSelectionChanged,
  }) : data = null;

  /// The plain text to display as a single [TextSpan].
  ///
  /// If this is non-null, [textSpan] must be null. This is checked by assertion.
  /// Use [data] for simple text; use [LayrzText.rich] for styled spans.
  final String? data;

  /// An [InlineSpan] tree for display as rich text.
  ///
  /// If this is non-null, [data] must be null. This is checked by assertion.
  final InlineSpan? textSpan;

  /// The text style to apply to the rendered text.
  ///
  /// When null, defaults to [LayrzTokens.typography.body] from the active theme,
  /// which is typically 14px, w400, body font family.
  ///
  /// When non-null, this style is passed directly to the inner [Text] widget
  /// and is not overridden by the default. This matches the behavior of Flutter's [Text].
  ///
  /// To customize the default style system-wide, configure [LayrzTokens.typography.body]
  /// when creating the [LayrzThemeData].
  final TextStyle? style;

  /// The strut style to use (for line height control).
  ///
  /// Passed directly to the inner [Text] widget. See [StrutStyle] for details.
  final StrutStyle? strutStyle;

  /// How the text should be aligned horizontally.
  ///
  /// Defaults to [TextAlign.start]. Passed directly to the inner [Text] widget.
  final TextAlign? textAlign;

  /// The directionality of the text.
  ///
  /// When null, the directionality is resolved from [Directionality.of]. Passed
  /// directly to the inner [Text] widget.
  final TextDirection? textDirection;

  /// The locale to use for text layout.
  ///
  /// Passed directly to the inner [Text] widget. See [Text.locale] for details.
  final Locale? locale;

  /// Whether the text should break on soft line breaks or wrap to fit available space.
  ///
  /// When null (default), defaults to `true`. Passed directly to the inner [Text] widget.
  final bool? softWrap;

  /// How overflowing text should be handled.
  ///
  /// Defaults to [TextOverflow.clip]. Passed directly to the inner [Text] widget.
  final TextOverflow? overflow;

  /// Controls the text scaling for the rendered text.
  ///
  /// Passed directly to the inner [Text] widget. See [TextScaler] for details.
  final TextScaler? textScaler;

  /// The maximum number of lines the text can occupy.
  ///
  /// When null (default), the text can occupy any number of lines. When set to 1,
  /// the text is constrained to a single line (unless soft wraps). Passed directly
  /// to the inner [Text] widget.
  final int? maxLines;

  /// A semantic label for the text, exposed to assistive technology.
  ///
  /// When non-null, overrides the raw text content in the semantics tree.
  /// When null, the raw text (from [data] or the [textSpan] tree) is exposed.
  /// Passed directly to the inner [Text] widget.
  final String? semanticsLabel;

  /// A custom semantic identifier for the text.
  ///
  /// Passed directly to the inner [Text] widget for custom semantic identification.
  final String? semanticsIdentifier;

  /// How width is measured when calculating text bounding boxes.
  ///
  /// Defaults to [TextWidthBasis.parent]. Passed directly to the inner [Text] widget.
  final TextWidthBasis? textWidthBasis;

  /// How height is measured when calculating text bounding boxes.
  ///
  /// Passed directly to the inner [Text] widget. See [TextHeightBehavior] for details.
  final TextHeightBehavior? textHeightBehavior;

  /// The color to apply to selected text.
  ///
  /// When non-null, overrides the default selection highlight color in the
  /// [SelectableRegion]. When null, the [SelectableRegion] uses the design system
  /// default (primary color at tonal opacity). Has no effect when [selectable] is `false`.
  final Color? selectionColor;

  /// Whether the text should be selectable by the user.
  ///
  /// When `true` (default), the widget wraps the text in a [SelectableRegion]
  /// and users can drag-select and copy the text with Ctrl+A and Ctrl+C.
  ///
  /// When `false`, the text is rendered as a plain [Text] without any selection
  /// mechanism. Use this in performance-sensitive scenarios like long lists where
  /// selection support is not needed.
  final bool selectable;

  /// The focus node for the text selection region.
  ///
  /// When null (default), [SelectableRegion] creates and manages an internal [FocusNode].
  /// This node is owned by [SelectableRegion], not by [LayrzText].
  ///
  /// When non-null, the caller is responsible for creating, managing, and disposing
  /// the supplied [FocusNode]. [LayrzText] and [SelectableRegion] do not dispose
  /// a supplied node. The supplied node remains usable after the widget is removed
  /// from the tree.
  final FocusNode? focusNode;

  /// Called when the user's text selection changes.
  ///
  /// The callback receives a [SelectedContent] object when text is selected,
  /// containing the selected text in [SelectedContent.plainText]. The callback
  /// receives `null` when the selection is cleared. Passed to the [SelectableRegion]
  /// and has no effect when [selectable] is `false`.
  final ValueChanged<SelectedContent?>? onSelectionChanged;

  /// Resolves the text style, defaulting to [LayrzTokens.typography.body] when null.
  TextStyle _resolveStyle(BuildContext context) {
    if (style != null) {
      return style!;
    }
    return context.tokens.typography.body;
  }

  /// Resolves the selection color, defaulting to primary at tonal opacity when null.
  Color _resolveSelectionColor(BuildContext context) {
    if (selectionColor != null) {
      return selectionColor!;
    }
    final tokens = context.tokens;
    return tokens.colors.primary.withValues(alpha: tokens.colors.tonalOpacity);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = _resolveStyle(context);

    // Resolve selection color for the Text widget
    final resolvedSelectionColor = _resolveSelectionColor(context);

    // Build the inner Text widget, either from data or textSpan.
    final innerText = data != null
        ? Text(
            data!,
            style: resolvedStyle,
            strutStyle: strutStyle,
            textAlign: textAlign,
            textDirection: textDirection,
            locale: locale,
            softWrap: softWrap,
            overflow: overflow,
            textScaler: textScaler,
            maxLines: maxLines,
            semanticsLabel: semanticsLabel,
            textWidthBasis: textWidthBasis,
            textHeightBehavior: textHeightBehavior,
            selectionColor: resolvedSelectionColor,
          )
        : Text.rich(
            textSpan!,
            style: resolvedStyle,
            strutStyle: strutStyle,
            textAlign: textAlign,
            textDirection: textDirection,
            locale: locale,
            softWrap: softWrap,
            overflow: overflow,
            textScaler: textScaler,
            maxLines: maxLines,
            semanticsLabel: semanticsLabel,
            textWidthBasis: textWidthBasis,
            textHeightBehavior: textHeightBehavior,
            selectionColor: resolvedSelectionColor,
          );

    // When not selectable, return the plain Text widget without SelectableRegion.
    if (!selectable) {
      return innerText;
    }

    // When selectable, wrap in SelectableRegion with empty controls and focus node.
    return SelectableRegion(
      focusNode: focusNode,
      onSelectionChanged: onSelectionChanged,
      selectionControls: emptyTextSelectionControls,
      child: innerText,
    );
  }
}
