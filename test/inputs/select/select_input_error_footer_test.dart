import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

/// Regression coverage for the error footer being gated on [LayrzSelectInput.labelText].
///
/// **Root cause:** `_appendExtras` early-returned the anchor unwrapped
/// whenever `labelText` was null -- so [LayrzInputFooterSlot], which renders
/// [LayrzSelectInput.errors], never got a chance to render either. A field
/// with an error and no label showed NO error text at all. Identical bug to
/// the one fixed in `LayrzComboBoxInput` (see
/// combobox_input_error_footer_test.dart), copied verbatim into this file
/// when it was written.
void main() {
  group('LayrzSelectInput error footer renders regardless of labelText', () {
    final items = <LayrzSelectItem<String>>[
      const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
      const LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
    ];

    testWidgets('errors render when labelText is null', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          errors: const ['This field is required'],
        ),
      );

      expect(
        find.textContaining('This field is required'),
        findsOneWidget,
        reason: 'the error footer must render even with no labelText',
      );
    });

    testWidgets('errors render when labelText is also present', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          errors: const ['This field is required'],
        ),
      );

      expect(find.textContaining('This field is required'), findsOneWidget);
    });

    testWidgets('no error text renders when errors is empty and labelText is null', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
        ),
      );

      expect(find.textContaining('This field is required'), findsNothing);
    });
  });
}
