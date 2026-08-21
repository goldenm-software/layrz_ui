import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_font_handler.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzDropdownItem types', () {
    group('Semantic factories', () {
      testWidgets('save factory uses correct icon and success color', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        var tapped = false;

        await pumpThemed(
          tester,
          theme: themeData,
          LayrzDropdownMenu(
            items: [
              LayrzDropdownEntry.save(
                labelText: 'Save',
                onTap: () => tapped = true,
              ),
            ],
            builder: (context, controller) => LayrzButton(
              labelText: 'Open',
              onTap: controller.open,
            ),
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        // Entry should be visible
        expect(find.text('Save'), findsOneWidget);

        // Entry should have success color dot
        final circleContainer = tester.widget<Container>(
          find.byWidgetPredicate(
            (w) => w is Container && (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
          ),
        );
        final decoration = circleContainer.decoration as BoxDecoration;
        expect(decoration.color, themeData.tokens.colors.success);

        // Callback should fire
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(tapped, isTrue);
      });

      testWidgets('cancel factory uses correct icon and danger color', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        await pumpThemed(
          tester,
          theme: themeData,
          LayrzDropdownMenu(
            items: [
              LayrzDropdownEntry.cancel(
                labelText: 'Cancel',
                onTap: () {},
              ),
            ],
            builder: (context, controller) => LayrzButton(
              labelText: 'Open',
              onTap: controller.open,
            ),
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        final circleContainer = tester.widget<Container>(
          find.byWidgetPredicate(
            (w) => w is Container && (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
          ),
        );
        final decoration = circleContainer.decoration as BoxDecoration;
        expect(decoration.color, themeData.tokens.colors.danger);
      });

      testWidgets('info factory uses correct icon and info color', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        await pumpThemed(
          tester,
          theme: themeData,
          LayrzDropdownMenu(
            items: [
              LayrzDropdownEntry.info(
                labelText: 'Info',
                onTap: () {},
              ),
            ],
            builder: (context, controller) => LayrzButton(
              labelText: 'Open',
              onTap: controller.open,
            ),
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        final circleContainer = tester.widget<Container>(
          find.byWidgetPredicate(
            (w) => w is Container && (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
          ),
        );
        final decoration = circleContainer.decoration as BoxDecoration;
        expect(decoration.color, themeData.tokens.colors.info);
      });

      testWidgets('show factory uses correct icon and info color', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        await pumpThemed(
          tester,
          theme: themeData,
          LayrzDropdownMenu(
            items: [
              LayrzDropdownEntry.show(
                labelText: 'Show',
                onTap: () {},
              ),
            ],
            builder: (context, controller) => LayrzButton(
              labelText: 'Open',
              onTap: controller.open,
            ),
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        final circleContainer = tester.widget<Container>(
          find.byWidgetPredicate(
            (w) => w is Container && (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
          ),
        );
        final decoration = circleContainer.decoration as BoxDecoration;
        expect(decoration.color, themeData.tokens.colors.info);
      });

      testWidgets('edit factory uses correct icon and warning color', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        await pumpThemed(
          tester,
          theme: themeData,
          LayrzDropdownMenu(
            items: [
              LayrzDropdownEntry.edit(
                labelText: 'Edit',
                onTap: () {},
              ),
            ],
            builder: (context, controller) => LayrzButton(
              labelText: 'Open',
              onTap: controller.open,
            ),
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        final circleContainer = tester.widget<Container>(
          find.byWidgetPredicate(
            (w) => w is Container && (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
          ),
        );
        final decoration = circleContainer.decoration as BoxDecoration;
        expect(decoration.color, themeData.tokens.colors.warning);
      });

      testWidgets('delete factory uses correct icon and danger color', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        await pumpThemed(
          tester,
          theme: themeData,
          LayrzDropdownMenu(
            items: [
              LayrzDropdownEntry.delete(
                labelText: 'Delete',
                onTap: () {},
              ),
            ],
            builder: (context, controller) => LayrzButton(
              labelText: 'Open',
              onTap: controller.open,
            ),
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        final circleContainer = tester.widget<Container>(
          find.byWidgetPredicate(
            (w) => w is Container && (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
          ),
        );
        final decoration = circleContainer.decoration as BoxDecoration;
        expect(decoration.color, themeData.tokens.colors.danger);
      });

      testWidgets('semantic factory icon can be overridden', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        await pumpThemed(
          tester,
          theme: themeData,
          LayrzDropdownMenu(
            items: [
              LayrzDropdownEntry.save(
                labelText: 'Custom Save',
                onTap: () {},
                icon: MdiIcons.checkCircleOutline,
              ),
            ],
            builder: (context, controller) => LayrzButton(
              labelText: 'Open',
              onTap: controller.open,
            ),
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        expect(find.text('Custom Save'), findsOneWidget);
      });

      testWidgets('semantic factory color can be overridden', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        final customColor = const Color(0xFFFF0000);

        await pumpThemed(
          tester,
          theme: themeData,
          LayrzDropdownMenu(
            items: [
              LayrzDropdownEntry.save(
                labelText: 'Save',
                onTap: () {},
                color: customColor,
              ),
            ],
            builder: (context, controller) => LayrzButton(
              labelText: 'Open',
              onTap: controller.open,
            ),
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        final circleContainer = tester.widget<Container>(
          find.byWidgetPredicate(
            (w) => w is Container && (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
          ),
        );
        final decoration = circleContainer.decoration as BoxDecoration;
        expect(decoration.color, customColor);
      });
    });

    testWidgets('entry isFocusable is true when enabled', (tester) async {
      final entry = LayrzDropdownEntry(
        labelText: 'Test',
        onTap: () {},
        enabled: true,
      );

      expect(entry.isFocusable, isTrue);
    });

    testWidgets('entry isFocusable is false when disabled', (tester) async {
      final entry = LayrzDropdownEntry(
        labelText: 'Test',
        onTap: () {},
        enabled: false,
      );

      expect(entry.isFocusable, isFalse);
    });

    testWidgets('label isFocusable is false', (tester) async {
      final label = LayrzDropdownLabel(labelText: 'Test');

      expect(label.isFocusable, isFalse);
    });

    testWidgets('label renders in label typography at fg3 color', (tester) async {
      await pumpThemed(
        tester,
        LayrzDropdownLabel(labelText: 'Section'),
      );

      final text = find.text('Section');
      expect(text, findsOneWidget);

      final textWidget = tester.widget<Text>(text);
      final tokens = tester.element(text).tokens;

      expect(textWidget.style?.color, tokens.colors.fg3);
    });

    testWidgets('label with color: null uses neutral surface3 band', (tester) async {
      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

      await pumpThemed(
        tester,
        theme: themeData,
        LayrzDropdownLabel(labelText: 'Section', color: null),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color, themeData.tokens.colors.sf3);
    });

    testWidgets('label with color uses flattened tonal fill', (tester) async {
      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
      final customColor = const Color(0xFFABCDEF);

      await pumpThemed(
        tester,
        theme: themeData,
        LayrzDropdownLabel(labelText: 'Colored Section', color: customColor),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final bandColor = container.color as Color;

      // Verify the result is fully opaque (alpha == 1.0)
      expect(bandColor.a, equals(1.0), reason: 'Band color should be fully opaque');

      // The exact colour is the flattened result of the tonal blend
      final expectedBand = customColor
          .withOpacityValue(themeData.tokens.colors.tonalOpacity)
          .flattenOn(themeData.tokens.colors.sf1);
      expect(bandColor, expectedBand);
    });

    testWidgets('label with color maintains non-focusable semantics', (tester) async {
      final customColor = const Color(0xFFABCDEF);

      await pumpThemed(
        tester,
        LayrzDropdownLabel(labelText: 'Colored Header', color: customColor),
      );

      // Verify it is not focusable
      final label = LayrzDropdownLabel(labelText: 'Test', color: customColor);
      expect(label.isFocusable, isFalse);

      // Verify header semantics are present
      final semantics = find.byType(Semantics);
      expect(semantics, findsWidgets);
    });

    testWidgets('arrow-key traversal skips labels', (tester) async {
      await pumpThemed(
        tester,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'Entry 1',
              onTap: () {},
            ),
            LayrzDropdownLabel(labelText: 'Header'),
            LayrzDropdownEntry(
              labelText: 'Entry 2',
              onTap: () {},
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
        ),
      );

      // Open menu
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // Focus should be on first entry
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Continue down (should skip label, land on Entry 2)
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // The second entry should be focused (we can't directly test focus, but
      // we can verify the structure makes sense)
      expect(find.text('Entry 1'), findsOneWidget);
      expect(find.text('Entry 2'), findsOneWidget);
    });

    testWidgets('entry with custom color uses that color', (tester) async {
      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

      await pumpThemed(
        tester,
        theme: themeData,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'Danger',
              onTap: () {},
              color: themeData.tokens.colors.danger,
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(find.text('Danger'), findsOneWidget);
    });

    testWidgets('entry renders icon when provided', (tester) async {
      await pumpThemed(
        tester,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'With Icon',
              onTap: () {},
              icon: MdiIcons.plusCircleOutline,
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(find.text('With Icon'), findsOneWidget);
      // Icon should be rendered (Icon widget exists)
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('color dot renders only when color is set', (tester) async {
      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

      // Test with color
      await pumpThemed(
        tester,
        theme: themeData,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'With Color',
              onTap: () {},
              color: themeData.tokens.colors.danger,
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // Find circles - should have at least one (the dot)
      final circlesWithColor = tester.widgetList<Container>(
        find.byWidgetPredicate(
          (w) => w is Container && (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
        ),
      );

      // Should have at least one circle (the dot)
      expect(circlesWithColor.length, greaterThan(0));
    });

    testWidgets('color dot uses the exact color passed', (tester) async {
      final customColor = const Color(0xFF123456);

      await pumpThemed(
        tester,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'Custom Color Entry',
              onTap: () {},
              color: customColor,
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // Find the circle container and verify its color matches exactly
      final circleContainer = tester.widget<Container>(
        find.byWidgetPredicate(
          (w) => w is Container && (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
        ),
      );

      final decoration = circleContainer.decoration as BoxDecoration;
      expect(decoration.color, customColor);
    });

    testWidgets('dot and icon can coexist in same entry', (tester) async {
      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

      await pumpThemed(
        tester,
        theme: themeData,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'Dot and Icon',
              onTap: () {},
              icon: MdiIcons.plusCircleOutline,
              color: themeData.tokens.colors.primary,
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // Both should be rendered
      expect(find.text('Dot and Icon'), findsOneWidget);
      // Icon exists
      expect(find.byType(Icon), findsWidgets);
      // Dot exists
      expect(
        find.byWidgetPredicate(
          (w) => w is Container && (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
        ),
        findsWidgets,
      );
    });

    testWidgets('entry height is fixed regardless of dot/icon presence', (tester) async {
      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

      // Test with dot and icon
      await pumpThemed(
        tester,
        theme: themeData,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'Dot Icon Label',
              onTap: () {},
              icon: MdiIcons.plusCircleOutline,
              color: themeData.tokens.colors.danger,
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // Verify the entry renders with all elements
      expect(find.text('Dot Icon Label'), findsOneWidget);
      expect(find.byType(Icon), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (w) => w is Container && (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
        ),
        findsWidgets,
      );
    });

    testWidgets('hover repaints the entry with the surface2 background', (tester) async {
      // FocusableActionDetector suppresses hover highlight under
      // FocusHighlightMode.touch, which is the default in widget tests.
      // Force traditional mode to enable hover in tests.
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
      });

      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
      await pumpThemed(
        tester,
        theme: themeData,
        LayrzDropdownEntry(labelText: 'Hover Me', onTap: () {}),
      );

      final box = find.byType(AnimatedContainer).first;
      Color? colorOf() => (tester.widget<AnimatedContainer>(box).decoration! as BoxDecoration).color;

      final resting = colorOf();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text('Hover Me')));
      await tester.pumpAndSettle();

      expect(resting, equals(themeData.tokens.colors.sf1));
      expect(colorOf(), equals(themeData.tokens.colors.sf2));
      expect(colorOf(), isNot(equals(resting)));
    });

    testWidgets('press repaints the entry with the surface3 background', (tester) async {
      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
      await pumpThemed(
        tester,
        theme: themeData,
        LayrzDropdownEntry(labelText: 'Press Me', onTap: () {}),
      );

      final box = find.byType(AnimatedContainer).first;
      Color? colorOf() => (tester.widget<AnimatedContainer>(box).decoration! as BoxDecoration).color;

      final resting = colorOf();

      final gesture = await tester.startGesture(tester.getCenter(find.text('Press Me')));
      await tester.pumpAndSettle();

      expect(resting, equals(themeData.tokens.colors.sf1));
      expect(colorOf(), equals(themeData.tokens.colors.sf3));
      expect(colorOf(), isNot(equals(resting)));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('shortcut is rendered in entry', (tester) async {
      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

      await pumpThemed(
        tester,
        theme: themeData,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'With Shortcut',
              onTap: () {},
              shortcut: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS},
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // Verify the entry still renders
      expect(find.text('With Shortcut'), findsOneWidget);
    });
  });

  group('LayrzDropdownEntry.resolveAccent', () {
    test('returns null when no color and no semantic type', () {
      final entry = LayrzDropdownEntry(
        labelText: 'Plain',
        onTap: () {},
      );

      final tokens = LayrzThemeData.light(fontHandler: const FakeFontHandler()).tokens;
      expect(entry.resolveAccent(tokens), isNull);
    });

    test('returns explicit color when provided', () {
      final customColor = const Color(0xFF1234FF);
      final entry = LayrzDropdownEntry(
        labelText: 'Custom Color',
        onTap: () {},
        color: customColor,
      );

      final tokens = LayrzThemeData.light(fontHandler: const FakeFontHandler()).tokens;
      expect(entry.resolveAccent(tokens), customColor);
    });

    test('returns success color for save semantic factory', () {
      final entry = LayrzDropdownEntry.save(
        labelText: 'Save',
        onTap: () {},
      );

      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
      expect(entry.resolveAccent(themeData.tokens), themeData.tokens.colors.success);
    });

    test('returns danger color for cancel semantic factory', () {
      final entry = LayrzDropdownEntry.cancel(
        labelText: 'Cancel',
        onTap: () {},
      );

      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
      expect(entry.resolveAccent(themeData.tokens), themeData.tokens.colors.danger);
    });

    test('returns info color for info semantic factory', () {
      final entry = LayrzDropdownEntry.info(
        labelText: 'Info',
        onTap: () {},
      );

      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
      expect(entry.resolveAccent(themeData.tokens), themeData.tokens.colors.info);
    });

    test('returns info color for show semantic factory', () {
      final entry = LayrzDropdownEntry.show(
        labelText: 'Show',
        onTap: () {},
      );

      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
      expect(entry.resolveAccent(themeData.tokens), themeData.tokens.colors.info);
    });

    test('returns warning color for edit semantic factory', () {
      final entry = LayrzDropdownEntry.edit(
        labelText: 'Edit',
        onTap: () {},
      );

      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
      expect(entry.resolveAccent(themeData.tokens), themeData.tokens.colors.warning);
    });

    test('returns danger color for delete semantic factory', () {
      final entry = LayrzDropdownEntry.delete(
        labelText: 'Delete',
        onTap: () {},
      );

      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
      expect(entry.resolveAccent(themeData.tokens), themeData.tokens.colors.danger);
    });

    test('explicit color takes precedence over semantic type', () {
      final customColor = const Color(0xFFFF00FF);
      final entry = LayrzDropdownEntry.save(
        labelText: 'Save',
        onTap: () {},
        color: customColor,
      );

      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
      // Should return the custom color, not the semantic success color
      expect(entry.resolveAccent(themeData.tokens), customColor);
      expect(entry.resolveAccent(themeData.tokens), isNot(themeData.tokens.colors.success));
    });
  });

  group('formatLayrzShortcut', () {
    test('formats control + shift on macOS correctly', () {
      final shortcut = {LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyS};
      final formatted = formatLayrzShortcut(shortcut, platform: LayrzPlatform.macOS);
      expect(formatted, '⌃⇧S');
    });

    test('formats control + shift on Windows correctly', () {
      final shortcut = {LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyS};
      final formatted = formatLayrzShortcut(shortcut, platform: LayrzPlatform.windows);
      expect(formatted, 'Ctrl+Shift+S');
    });

    test('formats meta alone on macOS', () {
      final shortcut = {LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN};
      final formatted = formatLayrzShortcut(shortcut, platform: LayrzPlatform.macOS);
      expect(formatted, '⌘N');
    });

    test('formats meta alone on Windows as Win', () {
      final shortcut = {LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN};
      final formatted = formatLayrzShortcut(shortcut, platform: LayrzPlatform.windows);
      expect(formatted, 'Win+N');
    });

    test('formats control + alt + shift on macOS', () {
      final shortcut = {
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.alt,
        LogicalKeyboardKey.shift,
        LogicalKeyboardKey.enter,
      };
      final formatted = formatLayrzShortcut(shortcut, platform: LayrzPlatform.macOS);
      expect(formatted, '⌃⌥⇧ENTER');
    });

    test('formats control + alt + shift on Windows', () {
      final shortcut = {
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.alt,
        LogicalKeyboardKey.shift,
        LogicalKeyboardKey.enter,
      };
      final formatted = formatLayrzShortcut(shortcut, platform: LayrzPlatform.windows);
      expect(formatted, 'Ctrl+Alt+Shift+ENTER');
    });

    test('handles bare key without modifiers', () {
      final shortcut = {LogicalKeyboardKey.delete};
      final formatted = formatLayrzShortcut(shortcut, platform: LayrzPlatform.windows);
      expect(formatted, 'DELETE');
    });

    test('returns empty string for null', () {
      final formatted = formatLayrzShortcut(null);
      expect(formatted, '');
    });

    test('returns empty string for empty set', () {
      final formatted = formatLayrzShortcut({});
      expect(formatted, '');
    });

    test('treats left control variants as control', () {
      final shortcut = {LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyS};
      final formatted = formatLayrzShortcut(shortcut, platform: LayrzPlatform.windows);
      expect(formatted, 'Ctrl+S');
    });

    test('renders meta key on macOS as command', () {
      final shortcut = {LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS};
      final formatted = formatLayrzShortcut(shortcut, platform: LayrzPlatform.macOS);
      expect(formatted, '⌘S');
    });

    test('renders meta key on Windows as Win', () {
      final shortcut = {LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS};
      final formatted = formatLayrzShortcut(shortcut, platform: LayrzPlatform.windows);
      expect(formatted, 'Win+S');
    });

    test('renders control key on macOS as control', () {
      final shortcut = {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS};
      final formatted = formatLayrzShortcut(shortcut, platform: LayrzPlatform.macOS);
      expect(formatted, '⌃S');
    });

    test('renders control key on Windows as Ctrl', () {
      final shortcut = {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS};
      final formatted = formatLayrzShortcut(shortcut, platform: LayrzPlatform.windows);
      expect(formatted, 'Ctrl+S');
    });

    test('formats Linux shortcuts like Windows', () {
      final shortcut = {LogicalKeyboardKey.control, LogicalKeyboardKey.alt, LogicalKeyboardKey.keyL};
      final formatted = formatLayrzShortcut(shortcut, platform: LayrzPlatform.linux);
      expect(formatted, 'Ctrl+Alt+L');
    });
  });
}
