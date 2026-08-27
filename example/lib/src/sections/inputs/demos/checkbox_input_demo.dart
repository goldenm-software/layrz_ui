import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Showroom demo for [LayrzCheckboxInput].
///
/// Every non-disabled checkbox below is wired to state via `onChanged` + `setState`,
/// including the error-state example, whose error message clears interactively once
/// the box is checked.
class CheckboxInputDemo extends StatefulWidget {
  /// Creates a new [CheckboxInputDemo].
  const CheckboxInputDemo({super.key});

  @override
  State<CheckboxInputDemo> createState() => _CheckboxInputDemoState();
}

class _CheckboxInputDemoState extends State<CheckboxInputDemo> {
  bool _unchecked = false;
  bool _checked = true;
  bool _requiredAccepted = false;
  bool _featureEnabled = true;
  bool _featureDisabled = false;

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
            // Basic states
            Text('Checkbox States', style: tokens.typography.title),
            LayrzRow(
              children: [
                LayrzCol(
                  xs: 12,
                  md: 6,
                  child: LayrzCheckboxInput(
                    value: _unchecked,
                    onChanged: (v) {
                      debugPrint('Unchecked checkbox changed to: $v');
                      setState(() {
                        _unchecked = v;
                      });
                    },
                    labelText: 'Unchecked checkbox',
                  ),
                ),
                LayrzCol(
                  xs: 12,
                  md: 6,
                  child: LayrzCheckboxInput(
                    value: _checked,
                    onChanged: (v) {
                      setState(() {
                        _checked = v;
                      });
                    },
                    labelText: 'Checked checkbox',
                  ),
                ),
                LayrzCol(
                  xs: 12,
                  child: LayrzCheckboxInput(
                    value: false,
                    disabled: true,
                    labelText: 'Disabled checkbox',
                  ),
                ),
              ],
            ),

            tokens.spacing.sb3,
            Text('Error State', style: tokens.typography.title),
            Text(
              'The error clears as soon as the box is checked -- check it to see the message disappear.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            tokens.spacing.sb1,
            LayrzRow(
              children: [
                LayrzCol(
                  xs: 12,
                  child: LayrzCheckboxInput(
                    value: _requiredAccepted,
                    onChanged: (v) {
                      setState(() {
                        _requiredAccepted = v;
                      });
                    },
                    labelText: 'Required field',
                    errors: _requiredAccepted ? const [] : const ['You must accept this'],
                  ),
                ),
              ],
            ),

            tokens.spacing.sb3,
            Text('Various States', style: tokens.typography.title),
            LayrzRow(
              children: [
                LayrzCol(
                  xs: 12,
                  md: 6,
                  child: LayrzCheckboxInput(
                    value: _featureEnabled,
                    onChanged: (v) {
                      setState(() {
                        _featureEnabled = v;
                      });
                    },
                    labelText: 'Feature enabled',
                  ),
                ),
                LayrzCol(
                  xs: 12,
                  md: 6,
                  child: LayrzCheckboxInput(
                    value: _featureDisabled,
                    onChanged: (v) {
                      setState(() {
                        _featureDisabled = v;
                      });
                    },
                    labelText: 'Feature disabled',
                  ),
                ),
                LayrzCol(
                  xs: 12,
                  child: const LayrzCheckboxInput(
                    value: false,
                    disabled: true,
                    labelText: 'Cannot toggle',
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
