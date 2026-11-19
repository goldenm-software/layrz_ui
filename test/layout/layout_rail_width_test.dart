import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

const Color _bodyColor = Color(0xFFFF0000);

Future<Rect> _pumpAndGetBodyRect(WidgetTester tester, {double? railWidth}) async {
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1600, 1200);

  final body = Align(
    alignment: Alignment.topLeft,
    child: Container(width: 100, height: 100, color: _bodyColor),
  );
  final items = [LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true)];

  await pumpThemedApp(
    tester,
    Directionality(
      textDirection: TextDirection.ltr,
      child: railWidth == null
          ? LayrzLayout(logo: 'assets/test-logo.png', items: items, body: body)
          : LayrzLayout(logo: 'assets/test-logo.png', items: items, body: body, railWidth: railWidth),
    ),
  );

  expect(tester.takeException(), isNull);
  return tester.getRect(find.byWidgetPredicate((w) => w is Container && w.color == _bodyColor));
}

void main() {
  group('LayrzLayout - railWidth', () {
    testWidgets('defaults to kLayrzLayoutRailWidth', (WidgetTester tester) async {
      final rect = await _pumpAndGetBodyRect(tester);
      expect(rect.left, moreOrLessEquals(kLayrzLayoutRailWidth, epsilon: 1.0));
    });

    testWidgets('custom railWidth widens the rail and insets the body', (WidgetTester tester) async {
      final rect = await _pumpAndGetBodyRect(tester, railWidth: 250);
      expect(rect.left, moreOrLessEquals(250.0, epsilon: 1.0));
    });

    testWidgets('custom railWidth gives labels the extra room', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1600, 1200);

      await pumpThemedApp(
        tester,
        Directionality(
          textDirection: TextDirection.ltr,
          child: LayrzLayout(
            logo: 'assets/test-logo.png',
            railWidth: 250,
            items: [LayrzNavigatorPage(id: 'sp', labelText: 'Supply points')],
            body: const SizedBox(),
          ),
        ),
      );

      final label = find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Supply points'));
      expect(label, findsOneWidget);
      expect(tester.getRect(label).right, lessThanOrEqualTo(250.0));
    });
  });
}
