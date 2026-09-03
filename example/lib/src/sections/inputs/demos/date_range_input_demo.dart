import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Showroom demo for [LayrzDateRangeInput].
///
/// Demonstrates:
/// - **In-panel Cancel/Save**: unlike [LayrzDateInput]'s commit-on-tap, the selection is only
///   committed when Save is pressed inside the panel.
/// - **Contiguity rejection**: the field is pre-seeded with a committed range (the 10th-15th of
///   the current month), so the days between the two endpoints render tinted and genuinely
///   inert (no hover, no pointer cursor) from the first frame, without the viewer having to
///   build a range first. Only the two endpoints stay tappable once a range exists.
class DateRangeInputDemo extends StatefulWidget {
  /// Creates a new [DateRangeInputDemo].
  const DateRangeInputDemo({super.key});

  @override
  State<DateRangeInputDemo> createState() => _DateRangeInputDemoState();
}

class _DateRangeInputDemoState extends State<DateRangeInputDemo> {
  /// The committed value for the demo field, pre-seeded so the contiguity-rejection behaviour
  /// (locked interior cells) is visible from the first frame rather than only after a first
  /// selection.
  LayrzDateRange? _range = LayrzDateRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 10),
    end: DateTime(DateTime.now().year, DateTime.now().month, 15),
  );

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
              'Contiguous only. Seeded with a range below, so the days between the two endpoints '
              'render tinted and genuinely inert (no hover, no pointer cursor) before you tap '
              'anything -- only the two endpoints stay tappable once a range exists.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDateRangeInput(
              value: _range,
              onChanged: (value) => setState(() => _range = value),
              labelText: 'Date range',
              hintText: 'Pick a date range',
            ),

            SizedBox(height: tokens.spacing.sp5),
            Text('Disabled', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDateRangeInput(
              value: _range,
              onChanged: (_) {},
              labelText: 'Locked date range',
              disabled: true,
            ),

            SizedBox(height: tokens.spacing.sp5),
            Text('With Error', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDateRangeInput(
              value: null,
              onChanged: (_) {},
              labelText: 'Date range (required)',
              hintText: 'Pick a date range',
              errors: const ['This field is required.'],
            ),
          ],
        ),
      ),
    );
  }
}
