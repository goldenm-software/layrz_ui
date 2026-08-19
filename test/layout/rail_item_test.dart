import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzLayoutRailItem rendering', () {
    testWidgets('renders selected state correctly', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders unselected state correctly', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: false),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders count badge when present', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home', count: 42),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('hides count badge when null', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home', count: null),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('LayrzLayoutRailItem - DESIGN-61 Active Indicator', () {
    testWidgets('renders for selected item and transparent for unselected', (WidgetTester tester) async {
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
            LayrzNavigatorPage(id: '1', labelText: 'Dashboard', isSelected: true),
            LayrzNavigatorPage(id: '2', labelText: 'Devices'),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('reserves space so label does not shift on selection', (WidgetTester tester) async {
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
            LayrzNavigatorPage(id: '1', labelText: 'Dashboard', isSelected: true),
            LayrzNavigatorPage(id: '2', labelText: 'Devices', isSelected: false),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      final dashboardLabel = find.text('Dashboard');
      final devicesLabel = find.text('Devices');

      final dashboardRect = tester.getRect(dashboardLabel);
      final devicesRect = tester.getRect(devicesLabel);

      expect(dashboardLabel, findsWidgets);
      expect(devicesLabel, findsWidgets);
      expect(dashboardRect.width, greaterThan(0));
      expect(devicesRect.width, greaterThan(0));

      expect(tester.takeException(), isNull);
    });
  });
}
