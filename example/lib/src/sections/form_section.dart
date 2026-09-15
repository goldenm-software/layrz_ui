import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds the form section for the showroom.
///
/// Demonstrates [LayrzForm] wrapping a real [LayrzUsernameInput] +
/// [LayrzPasswordInput] pair and a submit button. [LayrzForm] itself renders
/// no chrome -- it only wraps [child] in the platform-appropriate autofill
/// grouping widget and exposes [LayrzForm.submit], which awaits the caller's
/// `onSubmit` and commits or discards the pending browser/OS credential save
/// based on its boolean result. The demo simulates success when the typed
/// password is `"correct"` and failure otherwise, so both the commit and
/// discard paths through [LayrzForm.submit] are reachable from this page.
class FormSection extends StatelessWidget {
  /// Creates a new [FormSection].
  const FormSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Form',
      description:
          'A behavioural autofill wrapper -- no chrome of its own, only the '
          'commit/discard mechanics a password manager needs to be told about.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mini login demo', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'Type "correct" as the password to simulate a successful submission -- any '
            'other value simulates a failed one. Watch the result text below the button; '
            'in a real browser, only the successful path offers to save the credential.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          const SizedBox(width: 360, child: _LoginFormDemo()),
          SizedBox(height: tokens.spacing.sp5),
          Text('OTP verification', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'Type "123456" as the code to simulate a successful verification -- any '
            'other value simulates a failed one. Completing the sixth digit auto-submits, '
            'so a pasted or autofilled code fires the flow without tapping the button.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          const SizedBox(width: 360, child: _OtpFormDemo()),
        ],
      ),
    );
  }
}

/// The actual [LayrzForm] demo: username + password fields, a submit button
/// driving [LayrzForm.submit], and a result line reporting the outcome.
class _LoginFormDemo extends StatefulWidget {
  /// Creates a new [_LoginFormDemo].
  const _LoginFormDemo();

  @override
  State<_LoginFormDemo> createState() => _LoginFormDemoState();
}

class _LoginFormDemoState extends State<_LoginFormDemo> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  /// The result text shown below the submit button, or null before the first
  /// submit attempt.
  String? _resultText;

  /// Whether a submission is currently in flight.
  bool _submitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// The caller's own submit handler passed to [LayrzForm.onSubmit].
  ///
  /// Simulates a backend call with a short delay, succeeding only when the
  /// typed password is exactly `"correct"`.
  Future<bool> _handleSubmit() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _passwordController.text == 'correct';
  }

  Future<void> _onSubmitPressed(LayrzForm form) async {
    setState(() {
      _submitting = true;
      _resultText = null;
    });
    final succeeded = await form.submit();
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _resultText = succeeded
          ? 'Submitted successfully -- credential save offered to the platform.'
          : 'Submission failed -- credential save discarded.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    late final LayrzForm form;
    form = LayrzForm(
      onSubmit: _handleSubmit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayrzUsernameInput(controller: _usernameController),
          SizedBox(height: tokens.spacing.sp3),
          LayrzPasswordInput(
            controller: _passwordController,
            onSubmit: (_) => _onSubmitPressed(form),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzButton(
            labelText: _submitting ? 'Submitting...' : 'Sign in',
            style: LayrzButtonStyle.filled,
            onTap: _submitting ? null : () => _onSubmitPressed(form),
          ),
          if (_resultText != null) ...[
            SizedBox(height: tokens.spacing.sp3),
            Text(
              _resultText!,
              style: tokens.typography.body.copyWith(color: tokens.colors.fg2),
            ),
          ],
        ],
      ),
    );

    return form;
  }
}

/// The [LayrzForm] + [LayrzOtpInput] demo: a single OTP field wrapped in a
/// [LayrzForm], a submit button driving [LayrzForm.submit], and a result line
/// reporting the outcome.
///
/// [LayrzOtpInput.onCompleted] is wired to the same submit path as the button, so
/// completing the sixth digit -- whether typed, pasted, or filled by autofill --
/// fires the flow on its own, in addition to the explicit button tap.
class _OtpFormDemo extends StatefulWidget {
  /// Creates a new [_OtpFormDemo].
  const _OtpFormDemo();

  @override
  State<_OtpFormDemo> createState() => _OtpFormDemoState();
}

class _OtpFormDemoState extends State<_OtpFormDemo> {
  /// The controller backing the OTP field, owned and disposed by this widget.
  late final TextEditingController _otpController;

  /// The result text shown below the submit button, or null before the first
  /// submit attempt.
  String? _resultText;

  /// Whether a submission is currently in flight.
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  /// The caller's own submit handler passed to [LayrzForm.onSubmit].
  ///
  /// Simulates a backend call with a short delay, succeeding only when the typed code is
  /// exactly `"123456"` -- the fixed demo-valid code for this showcase.
  Future<bool> _handleSubmit() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _otpController.text == '123456';
  }

  /// Drives [LayrzForm.submit] from either the button tap or
  /// [LayrzOtpInput.onCompleted], updating [_submitting] and [_resultText] with the
  /// outcome.
  Future<void> _onSubmitPressed(LayrzForm form) async {
    setState(() {
      _submitting = true;
      _resultText = null;
    });
    final succeeded = await form.submit();
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _resultText = succeeded
          ? 'Code verified -- autofill committed.'
          : 'Invalid code -- 123456 expected in this demo.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    late final LayrzForm form;
    form = LayrzForm(
      onSubmit: _handleSubmit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayrzOtpInput(
            controller: _otpController,
            labelText: 'Verification code',
            onCompleted: (_) => _onSubmitPressed(form),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzButton(
            labelText: _submitting ? 'Verifying...' : 'Verify',
            style: LayrzButtonStyle.filled,
            onTap: _submitting ? null : () => _onSubmitPressed(form),
          ),
          if (_resultText != null) ...[
            SizedBox(height: tokens.spacing.sp3),
            Text(
              _resultText!,
              style: tokens.typography.body.copyWith(color: tokens.colors.fg2),
            ),
          ],
        ],
      ),
    );

    return form;
  }
}
