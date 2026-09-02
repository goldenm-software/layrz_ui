import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Showroom demo for [LayrzDateTimeInput].
///
/// Demonstrates:
/// - **In-panel Cancel/Save**: a single [DateTime] value, but it collects two coordinated parts
///   (date and time), so it gets a Save button like the other range widgets.
/// - **Both [LayrzDateTimeInputPresentation] values toggled live** on the same field, so the
///   tabbed-vs-stepped arrangement is observable rather than only documented. Tabbed shows two
///   selectable tab headers; stepped shows the calendar first, then advances to the time step
///   with a back affordance.
class DateTimeInputDemo extends StatefulWidget {
  /// Creates a new [DateTimeInputDemo].
  const DateTimeInputDemo({super.key});

  @override
  State<DateTimeInputDemo> createState() => _DateTimeInputDemoState();
}

class _DateTimeInputDemoState extends State<DateTimeInputDemo> {
  /// The committed value for the demo field.
  DateTime? _dateTime;

  /// Which [LayrzDateTimeInputPresentation] the demo field currently uses.
  LayrzDateTimeInputPresentation _presentation = LayrzDateTimeInputPresentation.tabbed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isStepped = _presentation == LayrzDateTimeInputPresentation.stepped;

    return SingleChildScrollView(
      child: Padding(
        padding: tokens.spacing.pd2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('In-panel Cancel/Save', style: tokens.typography.title),
            Text(
              'Single DateTime value, but collects two coordinated parts (date and time), so it '
              'gets a Save button like the range widgets. Toggle the presentation below: tabbed '
              'shows two selectable tab headers; stepped shows the calendar first, then advances '
              'to the time step with a back affordance.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzButton(
              labelText: isStepped ? 'Presentation: stepped' : 'Presentation: tabbed (default)',
              style: isStepped ? LayrzButtonStyle.filled : LayrzButtonStyle.outlined,
              onTap: () => setState(() {
                _presentation = isStepped
                    ? LayrzDateTimeInputPresentation.tabbed
                    : LayrzDateTimeInputPresentation.stepped;
              }),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDateTimeInput(
              value: _dateTime,
              onChanged: (value) => setState(() => _dateTime = value),
              presentation: _presentation,
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
