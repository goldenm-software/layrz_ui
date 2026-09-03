import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Showroom demo for [LayrzMonthRangeInput].
///
/// Demonstrates **in-panel Cancel/Save**, in both `consecutive` modes side by side, making
/// explicit that month range is the only range widget in the whole batch that allows a
/// non-contiguous (arbitrary) selection:
/// - Left: the default arbitrary mode (`consecutive: false`) -- pick any set of months, not
///   necessarily adjacent.
/// - Right: consecutive mode (`consecutive: true`), which behaves like [LayrzDateRangeInput]'s
///   endpoint-adjust state machine.
class MonthRangeInputDemo extends StatefulWidget {
  /// Creates a new [MonthRangeInputDemo].
  const MonthRangeInputDemo({super.key});

  @override
  State<MonthRangeInputDemo> createState() => _MonthRangeInputDemoState();
}

class _MonthRangeInputDemoState extends State<MonthRangeInputDemo> {
  /// The committed arbitrary (non-contiguous) selection for the first demo field.
  List<LayrzMonth> _arbitrary = const [];

  /// The committed contiguous range for the second demo field.
  LayrzMonthRange? _consecutive;

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
              'The only picker in this batch where a non-contiguous selection is reachable. Left: '
              'the default arbitrary mode (consecutive: false) -- pick any set of months, not '
              'necessarily adjacent. Right: consecutive mode (consecutive: true), which behaves '
              'like LayrzDateRangeInput\'s endpoint-adjust state machine.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzRow(
              spacing: tokens.spacing.sp3,
              children: [
                LayrzCol(
                  xs: 12,
                  md: 6,
                  child: LayrzMonthRangeInput(
                    arbitraryValue: _arbitrary,
                    onArbitraryChanged: (value) => setState(() => _arbitrary = value),
                    labelText: 'Months (arbitrary)',
                    hintText: 'Pick any months',
                  ),
                ),
                LayrzCol(
                  xs: 12,
                  md: 6,
                  child: LayrzMonthRangeInput(
                    consecutive: true,
                    rangeValue: _consecutive,
                    onRangeChanged: (value) => setState(() => _consecutive = value),
                    labelText: 'Months (consecutive)',
                    hintText: 'Pick a range of months',
                  ),
                ),
              ],
            ),

            SizedBox(height: tokens.spacing.sp5),
            Text('Disabled', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp3),
            LayrzMonthRangeInput(
              arbitraryValue: const [],
              onArbitraryChanged: (_) {},
              labelText: 'Locked months',
              disabled: true,
            ),

            SizedBox(height: tokens.spacing.sp5),
            Text('With Error', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp3),
            LayrzMonthRangeInput(
              arbitraryValue: const [],
              onArbitraryChanged: (_) {},
              labelText: 'Months (required)',
              hintText: 'Pick any months',
              errors: const ['This field is required.'],
            ),
          ],
        ),
      ),
    );
  }
}
