import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

class TextAreaInputDemo extends StatefulWidget {
  const TextAreaInputDemo({super.key});

  @override
  State<TextAreaInputDemo> createState() => _TextAreaInputDemoState();
}

class _TextAreaInputDemoState extends State<TextAreaInputDemo> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
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
          spacing: tokens.spacing.sp5,
          children: [
            // Basic states
            Text('Field States', style: tokens.typography.title),
            LayrzRow(
              spacing: tokens.spacing.sp3,
              children: [
                LayrzCol(
                  xs: 12,
                  md: 6,
                  child: const LayrzTextAreaInput(
                    labelText: 'Comment',
                    hintText: 'Enter your feedback here',
                  ),
                ),
                LayrzCol(
                  xs: 12,
                  md: 6,
                  child: const LayrzTextAreaInput(
                    labelText: 'Required Field',
                    hintText: 'This field is required',
                    isRequired: true,
                  ),
                ),
              ],
            ),

            // Disabled and read-only
            SizedBox(height: tokens.spacing.sp3),
            Text('Disabled and Read-only', style: tokens.typography.title),
            LayrzRow(
              spacing: tokens.spacing.sp3,
              children: [
                LayrzCol(
                  xs: 12,
                  md: 6,
                  child: const LayrzTextAreaInput(
                    labelText: 'Disabled',
                    disabled: true,
                    hintText: 'This is disabled',
                  ),
                ),
                LayrzCol(
                  xs: 12,
                  md: 6,
                  child: const LayrzTextAreaInput(
                    labelText: 'Read-only',
                    readOnly: true,
                    hintText: 'View only',
                  ),
                ),
              ],
            ),

            // With errors
            SizedBox(height: tokens.spacing.sp3),
            Text('Error States', style: tokens.typography.title),
            LayrzRow(
              spacing: tokens.spacing.sp3,
              children: [
                LayrzCol(
                  xs: 12,
                  child: const LayrzTextAreaInput(
                    labelText: 'Description',
                    hintText: 'Enter a description',
                    errors: ['Description is required', 'Must be at least 10 characters'],
                  ),
                ),
              ],
            ),

            // With character limit
            SizedBox(height: tokens.spacing.sp3),
            Text('With Character Limit', style: tokens.typography.title),
            LayrzRow(
              spacing: tokens.spacing.sp3,
              children: [
                LayrzCol(
                  xs: 12,
                  child: const LayrzTextAreaInput(
                    labelText: 'Bio',
                    hintText: 'Tell us about yourself (max 200 characters)',
                    maxLength: 200,
                  ),
                ),
              ],
            ),

            // Variable line count
            SizedBox(height: tokens.spacing.sp3),
            Text('Variable Line Count', style: tokens.typography.title),
            LayrzRow(
              spacing: tokens.spacing.sp3,
              children: [
                LayrzCol(
                  xs: 12,
                  md: 6,
                  child: const LayrzTextAreaInput(
                    labelText: 'Minimal',
                    hintText: 'Few lines',
                    minLines: 2,
                    maxLines: 4,
                  ),
                ),
                LayrzCol(
                  xs: 12,
                  md: 6,
                  child: const LayrzTextAreaInput(
                    labelText: 'Expansive',
                    hintText: 'Many lines',
                    minLines: 5,
                    maxLines: 15,
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
