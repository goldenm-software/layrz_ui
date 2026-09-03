import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Showroom demo for [LayrzDateTimeInput].
///
/// Demonstrates:
/// - **In-drawer Cancel/Save**: a single [DateTime] value, but it collects two coordinated parts
///   (date and time), so it gets a Save button like the other range widgets.
/// - The calendar and time fields are always shown together in the drawer -- DESIGN-49 removed
///   the tabbed/stepped presentation split this demo used to toggle, since
///   [LayrzDateTimeInputPresentation] is now deprecated and ignored.
class DateTimeInputDemo extends StatefulWidget {
  /// Creates a new [DateTimeInputDemo].
  const DateTimeInputDemo({super.key});

  @override
  State<DateTimeInputDemo> createState() => _DateTimeInputDemoState();
}

class _DateTimeInputDemoState extends State<DateTimeInputDemo> {
  /// The committed value for the demo field.
  DateTime? _dateTime;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      child: Padding(
        padding: tokens.spacing.pd2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('In-drawer Cancel/Save', style: tokens.typography.title),
            Text(
              'Single DateTime value, but collects two coordinated parts (date and time), so it '
              'gets a Save button like the range widgets. The calendar and time fields are always '
              'shown together in the drawer.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDateTimeInput(
              value: _dateTime,
              onChanged: (value) => setState(() => _dateTime = value),
              labelText: 'Date & time',
              hintText: 'Pick a date and time',
            ),

            SizedBox(height: tokens.spacing.sp5),
            Text('Disabled', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDateTimeInput(
              value: DateTime.now(),
              onChanged: (_) {},
              labelText: 'Locked date & time',
              disabled: true,
            ),

            SizedBox(height: tokens.spacing.sp5),
            Text('With Error', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDateTimeInput(
              value: null,
              onChanged: (_) {},
              labelText: 'Date & time (required)',
              hintText: 'Pick a date and time',
              errors: const ['This field is required.'],
            ),
          ],
        ),
      ),
    );
  }
}
