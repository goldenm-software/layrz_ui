import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finds a [RichText] whose composed plain text contains [text].
///
/// Button content is rendered as a single [RichText] with inline spans, so
/// [find.text] does not match it — that finder only matches [Text] and
/// [EditableText]. This helper bridges that gap by searching the RichText's
/// plain-text representation for the expected content.
///
/// The [includePlaceholders] parameter is set to false by default to avoid
/// matching placeholder glyphs (U+FFFC) used for inline widgets like icons.
Finder findButtonLabel(String text) => find.byWidgetPredicate(
  (widget) => widget is RichText && widget.text.toPlainText(includePlaceholders: false).contains(text),
  description: 'RichText containing "$text"',
);
