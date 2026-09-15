import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Showroom demo for [LayrzOtpInput].
///
/// Exercises a live field (showing the current value as it is typed), an errored variant,
/// and a disabled variant -- matching the shape of [DurationInputDemo] (one titled section
/// per variant, scrollable, laid out with design tokens throughout).
class OtpInputDemo extends StatefulWidget {
  /// Creates a new [OtpInputDemo].
  const OtpInputDemo({super.key});

  @override
  State<OtpInputDemo> createState() => _OtpInputDemoState();
}

class _OtpInputDemoState extends State<OtpInputDemo> {
  /// Controller backing the live demo field, so its current text can be read directly by
  /// [dispose] and mirrored into [_liveValue] as the user types.
  late TextEditingController _liveController;

  /// Mirrors the live field's current value for display in the "current value" caption.
  String _liveValue = '';

  /// Whether the live field has completed all 6 digits at least once, for the completion
  /// caption below it.
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _liveController = TextEditingController();
  }

  @override
  void dispose() {
    _liveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      child: Padding(
        padding: tokens.spacing.pd2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live example
            Text('Live', style: tokens.typography.title),
            Text(
              'Type into the field below -- the current value and completion state update live.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzOtpInput(
              labelText: 'Verification code',
              isRequired: true,
              controller: _liveController,
              onChanged: (value) {
                setState(() {
                  _liveValue = value;
                });
              },
              onCompleted: (value) {
                setState(() {
                  _completed = true;
                });
              },
            ),
            SizedBox(height: tokens.spacing.sp2),
            Text(
              'Current value: "$_liveValue"${_completed ? ' (completed at least once)' : ''}',
              style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
            ),

            // With error
            SizedBox(height: tokens.spacing.sp5),
            Text('With Error', style: tokens.typography.title),
            Text(
              'Every slot paints its danger state together when errors is non-empty.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            const LayrzOtpInput(
              labelText: 'Verification code',
              value: '123',
              errors: ['Invalid code'],
            ),

            // Disabled
            SizedBox(height: tokens.spacing.sp5),
            Text('Disabled', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp3),
            const LayrzOtpInput(
              labelText: 'Verification code',
              value: '482913',
              disabled: true,
            ),
          ],
        ),
      ),
    );
  }
}
