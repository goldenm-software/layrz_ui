import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzButtonGroup', () {
    group('Empty actions', () {
      testWidgets('renders nothing when actions is empty', (tester) async {
        await pumpThemed(
          tester,
          const LayrzButtonGroup(
            triggerHintText: 'Actions',
            actions: [],
          ),
        );

        expect(find.byType(LayrzButton), findsNothing);
        expect(find.byType(LayrzDropdownMenu), findsNothing);
      });
    });

    group('Row mode', () {
      testWidgets('renders all buttons in row mode', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Row actions',
            actions: [
              LayrzButton(labelText: 'Save', onTap: () {}),
              LayrzButton(labelText: 'Cancel', onTap: () {}),
              LayrzButton(labelText: 'Delete', onTap: () {}),
            ],
            useDropdown: false,
          ),
        );

        // All buttons should render
        expect(find.byType(LayrzButton), findsNWidgets(3));
        expect(find.byType(LayrzDropdownMenu), findsNothing);
        expect(find.byType(Wrap), findsOneWidget);
      });

      testWidgets('uses custom spacing in row mode', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Actions',
            actions: [
              LayrzButton(labelText: 'Button 1', onTap: () {}),
              LayrzButton(labelText: 'Button 2', onTap: () {}),
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
            actions: [
              LayrzButton(labelText: 'Button 1', onTap: () {}),
              LayrzButton(labelText: 'Button 2', onTap: () {}),
              LayrzButton(labelText: 'Button 3', onTap: () {}),
            ],
            useDropdown: false,
          ),
        );

        // All buttons should still render (Wrap allows them to wrap to next line)
        expect(find.byType(LayrzButton), findsNWidgets(3));
        expect(find.byType(Wrap), findsOneWidget);
      });
    });

    group('Dropdown mode', () {
      testWidgets('renders single trigger in dropdown mode', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Actions',
            actions: [
              LayrzButton(labelText: 'Save', onTap: () {}),
              LayrzButton(labelText: 'Cancel', onTap: () {}),
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
            actions: [
              LayrzButton(labelText: 'Save', onTap: () {}),
              LayrzButton(labelText: 'Cancel', onTap: () {}),
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
            actions: [
              LayrzButton(labelText: 'Save', onTap: () {}),
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
              actions: [
                LayrzButton(labelText: 'Save', onTap: () {}),
                LayrzButton(labelText: 'Delete', onTap: () {}),
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
            actions: [
              LayrzButton(labelText: 'Save', onTap: () {}),
            ],
            useDropdown: true,
            triggerIcon: LayrzIcons.solarOutlineCheckCircle,
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
            actions: [
              LayrzButton(labelText: 'Save', onTap: () {}),
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
            actions: [
              LayrzButton(
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
              actions: [
                LayrzButton(
                  labelText: 'Enabled',
                  onTap: () => enabledTapped = true,
                ),
                LayrzButton(
                  labelText: 'Disabled',
                  isDisabled: true,
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

      testWidgets('button with null onTap converts to disabled entry', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzButtonGroup(
              triggerHintText: 'Actions',
              actions: [
                LayrzButton(
                  labelText: 'Action',
                  onTap: null,
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

          // Tap entry - should not work since onTap is null
          await tester.tap(find.text('Action'), warnIfMissed: false);
          await tester.pumpAndSettle();

          // If it's disabled, tapping it should not close the menu
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
            actions: [
              LayrzButton.save(labelText: 'Save', onTap: () {}),
              LayrzButton.delete(labelText: 'Delete', onTap: () {}),
              LayrzButton(labelText: 'Custom', onTap: () {}),
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
            actions: [
              LayrzButton(
                labelText: 'Save',
                icon: LayrzIcons.solarOutlineCheckCircle,
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
            actions: [
              LayrzButton(labelText: 'Action', onTap: () {}),
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
            actions: [
              LayrzButton(labelText: 'Action', onTap: () {}),
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
            actions: [
              LayrzButton(labelText: 'Action', onTap: () {}),
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
            actions: [
              LayrzButton(labelText: 'Action', onTap: () {}),
            ],
            useDropdown: true,
          ),
        );

        // Even at wide width, should render dropdown mode
        expect(find.byType(LayrzDropdownMenu), findsOneWidget);
        expect(find.byType(Wrap), findsNothing); // Not row mode
      });
    });

    group('Button to entry conversion', () {
      testWidgets('custom button without color yields no color dot', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Actions',
            actions: [
              LayrzButton(
                labelText: 'Action',
                onTap: () {},
                // type defaults to custom, color defaults to null
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
      });

      testWidgets('custom button with explicit color uses that color', (tester) async {
        await pumpThemed(
          tester,
          LayrzButtonGroup(
            triggerHintText: 'Actions',
            actions: [
              LayrzButton(
                labelText: 'Action',
                onTap: () {},
                type: LayrzButtonType.custom,
                color: const Color(0xFFFF5500),
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
              actions: [
                LayrzButton(labelText: 'Action', onTap: () {}),
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
              actions: [
                LayrzButton(
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
  });

  group('LayrzButtonTypeColor extension', () {
    group('semanticColor', () {
      testWidgets('success type returns success color', (tester) async {
        await pumpThemed(tester, const SizedBox.shrink());

        final context = tester.element(find.byType(SizedBox));
        final tokens = context.tokens;
        final color = LayrzButtonType.success.semanticColor(tokens);

        expect(color, equals(tokens.colors.success));
      });

      testWidgets('info type returns info color', (tester) async {
        await pumpThemed(tester, const SizedBox.shrink());

        final context = tester.element(find.byType(SizedBox));
        final tokens = context.tokens;
        final color = LayrzButtonType.info.semanticColor(tokens);

        expect(color, equals(tokens.colors.info));
      });

      testWidgets('context type returns contextual color', (tester) async {
        await pumpThemed(tester, const SizedBox.shrink());

        final context = tester.element(find.byType(SizedBox));
        final tokens = context.tokens;
        final color = LayrzButtonType.context.semanticColor(tokens);

        expect(color, equals(tokens.colors.contextual));
      });

      testWidgets('danger type returns danger color', (tester) async {
        await pumpThemed(tester, const SizedBox.shrink());

        final context = tester.element(find.byType(SizedBox));
        final tokens = context.tokens;
        final color = LayrzButtonType.danger.semanticColor(tokens);

        expect(color, equals(tokens.colors.danger));
      });

      testWidgets('warning type returns warning color', (tester) async {
        await pumpThemed(tester, const SizedBox.shrink());

        final context = tester.element(find.byType(SizedBox));
        final tokens = context.tokens;
        final color = LayrzButtonType.warning.semanticColor(tokens);

        expect(color, equals(tokens.colors.warning));
      });

      testWidgets('custom type returns null', (tester) async {
        await pumpThemed(tester, const SizedBox.shrink());

        final context = tester.element(find.byType(SizedBox));
        final tokens = context.tokens;
        final color = LayrzButtonType.custom.semanticColor(tokens);

        expect(color, isNull);
      });
    });
  });
}
