import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  const testIcon = IconData(0xe88a, fontFamily: 'MaterialIcons');

  group('LayrzNavigatorPage', () {
    test('creates with all parameters', () {
      void callback() {}
      final page = LayrzNavigatorPage(
        id: 'home',
        labelText: 'Home',
        icon: testIcon,
        count: 5,
        onTap: callback,
      );

      expect(page.id, 'home');
      expect(page.labelText, 'Home');
      expect(page.icon, testIcon);
      expect(page.count, 5);
      expect(page.onTap, callback);
    });

    test('creates with minimal parameters', () {
      final page = LayrzNavigatorPage(
        id: 'home',
        labelText: 'Home',
      );

      expect(page.id, 'home');
      expect(page.labelText, 'Home');
      expect(page.icon, isNull);
      expect(page.count, isNull);
      expect(page.onTap, isNull);
    });

    test('equals two identical pages', () {
      void callback() {}
      final page1 = LayrzNavigatorPage(
        id: 'home',
        labelText: 'Home',
        icon: testIcon,
        count: 5,
        onTap: callback,
      );
      final page2 = LayrzNavigatorPage(
        id: 'home',
        labelText: 'Home',
        icon: testIcon,
        count: 5,
        onTap: callback,
      );

      expect(page1, equals(page2));
    });

    test('not equals pages with different id', () {
      final page1 = LayrzNavigatorPage(id: 'home', labelText: 'Home');
      final page2 = LayrzNavigatorPage(id: 'about', labelText: 'About');

      expect(page1, isNot(equals(page2)));
    });

    test('copyWith replaces fields', () {
      final page1 = LayrzNavigatorPage(
        id: 'home',
        labelText: 'Home',
        icon: testIcon,
        count: 5,
      );

      final page2 = page1.copyWith(
        labelText: 'Home Page',
        count: 3,
      );

      expect(page2.id, 'home');
      expect(page2.labelText, 'Home Page');
      expect(page2.icon, testIcon);
      expect(page2.count, 3);
    });

    test('copyWith without count parameter keeps count', () {
      final page1 = LayrzNavigatorPage(
        id: 'home',
        labelText: 'Home',
        count: 5,
      );

      final page2 = page1.copyWith(labelText: 'Home Page');
      expect(page2.count, 5);
    });
  });
}
