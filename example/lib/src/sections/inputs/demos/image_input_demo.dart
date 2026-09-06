import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Demonstrates [LayrzImageInput], the image picker input.
///
/// Wires the widget to local state via `setState` so the currently selected
/// image value is both visibly interactive and echoed back below the field.
/// Seeded with a URL to show the preview path; replacing it emits base64 via
/// `onChanged`.
class ImageInputDemo extends StatefulWidget {
  /// Creates a new [ImageInputDemo].
  const ImageInputDemo({super.key});

  @override
  State<ImageInputDemo> createState() => _ImageInputDemoState();
}

class _ImageInputDemoState extends State<ImageInputDemo> {
  /// A sample image URL seeding the demo, so its preview (and broken-image
  /// fallback, if the URL fails to load) is visible without any user action.
  String? _image = 'https://cdn.layrz.com/resources/com.layrz.ui/logo.png?3';

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      child: Padding(
        padding: tokens.spacing.pd2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Default Image Input', style: tokens.typography.title),
            Text(
              'Seeded with a URL to show the preview path; replacing it emits base64 via onChanged. '
              'Try an invalid URL (edit the seed) to see the broken-image fallback.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzImageInput(
              labelText: 'Cover image',
              value: _image,
              maxFileSizeBytes: 5 * 1024 * 1024,
              maxFileSizeLabel: '5 MB',
              onChanged: (base64) => setState(() => _image = base64),
            ),
            SizedBox(height: tokens.spacing.sp2),
            Text(
              _image == null
                  ? 'Value: (none)'
                  : (_image!.startsWith('data:')
                        ? 'Value: base64 data URI, ${_image!.length} characters'
                        : 'Value: URL, ${_image!.length} characters'),
              style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
            ),
          ],
        ),
      ),
    );
  }
}
