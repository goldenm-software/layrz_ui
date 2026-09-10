import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Demonstrates [LayrzDualListInput], the desktop-only two-panel transfer
/// field that delegates to [LayrzMultiSelectInput] on compact viewports.
///
/// Wires the widget to local state via `setState` so the currently selected
/// fruit list is both visibly interactive and echoed back below the field.
/// Resize the window below ~960px to see the compact `LayrzMultiSelectInput`
/// delegate (with its own "All (count)" / "Selected (count)" tabs) take
/// over from the two-panel desktop surface.
class DualListInputDemo extends StatefulWidget {
  /// Creates a new [DualListInputDemo].
  const DualListInputDemo({super.key});

  @override
  State<DualListInputDemo> createState() => _DualListInputDemoState();
}

class _DualListInputDemoState extends State<DualListInputDemo> {
  /// The fruit items offered by the demo -- shared verbatim (same values and
  /// labels) with [MultiSelectInputDemo], since both compose the same
  /// [LayrzSelectItem] type.
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

  /// The values currently selected by the demo.
  List<String> _selectedFruits = const ['apple', 'cherry'];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      child: Padding(
        padding: tokens.spacing.pd2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Default Dual-List Input', style: tokens.typography.title),
            Text(
              'Desktop-only two-panel transfer field -- delegates to LayrzMultiSelectInput '
              '(with its own All/Selected tabs) below the desktop breakpoint. Tap a row to '
              'move it across, or use the move-all buttons.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzDualListInput<String>(
              labelText: 'Favorite fruits',
              items: _fruitItems,
              value: _selectedFruits,
              itemExtent: 52,
              availableListName: 'Available',
              selectedListName: 'Selected',
              onChanged: (values) => setState(() => _selectedFruits = values),
            ),
            SizedBox(height: tokens.spacing.sp2),
            Text(
              'Selected: ${_selectedFruits.isEmpty ? '(none)' : _selectedFruits.join(', ')}',
              style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
            ),
          ],
        ),
      ),
    );
  }
}
