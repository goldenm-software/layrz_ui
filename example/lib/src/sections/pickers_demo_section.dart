import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds the pickers demo section for the showroom.
///
/// Demonstrates the four `pickers/` module widgets — [LayrzColorInput],
/// [LayrzMultiSelectInput], [LayrzEmojiInput], and [LayrzImageInput] — each
/// wired to local state via `setState` so its current value is both visibly
/// interactive and echoed back below the field as plain text. This mirrors
/// the same live-state pattern [FileInputSection] uses for [LayrzFileInput].
class PickersDemoSection extends StatefulWidget {
  /// Creates a new [PickersDemoSection].
  const PickersDemoSection({super.key});

  @override
  State<PickersDemoSection> createState() => _PickersDemoSectionState();
}

class _PickersDemoSectionState extends State<PickersDemoSection> {
  /// The color currently selected by the [LayrzColorInput] demo.
  Color _color = const Color(0xFF2196F3);

  /// A sample palette of 8 swatches feeding the color input's Palette tab.
  static final Set<Color> _palette = {
    Color(0xFFF44336),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF3F51B5),
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFFEB3B),
    Color(0xFFFF9800),
  };

  /// The fruit items offered by the [LayrzMultiSelectInput] demo.
  static const List<LayrzSelectItem<String>> _fruitItems = [
    LayrzSelectItem(value: 'apple', child: Text('Apple'), searchableStrings: {'Apple'}),
    LayrzSelectItem(value: 'banana', child: Text('Banana'), searchableStrings: {'Banana'}),
    LayrzSelectItem(value: 'cherry', child: Text('Cherry'), searchableStrings: {'Cherry'}),
    LayrzSelectItem(value: 'durian', child: Text('Durian'), searchableStrings: {'Durian'}),
    LayrzSelectItem(value: 'elderberry', child: Text('Elderberry'), searchableStrings: {'Elderberry'}),
    LayrzSelectItem(value: 'fig', child: Text('Fig'), searchableStrings: {'Fig'}),
    LayrzSelectItem(value: 'grape', child: Text('Grape'), searchableStrings: {'Grape'}),
    LayrzSelectItem(value: 'honeydew', child: Text('Honeydew'), searchableStrings: {'Honeydew'}),
    LayrzSelectItem(value: 'kiwi', child: Text('Kiwi'), searchableStrings: {'Kiwi'}),
    LayrzSelectItem(value: 'lemon', child: Text('Lemon'), searchableStrings: {'Lemon'}),
  ];

  /// The values currently selected by the [LayrzMultiSelectInput] demo.
  List<String> _selectedFruits = const ['apple', 'cherry'];

  /// The emoji character currently selected by the [LayrzEmojiInput] demo.
  String? _emoji;

  /// A sample image URL seeding the [LayrzImageInput] demo, so its preview
  /// (and broken-image fallback, if the URL fails to load) is visible without
  /// any user action.
  String? _image = 'https://cdn.layrz.com/resources/com.layrz.ui/logo.png?3';

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Pickers',
      description:
          'The four adaptive picker inputs -- color, multi-select, emoji, and image -- each '
          'wired to local state so their current value is visible below the field.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Color', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'Try pasting a hex value, dragging the wheel, or tapping a palette swatch, then Save.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzColorInput(
            labelText: 'Accent color',
            value: _color,
            palette: _palette,
            onChanged: (color) => setState(() => _color = color),
          ),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'Selected: ${_color.toHex()}',
            style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('Multi-select', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'Toggling rows only stages the draft -- Save commits the whole list at once.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzMultiSelectInput<String>(
            labelText: 'Favorite fruits',
            items: _fruitItems,
            value: _selectedFruits,
            itemExtent: 48,
            onChanged: (values) => setState(() => _selectedFruits = values),
          ),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'Selected: ${_selectedFruits.isEmpty ? '(none)' : _selectedFruits.join(', ')}',
            style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('Emoji', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'Search or browse by group -- picking an emoji commits and closes immediately.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzEmojiInput(
            labelText: 'Reaction',
            value: _emoji,
            onChanged: (char) => setState(() => _emoji = char),
          ),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            _emoji == null ? 'Selected: (none)' : 'Selected: $_emoji',
            style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('Image', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
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
    );
  }
}
