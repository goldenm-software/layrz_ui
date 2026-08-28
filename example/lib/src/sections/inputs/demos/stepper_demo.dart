import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Showroom demo for [LayrzStepper].
///
/// The wide-layout stepper is a page-filling component by design — it does
/// not manage its own height the way a text field does — so this demo sizes
/// its container to (most of) the real available viewport via [LayoutBuilder]
/// rather than boxing it in an arbitrary fixed height. A fixed
/// `SizedBox(height: 500)` around it would hide exactly the assumption this
/// component makes, which is the point of a showroom: show what the widget
/// actually looks like in the layout it expects to live in.
class StepperDemo extends StatefulWidget {
  /// Creates a [StepperDemo].
  const StepperDemo({super.key});

  @override
  State<StepperDemo> createState() => _StepperDemoState();
}

class _StepperDemoState extends State<StepperDemo> {
  /// Controller for the full-height wide/compact wizard demo.
  late LayrzStepperController _controller1;

  /// Controller for the sequential-steps demo, forced to the compact layout
  /// so both branches are represented regardless of the demo pane's width.
  late LayrzStepperController _controller2;

  @override
  void initState() {
    super.initState();
    _controller1 = LayrzStepperController();
    _controller2 = LayrzStepperController();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Reserve enough room for the section header text above the first
        // demo so the page-filling stepper below it still fits without the
        // whole page needing to scroll — while still occupying the large
        // majority of the available height, unlike the old fixed 500px box.
        // 160px is an estimate for the title, subtitle and gaps above it;
        // there is no spacing token above sp5 (32px) to compose this from.
        const reservedForHeader = 160.0;
        final wizardHeight = (constraints.maxHeight - reservedForHeader).clamp(400.0, double.infinity);

        return SingleChildScrollView(
          child: Padding(
            padding: tokens.spacing.pd2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.sp5,
              children: [
                // Full-height wizard — demonstrates the wide layout genuinely
                // filling its container, which is the layout LayrzStepper is
                // designed to occupy (see class doc above).
                Text('Multi-Step Wizard', style: tokens.typography.title),
                Text(
                  'A guided flow with back/next navigation, sized to the '
                  'available page height rather than boxed to a fixed size',
                  style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
                ),
                SizedBox(height: tokens.spacing.sp3),
                SizedBox(
                  height: wizardHeight,
                  child: LayrzStepper(
                    controller: _controller1,
                    steps: [
                      LayrzStep(
                        labelText: 'Personal Info',
                        body: _buildStepContent(
                          'Enter your name and email',
                          tokens,
                        ),
                      ),
                      LayrzStep(
                        labelText: 'Address',
                        body: _buildStepContent(
                          'Provide your contact address',
                          tokens,
                        ),
                      ),
                      LayrzStep(
                        labelText: 'Confirmation',
                        body: _buildStepContent(
                          'Review and confirm your information',
                          tokens,
                        ),
                      ),
                    ],
                  ),
                ),

                // Compact accordion — forced via isCompact: true regardless of
                // the demo pane's actual width, so the vertical accordion
                // layout (and its inline active body) is always visible here
                // even when the showroom window is wide.
                SizedBox(height: tokens.spacing.sp5),
                Text('Sequential Steps (compact layout)', style: tokens.typography.title),
                Text(
                  'Steps must be completed in order — forced to the compact '
                  'accordion layout to show it regardless of window width',
                  style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
                ),
                SizedBox(height: tokens.spacing.sp3),
                LayrzStepper(
                  controller: _controller2,
                  backButtonLabel: 'Previous',
                  nextButtonLabel: 'Continue',
                  isCompact: true,
                  steps: [
                    LayrzStep(
                      labelText: 'Agreement',
                      body: _buildStepContent(
                        'Read and accept terms of service',
                        tokens,
                      ),
                    ),
                    LayrzStep(
                      labelText: 'Setup',
                      body: _buildStepContent(
                        'Configure your account settings',
                        tokens,
                      ),
                    ),
                    LayrzStep(
                      labelText: 'Done',
                      body: _buildStepContent(
                        'Your account is ready!',
                        tokens,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the shared placeholder body content shown for each step: a short
  /// description line followed by a sample input field.
  Widget _buildStepContent(String text, LayrzTokens tokens) {
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spacing.sp3,
        children: [
          Text(text, style: tokens.typography.body),
          const LayrzTextInput(
            labelText: 'Input field',
            hintText: 'Enter some information',
          ),
        ],
      ),
    );
  }
}
