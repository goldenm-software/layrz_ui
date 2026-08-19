import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/preview/preview.dart';

/// Preview of [LayrzCard] with all elevation levels.
@Preview(name: 'Elevations', theme: LayrzPreviewTheme.light)
Widget previewLayrzCardElevations() {
  return _PreviewElevations();
}

/// Helper widget displaying [LayrzCard] with all elevation levels.
class _PreviewElevations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          for (int i = 1; i <= 5; i++)
            LayrzCard(
              elevation: i,
              child: Text(
                'Elevation $i',
                style: const TextStyle(fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}

/// Preview of an interactive [LayrzCard].
@Preview(name: 'Interactive', theme: LayrzPreviewTheme.light)
Widget previewLayrzCardInteractive() {
  return _PreviewInteractive();
}

/// Helper widget displaying an interactive [LayrzCard].
class _PreviewInteractive extends StatefulWidget {
  @override
  State<_PreviewInteractive> createState() => _PreviewInteractiveState();
}

class _PreviewInteractiveState extends State<_PreviewInteractive> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return LayrzCard(
      elevation: 2,
      onTap: () {
        setState(() {
          _isPressed = !_isPressed;
        });
      },
      child: Text(
        'Tap me! ${_isPressed ? '(pressed)' : ''}',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

/// Preview of [LayrzCard] with custom background color.
@Preview(name: 'Custom Background', theme: LayrzPreviewTheme.light)
Widget previewLayrzCardCustomBackground() {
  return _PreviewCustomBackground();
}

/// Helper widget displaying [LayrzCard] with a custom background.
class _PreviewCustomBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayrzCard(
      elevation: 3,
      backgroundColor: const Color(0xFFE3F2FD),
      child: const Text(
        'Custom blue background',
        style: TextStyle(fontSize: 14),
      ),
    );
  }
}
