import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/input_error_block.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzInputErrorBlock', () {
    testWidgets('renders error messages when provided', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputErrorBlock(
          errors: ['Error 1', 'Error 2'],
          hideDetails: false,
        ),
      );

      expect(find.text('Error 1, Error 2'), findsOneWidget);
    });

    testWidgets('renders nothing when hideDetails is true', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputErrorBlock(
          errors: ['Error 1'],
          hideDetails: true,
        ),
      );

      expect(find.text('Error 1'), findsNothing);
    });

    testWidgets('renders nothing when errors list is empty', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputErrorBlock(
          errors: [],
          hideDetails: false,
        ),
      );

      expect(find.byType(LayrzInputErrorBlock), findsOneWidget);
    });

    testWidgets('renders multiple errors joined with comma separator', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputErrorBlock(
          errors: ['First', 'Second', 'Third'],
          hideDetails: false,
        ),
      );

      expect(find.text('First, Second, Third'), findsOneWidget);
    });
  });
}
