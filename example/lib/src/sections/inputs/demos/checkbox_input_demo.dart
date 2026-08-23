import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

class CheckboxInputDemo extends StatefulWidget {
  const CheckboxInputDemo({super.key});

  @override
  State<CheckboxInputDemo> createState() => _CheckboxInputDemoState();
}

class _CheckboxInputDemoState extends State<CheckboxInputDemo> {
  bool _unchecked = false;
  bool _checked = true;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SizedBox(
      height: double.infinity,
      child: SingleChildScrollView(
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
              LayrzRow(
                children: [
                  LayrzCol(
                    xs: 12,
                    child: LayrzCheckboxInput(
                      value: false,
                      labelText: 'Required field',
                      errors: ['You must accept this'],
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
                      value: true,
                      labelText: 'Feature enabled',
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzCheckboxInput(
                      value: false,
                      labelText: 'Feature disabled',
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    child: LayrzCheckboxInput(
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
      ),
    );
  }
}
