import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzScaffoldItem', () {
    test('creates with required fields', () {
      final item = LayrzScaffoldItem(
        id: 'item-1',
        title: 'Item Title',
      );

      expect(item.id, 'item-1');
      expect(item.title, 'Item Title');
      expect(item.subtitle, null);
      expect(item.icon, null);
      expect(item.tint, null);
      expect(item.group, null);
    });

    test('creates with all fields', () {
      final color = const Color(0xFF0066FF);
      final icon = IconData(0xE000, fontFamily: 'Material Icons');

      final item = LayrzScaffoldItem(
        id: 'item-1',
        title: 'Item Title',
        subtitle: 'Item Subtitle',
        icon: icon,
        tint: color,
        group: 'Group 1',
      );

      expect(item.id, 'item-1');
      expect(item.title, 'Item Title');
      expect(item.subtitle, 'Item Subtitle');
      expect(item.icon, icon);
      expect(item.tint, color);
      expect(item.group, 'Group 1');
    });

    test('copyWith replaces specified fields', () {
      final item = LayrzScaffoldItem(
        id: 'item-1',
        title: 'Original Title',
        subtitle: 'Original Subtitle',
      );

      final updated = item.copyWith(
        title: 'Updated Title',
      );

      expect(updated.id, 'item-1');
      expect(updated.title, 'Updated Title');
      expect(updated.subtitle, 'Original Subtitle');
    });

    test('copyWith copies all fields when called with all parameters', () {
      final item = LayrzScaffoldItem(
        id: 'item-1',
        title: 'Title',
      );

      final color = const Color(0xFF00FF00);
      final icon = IconData(0xE001, fontFamily: 'Material Icons');

      final updated = item.copyWith(
        id: 'item-2',
        title: 'New Title',
        subtitle: 'New Subtitle',
        icon: icon,
        tint: color,
        group: 'Group A',
      );

      expect(updated.id, 'item-2');
      expect(updated.title, 'New Title');
      expect(updated.subtitle, 'New Subtitle');
      expect(updated.icon, icon);
      expect(updated.tint, color);
      expect(updated.group, 'Group A');
    });

    test('equality compares all fields', () {
      final item1 = LayrzScaffoldItem(
        id: 'item-1',
        title: 'Title',
      );

      final item2 = LayrzScaffoldItem(
        id: 'item-1',
        title: 'Title',
      );

      expect(item1, item2);
    });

    test('equality returns false when any field differs', () {
      final item1 = LayrzScaffoldItem(
        id: 'item-1',
        title: 'Title',
      );

      final item2 = LayrzScaffoldItem(
        id: 'item-1',
        title: 'Different Title',
      );

      expect(item1, isNot(item2));
    });

    test('identical items return true for equality', () {
      final item = LayrzScaffoldItem(
        id: 'item-1',
        title: 'Title',
      );

      expect(item, item);
    });

    test('hashCode is consistent with equality', () {
      final item1 = LayrzScaffoldItem(
        id: 'item-1',
        title: 'Title',
      );

      final item2 = LayrzScaffoldItem(
        id: 'item-1',
        title: 'Title',
      );

      expect(item1.hashCode, item2.hashCode);
    });

    test('hashCode differs when any field differs', () {
      final item1 = LayrzScaffoldItem(
        id: 'item-1',
        title: 'Title',
      );

      final item2 = LayrzScaffoldItem(
        id: 'item-1',
        title: 'Different Title',
      );

      expect(item1.hashCode, isNot(item2.hashCode));
    });

    test('toString includes all fields', () {
      final item = LayrzScaffoldItem(
        id: 'item-1',
        title: 'Title',
        subtitle: 'Subtitle',
      );

      final str = item.toString();

      expect(str, contains('item-1'));
      expect(str, contains('Title'));
      expect(str, contains('Subtitle'));
    });
  });
}
