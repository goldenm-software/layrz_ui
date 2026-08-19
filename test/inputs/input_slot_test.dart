import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/input_slot.dart';

void main() {
  group('LayrzInputPrefixSlot', () {
    test('creates with icon only', () {
      final slot = LayrzInputPrefixSlot(icon: const IconData(0xe900, fontFamily: 'test'));
      expect(slot.icon, isNotNull);
      expect(slot.widget, isNull);
      expect(slot.text, isNull);
      expect(slot.hasContent, true);
    });

    test('creates with widget only', () {
      const widget = Text('test');
      final slot = LayrzInputPrefixSlot(widget: widget);
      expect(slot.icon, isNull);
      expect(slot.widget, widget);
      expect(slot.text, isNull);
      expect(slot.hasContent, true);
    });

    test('creates with text only', () {
      final slot = LayrzInputPrefixSlot(text: 'test');
      expect(slot.icon, isNull);
      expect(slot.widget, isNull);
      expect(slot.text, 'test');
      expect(slot.hasContent, true);
    });

    test('creates with no content', () {
      final slot = LayrzInputPrefixSlot();
      expect(slot.hasContent, false);
    });

    test('asserts when icon and widget both provided', () {
      expect(
        () => LayrzInputPrefixSlot(
          icon: const IconData(0xe900, fontFamily: 'test'),
          widget: const Text('test'),
        ),
        throwsAssertionError,
      );
    });

    test('asserts when widget and text both provided', () {
      expect(
        () => LayrzInputPrefixSlot(
          widget: const Text('test'),
          text: 'test',
        ),
        throwsAssertionError,
      );
    });

    test('asserts when icon and text both provided', () {
      expect(
        () => LayrzInputPrefixSlot(
          icon: const IconData(0xe900, fontFamily: 'test'),
          text: 'test',
        ),
        throwsAssertionError,
      );
    });
  });

  group('LayrzInputSuffixSlot', () {
    test('creates with icon only', () {
      final slot = LayrzInputSuffixSlot(icon: const IconData(0xe900, fontFamily: 'test'));
      expect(slot.icon, isNotNull);
      expect(slot.widget, isNull);
      expect(slot.text, isNull);
      expect(slot.hasContent, true);
    });

    test('creates with widget only', () {
      const widget = Text('test');
      final slot = LayrzInputSuffixSlot(widget: widget);
      expect(slot.icon, isNull);
      expect(slot.widget, widget);
      expect(slot.text, isNull);
      expect(slot.hasContent, true);
    });

    test('creates with text only', () {
      final slot = LayrzInputSuffixSlot(text: 'test');
      expect(slot.icon, isNull);
      expect(slot.widget, isNull);
      expect(slot.text, 'test');
      expect(slot.hasContent, true);
    });

    test('creates with no content', () {
      final slot = LayrzInputSuffixSlot();
      expect(slot.hasContent, false);
    });

    test('asserts when icon and widget both provided', () {
      expect(
        () => LayrzInputSuffixSlot(
          icon: const IconData(0xe900, fontFamily: 'test'),
          widget: const Text('test'),
        ),
        throwsAssertionError,
      );
    });
  });

  group('resolvePrefixSlot', () {
    test('asserts at most one prefix type', () {
      expect(
        () => resolvePrefixSlot(
          prefixIcon: const IconData(0xe900, fontFamily: 'test'),
          prefix: const Text('test'),
        ),
        throwsAssertionError,
      );
    });
  });

  group('resolveSuffixSlot', () {
    test('asserts at most one suffix type', () {
      expect(
        () => resolveSuffixSlot(
          suffixIcon: const IconData(0xe900, fontFamily: 'test'),
          suffixText: 'test',
        ),
        throwsAssertionError,
      );
    });
  });
}
