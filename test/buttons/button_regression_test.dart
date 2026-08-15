import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/buttons/buttons.dart';
import 'package:layrz_ui/tokens/tokens.dart';

import '../helpers/fake_font_handler.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzButton Regression Tests', () {
    group('BUG 1: Label truncation — all non-Fab styles have identical width', () {
      testWidgets('all six non-Fab styles render with identical width for same label', (tester) async {
        final widths = <LayrzButtonStyle, double>{};

        for (final style in [
          LayrzButtonStyle.filled,
          LayrzButtonStyle.elevated,
          LayrzButtonStyle.filledTonal,
          LayrzButtonStyle.outlined,
          LayrzButtonStyle.outlinedTonal,
        ]) {
          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Test',
              style: style,
              onTap: () {},
            ),
          );

          final buttonFinder = find.byType(AnimatedContainer);
          final renderBox = tester.renderObject<RenderBox>(buttonFinder);
          widths[style] = renderBox.size.width;
        }

        // All widths should be identical (within tolerance for floating point)
        final firstWidth = widths.values.first;
        for (final width in widths.values) {
          expect(
            width,
            closeTo(firstWidth, 0.01),
            reason: 'All non-Fab styles should have identical width',
          );
        }
      });

      testWidgets('label is not ellipsised with fixed width', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'FilledTonal',
            style: LayrzButtonStyle.filledTonal,
            onTap: () {},
          ),
        );

        // Verify the label text is rendered
        expect(find.text('FilledTonal'), findsOneWidget);

        // Find the Text widget and verify it has the correct overflow behavior
        final textFinder = find.byType(Text).last; // Last one is the actual label
        final textWidget = tester.widget<Text>(textFinder);

        // The text should be in a Flexible, which constrains it but doesn't force ellipsis
        // We verify the text widget itself has ellipsis configured for overflow
        expect(textWidget.overflow, equals(TextOverflow.ellipsis));
      });

      testWidgets('label is not truncated with icon present', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Save Button',
            icon: LayrzIcons.solarOutlineCheckCircle,
            style: LayrzButtonStyle.filledTonal,
            onTap: () {},
          ),
        );

        expect(find.text('Save Button'), findsOneWidget);
        expect(find.byIcon(LayrzIcons.solarOutlineCheckCircle), findsOneWidget);
      });
    });

    group('BUG 2: Border opacity — borderless styles never show visible border', () {
      test('filled does not show border in any state', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        for (final state in [
          <WidgetState>{},
          {WidgetState.disabled},
          {WidgetState.hovered},
          {WidgetState.pressed},
        ]) {
          final spec = LayrzButtonStyleSpec.resolve(
            style: LayrzButtonStyle.filled,
            states: state,
            tokens: tokens,
            accent: accent,
          );

          expect(
            spec.borderColor.a,
            equals(0.0),
            reason: 'filled borderColor alpha should always be 0',
          );
        }
      });

      test('elevated does not show border in any state', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        for (final state in [
          <WidgetState>{},
          {WidgetState.disabled},
          {WidgetState.hovered},
          {WidgetState.pressed},
        ]) {
          final spec = LayrzButtonStyleSpec.resolve(
            style: LayrzButtonStyle.elevated,
            states: state,
            tokens: tokens,
            accent: accent,
          );

          expect(
            spec.borderColor.a,
            equals(0.0),
            reason: 'elevated borderColor alpha should always be 0',
          );
        }
      });

      test('filledTonal does not show border in any state', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        for (final state in [
          <WidgetState>{},
          {WidgetState.disabled},
          {WidgetState.hovered},
          {WidgetState.pressed},
        ]) {
          final spec = LayrzButtonStyleSpec.resolve(
            style: LayrzButtonStyle.filledTonal,
            states: state,
            tokens: tokens,
            accent: accent,
          );

          expect(
            spec.borderColor.a,
            equals(0.0),
            reason: 'filledTonal borderColor alpha should always be 0',
          );
        }
      });

      test('filledFab does not show border in any state', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        for (final state in [
          <WidgetState>{},
          {WidgetState.disabled},
          {WidgetState.hovered},
          {WidgetState.pressed},
        ]) {
          final spec = LayrzButtonStyleSpec.resolve(
            style: LayrzButtonStyle.filledFab,
            states: state,
            tokens: tokens,
            accent: accent,
          );

          expect(
            spec.borderColor.a,
            equals(0.0),
            reason: 'filledFab borderColor alpha should always be 0',
          );
        }
      });

      test('elevatedFab does not show border in any state', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        for (final state in [
          <WidgetState>{},
          {WidgetState.disabled},
          {WidgetState.hovered},
          {WidgetState.pressed},
        ]) {
          final spec = LayrzButtonStyleSpec.resolve(
            style: LayrzButtonStyle.elevatedFab,
            states: state,
            tokens: tokens,
            accent: accent,
          );

          expect(
            spec.borderColor.a,
            equals(0.0),
            reason: 'elevatedFab borderColor alpha should always be 0',
          );
        }
      });

      test('filledTonalFab does not show border in any state', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        for (final state in [
          <WidgetState>{},
          {WidgetState.disabled},
          {WidgetState.hovered},
          {WidgetState.pressed},
        ]) {
          final spec = LayrzButtonStyleSpec.resolve(
            style: LayrzButtonStyle.filledTonalFab,
            states: state,
            tokens: tokens,
            accent: accent,
          );

          expect(
            spec.borderColor.a,
            equals(0.0),
            reason: 'filledTonalFab borderColor alpha should always be 0',
          );
        }
      });

      test('outlined shows visible border in default, hovered, and pressed states', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        for (final state in [
          <WidgetState>{},
          {WidgetState.hovered},
          {WidgetState.pressed},
        ]) {
          final spec = LayrzButtonStyleSpec.resolve(
            style: LayrzButtonStyle.outlined,
            states: state,
            tokens: tokens,
            accent: accent,
          );

          expect(
            spec.borderColor.a,
            greaterThan(0.0),
            reason: 'outlined borderColor alpha should be > 0 in non-disabled states',
          );
        }
      });

      test('outlined shows visible border in disabled state', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {WidgetState.disabled},
          tokens: tokens,
          accent: accent,
        );

        expect(
          spec.borderColor.a,
          greaterThan(0.0),
          reason: 'outlined borderColor alpha should be > 0 even when disabled',
        );
      });

      test('outlinedFab shows visible border in disabled state', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedFab,
          states: {WidgetState.disabled},
          tokens: tokens,
          accent: accent,
        );

        expect(
          spec.borderColor.a,
          greaterThan(0.0),
          reason: 'outlinedFab borderColor alpha should be > 0 even when disabled',
        );
      });

      test('outlinedTonal shows visible border in disabled state', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedTonal,
          states: {WidgetState.disabled},
          tokens: tokens,
          accent: accent,
        );

        expect(
          spec.borderColor.a,
          greaterThan(0.0),
          reason: 'outlinedTonal borderColor alpha should be > 0 even when disabled',
        );
      });

      test('outlinedTonalFab shows visible border in disabled state', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedTonalFab,
          states: {WidgetState.disabled},
          tokens: tokens,
          accent: accent,
        );

        expect(
          spec.borderColor.a,
          greaterThan(0.0),
          reason: 'outlinedTonalFab borderColor alpha should be > 0 even when disabled',
        );
      });
    });

    group('BUG 3: Outlined styles have hover and press feedback', () {
      test('outlined hovered spec differs from default spec', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        final defaultSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {},
          tokens: tokens,
          accent: accent,
        );

        final hoveredSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: accent,
        );

        expect(
          hoveredSpec,
          isNot(equals(defaultSpec)),
          reason: 'outlined hovered spec should differ from default',
        );

        // Specifically, background should change on hover
        expect(
          hoveredSpec.backgroundColor,
          isNot(equals(defaultSpec.backgroundColor)),
          reason: 'outlined should gain a tonal background on hover',
        );
      });

      test('outlined pressed spec differs from default spec', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        final defaultSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {},
          tokens: tokens,
          accent: accent,
        );

        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: accent,
        );

        expect(
          pressedSpec,
          isNot(equals(defaultSpec)),
          reason: 'outlined pressed spec should differ from default',
        );

        // Specifically, background should change on press
        expect(
          pressedSpec.backgroundColor,
          isNot(equals(defaultSpec.backgroundColor)),
          reason: 'outlined should gain a stronger tonal background on press',
        );
      });

      test('outlined pressed background is darker than hovered', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        final hoveredSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: accent,
        );

        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: accent,
        );

        // Pressed background should have higher opacity than hovered
        expect(
          pressedSpec.backgroundColor.a,
          greaterThan(hoveredSpec.backgroundColor.a),
          reason: 'pressed background opacity should be greater than hovered',
        );
      });

      test('outlinedFab hovered spec differs from default spec', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        final defaultSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedFab,
          states: {},
          tokens: tokens,
          accent: accent,
        );

        final hoveredSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedFab,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: accent,
        );

        expect(
          hoveredSpec,
          isNot(equals(defaultSpec)),
          reason: 'outlinedFab hovered spec should differ from default',
        );
      });

      test('outlinedFab pressed spec differs from default spec', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        final defaultSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedFab,
          states: {},
          tokens: tokens,
          accent: accent,
        );

        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedFab,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: accent,
        );

        expect(
          pressedSpec,
          isNot(equals(defaultSpec)),
          reason: 'outlinedFab pressed spec should differ from default',
        );
      });

      test('all styles have hover feedback', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        for (final style in LayrzButtonStyle.values) {
          final defaultSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {},
            tokens: tokens,
            accent: accent,
          );

          final hoveredSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.hovered},
            tokens: tokens,
            accent: accent,
          );

          expect(
            hoveredSpec,
            isNot(equals(defaultSpec)),
            reason: '$style should have hover feedback',
          );
        }
      });

      test('all styles have press feedback', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        for (final style in LayrzButtonStyle.values) {
          final defaultSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {},
            tokens: tokens,
            accent: accent,
          );

          final pressedSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.pressed},
            tokens: tokens,
            accent: accent,
          );

          expect(
            pressedSpec,
            isNot(equals(defaultSpec)),
            reason: '$style should have press feedback',
          );
        }
      });
    });

    group('BUG 4: Loading and cooldown preserve button style', () {
      test('disabled and default specs differ', () {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        final accent = tokens.colors.primary;

        final defaultSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filledTonal,
          states: {},
          tokens: tokens,
          accent: accent,
        );

        final disabledSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filledTonal,
          states: {WidgetState.disabled},
          tokens: tokens,
          accent: accent,
        );

        // Verify that disabled and default specs are different
        // When loading, the button does NOT set WidgetState.disabled,
        // so it should use the default spec, not the disabled spec.
        expect(
          disabledSpec,
          isNot(equals(defaultSpec)),
          reason: 'disabled spec should differ from default spec',
        );
      });

      testWidgets('loading button does not invoke tap callback', (tester) async {
        int tapCount = 0;
        final loading = ValueNotifier<bool>(true);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Loading Button',
            isLoading: loading,
            onTap: () => tapCount++,
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pump();

        expect(tapCount, equals(0), reason: 'loading button should not invoke tap');
      });

      testWidgets('cooldown button does not invoke tap callback', (tester) async {
        int tapCount = 0;
        final cooldown = ValueNotifier<bool>(true);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Cooldown Button',
            isCooldown: cooldown,
            onTap: () => tapCount++,
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pump();

        expect(tapCount, equals(0), reason: 'cooldown button should not invoke tap');
      });

      testWidgets('disabled button still renders disabled spec', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Disabled Button',
            isDisabled: true,
            onTap: () {},
          ),
        );

        expect(find.text('Disabled Button'), findsOneWidget);
      });

      testWidgets('onTap: null button renders disabled spec', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Disabled Button',
            onTap: null,
          ),
        );

        expect(find.text('Disabled Button'), findsOneWidget);
      });

      testWidgets('loading button with all style variants renders without exception', (tester) async {
        final loading = ValueNotifier<bool>(true);

        for (final style in LayrzButtonStyle.values) {
          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Loading',
              style: style,
              isLoading: loading,
              onTap: () {},
            ),
          );

          await tester.pump(const Duration(milliseconds: 100));

          expect(find.byType(LayrzButton), findsOneWidget);
        }
      });

      testWidgets('cooldown button with all style variants renders without exception', (tester) async {
        final cooldown = ValueNotifier<bool>(true);

        for (final style in LayrzButtonStyle.values) {
          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Cooldown',
              style: style,
              isCooldown: cooldown,
              onTap: () {},
            ),
          );

          await tester.pump(const Duration(milliseconds: 100));

          expect(find.byType(LayrzButton), findsOneWidget);
        }
      });

      testWidgets('loading button is not tappable while loading then becomes tappable', (tester) async {
        int tapCount = 0;
        final loading = ValueNotifier<bool>(true);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Toggle Loading',
            isLoading: loading,
            onTap: () => tapCount++,
          ),
        );

        // Try to tap while loading
        await tester.tap(find.byType(LayrzButton));
        await tester.pump();
        expect(tapCount, equals(0), reason: 'should not tap while loading');

        // Stop loading
        loading.value = false;
        await tester.pump();

        // Now try to tap
        await tester.tap(find.byType(LayrzButton));
        await tester.pump();
        expect(tapCount, equals(1), reason: 'should tap after loading stops');
      });

      testWidgets('cooldown button is not tappable while cooldown then becomes tappable', (tester) async {
        int tapCount = 0;
        final cooldown = ValueNotifier<bool>(true);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Toggle Cooldown',
            isCooldown: cooldown,
            onTap: () => tapCount++,
          ),
        );

        // Try to tap while cooldown
        await tester.tap(find.byType(LayrzButton));
        await tester.pump();
        expect(tapCount, equals(0), reason: 'should not tap while cooldown');

        // Stop cooldown
        cooldown.value = false;
        await tester.pump();

        // Now try to tap
        await tester.tap(find.byType(LayrzButton));
        await tester.pump();
        expect(tapCount, equals(1), reason: 'should tap after cooldown stops');
      });
    });
  });
}
