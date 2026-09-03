import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Showroom demo for [LayrzDateInput].
///
/// Demonstrates:
/// - **Cancel/Save**: opens a [LayrzEndDrawer] (desktop) or [LayrzBottomSheet] (mobile) with
///   Cancel and Save actions — tapping a day only drafts it; `onChanged` fires once, on Save.
/// - **A live `strftime` pattern swap**, comparing `%Y-%m-%d` against `%B %d, %Y` on the same
///   value, so the formatter is visibly in effect rather than merely documented. No `intl`
///   dependency is available to this package.
/// - **`showWeekNumbers`** together with a non-default `firstDayOfWeek` (`DateTime.sunday`,
///   deliberately differing from the widget's own `DateTime.monday` default).
class DateInputDemo extends StatefulWidget {
  /// Creates a new [DateInputDemo].
  const DateInputDemo({super.key});

  @override
  State<DateInputDemo> createState() => _DateInputDemoState();
}

class _DateInputDemoState extends State<DateInputDemo> {
  /// The committed value for the demo field.
  DateTime? _date;

  /// Whether the field formats with `%B %d, %Y` instead of the widget's own `%Y-%m-%d` default.
  bool _useLongPattern = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      child: Padding(
        padding: tokens.spacing.pd2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cancel / Save', style: tokens.typography.title),
            Text(
              'Tapping a day only drafts it -- the date commits when Save is pressed, and Cancel '
              'discards the draft. Toggle the pattern below to see the strftime formatter change '
              'the display text for the same value. firstDayOfWeek is set to DateTime.sunday '
              'here, differing from the widget\'s own DateTime.monday default.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzButton(
              labelText: _useLongPattern ? 'Pattern: %B %d, %Y' : 'Pattern: %Y-%m-%d (default)',
              style: _useLongPattern ? LayrzButtonStyle.filled : LayrzButtonStyle.outlined,
              onTap: () => setState(() => _useLongPattern = !_useLongPattern),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDateInput(
              value: _date,
              onChanged: (value) => setState(() => _date = value),
              labelText: 'Date',
              hintText: 'Pick a date',
              pattern: _useLongPattern ? '%B %d, %Y' : '%Y-%m-%d',
              firstDayOfWeek: DateTime.sunday,
              showWeekNumbers: true,
            ),

            SizedBox(height: tokens.spacing.sp5),
            Text('Disabled', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDateInput(
              value: DateTime.now(),
              onChanged: (_) {},
              labelText: 'Locked date',
              disabled: true,
            ),

            SizedBox(height: tokens.spacing.sp5),
            Text('With Error', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDateInput(
              value: null,
              onChanged: (_) {},
              labelText: 'Date (required)',
              hintText: 'Pick a date',
              errors: const ['This field is required.'],
            ),
          ],
        ),
      ),
    );
  }
}
