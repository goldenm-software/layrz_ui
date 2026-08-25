import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Showroom demo for [LayrzDurationInput].
///
/// Exercises both [LayrzDurationFormat] values, a reduced [LayrzDurationInput.visibleUnits]
/// set, an explicit zero-valued duration, the disabled state, and an error state -- matching
/// the shape of [ComboBoxInputDemo] and [SelectInputDemo] (one titled section per variant,
/// scrollable, laid out with design tokens throughout).
class DurationInputDemo extends StatefulWidget {
  /// Creates a new [DurationInputDemo].
  const DurationInputDemo({super.key});

  @override
  State<DurationInputDemo> createState() => _DurationInputDemoState();
}

class _DurationInputDemoState extends State<DurationInputDemo> {
  /// Backing value for the default (long-format) section.
  Duration? _longFormatDuration = const Duration(hours: 2, minutes: 30);

  /// Backing value for the short-format section.
  Duration? _shortFormatDuration = const Duration(hours: 2, minutes: 30);

  /// Backing value for the reduced-[LayrzDurationInput.visibleUnits] section.
  ///
  /// Only hours and minutes are visible here, so the days component of this seed value
  /// never surfaces in the summary -- demonstrating that hidden units are dropped, not
  /// merely zeroed.
  Duration? _reducedUnitsDuration = const Duration(days: 1, hours: 5, minutes: 15);

  /// Backing value for the explicit-zero section.
  ///
  /// Deliberately [Duration.zero], not `null`, to demonstrate that a chosen zero renders the
  /// smallest visible unit (e.g. "0s") rather than empty text.
  Duration? _zeroDuration = Duration.zero;

  /// Backing value for the error-state section. Left unset so the field renders empty
  /// alongside its error message.
  Duration? _requiredDuration;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      child: Padding(
        padding: tokens.spacing.pd2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.sp5,
          children: [
            // Long format (default)
            Text('Long Format (Default)', style: tokens.typography.title),
            Text(
              'LayrzDurationFormat.long reads like "2 hours, 30 minutes".',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDurationInput(
              labelText: 'Session Timeout',
              hintText: 'Select a duration',
              value: _longFormatDuration,
              onChanged: (value) {
                setState(() {
                  _longFormatDuration = value;
                });
              },
            ),

            // Short format
            SizedBox(height: tokens.spacing.sp5),
            Text('Short Format', style: tokens.typography.title),
            Text(
              'LayrzDurationFormat.short abbreviates the same value to "2h 30m".',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDurationInput(
              labelText: 'Cache TTL',
              hintText: 'Select a duration',
              format: LayrzDurationFormat.short,
              value: _shortFormatDuration,
              onChanged: (value) {
                setState(() {
                  _shortFormatDuration = value;
                });
              },
            ),

            // Reduced visible units
            SizedBox(height: tokens.spacing.sp5),
            Text('Reduced Visible Units', style: tokens.typography.title),
            Text(
              'visibleUnits restricted to hours and minutes -- the picker and summary both '
              'drop days and seconds entirely, rather than showing them as zero.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDurationInput(
              labelText: 'Shift Length',
              hintText: 'Select a duration',
              visibleUnits: const {LayrzDurationUnit.hour, LayrzDurationUnit.minute},
              value: _reducedUnitsDuration,
              onChanged: (value) {
                setState(() {
                  _reducedUnitsDuration = value;
                });
              },
            ),

            // Explicit zero duration
            SizedBox(height: tokens.spacing.sp5),
            Text('Zero Duration', style: tokens.typography.title),
            Text(
              'An explicit Duration.zero renders the smallest visible unit (e.g. "0s"), '
              'staying visually distinct from an unset (null) value.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDurationInput(
              labelText: 'Grace Period',
              hintText: 'Select a duration',
              value: _zeroDuration,
              onChanged: (value) {
                setState(() {
                  _zeroDuration = value;
                });
              },
            ),

            // Disabled
            SizedBox(height: tokens.spacing.sp5),
            Text('Disabled', style: tokens.typography.title),
            LayrzDurationInput(
              labelText: 'Locked Timeout',
              value: const Duration(minutes: 45),
              disabled: true,
            ),

            // With error
            SizedBox(height: tokens.spacing.sp5),
            Text('With Error', style: tokens.typography.title),
            LayrzDurationInput(
              labelText: 'Required Duration',
              hintText: 'Select a duration',
              isRequired: true,
              value: _requiredDuration,
              errors: const ['Duration is required'],
              onChanged: (value) {
                setState(() {
                  _requiredDuration = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
