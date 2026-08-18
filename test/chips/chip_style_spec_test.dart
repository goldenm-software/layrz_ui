import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzChipStyleSpec', () {
    group('resolve', () {
      testWidgets('filled style produces solid background and contrast content', (tester) async {
        await pumpThemed(tester, Container());

        final tokens = LayrzTheme.of(tester.element(find.byType(Container))).tokens;
        final accent = tokens.colors.info.shade500;

        final spec = LayrzChipStyleSpec.resolve(
          style: LayrzChipStyle.filled,
          accent: accent,
          tokens: tokens,
        );

        expect(spec.backgroundColor, equals(accent));
        expect(spec.borderWidth, equals(0));
        expect(spec.borderColor, equals(const Color(0x00000000)));
        expect(spec.contentColor, equals(accent.contrastColor));
      });

      testWidgets('outlined style produces border with transparent background', (tester) async {
        await pumpThemed(tester, Container());

        final tokens = LayrzTheme.of(tester.element(find.byType(Container))).tokens;
        final accent = tokens.colors.success.shade500;

        final spec = LayrzChipStyleSpec.resolve(
          style: LayrzChipStyle.outlined,
          accent: accent,
          tokens: tokens,
        );

        expect(spec.backgroundColor, equals(const Color(0x00000000)));
        expect(spec.borderColor, equals(accent));
        expect(spec.borderWidth, equals(tokens.border.stroke1));
        expect(spec.contentColor, equals(accent));
      });

      testWidgets('filledTonal style produces tonal background', (tester) async {
        await pumpThemed(tester, Container());

        final tokens = LayrzTheme.of(tester.element(find.byType(Container))).tokens;
        final accent = tokens.colors.warning.shade500;

        final spec = LayrzChipStyleSpec.resolve(
          style: LayrzChipStyle.filledTonal,
          accent: accent,
          tokens: tokens,
        );

        expect(spec.backgroundColor.a, lessThan(accent.a));
        expect(spec.borderWidth, equals(0));
        expect(spec.borderColor, equals(const Color(0x00000000)));
        expect(spec.contentColor, equals(accent));
      });

      testWidgets('all three styles produce different specs', (tester) async {
        await pumpThemed(tester, Container());

        final tokens = LayrzTheme.of(tester.element(find.byType(Container))).tokens;
        final accent = tokens.colors.danger.shade500;

        final filledSpec = LayrzChipStyleSpec.resolve(
          style: LayrzChipStyle.filled,
          accent: accent,
          tokens: tokens,
        );

        final outlinedSpec = LayrzChipStyleSpec.resolve(
          style: LayrzChipStyle.outlined,
          accent: accent,
          tokens: tokens,
        );

        final tonalSpec = LayrzChipStyleSpec.resolve(
          style: LayrzChipStyle.filledTonal,
          accent: accent,
          tokens: tokens,
        );

        // All three should be different
        expect(filledSpec, isNot(outlinedSpec));
        expect(filledSpec, isNot(tonalSpec));
        expect(outlinedSpec, isNot(tonalSpec));
      });
    });

    group('copyWith', () {
      testWidgets('copyWith preserves unspecified fields', (tester) async {
        await pumpThemed(tester, Container());

        const testColor = Color(0xFFFF5722);

        final spec = LayrzChipStyleSpec(
          backgroundColor: testColor,
          borderColor: testColor,
          borderWidth: 2.0,
          contentColor: testColor,
        );

        const newColor = Color(0xFF2196F3);
        final modified = spec.copyWith(backgroundColor: newColor);

        expect(modified.backgroundColor, equals(newColor));
        expect(modified.borderColor, equals(testColor));
        expect(modified.borderWidth, equals(2.0));
        expect(modified.contentColor, equals(testColor));
      });

      testWidgets('copyWith with all parameters creates new spec', (tester) async {
        const color1 = Color(0xFFFF5722);
        const color2 = Color(0xFF2196F3);
        const color3 = Color(0xFF4CAF50);
        const color4 = Color(0xFFFFC107);

        final spec = const LayrzChipStyleSpec(
          backgroundColor: color1,
          borderColor: color1,
          borderWidth: 1.0,
          contentColor: color1,
        );

        final modified = spec.copyWith(
          backgroundColor: color2,
          borderColor: color3,
          borderWidth: 2.0,
          contentColor: color4,
        );

        expect(modified.backgroundColor, equals(color2));
        expect(modified.borderColor, equals(color3));
        expect(modified.borderWidth, equals(2.0));
        expect(modified.contentColor, equals(color4));
      });
    });

    group('equality and hashing', () {
      testWidgets('identical specs are equal', (tester) async {
        const spec1 = LayrzChipStyleSpec(
          backgroundColor: Color(0xFFFF5722),
          borderColor: Color(0xFF2196F3),
          borderWidth: 1.5,
          contentColor: Color(0xFF4CAF50),
        );

        const spec2 = LayrzChipStyleSpec(
          backgroundColor: Color(0xFFFF5722),
          borderColor: Color(0xFF2196F3),
          borderWidth: 1.5,
          contentColor: Color(0xFF4CAF50),
        );

        expect(spec1, equals(spec2));
        expect(spec1.hashCode, equals(spec2.hashCode));
      });

      testWidgets('different specs are not equal', (tester) async {
        const spec1 = LayrzChipStyleSpec(
          backgroundColor: Color(0xFFFF5722),
          borderColor: Color(0xFF2196F3),
          borderWidth: 1.5,
          contentColor: Color(0xFF4CAF50),
        );

        const spec2 = LayrzChipStyleSpec(
          backgroundColor: Color(0xFF2196F3), // Different
          borderColor: Color(0xFF2196F3),
          borderWidth: 1.5,
          contentColor: Color(0xFF4CAF50),
        );

        expect(spec1, isNot(spec2));
      });
    });

    group('delete icon color resolution', () {
      testWidgets('resolveDeleteIconColor in normal state returns contentColor', (tester) async {
        const contentColor = Color(0xFFFF5722);

        final normalColor = LayrzChipStyleSpec.resolveDeleteIconColor(
          contentColor: contentColor,
          isPressed: false,
        );

        expect(normalColor, equals(contentColor));
      });

      testWidgets('resolveDeleteIconColor in pressed state reduces opacity', (tester) async {
        const contentColor = Color(0xFFFF5722);

        final pressedColor = LayrzChipStyleSpec.resolveDeleteIconColor(
          contentColor: contentColor,
          isPressed: true,
        );

        expect(pressedColor.a, lessThan(contentColor.a));
      });
    });
  });
}
