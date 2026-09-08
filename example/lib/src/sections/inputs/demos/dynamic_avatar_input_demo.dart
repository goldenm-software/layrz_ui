import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Demonstrates [LayrzDynamicAvatarInput], the flexible avatar picker input.
///
/// Combines URL, base64 image upload, icon, and emoji sources into a single
/// avatar value. Wires the widget to local state via `setState` so the
/// currently selected avatar source is echoed back below the field.
class DynamicAvatarInputDemo extends StatefulWidget {
  /// Creates a new [DynamicAvatarInputDemo].
  const DynamicAvatarInputDemo({super.key});

  @override
  State<DynamicAvatarInputDemo> createState() => _DynamicAvatarInputDemoState();
}

class _DynamicAvatarInputDemoState extends State<DynamicAvatarInputDemo> {
  /// The avatar source currently selected by the demo.
  LayrzAvatarSource? _avatar;

  /// Describes [_avatar] as a short human-readable string for the echo-back
  /// text below the field, exhaustively switching over the sealed
  /// [LayrzAvatarSource] hierarchy.
  String _describe(LayrzAvatarSource? source) {
    return switch (source) {
      null => 'No avatar selected',
      LayrzAvatarUrl(:final url) => 'URL: $url',
      LayrzAvatarBase64(:final base64) => 'Base64 image (${base64.length} chars)',
      LayrzAvatarIcon(:final icon) => 'Icon: ${icon.name}',
      LayrzAvatarEmoji(:final emoji) => 'Emoji: $emoji',
    };
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      child: Padding(
        padding: tokens.spacing.pd2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dynamic Avatar Input', style: tokens.typography.title),
            Text(
              'Combines URL, image upload, icon, and emoji into a single avatar value -- '
              'switch between tabs in the dialog to pick a source.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDynamicAvatarInput(
              labelText: 'Avatar',
              value: _avatar,
              onChanged: (source) => setState(() => _avatar = source),
            ),
            SizedBox(height: tokens.spacing.sp2),
            Text(
              _describe(_avatar),
              style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
            ),
          ],
        ),
      ),
    );
  }
}
