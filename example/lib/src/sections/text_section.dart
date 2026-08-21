import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// The content widget for the text section.
///
/// Shows multiple demo subsections illustrating text styles, rich text,
/// selection behavior, and accessibility.
class TextSection extends StatelessWidget {
  /// Creates a new [TextSection].
  const TextSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Text',
      description:
          'Material-free text component with built-in text selection, rich text support, and theme-aware styling',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Plain text examples with different styles
          _PlainTextDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp5),

          // 2. Rich text examples
          _RichTextDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp5),

          // 3. Selection behavior demonstration
          _SelectionDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp5),

          // 4. Long paragraph with selection
          _ParagraphDemo(tokens: tokens),
        ],
      ),
    );
  }
}

/// Demonstrates plain text rendering with different typography styles.
///
/// Shows the five typography scales (display, headline, title, body, label)
/// and how they render with plain [Text] widgets using the app's theme.
class _PlainTextDemo extends StatelessWidget {
  /// Creates a new [_PlainTextDemo].
  const _PlainTextDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plain Text Examples',
          style: tokens.typography.title,
        ),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'Each style scale renders with default theme colors and fonts.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.sp3,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp1,
              children: [
                Text(
                  'Display Style (45px, w800)',
                  style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                ),
                Text(
                  'This is display text',
                  style: tokens.typography.display,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp1,
              children: [
                Text(
                  'Headline Style (28px, w700)',
                  style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                ),
                Text(
                  'This is headline text',
                  style: tokens.typography.headline,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp1,
              children: [
                Text(
                  'Title Style (16px, w600)',
                  style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                ),
                Text(
                  'This is title text',
                  style: tokens.typography.title,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp1,
              children: [
                Text(
                  'Body Style (14px, w400) — Default',
                  style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                ),
                const Text('This is body text, rendered with default style'),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp1,
              children: [
                Text(
                  'Label Style (12px, w300)',
                  style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                ),
                Text(
                  'This is label text',
                  style: tokens.typography.label,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates rich text rendering with mixed styles within a single text span.
///
/// Shows how [Text.rich] allows styling different parts of the text differently.
class _RichTextDemo extends StatelessWidget {
  /// Creates a new [_RichTextDemo].
  const _RichTextDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rich Text Examples',
          style: tokens.typography.title,
        ),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'Mix multiple styles within a single text widget.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.sp3,
          children: [
            Text.rich(
              TextSpan(
                text: 'This text is ',
                children: [
                  TextSpan(
                    text: 'bold',
                    style: tokens.typography.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' and this is '),
                  TextSpan(
                    text: 'italic',
                    style: tokens.typography.body.copyWith(fontStyle: FontStyle.italic),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                text: 'You can also ',
                children: [
                  TextSpan(
                    text: 'color text',
                    style: tokens.typography.body.copyWith(color: tokens.colors.danger),
                  ),
                  const TextSpan(text: ' or '),
                  TextSpan(
                    text: 'change size',
                    style: tokens.typography.body.copyWith(fontSize: 18),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                text: 'Even ',
                children: [
                  TextSpan(
                    text: 'combine',
                    style: tokens.typography.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tokens.colors.success,
                    ),
                  ),
                  const TextSpan(text: ' multiple styles at once.'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates text selection behavior in the app.
///
/// With the app-wide [SelectableRegion] enabled, text across all widgets
/// can be selected and copied using drag-selection and Ctrl+A / Ctrl+C.
class _SelectionDemo extends StatelessWidget {
  /// Creates a new [_SelectionDemo].
  const _SelectionDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selection Behavior',
          style: tokens.typography.title,
        ),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'Control whether text can be selected and copied to the clipboard.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.sp3,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp2,
              children: [
                Text(
                  'Selectable (default): Try dragging to select',
                  style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                ),
                Container(
                  padding: EdgeInsets.all(tokens.spacing.sp3),
                  decoration: BoxDecoration(
                    color: tokens.colors.sf2,
                    borderRadius: tokens.radius.br2,
                    border: Border.all(color: tokens.colors.divider),
                  ),
                  child: const Text(
                    'This text is fully selectable. You can drag your cursor across it to select, '
                    'and press Ctrl+C (or Cmd+C on Mac) to copy to clipboard.',
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp2,
              children: [
                Text(
                  'Non-selectable: No selection overhead',
                  style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                ),
                Container(
                  padding: EdgeInsets.all(tokens.spacing.sp3),
                  decoration: BoxDecoration(
                    color: tokens.colors.sf2,
                    borderRadius: tokens.radius.br2,
                    border: Border.all(color: tokens.colors.divider),
                  ),
                  child: const Text(
                    'With the app-wide SelectableRegion enabled, all text in the app is selectable '
                    'using drag-selection and Ctrl+A / Ctrl+C.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates plain [Text] widgets with a longer paragraph of content.
///
/// Shows how text wrapping, line breaks, and readability are handled
/// with the default body style.
class _ParagraphDemo extends StatelessWidget {
  /// Creates a new [_ParagraphDemo].
  const _ParagraphDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Long-form Content',
          style: tokens.typography.title,
        ),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'Reading passages and longer text blocks render naturally with appropriate line height and letter spacing.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        Container(
          padding: EdgeInsets.all(tokens.spacing.sp3),
          decoration: BoxDecoration(
            color: tokens.colors.sf2,
            borderRadius: tokens.radius.br3,
            border: Border.all(color: tokens.colors.divider),
          ),
          child: const Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
            'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
            'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. '
            'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. '
            'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. '
            'Try selecting and copying this entire paragraph!',
          ),
        ),
      ],
    );
  }
}
