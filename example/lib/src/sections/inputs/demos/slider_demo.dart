import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Showroom demo for [LayrzSlider].
///
/// Shows a continuous slider, a quantised slider using [LayrzSlider.divisions],
/// one with a custom [LayrzSlider.valueFormatter], a disabled slider, and one
/// displaying validation [LayrzSlider.errors]. Every interactive slider is wired
/// to state via `onChanged` + `setState` so the live value label at the top of
/// the track can be watched updating on every drag delta, not only on release.
///
/// Dragging any enabled slider also shows the drag-only value bubble directly
/// above the thumb (a mouse click-and-drag, not a single tap, is needed to
/// see it — a tap alone does not enter the dragging state).
class SliderDemo extends StatefulWidget {
  /// Creates a new [SliderDemo].
  const SliderDemo({super.key});

  @override
  State<SliderDemo> createState() => _SliderDemoState();
}

class _SliderDemoState extends State<SliderDemo> {
  double _continuous = 40.0;
  double _quantized = 50.0;
  double _percentage = 0.65;
  double _errorValue = 10.0;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      child: Container(
        padding: tokens.spacing.pd2,
        child: Column(
          crossAxisAlignment: .start,
          mainAxisAlignment: .start,
          spacing: tokens.spacing.sp1,
          children: [
            // Continuous slider
            Text('Continuous', style: tokens.typography.title),
            Text(
              'Drag, click, or use the arrow keys once focused to move the value. '
              'While dragging, a value bubble also appears above the thumb.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            tokens.spacing.sb1,
            LayrzSlider(
              labelText: 'Volume',
              value: _continuous,
              onChanged: (v) {
                setState(() {
                  _continuous = v;
                });
              },
            ),

            tokens.spacing.sb3,
            Text('Quantized (divisions)', style: tokens.typography.title),
            Text(
              'divisions: 4 across [0, 100] snaps the thumb to 0 / 25 / 50 / 75 / 100.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            tokens.spacing.sb1,
            LayrzSlider(
              labelText: 'Quality preset',
              value: _quantized,
              divisions: 4,
              onChanged: (v) {
                setState(() {
                  _quantized = v;
                });
              },
            ),

            tokens.spacing.sb3,
            Text('Custom valueFormatter', style: tokens.typography.title),
            Text(
              'The range is [0.0, 1.0] but the value label and semantics announce a percentage.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            tokens.spacing.sb1,
            LayrzSlider(
              labelText: 'Completion',
              value: _percentage,
              min: 0.0,
              max: 1.0,
              valueFormatter: (v) => '${(v * 100).round()}%',
              onChanged: (v) {
                setState(() {
                  _percentage = v;
                });
              },
            ),

            tokens.spacing.sb3,
            Text('Disabled', style: tokens.typography.title),
            tokens.spacing.sb1,
            const LayrzSlider(
              labelText: 'Locked value',
              value: 30.0,
              disabled: true,
            ),

            tokens.spacing.sb3,
            Text('Error state', style: tokens.typography.title),
            Text(
              'The error clears once the value reaches at least 50 -- drag it past the midpoint to see the message disappear.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            tokens.spacing.sb1,
            LayrzSlider(
              labelText: 'Minimum threshold',
              value: _errorValue,
              onChanged: (v) {
                setState(() {
                  _errorValue = v;
                });
              },
              errors: _errorValue >= 50 ? const [] : const ['Value must be at least 50'],
            ),
          ],
        ),
      ),
    );
  }
}
