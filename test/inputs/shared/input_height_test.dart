import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_slot.dart';

import '../../helpers/pump_themed.dart';

/// Viewport sizes paired with the painted input height they must resolve to.
const _wide = Size(1600, 1200);
const _compact = Size(400, 800);

Future<void> _pump(WidgetTester tester, Size viewport, Widget child) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await pumpThemed(tester, SizedBox(width: viewport.width - 40, child: child));
}

LayrzInputChrome _chrome({bool dense = false}) => LayrzInputChrome(
  labelText: null,
  isRequired: false,
  prefixSlot: const LayrzInputPrefixSlot(),
  suffixSlot: const LayrzInputSuffixSlot(),
  disabled: false,
  readOnly: false,
  errors: const [],
  hideDetails: true,
  states: const {},
  dense: dense,
  child: const SizedBox(),
);

/// Height of the first (outermost) decorated box inside the chrome, i.e. the field box without label/footer.
double _fieldBoxHeight(WidgetTester tester) {
  final box = find.descendant(of: find.byType(LayrzInputChrome), matching: find.byType(Container)).first;
  return tester.getSize(box).height;
}

void main() {
  group('input heights match buttons', () {
    testWidgets('exposes the button heights through constants and context', (tester) async {
      expect(kLayrzInputHeight, kLayrzButtonHeight);
      expect(kLayrzInputCompactHeight, kLayrzButtonCompactHeight);
      expect(kLayrzInputHeight, 45.0);
      expect(kLayrzInputCompactHeight, 50.0);
    });

    testWidgets('chrome is 45 on wide viewports and 50 on compact ones', (tester) async {
      await _pump(tester, _wide, _chrome());
      expect(tester.getSize(find.byType(LayrzInputChrome)).height, 45.0);

      await _pump(tester, _compact, _chrome());
      expect(tester.getSize(find.byType(LayrzInputChrome)).height, 50.0);
    });

    testWidgets('dense chrome keeps its natural 35 on both viewports', (tester) async {
      await _pump(tester, _wide, _chrome(dense: true));
      expect(tester.getSize(find.byType(LayrzInputChrome)).height, 35.0);

      await _pump(tester, _compact, _chrome(dense: true));
      expect(tester.getSize(find.byType(LayrzInputChrome)).height, 35.0);
    });

    testWidgets('text input and password input are 45 wide / 50 compact', (tester) async {
      for (final entry in {_wide: 45.0, _compact: 50.0}.entries) {
        await _pump(tester, entry.key, const LayrzTextInput());
        expect(_fieldBoxHeight(tester), entry.value);

        await _pump(tester, entry.key, const LayrzPasswordInput());
        expect(_fieldBoxHeight(tester), entry.value);
      }
    });

    testWidgets('textarea never drops below the input height and still grows', (tester) async {
      await _pump(tester, _wide, const LayrzTextAreaInput(minLines: 1, maxLines: 6));
      expect(tester.getSize(find.byType(LayrzTextAreaInput)).height, greaterThanOrEqualTo(45.0));

      await _pump(tester, _compact, const LayrzTextAreaInput(minLines: 1, maxLines: 6));
      expect(tester.getSize(find.byType(LayrzTextAreaInput)).height, greaterThanOrEqualTo(50.0));

      await _pump(tester, _wide, const LayrzTextAreaInput(minLines: 5, maxLines: 6));
      expect(tester.getSize(find.byType(LayrzTextAreaInput)).height, greaterThan(45.0 + 40));
    });

    testWidgets('combobox is 45 wide / 50 compact', (tester) async {
      await _pump(tester, _wide, const LayrzComboBoxInput(options: ['a']));
      expect(tester.getSize(find.byType(LayrzComboBoxInput)).height, 45.0);

      await _pump(tester, _compact, const LayrzComboBoxInput(options: ['a']));
      expect(tester.getSize(find.byType(LayrzComboBoxInput)).height, 50.0);
    });

    testWidgets('number input with step caps is 45 wide / 50 compact', (tester) async {
      await _pump(tester, _wide, const LayrzNumberInput());
      expect(tester.getSize(find.byType(LayrzNumberInput)).height, 45.0);

      await _pump(tester, _compact, const LayrzNumberInput());
      expect(tester.getSize(find.byType(LayrzNumberInput)).height, 50.0);
    });

    testWidgets('duration input is 45 wide / 50 compact', (tester) async {
      await _pump(tester, _wide, LayrzDurationInput(hintText: 'd'));
      expect(tester.getSize(find.byType(LayrzDurationInput)).height, 45.0);

      await _pump(tester, _compact, LayrzDurationInput(hintText: 'd'));
      expect(tester.getSize(find.byType(LayrzDurationInput)).height, 50.0);
    });

    testWidgets('date picker anchor is 45 wide / 50 compact', (tester) async {
      await _pump(tester, _wide, const LayrzDateInput(hintText: 'd'));
      expect(tester.getSize(find.byType(LayrzDateInput)).height, 45.0);

      await _pump(tester, _compact, const LayrzDateInput(hintText: 'd'));
      expect(tester.getSize(find.byType(LayrzDateInput)).height, 50.0);
    });

    testWidgets('select paints 45 wide / 50 compact (its outside stroke adds 3 to the 42 / 47 layout box)', (
      tester,
    ) async {
      const items = [
        LayrzSelectItem(value: 'a', child: Text('A'), searchableStrings: {'A'}),
      ];
      for (final entry in {_wide: 45.0, _compact: 50.0}.entries) {
        await _pump(tester, entry.key, const LayrzSelectInput<String>(items: items, itemExtent: 40));
        final layout = tester.getSize(find.byType(LayrzSelectInput<String>)).height;
        expect(layout + 2 * 1.5, entry.value);
      }
    });
  });
}
