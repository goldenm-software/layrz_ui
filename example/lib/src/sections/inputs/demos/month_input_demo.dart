import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Showroom demo for [LayrzMonthInput].
///
/// Demonstrates three instances side by side: a normal instance, an instance with a non-empty
/// `errors` list (showing the danger border), and a `disabled` instance. Each opens a
/// [LayrzEndDrawer] (desktop) or [LayrzBottomSheet] (mobile) with Cancel and Save actions --
/// tapping a month only drafts it; `onChanged` fires once, on Save.
class MonthInputDemo extends StatefulWidget {
  /// Creates a new [MonthInputDemo].
  const MonthInputDemo({super.key});

  @override
  State<MonthInputDemo> createState() => _MonthInputDemoState();
}

class _MonthInputDemoState extends State<MonthInputDemo> {
  /// The committed value for the normal instance.
  LayrzMonth? _month;

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
              'Left: a normal instance. Middle: a non-empty errors list, showing the danger '
              'border. Right: disabled. Tapping a month only drafts it -- Save commits, Cancel '
              'discards.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzRow(
              spacing: tokens.spacing.sp3,
              children: [
                LayrzCol(
                  xs: 12,
                  md: 4,
                  child: LayrzMonthInput(
                    value: _month,
                    onChanged: (value) => setState(() => _month = value),
                    labelText: 'Month',
                    hintText: 'Pick a month',
                  ),
                ),
                LayrzCol(
                  xs: 12,
                  md: 4,
                  child: LayrzMonthInput(
                    value: null,
                    onChanged: (_) {},
                    labelText: 'Month (error)',
                    errors: const ['This field is required.'],
                  ),
                ),
                LayrzCol(
                  xs: 12,
                  md: 4,
                  child: LayrzMonthInput(
                    value: LayrzMonth.fromDateTime(DateTime.now()),
                    onChanged: (_) {},
                    labelText: 'Month (disabled)',
                    disabled: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
