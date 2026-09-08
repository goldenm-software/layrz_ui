import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Demonstrates [LayrzIconInput], the MDI icon picker input.
///
/// Wires the widget to local state via `setState` so the currently selected
/// icon is both visibly interactive and echoed back below the field as its
/// stable `'mdi-...'` name. Searching or browsing the icon grid and picking
/// an icon commits and closes immediately.
class IconInputDemo extends StatefulWidget {
  /// Creates a new [IconInputDemo].
  const IconInputDemo({super.key});

  @override
  State<IconInputDemo> createState() => _IconInputDemoState();
}

class _IconInputDemoState extends State<IconInputDemo> {
  /// The icon's stable `'mdi-...'` name currently selected by the demo.
  String? _icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      child: Padding(
        padding: tokens.spacing.pd2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Default Icon Input', style: tokens.typography.title),
            Text(
              'Search or browse the MDI icon grid -- picking an icon commits and closes immediately.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzIconInput(
              labelText: 'Icon',
              value: _icon,
              onChanged: (name) => setState(() => _icon = name),
            ),
            SizedBox(height: tokens.spacing.sp2),
            Text(
              _icon == null ? 'Selected: (none)' : 'Selected: $_icon',
              style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
            ),
          ],
        ),
      ),
    );
  }
}
