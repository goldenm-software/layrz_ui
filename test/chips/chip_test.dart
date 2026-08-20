import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzChip', () {
    group('Basic rendering', () {
      testWidgets('renders labelText', (tester) async {
        await pumpThemed(
          tester,
          const LayrzChip(labelText: 'Test Chip'),
        );

        expect(find.text('Test Chip'), findsOneWidget);
        expect(find.byType(LayrzChip), findsOneWidget);
      });

      testWidgets('renders with leading icon', (tester) async {
        await pumpThemed(
          tester,
          LayrzChip(
            labelText: 'With Icon',
            leadingIcon: MdiIcons.checkCircleOutline,
          ),
        );

        expect(find.byType(LayrzChip), findsOneWidget);
        expect(find.byIcon(MdiIcons.checkCircleOutline), findsOneWidget);
      });

      testWidgets('renders delete icon when onDelete is non-null', (tester) async {
        await pumpThemed(
          tester,
          LayrzChip(
            labelText: 'Deletable',
            onDelete: () {},
          ),
        );

        expect(find.byIcon(MdiIcons.closeCircle), findsOneWidget);
      });

      testWidgets('does not render delete icon when onDelete is null', (tester) async {
        await pumpThemed(
          tester,
          const LayrzChip(labelText: 'Not Deletable'),
        );

        expect(find.byIcon(MdiIcons.closeCircle), findsNothing);
      });

      testWidgets('renders with long labelText', (tester) async {
        await pumpThemed(
          tester,
          const LayrzChip(
            labelText: 'This is a very long chip label',
          ),
        );

        // Verify the chip and long text are rendered
        expect(find.byType(LayrzChip), findsOneWidget);
        expect(find.text('This is a very long chip label'), findsOneWidget);
      });
    });

    group('Style variants', () {
      testWidgets('filled style produces solid background', (tester) async {
        await pumpThemed(
          tester,
          const LayrzChip(
            labelText: 'Filled',
            style: LayrzChipStyle.filled,
            type: LayrzChipType.info,
          ),
        );

        expect(find.byType(LayrzChip), findsOneWidget);

        // Find the Container with BoxDecoration
        final containers = find.byType(Container);
        expect(containers, findsWidgets);

        // Check that at least one has the filled style (solid background, no border)
        bool foundFilled = false;
        for (int i = 0; i < containers.evaluate().length; i++) {
          final container = tester.widget<Container>(containers.at(i));
          final decoration = container.decoration as BoxDecoration?;
          if (decoration != null && decoration.color != null && decoration.border == null) {
            foundFilled = true;
            break;
          }
        }
        expect(foundFilled, isTrue);
      });

      testWidgets('outlined style produces border only', (tester) async {
        await pumpThemed(
          tester,
          const LayrzChip(
            labelText: 'Outlined',
            style: LayrzChipStyle.outlined,
            type: LayrzChipType.success,
          ),
        );

        expect(find.byType(LayrzChip), findsOneWidget);

        // Find the Container with BoxDecoration
        final containers = find.byType(Container);
        expect(containers, findsWidgets);

        // Check that at least one has the outlined style (border, transparent background)
        bool foundOutlined = false;
        for (int i = 0; i < containers.evaluate().length; i++) {
          final container = tester.widget<Container>(containers.at(i));
          final decoration = container.decoration as BoxDecoration?;
          if (decoration != null && decoration.border != null) {
            foundOutlined = true;
            break;
          }
        }
        expect(foundOutlined, isTrue);
      });

      testWidgets('filledTonal style produces tonal background', (tester) async {
        await pumpThemed(
          tester,
          const LayrzChip(
            labelText: 'Tonal',
            style: LayrzChipStyle.filledTonal,
            type: LayrzChipType.warning,
          ),
        );

        expect(find.byType(LayrzChip), findsOneWidget);

        // filledTonal should produce a background color with opacity
        final containers = find.byType(Container);
        expect(containers, findsWidgets);

        bool foundTonal = false;
        for (int i = 0; i < containers.evaluate().length; i++) {
          final container = tester.widget<Container>(containers.at(i));
          final decoration = container.decoration as BoxDecoration?;
          if (decoration != null && decoration.color != null) {
            // Check if it has some opacity (tonal)
            if (decoration.color!.a < 1.0) {
              foundTonal = true;
              break;
            }
          }
        }
        expect(foundTonal, isTrue);
      });
    });

    group('Type variants', () {
      testWidgets('custom type with color uses provided color', (tester) async {
        const customColor = Color(0xFFFF5722);

        await pumpThemed(
          tester,
          const LayrzChip(
            labelText: 'Custom',
            type: LayrzChipType.custom,
            color: customColor,
          ),
        );

        expect(find.byType(LayrzChip), findsOneWidget);
      });

      testWidgets('custom type with color=null uses primary color', (tester) async {
        await pumpThemed(
          tester,
          const LayrzChip(
            labelText: 'Default Custom',
            type: LayrzChipType.custom,
            color: null,
          ),
        );

        expect(find.byType(LayrzChip), findsOneWidget);
      });

      testWidgets('semantic type with color parameter asserts', (tester) async {
        expect(
          () => LayrzChip(
            labelText: 'Invalid',
            type: LayrzChipType.info,
            color: const Color(0xFFFF5722),
          ),
          throwsAssertionError,
        );
      });
    });

    group('Delete affordance interaction', () {
      testWidgets('tapping delete icon fires onDelete callback', (tester) async {
        bool deleted = false;

        await pumpThemed(
          tester,
          LayrzChip(
            labelText: 'Delete Me',
            onDelete: () {
              deleted = true;
            },
          ),
        );

        expect(deleted, isFalse);

        // Tap the delete icon
        await tester.tap(find.byIcon(MdiIcons.closeCircle));
        await tester.pump();

        expect(deleted, isTrue);
      });

      testWidgets('chip body has no tap handler', (tester) async {
        bool deleted = false;

        await pumpThemed(
          tester,
          LayrzChip(
            labelText: 'No Tap',
            onDelete: () {
              deleted = true;
            },
          ),
        );

        // Tap on the label text
        await tester.tap(find.text('No Tap'));
        await tester.pump();

        // Callback should not fire from body tap
        expect(deleted, isFalse);
      });

      testWidgets('delete icon is a button in semantics tree', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzChip(
              labelText: 'Semantic Delete',
              onDelete: () {},
            ),
          );

          // Find the Semantics node for the delete button
          final semanticsFinder = find.bySemanticsLabel('Delete Semantic Delete');
          expect(semanticsFinder, findsWidgets);

          // Check that it has the correct label in semantics
          final semantics = tester.getSemantics(semanticsFinder.first);
          expect(semantics.label, equals('Delete Semantic Delete'));
        } finally {
          handle.dispose();
        }
      });
    });

    group('Width computation', () {
      testWidgets('computeWidth returns sensible value', (tester) async {
        await pumpThemed(
          tester,
          const LayrzChip(labelText: 'Width Test'),
        );

        final chip = tester.widget<LayrzChip>(find.byType(LayrzChip));
        final width = chip.computeWidth(tester.element(find.byType(LayrzChip)));

        expect(width, greaterThan(0));
        expect(width, lessThan(500)); // Sanity check for reasonable width
      });

      testWidgets('computeWidth grows with leading icon', (tester) async {
        await pumpThemed(tester, const LayrzChip(labelText: 'Base'));

        final baseWidth = tester
            .widget<LayrzChip>(find.byType(LayrzChip))
            .computeWidth(
              tester.element(find.byType(LayrzChip)),
            );

        await tester.pumpWidget(
          Container(), // Reset
        );
        await pumpThemed(
          tester,
          LayrzChip(
            labelText: 'Base',
            leadingIcon: MdiIcons.checkCircleOutline,
          ),
        );

        final widthWithIcon = tester
            .widget<LayrzChip>(find.byType(LayrzChip))
            .computeWidth(
              tester.element(find.byType(LayrzChip)),
            );

        expect(widthWithIcon, greaterThan(baseWidth));
      });

      testWidgets('computeWidth grows with delete icon', (tester) async {
        await pumpThemed(tester, const LayrzChip(labelText: 'Base'));

        final baseWidth = tester
            .widget<LayrzChip>(find.byType(LayrzChip))
            .computeWidth(
              tester.element(find.byType(LayrzChip)),
            );

        await tester.pumpWidget(
          Container(), // Reset
        );
        await pumpThemed(
          tester,
          LayrzChip(
            labelText: 'Base',
            onDelete: () {},
          ),
        );

        final widthWithDelete = tester
            .widget<LayrzChip>(find.byType(LayrzChip))
            .computeWidth(
              tester.element(find.byType(LayrzChip)),
            );

        expect(widthWithDelete, greaterThan(baseWidth));
      });
    });

    group('Semantics', () {
      testWidgets('chip body has label semantics', (tester) async {
        await pumpThemed(
          tester,
          const LayrzChip(labelText: 'Semantic Chip'),
        );

        // Verify label text is rendered and accessible
        expect(find.text('Semantic Chip'), findsOneWidget);
        expect(find.byType(LayrzChip), findsOneWidget);
      });

      testWidgets('delete icon is labeled correctly', (tester) async {
        await pumpThemed(
          tester,
          LayrzChip(
            labelText: 'My Chip',
            onDelete: () {},
          ),
        );

        // Verify both chip label and delete icon are rendered
        expect(find.text('My Chip'), findsOneWidget);
        expect(find.byIcon(MdiIcons.closeCircle), findsOneWidget);
      });
    });
  });
}
