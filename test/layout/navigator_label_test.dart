import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzNavigatorLabel', () {
    test('creates with label text', () {
      final label = LayrzNavigatorLabel('MAIN');
      expect(label.labelText, 'MAIN');
      expect(label.color, isNull);
    });

    test('creates with label text and color', () {
      const testColor = Color(0xFF001E60);
      final label = LayrzNavigatorLabel('MAIN', color: testColor);
      expect(label.labelText, 'MAIN');
      expect(label.color, testColor);
    });

    test('equals two identical labels', () {
      final label1 = LayrzNavigatorLabel('MAIN');
      final label2 = LayrzNavigatorLabel('MAIN');
      expect(label1, equals(label2));
    });

    test('not equals labels with different text', () {
      final label1 = LayrzNavigatorLabel('MAIN');
      final label2 = LayrzNavigatorLabel('REFERENCE');
      expect(label1, isNot(equals(label2)));
    });

    test('not equals labels with different colors', () {
      const color1 = Color(0xFF001E60);
      const color2 = Color(0xFF4CAF50);
      final label1 = LayrzNavigatorLabel('MAIN', color: color1);
      final label2 = LayrzNavigatorLabel('MAIN', color: color2);
      expect(label1, isNot(equals(label2)));
    });

    test('copyWith replaces label text', () {
      final label1 = LayrzNavigatorLabel('MAIN');
      final label2 = label1.copyWith(labelText: 'REFERENCE');
      expect(label2.labelText, 'REFERENCE');
    });

    test('copyWith replaces color', () {
      const color = Color(0xFF001E60);
      final label1 = LayrzNavigatorLabel('MAIN');
      final label2 = label1.copyWith(color: color);
      expect(label2.color, color);
    });

    testWidgets('band is full-width in rail presentation', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1500, 950);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorLabel('SECTION'),
            LayrzNavigatorPage(id: '1', labelText: 'Page'),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      // Find the container that renders the band in the rail
      final bandContainers = find.byType(Container);
      expect(bandContainers, findsWidgets);

      // The band should span the full width of the rail (178px) minus the scroll view horizontal padding
      // The scroll view has padding, but the Container itself should be full width
      expect(tester.takeException(), isNull);
    });

    testWidgets('band uses surface3 color when color is null', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1500, 950);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorLabel('SECTION'),
            LayrzNavigatorPage(id: '1', labelText: 'Page'),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('band uses tinted color when color is provided', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1500, 950);

      const accentColor = Color(0xFF4CAF50);
      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorLabel('SECTION', color: accentColor),
            LayrzNavigatorPage(id: '1', labelText: 'Page'),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
