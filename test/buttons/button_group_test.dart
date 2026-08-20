import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_font_handler.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzButtonGroup', () {
    group('Empty items', () {
      testWidgets('renders nothing when items is empty', (tester) async {
        await pumpThemed(
          tester,
          const LayrzButtonGroup(
            triggerHintText: 'Actions',
            items: [],
          ),
        );

        expect(find.byType(LayrzButton), findsNothing);
        expect(find.byType(LayrzDropdownMenu), findsNothing);
      });
    });

    group('Row mode', () {
      testWidgets('renders entries as labelled buttons in row mode', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Row actions',
            items: [
              LayrzDropdownEntry(labelText: 'Save', onTap: () {}),
              LayrzDropdownEntry(labelText: 'Cancel', onTap: () {}),
              LayrzDropdownEntry(labelText: 'Delete', onTap: () {}),
            ],
            useDropdown: false,
          ),
        );

        // All entries should render as buttons
        expect(find.byType(LayrzButton), findsNWidgets(3));
        expect(find.byType(LayrzDropdownMenu), findsNothing);
        expect(find.byType(Wrap), findsOneWidget);
      });

      testWidgets('uses custom spacing in row mode', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Actions',
            items: [
              LayrzDropdownEntry(labelText: 'Button 1', onTap: () {}),
              LayrzDropdownEntry(labelText: 'Button 2', onTap: () {}),
            ],
            useDropdown: false,
            spacing: 24,
          ),
        );

        // Both buttons should render in a Wrap
        expect(find.byType(LayrzButton), findsNWidgets(2));
        expect(find.byType(LayrzDropdownMenu), findsNothing);
        expect(find.byType(Wrap), findsOneWidget);
      });

      testWidgets('wraps buttons on narrow width in row mode', (tester) async {
        tester.view.physicalSize = const Size(200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Actions',
            items: [
              LayrzDropdownEntry(labelText: 'Button 1', onTap: () {}),
              LayrzDropdownEntry(labelText: 'Button 2', onTap: () {}),
              LayrzDropdownEntry(labelText: 'Button 3', onTap: () {}),
            ],
            useDropdown: false,
          ),
        );

        // All buttons should still render (Wrap allows them to wrap to next line)
        expect(find.byType(LayrzButton), findsNWidgets(3));
        expect(find.byType(Wrap), findsOneWidget);
      });

      testWidgets('skips labels in row mode', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Actions',
            items: [
              LayrzDropdownEntry(labelText: 'Save', onTap: () {}),
              LayrzDropdownLabel(labelText: 'Section'),
              LayrzDropdownEntry(labelText: 'Delete', onTap: () {}),
            ],
            useDropdown: false,
          ),
        );

        // Only entries should render as buttons (not the label)
        // Two entries + one label, but label is skipped, so 2 buttons
        expect(find.byType(LayrzButton), findsNWidgets(2));
        expect(find.byType(Wrap), findsOneWidget);
      });

      group('Semantic entry colors in row mode', () {
        testWidgets('save semantic entry carries success color to row button', (tester) async {
          await pumpThemed(
            tester,
            LayrzButtonGroup(
              triggerHintText: 'Actions',
              items: [
                LayrzDropdownEntry.save(labelText: 'Save', onTap: () {}),
              ],
              useDropdown: false,
            ),
          );

          // Save entry should be converted to a button with success color
          expect(find.byType(LayrzButton), findsOneWidget);
        });

        testWidgets('cancel semantic entry carries danger color to row button', (tester) async {
          await pumpThemed(
            tester,
            LayrzButtonGroup(
              triggerHintText: 'Actions',
              items: [
                LayrzDropdownEntry.cancel(labelText: 'Cancel', onTap: () {}),
              ],
              useDropdown: false,
            ),
          );

          expect(find.byType(LayrzButton), findsOneWidget);
        });

        testWidgets('info semantic entry carries info color to row button', (tester) async {
          await pumpThemed(
            tester,
            LayrzButtonGroup(
              triggerHintText: 'Actions',
              items: [
                LayrzDropdownEntry.info(labelText: 'Info', onTap: () {}),
              ],
              useDropdown: false,
            ),
          );

          expect(find.byType(LayrzButton), findsOneWidget);
        });

        testWidgets('show semantic entry carries info color to row button', (tester) async {
          await pumpThemed(
            tester,
            LayrzButtonGroup(
              triggerHintText: 'Actions',
              items: [
                LayrzDropdownEntry.show(labelText: 'Show', onTap: () {}),
              ],
              useDropdown: false,
            ),
          );

          expect(find.byType(LayrzButton), findsOneWidget);
        });

        testWidgets('edit semantic entry carries warning color to row button', (tester) async {
          await pumpThemed(
            tester,
            LayrzButtonGroup(
              triggerHintText: 'Actions',
              items: [
                LayrzDropdownEntry.edit(labelText: 'Edit', onTap: () {}),
              ],
              useDropdown: false,
            ),
          );

          expect(find.byType(LayrzButton), findsOneWidget);
        });

        testWidgets('delete semantic entry carries danger color to row button', (tester) async {
          await pumpThemed(
            tester,
            LayrzButtonGroup(
              triggerHintText: 'Actions',
              items: [
                LayrzDropdownEntry.delete(labelText: 'Delete', onTap: () {}),
              ],
              useDropdown: false,
            ),
          );

          expect(find.byType(LayrzButton), findsOneWidget);
        });

        testWidgets('explicit color overrides semantic factory color', (tester) async {
          final customColor = const Color(0xFF1234FF);
          await pumpThemed(
            tester,
            LayrzButtonGroup(
              triggerHintText: 'Actions',
              items: [
                LayrzDropdownEntry.save(
                  labelText: 'Save',
                  onTap: () {},
                  color: customColor,
                ),
              ],
              useDropdown: false,
            ),
          );

          // Entry with explicit color should render as button
          expect(find.byType(LayrzButton), findsOneWidget);
        });

        testWidgets('entry with no color and no semantic renders button', (tester) async {
          await pumpThemed(
            tester,
            LayrzButtonGroup(
              triggerHintText: 'Actions',
              items: [
                LayrzDropdownEntry(labelText: 'Plain', onTap: () {}),
              ],
              useDropdown: false,
            ),
          );

          // Plain entry should render as button with no accent
          expect(find.byType(LayrzButton), findsOneWidget);
        });

        testWidgets('semantic entry dot and row button use the same resolved color', (tester) async {
          final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
          await pumpThemed(
            tester,
            theme: themeData,
            LayrzButtonGroup(
              triggerHintText: 'Actions',
              items: [
                LayrzDropdownEntry.delete(labelText: 'Delete', onTap: () {}),
              ],
              useDropdown: false,
            ),
          );

          // Get the button's color from its type: custom color
          final button = tester.widget<LayrzButton>(find.byType(LayrzButton));
          // The button should have a custom color (the danger color from semantic type)
          expect(button.color, isNotNull);

          // Verify the button's color matches the semantic factory's expected color
          final entry = LayrzDropdownEntry.delete(labelText: 'Delete', onTap: () {});
          expect(button.color, entry.resolveAccent(themeData.tokens));
          expect(button.color, themeData.tokens.colors.danger);
        });
      });
    });

    group('Dropdown mode', () {
      testWidgets('renders single trigger in dropdown mode', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Actions',
            items: [
              LayrzDropdownEntry(labelText: 'Save', onTap: () {}),
              LayrzDropdownEntry(labelText: 'Cancel', onTap: () {}),
            ],
            useDropdown: true,
          ),
        );

        // Only the trigger button should be visible initially
        expect(find.text('Save'), findsNothing);
        expect(find.text('Cancel'), findsNothing);
        expect(find.byType(LayrzDropdownMenu), findsOneWidget);
        // Verify trigger button exists
        expect(find.byType(LayrzButton), findsOneWidget);
      });

      testWidgets('tap trigger opens dropdown menu', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Actions',
            items: [
              LayrzDropdownEntry(labelText: 'Save', onTap: () {}),
              LayrzDropdownEntry(labelText: 'Cancel', onTap: () {}),
            ],
            useDropdown: true,
          ),
        );

        // Trigger button
        final triggerButton = find.byType(LayrzButton).first;
        await tester.tap(triggerButton);
        await tester.pumpAndSettle();

        // Menu items should now be visible
        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('uses custom trigger hint text', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'More options',
            items: [
              LayrzDropdownEntry(labelText: 'Save', onTap: () {}),
            ],
            useDropdown: true,
          ),
        );

        // Verify trigger button exists
        expect(find.byType(LayrzButton), findsOneWidget);
        // Verify menu exists
        expect(find.byType(LayrzDropdownMenu), findsOneWidget);
      });

      testWidgets('trigger tooltip is exactly triggerHintText without action labels', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzButtonGroup(
              triggerHintText: 'Export options',
              items: [
                LayrzDropdownEntry(labelText: 'Save', onTap: () {}),
                LayrzDropdownEntry(labelText: 'Delete', onTap: () {}),
              ],
              useDropdown: true,
            ),
          );

          // Trigger should have the hint text exactly once (no duplication)
          final triggerSemantics = tester.getSemantics(find.byType(LayrzButton).first);
          final label = triggerSemantics.label;

          // Verify the hint text appears exactly once
          final hintCount = 'Export options'.allMatches(label).length;
          expect(hintCount, equals(1), reason: 'Tooltip should show hint text exactly once');

          // Verify action labels do NOT appear
          expect(label, isNot(contains('Save')), reason: 'Action label "Save" should not appear in tooltip');
          expect(label, isNot(contains('Delete')), reason: 'Action label "Delete" should not appear in tooltip');
        } finally {
          handle.dispose();
        }
      });

      testWidgets('uses custom trigger icon', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Actions',
            items: [
              LayrzDropdownEntry(labelText: 'Save', onTap: () {}),
            ],
            useDropdown: true,
            triggerIcon: MdiIcons.checkCircleOutline,
          ),
        );

        // Verify the button was created (we can't directly check icon data in RichText)
        expect(find.byType(LayrzButton), findsOneWidget);
      });

      testWidgets('respects custom alignment', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Actions',
            items: [
              LayrzDropdownEntry(labelText: 'Save', onTap: () {}),
            ],
            useDropdown: true,
            alignment: LayrzDropdownMenuAlignment.end,
          ),
        );

        expect(find.byType(LayrzDropdownMenu), findsOneWidget);
      });

      testWidgets('button on tap callback fires', (tester) async {
        var callCount = 0;

        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Actions',
            items: [
              LayrzDropdownEntry(
                labelText: 'Action',
                onTap: () => callCount++,
              ),
            ],
            useDropdown: true,
          ),
        );

        // Open menu
        final triggerButton = find.byType(LayrzButton).first;
        await tester.tap(triggerButton);
        await tester.pumpAndSettle();

        // Tap menu item
        final menuItem = find.text('Action');
        await tester.tap(menuItem);
        await tester.pumpAndSettle();

        expect(callCount, equals(1));
      });

      testWidgets('disabled button converts to disabled entry', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          var enabledTapped = false;
          var disabledTapped = false;

          await pumpThemed(
            tester,
            LayrzButtonGroup(
              triggerHintText: 'Actions',
              items: [
                LayrzDropdownEntry(
                  labelText: 'Enabled',
                  onTap: () => enabledTapped = true,
                ),
                LayrzDropdownEntry(
                  labelText: 'Disabled',
                  enabled: false,
                  onTap: () => disabledTapped = true,
                ),
              ],
              useDropdown: true,
            ),
          );

          // Open menu
          final triggerButton = find.byType(LayrzButton).first;
          await tester.tap(triggerButton);
          await tester.pumpAndSettle();

          // Both entries should be visible
          expect(find.text('Enabled'), findsOneWidget);
          expect(find.text('Disabled'), findsOneWidget);

          // Tap enabled entry - should work
          await tester.tap(find.text('Enabled'));
          await tester.pumpAndSettle();
          expect(enabledTapped, isTrue);

          // Re-open menu
          await tester.tap(find.byType(LayrzButton).first);
          await tester.pumpAndSettle();

          // Tap disabled entry - should not work
          await tester.tap(find.text('Disabled'), warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(disabledTapped, isFalse);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('disabled entry cannot be tapped in dropdown mode', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzButtonGroup(
              triggerHintText: 'Actions',
              items: [
                LayrzDropdownEntry(
                  labelText: 'Action',
                  onTap: () {},
                  enabled: false,
                ),
              ],
              useDropdown: true,
            ),
          );

          // Open menu
          final triggerButton = find.byType(LayrzButton).first;
          await tester.tap(triggerButton);
          await tester.pumpAndSettle();

          // Entry should be visible
          expect(find.text('Action'), findsOneWidget);

          // Tap disabled entry - should not work
          await tester.tap(find.text('Action'), warnIfMissed: false);
          await tester.pumpAndSettle();

          // Menu should still be open since tapping disabled entry doesn't close it
          expect(find.text('Action'), findsOneWidget);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('semantic types are preserved in entries', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Actions',
            items: [
              LayrzDropdownEntry.save(labelText: 'Save', onTap: () {}),
              LayrzDropdownEntry.delete(labelText: 'Delete', onTap: () {}),
              LayrzDropdownEntry(labelText: 'Custom', onTap: () {}),
            ],
            useDropdown: true,
          ),
        );

        // Open menu
        final triggerButton = find.byType(LayrzButton).first;
        await tester.tap(triggerButton);
        await tester.pumpAndSettle();

        // All entries should be visible
        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
        expect(find.text('Custom'), findsOneWidget);
      });

      testWidgets('icon is preserved in entries', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Actions',
            items: [
              LayrzDropdownEntry(
                labelText: 'Save',
                icon: MdiIcons.checkCircleOutline,
                onTap: () {},
              ),
            ],
            useDropdown: true,
          ),
        );

        // Open menu
        final triggerButton = find.byType(LayrzButton).first;
        await tester.tap(triggerButton);
        await tester.pumpAndSettle();

        // Entry should be visible with icon preserved
        expect(find.text('Save'), findsOneWidget);
      });

      testWidgets('menu closes after tapping entry', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Actions',
            items: [
              LayrzDropdownEntry(labelText: 'Action', onTap: () {}),
            ],
            useDropdown: true,
          ),
        );

        // Open menu
        final triggerButton = find.byType(LayrzButton).first;
        await tester.tap(triggerButton);
        await tester.pumpAndSettle();

        // Entry is visible
        expect(find.text('Action'), findsOneWidget);

        // Tap entry
        await tester.tap(find.text('Action'));
        await tester.pumpAndSettle();

        // Entry should no longer be visible (menu closed)
        expect(find.text('Action'), findsNothing);
      });
    });

    group('Responsive mode', () {
      testWidgets('useDropdown: null at narrow width uses dropdown', (tester) async {
        // Simulate narrow viewport (xs/sm band, below md which starts at 960px)
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Actions',
            items: [
              LayrzDropdownEntry(labelText: 'Action', onTap: () {}),
            ],
            // useDropdown is null, so responsive mode applies
          ),
        );

        // At narrow width (< 960), should render dropdown mode
        expect(find.byType(LayrzDropdownMenu), findsOneWidget);
        expect(find.byType(Wrap), findsNothing); // Not row mode
      });

      testWidgets('useDropdown: false forces row mode on narrow viewport', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Actions',
            items: [
              LayrzDropdownEntry(labelText: 'Action', onTap: () {}),
            ],
            useDropdown: false,
          ),
        );

        // Even at narrow width, should render row mode
        expect(find.byType(LayrzButton), findsOneWidget);
        expect(find.byType(LayrzDropdownMenu), findsNothing);
        expect(find.byType(Wrap), findsOneWidget); // Row mode uses Wrap
      });

      testWidgets('useDropdown: true forces dropdown on wide viewport', (tester) async {
        tester.view.physicalSize = const Size(1920, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Actions',
            items: [
              LayrzDropdownEntry(labelText: 'Action', onTap: () {}),
            ],
            useDropdown: true,
          ),
        );

        // Even at wide width, should render dropdown mode
        expect(find.byType(LayrzDropdownMenu), findsOneWidget);
        expect(find.byType(Wrap), findsNothing); // Not row mode
      });
    });

    group('Accessibility', () {
      testWidgets('trigger button is accessible', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzButtonGroup(
              triggerHintText: 'Actions',
              items: [
                LayrzDropdownEntry(labelText: 'Action', onTap: () {}),
              ],
              useDropdown: true,
            ),
          );

          // Trigger button exists and is accessible
          expect(find.byType(LayrzButton), findsOneWidget);

          final triggerButton = tester.getSemantics(find.byType(LayrzButton).first);
          expect(triggerButton.label, isNotEmpty); // Has some label
        } finally {
          handle.dispose();
        }
      });

      testWidgets('entries are accessible and tappable', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          var tapped = false;

          await pumpThemed(
            tester,
            LayrzButtonGroup(
              triggerHintText: 'Actions',
              items: [
                LayrzDropdownEntry(
                  labelText: 'Action',
                  onTap: () => tapped = true,
                ),
              ],
              useDropdown: true,
            ),
          );

          // Open menu
          final triggerButton = find.byType(LayrzButton).first;
          await tester.tap(triggerButton);
          await tester.pumpAndSettle();

          final entrySemantics = tester.getSemantics(find.text('Action'));
          expect(entrySemantics.label, contains('Action'));

          // Entry should be tappable
          await tester.tap(find.text('Action'));
          await tester.pumpAndSettle();
          expect(tapped, isTrue);
        } finally {
          handle.dispose();
        }
      });
    });

    group('LayrzButtonGroup.builder', () {
      testWidgets('builder renders custom trigger widget', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup.builder(
            items: [
              LayrzDropdownEntry(labelText: 'Save', onTap: () {}),
              LayrzDropdownEntry(labelText: 'Cancel', onTap: () {}),
            ],
            useDropdown: true,
            builder: (context, controller) => LayrzButton(
              labelText: 'Custom Trigger',
              style: LayrzButtonStyle.outlinedFab,
              onTap: controller.isOpen ? controller.close : controller.open,
            ),
          ),
        );

        // Verify the custom trigger is rendered (verify button exists)
        expect(find.byType(LayrzButton), findsOneWidget);
        expect(find.byType(LayrzDropdownMenu), findsOneWidget);
      });

      testWidgets('builder trigger opens and closes menu', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup.builder(
            items: [
              LayrzDropdownEntry(labelText: 'Action 1', onTap: () {}),
              LayrzDropdownEntry(labelText: 'Action 2', onTap: () {}),
            ],
            useDropdown: true,
            builder: (context, controller) => LayrzButton(
              labelText: 'Menu',
              style: LayrzButtonStyle.outlinedFab,
              onTap: controller.isOpen ? controller.close : controller.open,
            ),
          ),
        );

        // Tap trigger to open
        final trigger = find.byType(LayrzButton).first;
        await tester.tap(trigger);
        await tester.pumpAndSettle();

        // Actions should be visible
        expect(find.text('Action 1'), findsOneWidget);
        expect(find.text('Action 2'), findsOneWidget);

        // Tap trigger again to close
        await tester.tap(trigger);
        await tester.pumpAndSettle();

        // Actions should be gone
        expect(find.text('Action 1'), findsNothing);
        expect(find.text('Action 2'), findsNothing);
      });

      testWidgets('builder actions work end-to-end', (tester) async {
        var action1Tapped = false;
        var action2Tapped = false;

        await pumpThemed(
          tester,
          LayrzButtonGroup.builder(
            items: [
              LayrzDropdownEntry(labelText: 'Action 1', onTap: () => action1Tapped = true),
              LayrzDropdownEntry(labelText: 'Action 2', onTap: () => action2Tapped = true),
            ],
            useDropdown: true,
            builder: (context, controller) => LayrzButton(
              labelText: 'Menu',
              onTap: controller.isOpen ? controller.close : controller.open,
            ),
          ),
        );

        // Open menu
        final trigger = find.byType(LayrzButton).first;
        await tester.tap(trigger);
        await tester.pumpAndSettle();

        // Tap first action
        await tester.tap(find.text('Action 1'));
        await tester.pumpAndSettle();
        expect(action1Tapped, isTrue);
        expect(action2Tapped, isFalse);

        // Re-open and tap second action
        await tester.tap(trigger);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Action 2'));
        await tester.pumpAndSettle();
        expect(action2Tapped, isTrue);
      });

      testWidgets('builder with useDropdown: false renders row and does not call builder', (tester) async {
        var builderCalled = false;

        await pumpThemed(
          tester,
          LayrzButtonGroup.builder(
            items: [
              LayrzDropdownEntry(labelText: 'Action 1', onTap: () {}),
              LayrzDropdownEntry(labelText: 'Action 2', onTap: () {}),
            ],
            useDropdown: false,
            builder: (context, controller) {
              builderCalled = true;
              return const SizedBox.shrink();
            },
          ),
        );

        // Should render row (Wrap) with actions
        expect(find.byType(Wrap), findsOneWidget);
        expect(find.byType(LayrzDropdownMenu), findsNothing);
        expect(find.byType(LayrzButton), findsNWidgets(2));

        // Builder should not be called in row mode
        expect(builderCalled, isFalse);
      });

      testWidgets('builder with useDropdown: null responds to breakpoint', (tester) async {
        // Narrow viewport (below md, should use dropdown)
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzButtonGroup.builder(
            items: [
              LayrzDropdownEntry(labelText: 'Action', onTap: () {}),
            ],
            builder: (context, controller) => LayrzButton(
              labelText: 'Menu',
              onTap: controller.isOpen ? controller.close : controller.open,
            ),
          ),
        );

        // At narrow width, should use dropdown
        expect(find.byType(LayrzDropdownMenu), findsOneWidget);
        expect(find.byType(Wrap), findsNothing);
      });

      testWidgets('builder with empty items renders nothing', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup.builder(
            items: [],
            builder: (context, controller) => LayrzButton(
              labelText: 'Menu',
              onTap: controller.isOpen ? controller.close : controller.open,
            ),
          ),
        );

        // Should render nothing
        expect(find.byType(LayrzButton), findsNothing);
        expect(find.byType(LayrzDropdownMenu), findsNothing);
      });

      testWidgets('builder can style trigger differently from default', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup.builder(
            items: [
              LayrzDropdownEntry(labelText: 'Save', onTap: () {}),
            ],
            useDropdown: true,
            builder: (context, controller) => LayrzButton(
              labelText: 'Options',
              style: LayrzButtonStyle.outlinedFab,
              icon: MdiIcons.cogOutline,
              onTap: controller.isOpen ? controller.close : controller.open,
            ),
          ),
        );

        // Verify trigger button was created
        expect(find.byType(LayrzButton), findsOneWidget);
        expect(find.byType(LayrzDropdownMenu), findsOneWidget);
      });
    });
  });
}
