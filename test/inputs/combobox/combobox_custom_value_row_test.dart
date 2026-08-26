import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/combobox/combobox_custom_value_row.dart';

import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzComboBoxCustomValueRow', () {
    testWidgets('renders the typed text inside the label', (tester) async {
      await pumpThemed(
        tester,
        LayrzComboBoxCustomValueRow(
          typedText: 'Something new',
          onCommit: (_) {},
        ),
      );

      expect(find.textContaining('Something new'), findsOneWidget);
    });

    testWidgets('tapping the row commits the typed text exactly once', (tester) async {
      var commitCount = 0;
      String? committed;

      await pumpThemed(
        tester,
        LayrzComboBoxCustomValueRow(
          typedText: 'Custom',
          onCommit: (value) {
            commitCount++;
            committed = value;
          },
        ),
      );

      await tester.tap(find.byType(LayrzComboBoxCustomValueRow));
      await tester.pump();

      expect(commitCount, 1);
      expect(committed, 'Custom');
    });

    testWidgets('never commits on its own without a tap', (tester) async {
      var commitCount = 0;

      await pumpThemed(
        tester,
        LayrzComboBoxCustomValueRow(
          typedText: 'Custom',
          onCommit: (_) => commitCount++,
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      expect(commitCount, 0, reason: 'a custom value must never commit implicitly');
    });

    testWidgets('is exposed to screen readers with a label mentioning the typed text', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        LayrzComboBoxCustomValueRow(
          typedText: 'Accessible value',
          onCommit: (_) {},
        ),
      );

      expect(
        tester.getSemantics(find.byType(LayrzComboBoxCustomValueRow)),
        matchesSemantics(
          label: 'Use "Accessible value"',
          isButton: true,
          hasTapAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('renders with a different background when highlighted', (tester) async {
      await pumpThemed(
        tester,
        Column(
          children: [
            LayrzComboBoxCustomValueRow(
              key: const ValueKey('not-highlighted'),
              typedText: 'A',
              isHighlighted: false,
              onCommit: (_) {},
            ),
            LayrzComboBoxCustomValueRow(
              key: const ValueKey('highlighted'),
              typedText: 'B',
              isHighlighted: true,
              onCommit: (_) {},
            ),
          ],
        ),
      );

      expect(find.byKey(const ValueKey('not-highlighted')), findsOneWidget);
      expect(find.byKey(const ValueKey('highlighted')), findsOneWidget);
    });

    testWidgets('truncates a very long typed value instead of overflowing', (tester) async {
      final longText = 'x' * 500;

      await pumpThemed(
        tester,
        SizedBox(
          width: 200,
          child: LayrzComboBoxCustomValueRow(
            typedText: longText,
            onCommit: (_) {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
