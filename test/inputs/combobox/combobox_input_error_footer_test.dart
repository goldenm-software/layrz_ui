import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

/// Regression coverage for the error footer being gated on [LayrzComboBoxInput.labelText].
///
/// **Root cause:** `_appendExtras` (copied from `LayrzSelectInput`, which
/// carries the identical bug) early-returned the anchor unwrapped whenever
/// `labelText` was null -- so [LayrzInputFooterSlot], which renders
/// `LayrzComboBoxInput.errors`, never got a chance to render either. A field
/// with an error and no label showed NO error text at all.
void main() {
  group('LayrzComboBoxInput error footer renders regardless of labelText', () {
    testWidgets('errors render when labelText is null', (tester) async {
      await pumpThemedApp(
        tester,
        const LayrzComboBoxInput(
          options: ['Option A', 'Option B'],
          errors: ['This field is required'],
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
        const LayrzComboBoxInput(
          options: ['Option A', 'Option B'],
          labelText: 'Choose one',
          errors: ['This field is required'],
        ),
      );

      expect(find.textContaining('This field is required'), findsOneWidget);
    });

    testWidgets('no error text renders when errors is empty and labelText is null', (tester) async {
      await pumpThemedApp(
        tester,
        const LayrzComboBoxInput(
          options: ['Option A', 'Option B'],
        ),
      );

      expect(find.textContaining('This field is required'), findsNothing);
    });
  });
}
