import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Widget that renders all sections of the textarea input demo.
class TextAreaInputDemoSections extends StatelessWidget {
  /// Controller for the basic textarea field.
  final TextEditingController basicController;

  /// Controller for the required field.
  final TextEditingController requiredController;

  /// Controller for the disabled field.
  final TextEditingController disabledController;

  /// Controller for the read-only field.
  final TextEditingController readOnlyController;

  /// Controller for the error state field.
  final TextEditingController errorController;

  /// Controller for the character limit field.
  final TextEditingController charLimitController;

  /// Controller for the minimal lines field.
  final TextEditingController minimalLinesController;

  /// Controller for the expansive lines field.
  final TextEditingController expansiveLinesController;

  /// Controller for the prefix icon field.
  final TextEditingController prefixIconController;

  /// Controller for the prefix widget field.
  final TextEditingController prefixWidgetController;

  /// Controller for the prefix text field.
  final TextEditingController prefixTextController;

  /// Controller for the suffix icon field.
  final TextEditingController suffixIconController;

  /// Controller for the suffix widget field.
  final TextEditingController suffixWidgetController;

  /// Controller for the suffix text field.
  final TextEditingController suffixTextController;

  /// Controller for the help affordance field.
  final TextEditingController helpController;

  /// Controller for the top-aligned field with pre-filled content.
  final TextEditingController topAlignWithContentController;

  /// Controller for the top-aligned empty field.
  final TextEditingController topAlignEmptyController;

  /// Controller for the live interaction field.
  final TextEditingController liveInteractionController;

  /// Controller for the input formatter field.
  final TextEditingController formatterController;

  /// Controller for the keyboard behaviour field.
  final TextEditingController keyboardController;

  /// Controller for the custom padding field.
  final TextEditingController customPaddingController;

  /// Controller for the default padding field.
  final TextEditingController defaultPaddingController;

  /// Callback fired when the input state changes.
  final VoidCallback onStateChanged;

