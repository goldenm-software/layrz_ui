import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Sample Python source shown by the read-only snippet demo.
///
/// A small, realistic function -- deliberately unremarkable so the syntax
/// highlighting (keywords, builtins, strings, numbers, comments, decorators,
/// and operators) is what stands out.
const String _pythonSnippet = '''
# average speed over a window
import statistics
from typing import Optional


@cached
def average(values: list[int]) -> Optional[float]:
    count = len(values)
    total = sum(values)
    if count == 0:
        return None
    return total / (count - 1)  # off-by-one on purpose


PRIMARY = True
LABEL = "sensor.speed"
THRESHOLD = 0x1F
''';

/// Sample Layrz Compute Language (LCL) expression shown by the read-only
/// snippet demo.
///
/// LCL has no infix operators -- every operation, including comparison, is a
/// nested builtin function call. This mirrors the true shape of the
/// language: [COMPARE] receives the result of [GET_PARAM] (itself built from
/// [CONCAT] and [PRIMARY_DEVICE]) against a [CONSTANT].
const String _lclSnippet = '''
COMPARE(
  GET_PARAM(
    CONCAT(
      PRIMARY_DEVICE(),
      ".alarm.event"
    ),
  ),
  CONSTANT(1)
)
''';

/// Sample Layrz Markup Language (LML) snippet shown by the read-only snippet
/// demo -- plain prose with `{{ mustache }}` variable interpolation, which is
/// the actual shape of LML: mostly text, with variables substituted inline.
const String _lmlSnippet = '''
The name of the asset is {{assetName}} and it's a great asset, message sent at {{executedAt}}.
''';

/// The initial source loaded into the editable [LayrzCodeEditor] demo.
///
/// Contains an intentional off-by-one bug (division by `count - 1`) and a
/// trailing unused import, so the paired [LayrzCodeError] entries below have
/// something plausible to point at.
const String _editableSample = '''
import statistics

def average(values):
    count = len(values)
    total = sum(values)
    return total / (count - 1)
''';

/// Diagnostics wired into the editable [LayrzCodeEditor] demo, marking the
/// unused import and the off-by-one division in [_editableSample].
final List<LayrzCodeError> _editableSampleErrors = [
  const LayrzCodeError(line: 1, column: 1, message: "Unused import 'statistics'"),
  const LayrzCodeError(line: 6, column: 21, message: 'Possible division by zero when count == 1'),
];

/// Read-only Python source shown by the disabled/read-only [LayrzCodeEditor]
/// demo.
const String _readOnlyEditorSample = '''
def is_moving(speed_kmh, threshold=2.0):
    return speed_kmh > threshold
''';

/// Builds the code section for the showroom.
///
/// Demonstrates the two code widgets added to layrz_ui:
///
/// - [LayrzCodeSnippet], a static, syntax-highlighted, read-only block --
///   shown once per supported [LayrzCodeLanguage] (Python, LCL, LML), with
///   line numbers enabled on the Python example and the copy button visible
///   on all three.
/// - [LayrzCodeEditor], the editable counterpart -- a live-typing demo with
///   tab preservation, line numbers, and current-line highlighting; a second
///   instance wired with [LayrzCodeError] entries to show gutter error
///   markers; and a third, read-only instance to show it degrades to the
///   same rendering as [LayrzCodeSnippet].
///
/// Both widgets always render in their own dark code theme regardless of the
/// showroom's own (light) theme -- see `LayrzCodeThemeExtension` -- so no
/// special theming is needed here.
class CodeSection extends StatefulWidget {
  /// Creates a new [CodeSection].
  const CodeSection({super.key});

  @override
  State<CodeSection> createState() => _CodeSectionState();
}

class _CodeSectionState extends State<CodeSection> {
  /// The live text backing the plain editable [LayrzCodeEditor] demo.
  ///
  /// Kept in state (rather than left uncontrolled) purely so the section can
  /// show the current line count below it, proving `onChanged` fires on
  /// every edit, including Tab/Shift+Tab indentation.
  String _editableValue = _editableSample;

  /// The name of the last action button tapped (`Run` or `Lint`), shown below
  /// the editable demo to prove `onRun`/`onLint` fire. `null` until first tap.
  String? _lastAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Code',
      description:
          'Syntax-highlighted code display and editing -- always rendered in the dark code '
          'theme regardless of the app theme, across Python, Layrz Compute Language, and Layrz Markup Language.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LayrzCodeSnippet -- read only', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'A static, syntax-highlighted block with a copy button. One example per supported '
            'language; line numbers are enabled on the Python example only.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          Text('Python -- with line numbers', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          const LayrzCodeSnippet(
            code: _pythonSnippet,
            language: LayrzCodeLanguage.python,
            showLineNumbers: true,
          ),
          SizedBox(height: tokens.spacing.sp3),
          Text('Layrz Compute Language -- nested builtin function calls', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          const LayrzCodeSnippet(
            code: _lclSnippet,
            language: LayrzCodeLanguage.lcl,
          ),
          SizedBox(height: tokens.spacing.sp3),
          Text('Layrz Markup Language -- prose with {{ mustache }} variables', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          const LayrzCodeSnippet(
            code: _lmlSnippet,
            language: LayrzCodeLanguage.lml,
          ),
          SizedBox(height: tokens.spacing.sp5),
          Container(height: 1, color: tokens.colors.divider),
          SizedBox(height: tokens.spacing.sp5),
          Text('LayrzCodeEditor -- editable', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'Live syntax highlighting as you type, Tab/Shift+Tab indent preservation, line numbers, '
            'and current-line highlighting.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzCodeEditor(
            labelText: 'Editable Python',
            helperText: 'Try Tab and Shift+Tab on a line -- indentation is preserved, not swallowed by focus.',
            language: LayrzCodeLanguage.python,
            value: _editableSample,
            onChanged: (value) => setState(() => _editableValue = value),
            onRun: () => setState(() => _lastAction = 'Run'),
            onLint: () => setState(() => _lastAction = 'Lint'),
            height: 220,
          ),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'Current length: ${_editableValue.length} characters'
            '${_lastAction == null ? '' : ' -- last action: $_lastAction'}',
            style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('With error markers', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'Two LayrzCodeError entries are wired to this instance -- an unused-import warning on '
            'line 1 and a possible division-by-zero on line 6, both marked in the gutter.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp2),
          LayrzCodeEditor(
            labelText: 'Python with diagnostics',
            language: LayrzCodeLanguage.python,
            value: _editableSample,
            errors: _editableSampleErrors,
            height: 220,
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('Read only', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'readOnly: true renders through LayrzCodeSurface, identical to LayrzCodeSnippet.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp2),
          const LayrzCodeEditor(
            labelText: 'Read-only Python',
            language: LayrzCodeLanguage.python,
            value: _readOnlyEditorSample,
            readOnly: true,
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('Autocomplete', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'Type an identifier to get a popup of matches -- Layrz Compute Language function names plus '
            'the caller-supplied variables below -- or press Ctrl/Cmd+Space to open the full list. '
            'Arrow keys navigate, Enter or click accepts, Esc closes.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp2),
          const LayrzCodeEditor(
            labelText: 'Layrz Compute Language with autocomplete',
            language: LayrzCodeLanguage.lcl,
            value: 'COMPARE(\n  GET_PARAM("speed"),\n  CONSTANT(1)\n)',
            suggestions: ['assetName', 'triggerName', 'executedAt'],
            height: 220,
          ),
        ],
      ),
    );
  }
}
