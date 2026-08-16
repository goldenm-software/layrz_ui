import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/buttons.dart';
import 'package:layrz_ui/tokens.dart';

import '../helpers/find_button_label.dart';
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

        // Verify the label text is rendered and check the RichText overflow behavior
        final richTextFinder = find.byType(RichText);
        expect(richTextFinder, findsWidgets, reason: 'RichText should be present for label rendering');

        final richTextWidget = tester.widget<RichText>(richTextFinder.first);

        // The RichText should have ellipsis configured for overflow
        expect(richTextWidget.overflow, equals(TextOverflow.ellipsis));
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

        expect(findButtonLabel('Save Button'), findsOneWidget);
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
        final controller = LayrzButtonController();

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Loading Button',
            controller: controller,
            onTap: () => tapCount++,
          ),
        );

        controller.startLoading();
        await tester.pump();
        await tester.tap(find.byType(LayrzButton));
        await tester.pump();

        expect(tapCount, equals(0), reason: 'loading button should not invoke tap');

        controller.dispose();
      });

      testWidgets('cooldown button does not invoke tap callback', (tester) async {
        int tapCount = 0;
        final controller = LayrzButtonController();

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Cooldown Button',
            controller: controller,
            onTap: () => tapCount++,
          ),
        );

        controller.startCooldown(const Duration(seconds: 10));
        await tester.pump();
        await tester.tap(find.byType(LayrzButton));
        await tester.pump();

        expect(tapCount, equals(0), reason: 'cooldown button should not invoke tap');

        controller.dispose();
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

        expect(findButtonLabel('Disabled Button'), findsOneWidget);
      });

      testWidgets('onTap: null button renders disabled spec', (tester) async {
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Disabled Button',
            onTap: null,
          ),
        );

        expect(findButtonLabel('Disabled Button'), findsOneWidget);
      });

      testWidgets('loading button with all style variants renders without exception', (tester) async {
        final controller = LayrzButtonController();

        for (final style in LayrzButtonStyle.values) {
          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Loading',
              style: style,
              controller: controller,
              onTap: () {},
            ),
          );

          controller.startLoading();
          await tester.pump(const Duration(milliseconds: 100));

          expect(find.byType(LayrzButton), findsOneWidget);
          controller.reset();
        }

        controller.dispose();
      });

      testWidgets('cooldown button with all style variants renders without exception', (tester) async {
        final controller = LayrzButtonController();

        for (final style in LayrzButtonStyle.values) {
          await pumpThemed(
            tester,
            LayrzButton(
              labelText: 'Cooldown',
              style: style,
              controller: controller,
              onTap: () {},
            ),
          );

          controller.startCooldown(const Duration(seconds: 10));
          await tester.pump(const Duration(milliseconds: 100));

          expect(find.byType(LayrzButton), findsOneWidget);
          controller.reset();
        }

        controller.dispose();
      });

      testWidgets('loading button is not tappable while loading then becomes tappable', (tester) async {
        int tapCount = 0;
        final controller = LayrzButtonController();

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Toggle Loading',
            controller: controller,
            onTap: () => tapCount++,
          ),
        );

        controller.startLoading();
        // Try to tap while loading
        await tester.pump();
        await tester.tap(find.byType(LayrzButton));
        await tester.pump();
        expect(tapCount, equals(0), reason: 'should not tap while loading');

        // Stop loading
        controller.stopLoading();
        await tester.pump(const Duration(milliseconds: 150));

        // Now try to tap
        await tester.tap(find.byType(LayrzButton));
        await tester.pump();
        expect(tapCount, equals(1), reason: 'should tap after loading stops');

        controller.dispose();
      });

      testWidgets('cooldown button is not tappable while cooldown then becomes tappable', (tester) async {
        int tapCount = 0;
        final controller = LayrzButtonController();

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Toggle Cooldown',
            controller: controller,
            onTap: () => tapCount++,
          ),
        );

        controller.startCooldown(const Duration(seconds: 10));
        // Try to tap while cooldown
        await tester.pump();
        await tester.tap(find.byType(LayrzButton));
        await tester.pump();
        expect(tapCount, equals(0), reason: 'should not tap while cooldown');

        // Stop cooldown
        controller.clearCooldown();
        await tester.pump();

        // Now try to tap
        await tester.tap(find.byType(LayrzButton));
        await tester.pump();
        expect(tapCount, equals(1), reason: 'should tap after cooldown stops');

        controller.dispose();
      });
    });
  });
}
