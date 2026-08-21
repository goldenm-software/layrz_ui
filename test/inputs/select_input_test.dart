import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzSelectInput', () {
    final items = <LayrzSelectItem<String>>[
      const LayrzSelectItem(labelText: 'Option A', value: 'a'),
      const LayrzSelectItem(labelText: 'Option B', value: 'b'),
      const LayrzSelectItem(labelText: 'Option C', value: 'c'),
    ];

    testWidgets('renders as read-only text input', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzSelectInput<String>(items: items, labelText: 'Choose'));

      final textInput = tester.widget<LayrzTextInput>(find.byType(LayrzTextInput));
      expect(textInput.readOnly, true);
    });

    testWidgets('escape dismisses without change', (tester) async {
      LayrzSelectItem<String>? selected;
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
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

    testWidgets('disabled prevents interaction', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(items: items, labelText: 'Choose', disabled: true),
      );

      final textInput = tester.widget<LayrzTextInput>(find.byType(LayrzTextInput));
      expect(textInput.disabled, true);
    });
  });
}
