import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Sample Markdown source demonstrating headings, inline formatting, a link,
/// unordered/ordered/nested lists, inline code, and two fenced code blocks —
/// one with a recognized language (Python) and one without (`json`), so the
/// [LayrzCodeLanguage.plain] pure-white rendering is visible side by side
/// with a highlighted fence.
const String _markdownSample = '''
# LayrzMarkdown

## A Material-free Markdown renderer

### Why it exists

Layrz backends and LLM responses come back as **Markdown**, not widgets — *LayrzMarkdown*
turns that text into themed layout: headings, lists, links, inline code like `context.tokens`,
and fenced code blocks, all without a single Material or Cupertino import.

Read more on the [project wiki](https://github.com/goldenm-software/layrz_ui/wiki) for the full
component catalog.

Supported block types:

- Headings, `h1` through `h6`
- Inline **bold**, *italic*, and ~~strikethrough~~
- Lists, including nested ones:
  - like this
  - and this
- Fenced code blocks in Python, LCL, LML, or any other language (rendered plain)

Rendering order for this demo:

1. Headings and prose
2. Lists (unordered, then ordered, both with a nested level)
3. A highlighted Python fence
4. An unknown-language fence, rendered pure white via `LayrzCodeLanguage.plain`

```python
def greet(name: str) -> str:
    # A friendly greeting, syntax-highlighted like any other Python snippet.
    return f"Hello, {name}!"
```

```json
{
  "widget": "LayrzMarkdown",
  "highlighted": false,
  "note": "Unknown fence languages fall back to LayrzCodeLanguage.plain."
}
```
''';

/// Builds the Markdown section for the showroom.
///
/// Presents [LayrzMarkdown] in a two-tab [LayrzTabView] so the same sample can
/// be inspected as both input and output: an **Output** tab renders the sample
/// end to end (headings `h1`–`h3`, bold/italic text, a tappable link whose
/// `href` is printed via `debugPrint` rather than launched, an unordered and an
/// ordered list each with one nested level, inline code, a syntax-highlighted
/// Python fence, and an unknown-language `json` fence showing
/// [LayrzCodeLanguage.plain]'s pure-white rendering), and a **Markdown code**
/// tab shows the raw source that produced it.
class MarkdownSection extends StatelessWidget {
  /// Creates a new [MarkdownSection].
  const MarkdownSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Markdown',
      description:
          'Renders a Markdown source string as themed block widgets -- headings, lists, links, '
          'inline code, and syntax-highlighted fenced code -- with no Material or Cupertino import.',
      child: Padding(
        padding: tokens.spacing.pd3,
        child: LayrzTabView(
          isScrollable: false,
          tabs: [
            LayrzTab(
              labelText: 'Output',
              child: LayrzMarkdown(
                data: _markdownSample,
                onTapLink: (href, title) =>
                    debugPrint('LayrzMarkdown: tapped link -- href="$href" title="$title"'),
              ),
            ),
            LayrzTab(
              labelText: 'Markdown code',
              // The raw source that produces the Output tab. Markdown is not one
              // of the highlighter's languages, so it renders through
              // LayrzCodeLanguage.plain -- the pure-white, unhighlighted path.
              child: LayrzCodeSnippet(
                code: _markdownSample.trim(),
                language: LayrzCodeLanguage.plain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
