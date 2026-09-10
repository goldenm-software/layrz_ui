import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Sample Python source shown by the read-only snippet demo.
///
/// A small, realistic function -- deliberately unremarkable so the syntax
/// highlighting (keywords, strings, numbers, comments) is what stands out.
const String _pythonSnippet = '''
def average_speed(distances, durations):
    # distances in kilometers, durations in hours
    total_distance = sum(distances)
    total_duration = sum(durations)
    if total_duration == 0:
        return 0.0
    return round(total_distance / total_duration, 2)
''';

/// Sample Layrz Compute Language (LCL) expression shown by the read-only
/// snippet demo, exercising a builtin function call, a comparison, and a
/// nested `IF`.
const String _lclSnippet = '''
IF(
  COMPARE(GET_SENSOR('fuel_level'), '<', 15),
  'Low fuel warning',
  CONCAT('Fuel OK: ', TO_STR(GET_SENSOR('fuel_level')))
)
''';

/// Sample Layrz Markup Language (LML) snippet shown by the read-only snippet
/// demo, mixing a `{{ mustache }}` variable with an embedded LCL function
/// call so both parts of LML's highlighting surface are visible at once.
const String _lmlSnippet = '''
Hello {{ asset.name }},

Your current fuel level is TO_STR(GET_SENSOR('fuel_level'))%.
Last seen: {{ asset.lastMessageAt }}.
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

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Code',
      description:
          'Syntax-highlighted code display and editing -- always rendered in the dark code '
          'theme regardless of the app theme, across Python, LCL, and LML.',
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
          Text('LCL -- GET_SENSOR, COMPARE, IF', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          const LayrzCodeSnippet(
            code: _lclSnippet,
            language: LayrzCodeLanguage.lcl,
          ),
          SizedBox(height: tokens.spacing.sp3),
          Text('LML -- {{ mustache }} variables mixed with LCL functions', style: tokens.typography.title),
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
            maxHeight: 220,
          ),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'Current length: ${_editableValue.length} characters',
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
            maxHeight: 220,
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
        ],
      ),
    );
  }
}
