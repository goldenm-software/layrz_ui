import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds the file input section for the showroom.
///
/// Demonstrates [LayrzFileInput] as a live, interactive drop-zone: a
/// multi-file field restricted to image extensions, wired to local state so
/// the accepted-file list and previews are visibly driven by
/// [LayrzFileInput.onChanged]. Dropping or picking a non-image file
/// demonstrates the rejection path -- [LayrzFileInput] validates extensions
/// internally and shows [LayrzFileInput.rejectionMessage] persistently below
/// the box, so no extra wiring is needed here to see it.
class FileInputSection extends StatefulWidget {
  /// Creates a new [FileInputSection].
  const FileInputSection({super.key});

  @override
  State<FileInputSection> createState() => _FileInputSectionState();
}

class _FileInputSectionState extends State<FileInputSection> {
  /// The files currently accepted by the image drop-zone below.
  List<LayrzFileInputResult> _imageFiles = const [];

  /// The files currently accepted by the single-file drop-zone below.
  List<LayrzFileInputResult> _singleFile = const [];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'File Input',
      description:
          'A click-to-browse and drag-and-drop drop-zone. Both paths funnel into the same '
          'onChanged callback with the same LayrzFileInputResult shape.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Multi-file, image-only', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'Accepts up to 4 files with png/jpg/jpeg/gif/webp extensions. Try dropping or '
            'picking a non-image file (e.g. a .pdf) to see the persistent rejection message '
            '-- it stays until the next successful pick, drop, or clear.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzFileInput(
            labelText: 'Product photos',
            hintText: 'Click to browse or drag images here',
            value: _imageFiles,
            maxFiles: 4,
            allowedExtensions: const ['png', 'jpg', 'jpeg', 'gif', 'webp'],
            onChanged: (files) => setState(() => _imageFiles = files),
          ),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            _imageFiles.isEmpty
                ? 'No photos selected yet.'
                : '${_imageFiles.length} photo(s) selected: ${_imageFiles.map((f) => f.name).join(', ')}',
            style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('Single file (maxFiles: 1)', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'Picking or dropping a new file replaces the current selection wholesale '
            'instead of appending to it.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzFileInput(
            labelText: 'Resume',
            isRequired: true,
            value: _singleFile,
            maxFiles: 1,
            allowedExtensions: const ['pdf', 'doc', 'docx'],
            onChanged: (files) => setState(() => _singleFile = files),
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('Disabled', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          const LayrzFileInput(labelText: 'Attachments', disabled: true),
        ],
      ),
    );
  }
}
