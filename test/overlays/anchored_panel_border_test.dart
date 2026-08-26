import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzAnchoredPanelBorder', () {
    test('two instances with the same fields are equal and share a hashCode', () {
      const a = LayrzAnchoredPanelBorder(color: Color(0xFF112233), width: 2.0);
      const b = LayrzAnchoredPanelBorder(color: Color(0xFF112233), width: 2.0);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different colors are not equal', () {
      const a = LayrzAnchoredPanelBorder(color: Color(0xFF112233), width: 2.0);
      const b = LayrzAnchoredPanelBorder(color: Color(0xFF445566), width: 2.0);

      expect(a, isNot(equals(b)));
    });

    test('instances with different widths are not equal', () {
      const a = LayrzAnchoredPanelBorder(color: Color(0xFF112233), width: 2.0);
      const b = LayrzAnchoredPanelBorder(color: Color(0xFF112233), width: 3.0);

      expect(a, isNot(equals(b)));
    });

    test('copyWith replaces only the given fields', () {
      const original = LayrzAnchoredPanelBorder(color: Color(0xFF112233), width: 2.0);

      final recoloredOnly = original.copyWith(color: const Color(0xFF445566));
      expect(recoloredOnly.color, equals(const Color(0xFF445566)));
      expect(recoloredOnly.width, equals(2.0));

      final widenedOnly = original.copyWith(width: 5.0);
      expect(widenedOnly.color, equals(const Color(0xFF112233)));
      expect(widenedOnly.width, equals(5.0));
    });

    test('copyWith with no arguments returns an equal instance', () {
      const original = LayrzAnchoredPanelBorder(color: Color(0xFF112233), width: 2.0);
      expect(original.copyWith(), equals(original));
    });

    test('toString includes color and width', () {
      const border = LayrzAnchoredPanelBorder(color: Color(0xFF112233), width: 2.0);
      expect(border.toString(), contains('LayrzAnchoredPanelBorder'));
      expect(border.toString(), contains('2.0'));
    });
  });

  group('LayrzAnchoredPanel.border', () {
    testWidgets('is absent by default -- no BoxDecoration.border on the panel decoration', (tester) async {
      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
          child: const SizedBox(width: 200, height: 100, child: Text('Panel content')),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      final panelContainer = _panelDecoratedBox(tester);
      final decoration = panelContainer.decoration;
      expect(decoration, isA<BoxDecoration>());
      expect((decoration as BoxDecoration).border, isNull);
    });

    testWidgets('paints a border when supplied', (tester) async {
      const border = LayrzAnchoredPanelBorder(color: Color(0xFFFF0000), width: 3.0);

      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          maxHeight: 120.0,
          border: border,
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
          child: const SizedBox(width: 200, height: 80, child: Text('Panel content')),
        ),
      );
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      final panelContainer = _panelDecoratedBox(tester);
      final decoration = panelContainer.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect((decoration.border as Border).top.color, equals(border.color));
      expect((decoration.border as Border).top.width, equals(border.width));
    });

    testWidgets('strokeAlignOutside means the border does not change the box size', (tester) async {
      const border = LayrzAnchoredPanelBorder(color: Color(0xFFFF0000), width: 3.0);

      // First tester: panel with no border.
      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          maxHeight: 120.0,
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
          child: const SizedBox(width: 200, height: 80, child: Text('Panel content')),
        ),
      );
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();
      final sizeWithoutBorder = tester.getSize(find.byType(SingleChildScrollView));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      // Second, independent pump: panel with a border, same content and cap.
      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          maxHeight: 120.0,
          border: border,
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
          child: const SizedBox(width: 200, height: 80, child: Text('Panel content')),
        ),
      );
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();
      final sizeWithBorder = tester.getSize(find.byType(SingleChildScrollView));

      expect(sizeWithBorder, equals(sizeWithoutBorder));
    });

    testWidgets("the bordered box's height equals the viewport height, not the uncapped content height", (
      tester,
    ) async {
      const border = LayrzAnchoredPanelBorder(color: Color(0xFF00FF00), width: 2.0);

      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          maxHeight: 100.0,
          border: border,
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
          // Content taller than maxHeight, so the panel must cap and scroll.
          child: Column(
            children: List.generate(
              20,
              (i) => SizedBox(height: 50, child: Text('Item $i')),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      final viewportHeight = tester.getSize(find.byType(SingleChildScrollView)).height;
      expect(viewportHeight, equals(100.0));

      // The decorated (bordered) `Container` that wraps the scroll viewport
      // must be sized to that same capped viewport, never to the uncapped
      // 20 * 50 = 1000px of content.
      final panelElement = _panelDecoratedBoxElement(tester);
      final renderBox = panelElement.renderObject as RenderBox;
      expect(renderBox.size.height, equals(viewportHeight));
      expect(renderBox.size.height, lessThan(1000.0));
    });
  });
}

/// Locates the `Container` that [LayrzAnchoredPanel] itself builds around its
/// scroll viewport -- the one carrying `sf1`/shadow/radius (and, when set,
/// the border) -- distinct from any `Container` a caller's own content or
/// anchor widget (e.g. [LayrzButton]) happens to build.
///
/// Identified structurally: it is the closest `Container` ancestor of the
/// panel's [SingleChildScrollView].
Element _panelDecoratedBoxElement(WidgetTester tester) {
  final scrollViewElement = tester.element(find.byType(SingleChildScrollView));
  final ancestor = scrollViewElement.findAncestorWidgetOfExactType<Container>();
  expect(ancestor, isNotNull, reason: 'LayrzAnchoredPanel must wrap its scroll viewport in a Container.');
  return find.byWidgetPredicate((w) => identical(w, ancestor)).evaluate().first;
}

/// Returns the [Container] widget itself for the panel's decorated box -- see
/// [_panelDecoratedBoxElement].
Container _panelDecoratedBox(WidgetTester tester) {
  return _panelDecoratedBoxElement(tester).widget as Container;
}
