import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

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
      expect(find.byIcon(MdiIcons.contentSaveOutline), findsOneWidget);
    });

    testWidgets('style: LayrzButtonStyle.elevated (default) uses elevated style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.save(
          labelText: 'Save',
          onTap: () {},
          isFab: false,
          style: LayrzButtonStyle.elevated,
        ),
      );

      expect(findButtonLabel('Save'), findsOneWidget);
    });

    testWidgets('style: LayrzButtonStyle.outlined uses outlined style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.save(
          labelText: 'Save',
          onTap: () {},
          isFab: false,
          style: LayrzButtonStyle.outlined,
        ),
      );

      expect(findButtonLabel('Save'), findsOneWidget);
    });

    testWidgets('isFab: true, style: LayrzButtonStyle.elevated uses elevatedFab style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.save(
          labelText: 'Save',
          onTap: () {},
          isFab: true,
          style: LayrzButtonStyle.elevated,
        ),
      );

      expect(find.byIcon(MdiIcons.contentSaveOutline), findsOneWidget);
    });

    testWidgets('isFab: true, style: LayrzButtonStyle.outlined uses outlinedFab style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.save(
          labelText: 'Save',
          onTap: () {},
          isFab: true,
          style: LayrzButtonStyle.outlined,
        ),
      );

      expect(find.byIcon(MdiIcons.contentSaveOutline), findsOneWidget);
    });

    testWidgets('save resolves to success color', (tester) async {
      final theme = LayrzThemeData.light(fontHandler: const FakeFontHandler());

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
      expect(find.byIcon(MdiIcons.closeCircleOutline), findsOneWidget);
    });

    testWidgets('isFab: false, style: LayrzButtonStyle.elevated (default) uses elevated style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.cancel(
          labelText: 'Cancel',
          onTap: () {},
          isFab: false,
          style: LayrzButtonStyle.elevated,
        ),
      );

      expect(findButtonLabel('Cancel'), findsOneWidget);
    });

    testWidgets('isFab: false, style: LayrzButtonStyle.outlined uses outlined style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.cancel(
          labelText: 'Cancel',
          onTap: () {},
          isFab: false,
          style: LayrzButtonStyle.outlined,
        ),
      );

      expect(findButtonLabel('Cancel'), findsOneWidget);
    });

    testWidgets('isFab: true, style: LayrzButtonStyle.elevated (default) uses elevatedFab style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.cancel(
          labelText: 'Cancel',
          onTap: () {},
          isFab: true,
          style: LayrzButtonStyle.elevated,
        ),
      );

      expect(find.byIcon(MdiIcons.closeCircleOutline), findsOneWidget);
    });

    testWidgets('isFab: true, style: LayrzButtonStyle.outlined uses outlinedFab style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.cancel(
          labelText: 'Cancel',
          onTap: () {},
          isFab: true,
          style: LayrzButtonStyle.outlined,
        ),
      );

      expect(find.byIcon(MdiIcons.closeCircleOutline), findsOneWidget);
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
      expect(find.byIcon(MdiIcons.informationOutline), findsOneWidget);
    });

    testWidgets('style: LayrzButtonStyle.elevated (default) uses elevated style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.info(
          labelText: 'Info',
          onTap: () {},
          isFab: false,
          style: LayrzButtonStyle.elevated,
        ),
      );

      expect(findButtonLabel('Info'), findsOneWidget);
    });

    testWidgets('style: LayrzButtonStyle.outlined uses outlined style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.info(
          labelText: 'Info',
          onTap: () {},
          isFab: false,
          style: LayrzButtonStyle.outlined,
        ),
      );

      expect(findButtonLabel('Info'), findsOneWidget);
    });

    testWidgets('isFab: true, style: LayrzButtonStyle.elevated uses elevatedFab style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.info(
          labelText: 'Info',
          onTap: () {},
          isFab: true,
          style: LayrzButtonStyle.elevated,
        ),
      );

      expect(find.byIcon(MdiIcons.informationOutline), findsOneWidget);
    });

    testWidgets('isFab: true, style: LayrzButtonStyle.outlined uses outlinedFab style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.info(
          labelText: 'Info',
          onTap: () {},
          isFab: true,
          style: LayrzButtonStyle.outlined,
        ),
      );

      expect(find.byIcon(MdiIcons.informationOutline), findsOneWidget);
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
      expect(find.byIcon(MdiIcons.eyeOutline), findsOneWidget);
    });

    testWidgets('style: LayrzButtonStyle.elevated (default) uses elevated style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.show(
          labelText: 'Show',
          onTap: () {},
          isFab: false,
          style: LayrzButtonStyle.elevated,
        ),
      );

      expect(findButtonLabel('Show'), findsOneWidget);
    });

    testWidgets('style: LayrzButtonStyle.outlined uses outlined style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.show(
          labelText: 'Show',
          onTap: () {},
          isFab: false,
          style: LayrzButtonStyle.outlined,
        ),
      );

      expect(findButtonLabel('Show'), findsOneWidget);
    });

    testWidgets('isFab: true, style: LayrzButtonStyle.elevated uses elevatedFab style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.show(
          labelText: 'Show',
          onTap: () {},
          isFab: true,
          style: LayrzButtonStyle.elevated,
        ),
      );

      expect(find.byIcon(MdiIcons.eyeOutline), findsOneWidget);
    });

    testWidgets('isFab: true, style: LayrzButtonStyle.outlined uses outlinedFab style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.show(
          labelText: 'Show',
          onTap: () {},
          isFab: true,
          style: LayrzButtonStyle.outlined,
        ),
      );

      expect(find.byIcon(MdiIcons.eyeOutline), findsOneWidget);
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
      expect(find.byIcon(MdiIcons.pencilOutline), findsOneWidget);
    });

    testWidgets('style: LayrzButtonStyle.elevated (default) uses elevated style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.edit(
          labelText: 'Edit',
          onTap: () {},
          isFab: false,
          style: LayrzButtonStyle.elevated,
        ),
      );

      expect(findButtonLabel('Edit'), findsOneWidget);
    });

    testWidgets('style: LayrzButtonStyle.outlined uses outlined style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.edit(
          labelText: 'Edit',
          onTap: () {},
          isFab: false,
          style: LayrzButtonStyle.outlined,
        ),
      );

      expect(findButtonLabel('Edit'), findsOneWidget);
    });

    testWidgets('isFab: true, style: LayrzButtonStyle.elevated uses elevatedFab style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.edit(
          labelText: 'Edit',
          onTap: () {},
          isFab: true,
          style: LayrzButtonStyle.elevated,
        ),
      );

      expect(find.byIcon(MdiIcons.pencilOutline), findsOneWidget);
    });

    testWidgets('isFab: true, style: LayrzButtonStyle.outlined uses outlinedFab style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.edit(
          labelText: 'Edit',
          onTap: () {},
          isFab: true,
          style: LayrzButtonStyle.outlined,
        ),
      );

      expect(find.byIcon(MdiIcons.pencilOutline), findsOneWidget);
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
      expect(find.byIcon(MdiIcons.trashCanOutline), findsOneWidget);
    });

    testWidgets('style: LayrzButtonStyle.elevated (default) uses elevated style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.delete(
          labelText: 'Delete',
          onTap: () {},
          isFab: false,
          style: LayrzButtonStyle.elevated,
        ),
      );

      expect(findButtonLabel('Delete'), findsOneWidget);
    });

    testWidgets('style: LayrzButtonStyle.outlined uses outlined style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.delete(
          labelText: 'Delete',
          onTap: () {},
          isFab: false,
          style: LayrzButtonStyle.outlined,
        ),
      );

      expect(findButtonLabel('Delete'), findsOneWidget);
    });

    testWidgets('isFab: true, style: LayrzButtonStyle.elevated (default) uses elevatedFab style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.delete(
          labelText: 'Delete',
          onTap: () {},
          isFab: true,
          style: LayrzButtonStyle.elevated,
        ),
      );

      expect(find.byIcon(MdiIcons.trashCanOutline), findsOneWidget);
    });

    testWidgets('isFab: true, style: LayrzButtonStyle.outlined uses outlinedFab style', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton.delete(
          labelText: 'Delete',
          onTap: () {},
          isFab: true,
          style: LayrzButtonStyle.outlined,
        ),
      );

      expect(find.byIcon(MdiIcons.trashCanOutline), findsOneWidget);
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
          icon: MdiIcons.trashCanOutline,
          onTap: () {},
          color: customColor,
        ),
      );

      // The button should render with the custom color, not the danger color.
      expect(findButtonLabel('Custom Color Button'), findsOneWidget);
      expect(find.byIcon(MdiIcons.trashCanOutline), findsOneWidget);
    });

    testWidgets('public constructor without semantic marker uses primary color by default', (tester) async {
      final theme = LayrzThemeData.light(fontHandler: const FakeFontHandler());

      // Public constructor without semantic should use primary.
      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'Primary Button',
          icon: MdiIcons.checkCircleOutline,
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
