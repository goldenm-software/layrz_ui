import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  const testIcon = IconData(0xe88a, fontFamily: 'MaterialIcons');

  group('LayrzNotificationItem', () {
    test('creates with all parameters', () {
      void callback() {}
      final item = LayrzNotificationItem(
        id: 'notif1',
        title: 'New Message',
        content: 'You have a new message',
        icon: testIcon,
        onTap: callback,
      );

      expect(item.id, 'notif1');
      expect(item.title, 'New Message');
      expect(item.content, 'You have a new message');
      expect(item.icon, testIcon);
      expect(item.onTap, callback);
    });

    test('creates with minimal parameters', () {
      final item = LayrzNotificationItem(
        id: 'notif1',
        title: 'New Message',
        content: 'You have a new message',
      );

      expect(item.id, 'notif1');
      expect(item.title, 'New Message');
      expect(item.content, 'You have a new message');
      expect(item.icon, isNull);
      expect(item.onTap, isNull);
    });

    test('equals two identical notifications', () {
      void callback() {}
      final item1 = LayrzNotificationItem(
        id: 'notif1',
        title: 'New Message',
        content: 'You have a new message',
        icon: testIcon,
        onTap: callback,
      );
      final item2 = LayrzNotificationItem(
        id: 'notif1',
        title: 'New Message',
        content: 'You have a new message',
        icon: testIcon,
        onTap: callback,
      );

      expect(item1, equals(item2));
    });

    test('not equals notifications with different id', () {
      final item1 = LayrzNotificationItem(
        id: 'notif1',
        title: 'Message 1',
        content: 'Content 1',
      );
      final item2 = LayrzNotificationItem(
        id: 'notif2',
        title: 'Message 2',
        content: 'Content 2',
      );

      expect(item1, isNot(equals(item2)));
    });

    test('copyWith replaces fields', () {
      final item1 = LayrzNotificationItem(
        id: 'notif1',
        title: 'New Message',
        content: 'Content',
      );

      final item2 = item1.copyWith(
        title: 'Updated',
        content: 'New content',
      );

      expect(item2.id, 'notif1');
      expect(item2.title, 'Updated');
      expect(item2.content, 'New content');
    });
  });
}
