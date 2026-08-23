import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_slot.dart';

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

    test('equality works correctly', () {
      const slot1 = LayrzInputPrefixSlot(text: 'test');
      const slot2 = LayrzInputPrefixSlot(text: 'test');
      const slot3 = LayrzInputPrefixSlot(text: 'other');

      expect(slot1 == slot2, true);
      expect(slot1 == slot3, false);
    });

    test('hashCode works correctly', () {
      const slot1 = LayrzInputPrefixSlot(text: 'test');
      const slot2 = LayrzInputPrefixSlot(text: 'test');

      expect(slot1.hashCode == slot2.hashCode, true);
    });

    test('onTap callback is included in equality', () {
      void callback1() {}
      void callback2() {}

      final slot1 = LayrzInputPrefixSlot(text: 'test', onTap: callback1);
      final slot2 = LayrzInputPrefixSlot(text: 'test', onTap: callback2);

      expect(slot1 == slot2, false);
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

    test('asserts when widget and text both provided', () {
      expect(
        () => LayrzInputSuffixSlot(
          widget: const Text('test'),
          text: 'test',
        ),
        throwsAssertionError,
      );
    });

    test('asserts when icon and text both provided', () {
      expect(
        () => LayrzInputSuffixSlot(
          icon: const IconData(0xe900, fontFamily: 'test'),
          text: 'test',
        ),
        throwsAssertionError,
      );
    });

    test('equality works correctly', () {
      const slot1 = LayrzInputSuffixSlot(text: 'test');
      const slot2 = LayrzInputSuffixSlot(text: 'test');
      const slot3 = LayrzInputSuffixSlot(text: 'other');

      expect(slot1 == slot2, true);
      expect(slot1 == slot3, false);
    });

    test('hashCode works correctly', () {
      const slot1 = LayrzInputSuffixSlot(text: 'test');
      const slot2 = LayrzInputSuffixSlot(text: 'test');

      expect(slot1.hashCode == slot2.hashCode, true);
    });

    test('onTap callback is included in equality', () {
      void callback1() {}
      void callback2() {}

      final slot1 = LayrzInputSuffixSlot(text: 'test', onTap: callback1);
      final slot2 = LayrzInputSuffixSlot(text: 'test', onTap: callback2);

      expect(slot1 == slot2, false);
    });
  });

  group('resolvePrefixSlot', () {
    test('returns slot with icon', () {
      final icon = const IconData(0xe900, fontFamily: 'test');
      void onTap() {}
      final slot = resolvePrefixSlot(
        prefixIcon: icon,
        onPrefixTap: onTap,
      );

      expect(slot.icon, icon);
      expect(slot.widget, isNull);
      expect(slot.text, isNull);
      expect(slot.onTap, onTap);
    });

    test('returns slot with widget', () {
      const widget = Text('test');
      void onTap() {}
      final slot = resolvePrefixSlot(
        prefix: widget,
        onPrefixTap: onTap,
      );

      expect(slot.icon, isNull);
      expect(slot.widget, widget);
      expect(slot.text, isNull);
      expect(slot.onTap, onTap);
    });

    test('returns slot with text', () {
      void onTap() {}
      final slot = resolvePrefixSlot(
        prefixText: 'test',
        onPrefixTap: onTap,
      );

      expect(slot.icon, isNull);
      expect(slot.widget, isNull);
      expect(slot.text, 'test');
      expect(slot.onTap, onTap);
    });

    test('returns empty slot', () {
      final slot = resolvePrefixSlot();

      expect(slot.icon, isNull);
      expect(slot.widget, isNull);
      expect(slot.text, isNull);
      expect(slot.onTap, isNull);
    });

    test('asserts when icon and widget both provided', () {
      expect(
        () => resolvePrefixSlot(
          prefixIcon: const IconData(0xe900, fontFamily: 'test'),
          prefix: const Text('test'),
        ),
        throwsAssertionError,
      );
    });

    test('asserts when widget and text both provided', () {
      expect(
        () => resolvePrefixSlot(
          prefix: const Text('test'),
          prefixText: 'test',
        ),
        throwsAssertionError,
      );
    });

    test('asserts when icon and text both provided', () {
      expect(
        () => resolvePrefixSlot(
          prefixIcon: const IconData(0xe900, fontFamily: 'test'),
          prefixText: 'test',
        ),
        throwsAssertionError,
      );
    });
  });

  group('resolveSuffixSlot', () {
    test('returns slot with icon', () {
      final icon = const IconData(0xe900, fontFamily: 'test');
      void onTap() {}
      final slot = resolveSuffixSlot(
        suffixIcon: icon,
        onSuffixTap: onTap,
      );

      expect(slot.icon, icon);
      expect(slot.widget, isNull);
      expect(slot.text, isNull);
      expect(slot.onTap, onTap);
    });

    test('returns slot with widget', () {
      const widget = Text('test');
      void onTap() {}
      final slot = resolveSuffixSlot(
        suffix: widget,
        onSuffixTap: onTap,
      );

      expect(slot.icon, isNull);
      expect(slot.widget, widget);
      expect(slot.text, isNull);
      expect(slot.onTap, onTap);
    });

    test('returns slot with text', () {
      void onTap() {}
      final slot = resolveSuffixSlot(
        suffixText: 'test',
        onSuffixTap: onTap,
      );

      expect(slot.icon, isNull);
      expect(slot.widget, isNull);
      expect(slot.text, 'test');
      expect(slot.onTap, onTap);
    });

    test('returns empty slot', () {
      final slot = resolveSuffixSlot();

      expect(slot.icon, isNull);
      expect(slot.widget, isNull);
      expect(slot.text, isNull);
      expect(slot.onTap, isNull);
    });

    test('asserts when icon and widget both provided', () {
      expect(
        () => resolveSuffixSlot(
          suffixIcon: const IconData(0xe900, fontFamily: 'test'),
          suffix: const Text('test'),
        ),
        throwsAssertionError,
      );
    });

    test('asserts when widget and text both provided', () {
      expect(
        () => resolveSuffixSlot(
          suffix: const Text('test'),
          suffixText: 'test',
        ),
        throwsAssertionError,
      );
    });

    test('asserts when icon and text both provided', () {
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
