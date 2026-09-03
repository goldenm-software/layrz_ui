import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Showroom demo for [LayrzTimeRangeInput].
///
/// Demonstrates **in-panel Cancel/Save**: although built from two single-time clusters rather
/// than a grid, it still gets a Save button -- every range widget in this batch shares the same
/// commit model for uniformity.
class TimeRangeInputDemo extends StatefulWidget {
  /// Creates a new [TimeRangeInputDemo].
  const TimeRangeInputDemo({super.key});

  @override
  State<TimeRangeInputDemo> createState() => _TimeRangeInputDemoState();
}

class _TimeRangeInputDemoState extends State<TimeRangeInputDemo> {
  /// The committed start of the demo field.
  LayrzTimeOfDay? _start;

  /// The committed end of the demo field.
  LayrzTimeOfDay? _end;

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
              'Built from two single-time clusters, but still gets a Save button -- every range '
              'widget in this batch shares the same commit model for uniformity.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzTimeRangeInput(
              startValue: _start,
              endValue: _end,
              onChanged: (start, end) => setState(() {
                _start = start;
                _end = end;
              }),
              labelText: 'Time range',
              hintText: 'Pick a time range',
            ),

            SizedBox(height: tokens.spacing.sp5),
            Text('Disabled', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp3),
            LayrzTimeRangeInput(
              startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
              endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
              onChanged: (_, _) {},
              labelText: 'Locked time range',
              disabled: true,
            ),

            SizedBox(height: tokens.spacing.sp5),
            Text('With Error', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp3),
            LayrzTimeRangeInput(
              startValue: null,
              endValue: null,
              onChanged: (_, _) {},
              labelText: 'Time range (required)',
              hintText: 'Pick a time range',
              errors: const ['This field is required.'],
            ),
          ],
        ),
      ),
    );
  }
}
