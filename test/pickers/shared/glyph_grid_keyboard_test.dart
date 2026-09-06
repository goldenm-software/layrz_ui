import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/shared/glyph_grid_keyboard.dart';

/// Builds a bare [KeyDownEvent] for [key] — [buildGlyphGridKeyboardHandler]
/// is a pure function taking [KeyEvent]s directly, so its tests never need
/// a pumped widget tree or [WidgetTester.sendKeyEvent]; constructing the
/// event value directly is both simpler and faster.
KeyDownEvent _keyDown(LogicalKeyboardKey key) {
  return KeyDownEvent(physicalKey: PhysicalKeyboardKey.keyA, logicalKey: key, timeStamp: Duration.zero);
}

void main() {
  group('buildGlyphGridKeyboardHandler — arrow movement', () {
    test('ArrowRight moves focus one item forward', () {
      int? focused;
      final handler = buildGlyphGridKeyboardHandler(
        columns: 5,
        itemCount: 20,
        isDisabled: (_) => false,
        onSelect: (_) {},
      );

      final result = handler(_keyDown(LogicalKeyboardKey.arrowRight), 6, (i) => focused = i);

      expect(result, KeyEventResult.handled);
      expect(focused, 7);
    });

    test('ArrowLeft moves focus one item back', () {
      int? focused;
      final handler = buildGlyphGridKeyboardHandler(
        columns: 5,
        itemCount: 20,
        isDisabled: (_) => false,
        onSelect: (_) {},
      );

      handler(_keyDown(LogicalKeyboardKey.arrowLeft), 6, (i) => focused = i);

      expect(focused, 5);
    });

    test('ArrowDown moves focus one full row forward', () {
      int? focused;
      final handler = buildGlyphGridKeyboardHandler(
        columns: 5,
        itemCount: 20,
        isDisabled: (_) => false,
        onSelect: (_) {},
      );

      handler(_keyDown(LogicalKeyboardKey.arrowDown), 3, (i) => focused = i);

      expect(focused, 8);
    });

    test('ArrowUp moves focus one full row back', () {
      int? focused;
      final handler = buildGlyphGridKeyboardHandler(
        columns: 5,
        itemCount: 20,
        isDisabled: (_) => false,
        onSelect: (_) {},
      );

      handler(_keyDown(LogicalKeyboardKey.arrowUp), 8, (i) => focused = i);

      expect(focused, 3);
    });

    test('ArrowLeft at index 0 clamps to index 0 (no negative index)', () {
      int? focused;
      final handler = buildGlyphGridKeyboardHandler(
        columns: 5,
        itemCount: 20,
        isDisabled: (_) => false,
        onSelect: (_) {},
      );

      handler(_keyDown(LogicalKeyboardKey.arrowLeft), 0, (i) => focused = i);

      expect(focused, 0);
    });

    test('ArrowRight at the last index clamps to the last index', () {
      int? focused;
      final handler = buildGlyphGridKeyboardHandler(
        columns: 5,
        itemCount: 20,
        isDisabled: (_) => false,
        onSelect: (_) {},
      );

      handler(_keyDown(LogicalKeyboardKey.arrowRight), 19, (i) => focused = i);

      expect(focused, 19);
    });

    test('ArrowDown on a ragged last row clamps to the final item', () {
      // 22 items, 5 columns -> last row has only 2 items (indices 20, 21).
      int? focused;
      final handler = buildGlyphGridKeyboardHandler(
        columns: 5,
        itemCount: 22,
        isDisabled: (_) => false,
        onSelect: (_) {},
      );

      // Index 17 (row 3, col 2) + 5 = 22, out of range -> clamps to 21.
      handler(_keyDown(LogicalKeyboardKey.arrowDown), 17, (i) => focused = i);

      expect(focused, 21);
    });
  });

  group('buildGlyphGridKeyboardHandler — Home/End row-local movement', () {
    test('Home moves to the first item of the focused item\'s own row', () {
      int? focused;
      final handler = buildGlyphGridKeyboardHandler(
        columns: 5,
        itemCount: 20,
        isDisabled: (_) => false,
        onSelect: (_) {},
      );

      handler(_keyDown(LogicalKeyboardKey.home), 8, (i) => focused = i);

      expect(focused, 5);
    });

    test('End moves to the last item of the focused item\'s own row', () {
      int? focused;
      final handler = buildGlyphGridKeyboardHandler(
        columns: 5,
        itemCount: 20,
        isDisabled: (_) => false,
        onSelect: (_) {},
      );

      handler(_keyDown(LogicalKeyboardKey.end), 6, (i) => focused = i);

      expect(focused, 9);
    });

    test('End on a ragged last row lands on the final real item, not a phantom column', () {
      // 22 items, 5 columns -> last row (row 4) spans indices 20-21 only.
      int? focused;
      final handler = buildGlyphGridKeyboardHandler(
        columns: 5,
        itemCount: 22,
        isDisabled: (_) => false,
        onSelect: (_) {},
      );

      handler(_keyDown(LogicalKeyboardKey.end), 20, (i) => focused = i);

      expect(focused, 21);
    });
  });

  group('buildGlyphGridKeyboardHandler — disabled items are skipped', () {
    test('ArrowRight skips a disabled item and lands on the next enabled one', () {
      int? focused;
      final handler = buildGlyphGridKeyboardHandler(
        columns: 5,
        itemCount: 20,
        isDisabled: (i) => i == 7,
        onSelect: (_) {},
      );

      handler(_keyDown(LogicalKeyboardKey.arrowRight), 6, (i) => focused = i);

      expect(focused, 8);
    });

    test('Home skips a disabled row-start item inward to the first enabled one', () {
      int? focused;
      final handler = buildGlyphGridKeyboardHandler(
        columns: 5,
        itemCount: 20,
        isDisabled: (i) => i == 5,
        onSelect: (_) {},
      );

      handler(_keyDown(LogicalKeyboardKey.home), 8, (i) => focused = i);

      expect(focused, 6);
    });

    test('Enter never fires onSelect for a disabled item', () {
      var selectCount = 0;
      final handler = buildGlyphGridKeyboardHandler(
        columns: 5,
        itemCount: 20,
        isDisabled: (i) => i == 7,
        onSelect: (_) => selectCount++,
      );

      handler(_keyDown(LogicalKeyboardKey.enter), 7, (_) {});

      expect(selectCount, 0);
    });
  });

  group('buildGlyphGridKeyboardHandler — activation', () {
    test('Enter invokes onSelect with the focused index', () {
      int? selected;
      final handler = buildGlyphGridKeyboardHandler(
        columns: 5,
        itemCount: 20,
        isDisabled: (_) => false,
        onSelect: (i) => selected = i,
      );

      final result = handler(_keyDown(LogicalKeyboardKey.enter), 4, (_) {});

      expect(result, KeyEventResult.handled);
      expect(selected, 4);
    });

    test('Space invokes onSelect with the focused index', () {
      int? selected;
      final handler = buildGlyphGridKeyboardHandler(
        columns: 5,
        itemCount: 20,
        isDisabled: (_) => false,
        onSelect: (i) => selected = i,
      );

      handler(_keyDown(LogicalKeyboardKey.space), 4, (_) {});

      expect(selected, 4);
    });
  });

  group('buildGlyphGridKeyboardHandler — negative assertions', () {
    test('an unrelated key is ignored and never invokes requestFocus or onSelect', () {
      var requestFocusCalled = false;
      var selectCalled = false;
      final handler = buildGlyphGridKeyboardHandler(
        columns: 5,
        itemCount: 20,
        isDisabled: (_) => false,
        onSelect: (_) => selectCalled = true,
      );

      final result = handler(_keyDown(LogicalKeyboardKey.keyA), 4, (_) => requestFocusCalled = true);

      expect(result, KeyEventResult.ignored);
      expect(requestFocusCalled, isFalse);
      expect(selectCalled, isFalse);
    });

    test('a KeyUpEvent is ignored (only KeyDownEvent is handled)', () {
      final handler = buildGlyphGridKeyboardHandler(
        columns: 5,
        itemCount: 20,
        isDisabled: (_) => false,
        onSelect: (_) {},
      );

      final upEvent = KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration.zero,
      );

      final result = handler(upEvent, 4, (_) {});

      expect(result, KeyEventResult.ignored);
    });

    test('an empty item list ignores every key', () {
      final handler = buildGlyphGridKeyboardHandler(
        columns: 5,
        itemCount: 0,
        isDisabled: (_) => false,
        onSelect: (_) {},
      );

      final result = handler(_keyDown(LogicalKeyboardKey.arrowRight), 0, (_) {});

      expect(result, KeyEventResult.ignored);
    });
  });
}
