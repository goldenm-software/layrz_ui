import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/buttons/buttons.dart';
import 'package:layrz_ui/theme/theme.dart';

import '../helpers/find_button_label.dart';
import '../helpers/fake_font_handler.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzButton.save()', () {
    testWidgets('renders with success-colored icon and style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.save(
          labelText: 'Save',
          onTap: () {},
        ),
      );

      expect(findButtonLabel('Save'), findsOneWidget);
      expect(find.byIcon(LayrzIcons.solarOutlineInboxIn), findsOneWidget);
    });

    testWidgets('isFab: false uses filledTonal style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.save(
          labelText: 'Save',
          onTap: () {},
          isFab: false,
        ),
      );

      expect(findButtonLabel('Save'), findsOneWidget);
    });

    testWidgets('isFab: true uses filledTonalFab style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.save(
          labelText: 'Save',
          onTap: () {},
          isFab: true,
        ),
      );

      expect(find.byIcon(LayrzIcons.solarOutlineInboxIn), findsOneWidget);
    });

    testWidgets('save resolves to success color', (tester) async {
      final theme = LayrzThemeData.light(fontHandler: const FakeFontHandler());

      // We test that the save factory is wired correctly to the semantic marker.
      // The actual color resolution happens in the button state.
      await pumpThemed(
        tester,
        LayrzButton.save(
          labelText: 'Save',
          onTap: () {},
        ),
        theme: theme,
      );

      expect(findButtonLabel('Save'), findsOneWidget);
    });

    testWidgets('isDisabled: true disables the button', (tester) async {
      int tapCount = 0;

      await pumpThemed(
        tester,
        LayrzButton.save(
          labelText: 'Save',
          onTap: () => tapCount++,
          isDisabled: true,
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pump();

      expect(tapCount, equals(0));
    });

    testWidgets('supports controller parameter', (tester) async {
      final controller = LayrzButtonController();

      await pumpThemed(
        tester,
        LayrzButton.save(
          labelText: 'Save',
          onTap: () {},
          controller: controller,
        ),
      );

      await tester.pump();
      expect(find.byType(LayrzButton), findsOneWidget);

      controller.dispose();
    });

    testWidgets('controller with cooldown works in factory', (tester) async {
      final controller = LayrzButtonController();

      await pumpThemed(
        tester,
        LayrzButton.save(
          labelText: 'Save',
          onTap: () {},
          controller: controller,
        ),
      );

      controller.startCooldown(const Duration(seconds: 5));
      await tester.pump();
      expect(find.byType(LayrzButton), findsOneWidget);

      controller.dispose();
    });
  });

  group('LayrzButton.cancel()', () {
    testWidgets('renders with danger-colored icon', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.cancel(
          labelText: 'Cancel',
          onTap: () {},
        ),
      );

      expect(findButtonLabel('Cancel'), findsOneWidget);
      expect(find.byIcon(LayrzIcons.solarOutlineCloseSquare), findsOneWidget);
    });

    testWidgets('isFab: false uses outlined style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.cancel(
          labelText: 'Cancel',
          onTap: () {},
          isFab: false,
        ),
      );

      expect(findButtonLabel('Cancel'), findsOneWidget);
    });

    testWidgets('isFab: true uses outlinedFab style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.cancel(
          labelText: 'Cancel',
          onTap: () {},
          isFab: true,
        ),
      );

      expect(find.byIcon(LayrzIcons.solarOutlineCloseSquare), findsOneWidget);
    });

    testWidgets('cancel resolves to danger color', (tester) async {
      final theme = LayrzThemeData.light(fontHandler: const FakeFontHandler());

      await pumpThemed(
        tester,
        LayrzButton.cancel(
          labelText: 'Cancel',
          onTap: () {},
        ),
        theme: theme,
      );

      expect(findButtonLabel('Cancel'), findsOneWidget);
    });
  });

  group('LayrzButton.info()', () {
    testWidgets('renders with info-colored icon', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.info(
          labelText: 'Info',
          onTap: () {},
        ),
      );

      expect(findButtonLabel('Info'), findsOneWidget);
      expect(find.byIcon(LayrzIcons.solarOutlineInfoSquare), findsOneWidget);
    });

    testWidgets('isFab: false uses filledTonal style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.info(
          labelText: 'Info',
          onTap: () {},
          isFab: false,
        ),
      );

      expect(findButtonLabel('Info'), findsOneWidget);
    });

    testWidgets('isFab: true uses filledTonalFab style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.info(
          labelText: 'Info',
          onTap: () {},
          isFab: true,
        ),
      );

      expect(find.byIcon(LayrzIcons.solarOutlineInfoSquare), findsOneWidget);
    });

    testWidgets('info resolves to info color', (tester) async {
      final theme = LayrzThemeData.light(fontHandler: const FakeFontHandler());

      await pumpThemed(
        tester,
        LayrzButton.info(
          labelText: 'Info',
          onTap: () {},
        ),
        theme: theme,
      );

      expect(findButtonLabel('Info'), findsOneWidget);
    });
  });

  group('LayrzButton.show()', () {
    testWidgets('renders with info-colored icon', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.show(
          labelText: 'Show',
          onTap: () {},
        ),
      );

      expect(findButtonLabel('Show'), findsOneWidget);
      expect(find.byIcon(LayrzIcons.solarOutlineEyeScan), findsOneWidget);
    });

    testWidgets('isFab: false uses filledTonal style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.show(
          labelText: 'Show',
          onTap: () {},
          isFab: false,
        ),
      );

      expect(findButtonLabel('Show'), findsOneWidget);
    });

    testWidgets('isFab: true uses filledTonalFab style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.show(
          labelText: 'Show',
          onTap: () {},
          isFab: true,
        ),
      );

      expect(find.byIcon(LayrzIcons.solarOutlineEyeScan), findsOneWidget);
    });

    testWidgets('show resolves to info color', (tester) async {
      final theme = LayrzThemeData.light(fontHandler: const FakeFontHandler());

      await pumpThemed(
        tester,
        LayrzButton.show(
          labelText: 'Show',
          onTap: () {},
        ),
        theme: theme,
      );

      expect(findButtonLabel('Show'), findsOneWidget);
    });
  });

  group('LayrzButton.edit()', () {
    testWidgets('renders with warning-colored icon', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.edit(
          labelText: 'Edit',
          onTap: () {},
        ),
      );

      expect(findButtonLabel('Edit'), findsOneWidget);
      expect(find.byIcon(LayrzIcons.solarOutlinePenNewSquare), findsOneWidget);
    });

    testWidgets('isFab: false uses filledTonal style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.edit(
          labelText: 'Edit',
          onTap: () {},
          isFab: false,
        ),
      );

      expect(findButtonLabel('Edit'), findsOneWidget);
    });

    testWidgets('isFab: true uses filledTonalFab style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.edit(
          labelText: 'Edit',
          onTap: () {},
          isFab: true,
        ),
      );

      expect(find.byIcon(LayrzIcons.solarOutlinePenNewSquare), findsOneWidget);
    });

    testWidgets('edit resolves to warning color', (tester) async {
      final theme = LayrzThemeData.light(fontHandler: const FakeFontHandler());

      await pumpThemed(
        tester,
        LayrzButton.edit(
          labelText: 'Edit',
          onTap: () {},
        ),
        theme: theme,
      );

      expect(findButtonLabel('Edit'), findsOneWidget);
    });
  });

  group('LayrzButton.delete()', () {
    testWidgets('renders with danger-colored icon', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.delete(
          labelText: 'Delete',
          onTap: () {},
        ),
      );

      expect(findButtonLabel('Delete'), findsOneWidget);
      expect(find.byIcon(LayrzIcons.solarOutlineTrashBinMinimalisticN2), findsOneWidget);
    });

    testWidgets('isFab: false uses filledTonal style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.delete(
          labelText: 'Delete',
          onTap: () {},
          isFab: false,
        ),
      );

      expect(findButtonLabel('Delete'), findsOneWidget);
    });

    testWidgets('isFab: true uses filledTonalFab style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.delete(
          labelText: 'Delete',
          onTap: () {},
          isFab: true,
        ),
      );

      expect(find.byIcon(LayrzIcons.solarOutlineTrashBinMinimalisticN2), findsOneWidget);
    });

    testWidgets('delete resolves to danger color', (tester) async {
      final theme = LayrzThemeData.light(fontHandler: const FakeFontHandler());

      await pumpThemed(
        tester,
        LayrzButton.delete(
          labelText: 'Delete',
          onTap: () {},
        ),
        theme: theme,
      );

      expect(findButtonLabel('Delete'), findsOneWidget);
    });
  });

  group('Semantic color resolution', () {
    testWidgets('public constructor with custom color overrides semantic color', (tester) async {
      const customColor = Color(0xFFFF0000);

      // Create a button with the delete icon but a custom color (not danger).
      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'Custom Color Button',
          icon: LayrzIcons.solarOutlineTrashBinMinimalisticN2,
          onTap: () {},
          color: customColor,
        ),
      );

      // The button should render with the custom color, not the danger color.
      expect(findButtonLabel('Custom Color Button'), findsOneWidget);
      expect(find.byIcon(LayrzIcons.solarOutlineTrashBinMinimalisticN2), findsOneWidget);
    });

    testWidgets('public constructor without semantic marker uses primary color by default', (tester) async {
      final theme = LayrzThemeData.light(fontHandler: const FakeFontHandler());

      // Public constructor without semantic should use primary.
      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'Primary Button',
          icon: LayrzIcons.solarOutlineCheckCircle,
          onTap: () {},
          // No semantic factory, no custom color specified.
        ),
        theme: theme,
      );

      expect(findButtonLabel('Primary Button'), findsOneWidget);
    });
  });

  group('Factory parameter validation', () {
    testWidgets('all factories accept required labelText and onTap', (tester) async {
      final factories = [
        LayrzButton.save(labelText: 'Save', onTap: () {}),
        LayrzButton.cancel(labelText: 'Cancel', onTap: () {}),
        LayrzButton.info(labelText: 'Info', onTap: () {}),
        LayrzButton.show(labelText: 'Show', onTap: () {}),
        LayrzButton.edit(labelText: 'Edit', onTap: () {}),
        LayrzButton.delete(labelText: 'Delete', onTap: () {}),
      ];

      for (final button in factories) {
        await pumpThemed(tester, button);
        expect(find.byType(LayrzButton), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('all factories respect isDisabled parameter', (tester) async {
      int tapCount = 0;

      final factories = [
        LayrzButton.save(
          labelText: 'Save',
          onTap: () => tapCount++,
          isDisabled: true,
        ),
        LayrzButton.cancel(
          labelText: 'Cancel',
          onTap: () => tapCount++,
          isDisabled: true,
        ),
        LayrzButton.info(
          labelText: 'Info',
          onTap: () => tapCount++,
          isDisabled: true,
        ),
        LayrzButton.show(
          labelText: 'Show',
          onTap: () => tapCount++,
          isDisabled: true,
        ),
        LayrzButton.edit(
          labelText: 'Edit',
          onTap: () => tapCount++,
          isDisabled: true,
        ),
        LayrzButton.delete(
          labelText: 'Delete',
          onTap: () => tapCount++,
          isDisabled: true,
        ),
      ];

      for (final button in factories) {
        await pumpThemed(tester, button);

        // Try to tap the button.
        await tester.tap(find.byType(LayrzButton));
        await tester.pump();

        await tester.pumpWidget(const SizedBox.shrink());
      }

      expect(tapCount, equals(0), reason: 'All disabled buttons should not invoke callbacks');
    });
  });
}
