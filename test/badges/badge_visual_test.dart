import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzBadgeVisual.formatCount', () {
    test('renders small counts as-is', () {
      expect(LayrzBadgeVisual.formatCount(0), '0');
      expect(LayrzBadgeVisual.formatCount(3), '3');
      expect(LayrzBadgeVisual.formatCount(42), '42');
    });

    test('renders the boundary value 99 as a literal number, not overflowed', () {
      expect(LayrzBadgeVisual.formatCount(99), '99');
    });

    test('renders 100 and above as the 99+ overflow form', () {
      expect(LayrzBadgeVisual.formatCount(100), '99+');
      expect(LayrzBadgeVisual.formatCount(999), '99+');
      expect(LayrzBadgeVisual.formatCount(1000000), '99+');
    });

    test('clamps negative counts to 0', () {
      expect(LayrzBadgeVisual.formatCount(-5), '0');
    });
  });

  group('LayrzBadgeVisual rendering', () {
    guardedTestWidgets('renders a number badge', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzBadgeVisual(count: 3));

      expect(find.text('3'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    guardedTestWidgets('renders the 99+ boundary form for a count of 100', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzBadgeVisual(count: 100));

      expect(find.text('99+'), findsOneWidget);
      expect(find.text('100'), findsNothing);
    });

    guardedTestWidgets('renders exactly 99 (not overflowed) at the boundary', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzBadgeVisual(count: 99));

      expect(find.text('99'), findsOneWidget);
      expect(find.text('99+'), findsNothing);
    });

    guardedTestWidgets('renders an icon badge when icon is provided and count is null', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzBadgeVisual(icon: MdiIcons.bell));

      expect(find.byWidgetPredicate((w) => w is Icon && w.icon == MdiIcons.bell), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    guardedTestWidgets('count takes precedence over icon when both are provided', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzBadgeVisual(count: 5, icon: MdiIcons.bell));

      expect(find.text('5'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Icon && w.icon == MdiIcons.bell), findsNothing);
    });

    guardedTestWidgets('renders a bare presence dot when count and icon are both null', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzBadgeVisual());

      expect(find.byType(Text), findsNothing);
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(LayrzBadgeVisual), findsOneWidget);
    });

    guardedTestWidgets('an explicit color overrides the resolved type color', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const customColor = Color(0xFF123456);
      await pumpThemed(tester, const LayrzBadgeVisual(count: 1, color: customColor));

      final container = tester.widget<Container>(
        find.descendant(of: find.byType(LayrzBadgeVisual), matching: find.byType(Container)).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, equals(customColor));
    });

    guardedTestWidgets('defaults to LayrzBadgeType.danger when no type or color is given', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzBadgeVisual(count: 1));

      final tokens = LayrzTheme.of(tester.element(find.byType(LayrzBadgeVisual))).tokens;
      final container = tester.widget<Container>(
        find.descendant(of: find.byType(LayrzBadgeVisual), matching: find.byType(Container)).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, equals(tokens.colors.danger.shade500));
    });
  });

  group('LayrzBadgeStyleSpec', () {
    testWidgets('resolve with a semantic type derives contentColor from contrast', (tester) async {
      await pumpThemed(tester, Container());
      final tokens = LayrzTheme.of(tester.element(find.byType(Container))).tokens;

      final spec = LayrzBadgeStyleSpec.resolve(type: LayrzBadgeType.info, color: null, tokens: tokens);

      expect(spec.backgroundColor, equals(tokens.colors.info.shade500));
      expect(spec.contentColor, equals(tokens.colors.info.shade500.contrastColor));
    });

    testWidgets('resolve with type.custom and no color falls back to primary', (tester) async {
      await pumpThemed(tester, Container());
      final tokens = LayrzTheme.of(tester.element(find.byType(Container))).tokens;

      final spec = LayrzBadgeStyleSpec.resolve(type: LayrzBadgeType.custom, color: null, tokens: tokens);

      expect(spec.backgroundColor, equals(tokens.colors.primary.shade500));
    });

    testWidgets('an explicit color overrides the type regardless of type', (tester) async {
      await pumpThemed(tester, Container());
      final tokens = LayrzTheme.of(tester.element(find.byType(Container))).tokens;
      const explicit = Color(0xFF00FF00);

      final spec = LayrzBadgeStyleSpec.resolve(type: LayrzBadgeType.danger, color: explicit, tokens: tokens);

      expect(spec.backgroundColor, equals(explicit));
    });

    test('copyWith preserves unspecified fields', () {
      const spec = LayrzBadgeStyleSpec(
        backgroundColor: Color(0xFFFF5722),
        contentColor: Color(0xFFFFFFFF),
      );

      const newColor = Color(0xFF2196F3);
      final modified = spec.copyWith(backgroundColor: newColor);

      expect(modified.backgroundColor, equals(newColor));
      expect(modified.contentColor, equals(const Color(0xFFFFFFFF)));
    });

    test('copyWith replaces contentColor when explicitly given', () {
      const spec = LayrzBadgeStyleSpec(
        backgroundColor: Color(0xFFFF5722),
        contentColor: Color(0xFFFFFFFF),
      );

      const newContentColor = Color(0xFF000000);
      final modified = spec.copyWith(contentColor: newContentColor);

      expect(modified.backgroundColor, equals(const Color(0xFFFF5722)));
      expect(modified.contentColor, equals(newContentColor));
    });

    test('equal specs compare equal and share a hash code', () {
      const spec1 = LayrzBadgeStyleSpec(backgroundColor: Color(0xFFFF5722), contentColor: Color(0xFFFFFFFF));
      const spec2 = LayrzBadgeStyleSpec(backgroundColor: Color(0xFFFF5722), contentColor: Color(0xFFFFFFFF));

      expect(spec1, equals(spec2));
      expect(spec1.hashCode, equals(spec2.hashCode));
    });

    test('different specs are not equal', () {
      const spec1 = LayrzBadgeStyleSpec(backgroundColor: Color(0xFFFF5722), contentColor: Color(0xFFFFFFFF));
      const spec2 = LayrzBadgeStyleSpec(backgroundColor: Color(0xFF2196F3), contentColor: Color(0xFFFFFFFF));

      expect(spec1, isNot(spec2));
    });

    test('specs with the same background but different content color are not equal', () {
      const spec1 = LayrzBadgeStyleSpec(backgroundColor: Color(0xFFFF5722), contentColor: Color(0xFFFFFFFF));
      const spec2 = LayrzBadgeStyleSpec(backgroundColor: Color(0xFFFF5722), contentColor: Color(0xFF000000));

      expect(spec1, isNot(spec2));
    });
  });
}
