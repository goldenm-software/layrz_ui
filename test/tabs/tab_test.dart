import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzTab — construction', () {
    test('accepts labelText alone', () {
      final tab = LayrzTab(labelText: 'One', child: const SizedBox());
      expect(tab.labelText, 'One');
      expect(tab.label, isNull);
    });

    test('accepts label widget alone', () {
      const labelWidget = Text('Custom');
      final tab = LayrzTab(label: labelWidget, child: const SizedBox());
      expect(tab.label, labelWidget);
      expect(tab.labelText, isNull);
    });

    test('throws when neither labelText nor label is provided', () {
      expect(
        () => LayrzTab(child: const SizedBox()),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws when both labelText and label are provided', () {
      expect(
        () => LayrzTab(labelText: 'One', label: const Text('Two'), child: const SizedBox()),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws when both leading and leadingIcon are provided', () {
      expect(
        () => LayrzTab(
          labelText: 'One',
          leading: const SizedBox(),
          leadingIcon: IconData(0xe000),
          child: const SizedBox(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws when both trailing and trailingIcon are provided', () {
      expect(
        () => LayrzTab(
          labelText: 'One',
          trailing: const SizedBox(),
          trailingIcon: IconData(0xe000),
          child: const SizedBox(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepts leading and trailing slots independently', () {
      final tab = LayrzTab(
        labelText: 'One',
        leading: const SizedBox(key: Key('leading')),
        trailing: const SizedBox(key: Key('trailing')),
        child: const SizedBox(),
      );
      expect(tab.leading, isNotNull);
      expect(tab.trailing, isNotNull);
      expect(tab.leadingIcon, isNull);
      expect(tab.trailingIcon, isNull);
    });

    test('accepts leadingIcon and trailingIcon independently', () {
      final icon = IconData(0xe001);
      final tab = LayrzTab(
        labelText: 'One',
        leadingIcon: icon,
        trailingIcon: icon,
        child: const SizedBox(),
      );
      expect(tab.leadingIcon, icon);
      expect(tab.trailingIcon, icon);
      expect(tab.leading, isNull);
      expect(tab.trailing, isNull);
    });

    test('stores the required child widget', () {
      const child = Text('Content');
      final tab = LayrzTab(labelText: 'One', child: child);
      expect(tab.child, child);
    });
  });
}
