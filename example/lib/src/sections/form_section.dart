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
