import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Builds a comprehensive showcase of [LayrzStepper] variants.
Widget buildStepperDemo(BuildContext context) {
  return _StepperDemo();
}

class _StepperDemo extends StatefulWidget {
  const _StepperDemo();

  @override
  State<_StepperDemo> createState() => _StepperDemoState();
}

class _StepperDemoState extends State<_StepperDemo> {
  late LayrzStepperController _controller1;
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spacing.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spacing.sp5,
        children: [
          // Basic stepper
          Text('Multi-Step Wizard', style: tokens.typography.title),
          Text(
            'A guided flow with back/next navigation',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          SizedBox(
            height: 500,
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

          // Linear stepper with custom labels
          SizedBox(height: tokens.spacing.sp5),
          Text('Sequential Steps', style: tokens.typography.title),
          Text(
            'Steps must be completed in order',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          SizedBox(
            height: 500,
            child: LayrzStepper(
              controller: _controller2,
              backButtonLabel: 'Previous',
              nextButtonLabel: 'Continue',
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
          ),
        ],
      ),
    );
  }

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
