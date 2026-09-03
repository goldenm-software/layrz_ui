import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Showroom demo for [LayrzTimeInput].
///
/// Demonstrates:
/// - **Cancel/Save**: opens a [LayrzEndDrawer] (desktop) or [LayrzBottomSheet] (mobile) with
///   Cancel and Save actions — field edits only update the draft; `onChanged` fires once, on Save.
/// - **A live `showSeconds` toggle on a single instance**, proving no layout reflow occurs when
///   the seconds field appears or disappears (D15) — two static instances would not demonstrate
///   this, since nothing would visibly change between them.
class TimeInputDemo extends StatefulWidget {
  /// Creates a new [TimeInputDemo].
  const TimeInputDemo({super.key});

  @override
  State<TimeInputDemo> createState() => _TimeInputDemoState();
}

class _TimeInputDemoState extends State<TimeInputDemo> {
  /// The committed value for the demo field.
  LayrzTimeOfDay? _time;

  /// Whether the demo field's seconds component is shown.
  bool _showSeconds = false;

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
              'Field edits only update the draft -- the time commits when Save is pressed, and '
              'Cancel discards the draft. Toggle showSeconds below; the panel/sheet does not '
              'reflow when the seconds field appears or disappears.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzButton(
              labelText: _showSeconds ? 'showSeconds: true' : 'showSeconds: false (default)',
              style: _showSeconds ? LayrzButtonStyle.filled : LayrzButtonStyle.outlined,
              onTap: () => setState(() => _showSeconds = !_showSeconds),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzTimeInput(
              value: _time,
              onChanged: (value) => setState(() => _time = value),
              labelText: 'Time',
              hintText: 'Pick a time',
              showSeconds: _showSeconds,
            ),

            SizedBox(height: tokens.spacing.sp5),
            Text('Disabled', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp3),
            LayrzTimeInput(
              value: const LayrzTimeOfDay(hour: 9, minute: 30),
              onChanged: (_) {},
              labelText: 'Locked time',
              disabled: true,
            ),

            SizedBox(height: tokens.spacing.sp5),
            Text('With Error', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp3),
            LayrzTimeInput(
              value: null,
              onChanged: (_) {},
              labelText: 'Time (required)',
              hintText: 'Pick a time',
              errors: const ['This field is required.'],
            ),
          ],
        ),
      ),
    );
  }
}
