import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Demonstrates [LayrzColorInput], the adaptive color picker input.
///
/// Wires the widget to local state via `setState` so the currently selected
/// color is both visibly interactive and echoed back below the field as a
/// hex string. A sample 8-swatch palette feeds the picker's Palette tab.
class ColorInputDemo extends StatefulWidget {
  /// Creates a new [ColorInputDemo].
  const ColorInputDemo({super.key});

  @override
  State<ColorInputDemo> createState() => _ColorInputDemoState();
}

class _ColorInputDemoState extends State<ColorInputDemo> {
  /// The color currently selected by the demo.
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

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      child: Padding(
        padding: tokens.spacing.pd2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Default Color Input', style: tokens.typography.title),
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
          ],
        ),
      ),
    );
  }
}
