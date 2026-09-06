import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Demonstrates [LayrzEmojiInput], the emoji picker input.
///
/// Wires the widget to local state via `setState` so the currently selected
/// emoji is both visibly interactive and echoed back below the field.
/// Searching or browsing by group and picking an emoji commits and closes
/// immediately.
class EmojiInputDemo extends StatefulWidget {
  /// Creates a new [EmojiInputDemo].
  const EmojiInputDemo({super.key});

  @override
  State<EmojiInputDemo> createState() => _EmojiInputDemoState();
}

class _EmojiInputDemoState extends State<EmojiInputDemo> {
  /// The emoji character currently selected by the demo.
  String? _emoji;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      child: Padding(
        padding: tokens.spacing.pd2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Default Emoji Input', style: tokens.typography.title),
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
          ],
        ),
      ),
    );
  }
}