  const TextAreaInputDemoSections({
    super.key,
    required this.basicController,
    required this.requiredController,
    required this.disabledController,
    required this.readOnlyController,
    required this.errorController,
    required this.charLimitController,
    required this.minimalLinesController,
    required this.expansiveLinesController,
    required this.prefixIconController,
    required this.prefixWidgetController,
    required this.prefixTextController,
    required this.suffixIconController,
    required this.suffixWidgetController,
    required this.suffixTextController,
    required this.helpController,
    required this.topAlignWithContentController,
    required this.topAlignEmptyController,
    required this.liveInteractionController,
    required this.formatterController,
    required this.keyboardController,
    required this.customPaddingController,
    required this.defaultPaddingController,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SizedBox(
      height: double.infinity,
      child: SingleChildScrollView(
        child: Container(
          padding: tokens.spacing.pd2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: tokens.spacing.sp1,
            children: [
              // Field States
              Text('Field States', style: tokens.typography.title),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzTextAreaInput(
                      labelText: 'Comment',
                      hintText: 'Enter your feedback here',
                      controller: basicController,
                      onChanged: (_) => onStateChanged(),
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzTextAreaInput(
                      labelText: 'Required Field',
                      hintText: 'This field is required',
                      isRequired: true,
                      controller: requiredController,
                      onChanged: (_) => onStateChanged(),
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('Disabled and Read-only', style: tokens.typography.title),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzTextAreaInput(
                      labelText: 'Disabled',
                      hintText: 'This is disabled',
                      disabled: true,
                      controller: disabledController,
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzTextAreaInput(
                      labelText: 'Read-only',
                      hintText: 'View only',
                      readOnly: true,
                      controller: readOnlyController,
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('Error States', style: tokens.typography.title),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    child: LayrzTextAreaInput(
                      labelText: 'Description',
                      hintText: 'Enter a description',
                      errors: ['Description is required', 'Must be at least 10 characters'],
                      controller: errorController,
                      onChanged: (_) => onStateChanged(),
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('With Character Limit', style: tokens.typography.title),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    child: LayrzTextAreaInput(
                      labelText: 'Bio',
                      hintText: 'Tell us about yourself (max 200 characters)',
                      maxLength: 200,
                      controller: charLimitController,
                      onChanged: (_) => onStateChanged(),
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('Variable Line Count', style: tokens.typography.title),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzTextAreaInput(
                      labelText: 'Minimal',
                      hintText: 'Few lines',
                      minLines: 2,
                      maxLines: 4,
                      controller: minimalLinesController,
                      onChanged: (_) => onStateChanged(),
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzTextAreaInput(
                      labelText: 'Expansive',
                      hintText: 'Many lines',
                      minLines: 5,
                      maxLines: 15,
                      controller: expansiveLinesController,
                      onChanged: (_) => onStateChanged(),
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('Prefix and Suffix Slots', style: tokens.typography.title),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzTextAreaInput(
                      labelText: 'With Prefix Icon',
                      hintText: 'Icon on the left',
                      prefixIcon: MdiIcons.pencil,
                      controller: prefixIconController,
                      onChanged: (_) => onStateChanged(),
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzTextAreaInput(
                      labelText: 'With Suffix Icon',
                      hintText: 'Icon on the right',
                      suffixIcon: MdiIcons.check,
                      onSuffixTap: () => onStateChanged(),
                      controller: suffixIconController,
                      onChanged: (_) => onStateChanged(),
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzTextAreaInput(
                      labelText: 'With Prefix Text',
                      hintText: 'Text prefix',
                      prefixText: '>> ',
                      controller: prefixTextController,
                      onChanged: (_) => onStateChanged(),
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzTextAreaInput(
                      labelText: 'With Suffix Text',
                      hintText: 'Text suffix',
                      suffixText: ' <<',
                      controller: suffixTextController,
                      onChanged: (_) => onStateChanged(),
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    child: LayrzTextAreaInput(
                      labelText: 'With Custom Widget Prefix',
                      hintText: 'Custom widget as prefix',
                      prefix: Container(
                        padding: EdgeInsets.only(right: tokens.spacing.sp1),
                        child: Text('[Custom]', style: tokens.typography.label),
                      ),
                      controller: prefixWidgetController,
                      onChanged: (_) => onStateChanged(),
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    child: LayrzTextAreaInput(
                      labelText: 'With Custom Widget Suffix',
                      hintText: 'Custom widget as suffix',
                      suffix: Container(
                        padding: EdgeInsets.only(left: tokens.spacing.sp1),
                        child: Text('[Info]', style: tokens.typography.label),
                      ),
                      controller: suffixWidgetController,
                      onChanged: (_) => onStateChanged(),
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('Help Affordance', style: tokens.typography.title),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    child: LayrzTextAreaInput(
                      labelText: 'With Help Text',
                      hintText: 'Enter additional details',
                      helpTitleText: 'Help',
                      helpContentText: 'This field accepts multiple lines of text. Be concise but descriptive.',
                      controller: helpController,
                      onChanged: (_) => onStateChanged(),
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('Top Alignment Demo', style: tokens.typography.title),
              Text(
                'Left field has pre-filled lines to show content-top alignment. Right field is empty to show hint-top alignment.',
                style: tokens.typography.label,
              ),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzTextAreaInput(
                      labelText: 'With Content',
                      hintText: 'Placeholder text',
                      minLines: 5,
                      maxLines: 5,
                      controller: topAlignWithContentController,
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzTextAreaInput(
                      labelText: 'Empty (shows hint)',
                      hintText: 'This hint starts at the top',
                      minLines: 5,
                      maxLines: 5,
                      controller: topAlignEmptyController,
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('Live Interaction', style: tokens.typography.title),
              Text(
                'Type in the field to see the character count update in real time.',
                style: tokens.typography.label,
              ),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzTextAreaInput(
                      labelText: 'Count Characters',
                      hintText: 'Type here to see the count',
                      controller: liveInteractionController,
                      onChanged: (_) => onStateChanged(),
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: tokens.spacing.sp2,
                        children: [
                          Text(
                            'Character count:',
                            style: tokens.typography.label,
                          ),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: liveInteractionController,
                            builder: (context, value, child) {
                              return Text(
                                '${value.text.length} characters',
                                style: tokens.typography.body,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('Input Formatters', style: tokens.typography.title),
              Text(
                'This field converts all input to uppercase using a custom formatter.',
                style: tokens.typography.label,
              ),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    child: LayrzTextAreaInput(
                      labelText: 'Uppercase Only',
                      hintText: 'Type lowercase, it becomes uppercase',
                      inputFormatters: [
                        UppercaseFormatter(),
                      ],
                      controller: formatterController,
                      onChanged: (_) => onStateChanged(),
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('Keyboard Behaviour', style: tokens.typography.title),
              Text(
                'Press Enter to insert a newline (default TextInputAction.newline).',
                style: tokens.typography.label,
              ),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    child: LayrzTextAreaInput(
                      labelText: 'Multi-line Entry',
                      hintText: 'Press Enter to create new lines',
                      textInputAction: TextInputAction.newline,
                      controller: keyboardController,
                      onChanged: (_) => onStateChanged(),
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('Padding Override', style: tokens.typography.title),
              Text(
                'Left field has custom padding (16px), right field uses default (10px).',
                style: tokens.typography.label,
              ),
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzTextAreaInput(
                      labelText: 'Custom Padding (16px)',
                      hintText: 'Extra internal spacing',
                      padding: EdgeInsets.all(16),
                      controller: customPaddingController,
                      onChanged: (_) => onStateChanged(),
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzTextAreaInput(
                      labelText: 'Default Padding',
                      hintText: 'Standard internal spacing',
                      controller: defaultPaddingController,
                      onChanged: (_) => onStateChanged(),
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

/// Custom formatter that converts text to uppercase.
class UppercaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: newValue.composing,
    );
  }
}
