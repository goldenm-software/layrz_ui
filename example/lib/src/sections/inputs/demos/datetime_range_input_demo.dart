import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Showroom demo for [LayrzDateTimeRangeInput].
///
/// Demonstrates **in-panel Cancel/Save**: the widest of the range widgets, coordinating start
/// and end dates each paired with their own time, committed together on Save.
class DateTimeRangeInputDemo extends StatefulWidget {
  /// Creates a new [DateTimeRangeInputDemo].
  const DateTimeRangeInputDemo({super.key});

  @override
  State<DateTimeRangeInputDemo> createState() => _DateTimeRangeInputDemoState();
}

class _DateTimeRangeInputDemoState extends State<DateTimeRangeInputDemo> {
  /// The committed start of the demo field.
  DateTime? _start;

  /// The committed end of the demo field.
  DateTime? _end;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      child: Padding(
        padding: tokens.spacing.pd2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('In-panel Cancel/Save', style: tokens.typography.title),
            Text(
              'Start and end datetimes, each with its own date and time part, committed together '
              'on Save.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDateTimeRangeInput(
              startValue: _start,
              endValue: _end,
              onChanged: (start, end) => setState(() {
                _start = start;
                _end = end;
              }),
              labelText: 'Date & time range',
              hintText: 'Pick a date and time range',
            ),

            SizedBox(height: tokens.spacing.sp5),
            Text('Disabled', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDateTimeRangeInput(
              startValue: DateTime.now(),
              endValue: DateTime.now().add(const Duration(days: 1)),
              onChanged: (_, _) {},
              labelText: 'Locked date & time range',
              disabled: true,
            ),

            SizedBox(height: tokens.spacing.sp5),
            Text('With Error', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDateTimeRangeInput(
              startValue: null,
              endValue: null,
              onChanged: (_, _) {},
              labelText: 'Date & time range (required)',
              hintText: 'Pick a date and time range',
              errors: const ['This field is required.'],
            ),
          ],
        ),
      ),
    );
  }
}
