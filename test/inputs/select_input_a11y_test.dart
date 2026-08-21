import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzSelectInput Accessibility', () {
    final items = <LayrzSelectItem<String>>[
      const LayrzSelectItem(labelText: 'Option A', value: 'a'),
      const LayrzSelectItem(labelText: 'Option B', value: 'b'),
      const LayrzSelectItem(labelText: 'Option C', value: 'c'),
    ];

    testWidgets('disabled state communicated', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(items: items, labelText: 'Choose', disabled: true),
      );
      final widget = tester.widget<LayrzTextInput>(find.byType(LayrzTextInput));
      expect(widget.disabled, true);
    });

    testWidgets('error messages accessible', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose',
          errors: const ['Error'],
        ),
      );
      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('keyboard escape closes', (tester) async {
      LayrzSelectItem<String>? selected;
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          value: 'a',
          labelText: 'Choose',
          onChanged: (item) {
            selected = item;
          },
        ),
      );
      await tester.tap(find.byType(LayrzTextInput));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(selected, isNull);
    });
  });
}
