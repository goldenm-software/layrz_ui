import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Demonstrates [LayrzMultiSelectInput], the multiple-value picker input.
///
/// Wires the widget to local state via `setState` so the currently selected
/// fruit list is both visibly interactive and echoed back below the field.
/// Toggling rows only stages the draft -- Save commits the whole list at once.
class MultiSelectInputDemo extends StatefulWidget {
  /// Creates a new [MultiSelectInputDemo].
  const MultiSelectInputDemo({super.key});

  @override
  State<MultiSelectInputDemo> createState() => _MultiSelectInputDemoState();
}

class _MultiSelectInputDemoState extends State<MultiSelectInputDemo> {
  /// The fruit items offered by the demo.
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
            Text('Default Multi-Select Input', style: tokens.typography.title),
            Text(
              'Toggling rows only stages the draft -- Save commits the whole list at once.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzMultiSelectInput<String>(
              labelText: 'Favorite fruits',
              items: _fruitItems,
              value: _selectedFruits,
              itemExtent: 52,
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
