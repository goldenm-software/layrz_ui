import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/alerts.dart';
import 'package:layrz_ui/constants.dart';
import 'package:layrz_ui/extensions.dart';
import 'package:layrz_ui/tokens.dart';
import 'package:layrz_icons/layrz_icons.dart';

import '../helpers/fake_font_handler.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzAlert', () {
    group('Content rendering', () {
      testWidgets('renders title and description text', (tester) async {
        const title = 'Test Title';
        const description = 'Test Description';
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: title,
              description: description,
            ),
          ),
        );

        expect(find.text(title), findsOneWidget);
        expect(find.text(description), findsOneWidget);
      });

      testWidgets('description text respects maxLines parameter', (tester) async {
        const description = 'Line 1\nLine 2\nLine 3\nLine 4\nLine 5';
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: description,
              maxLines: 2,
            ),
          ),
        );

        final textWidget =
            find
                    .byWidgetPredicate(
                      (widget) => widget is Text && widget.data == description,
                    )
                    .evaluate()
                    .single
                    .widget
                as Text;

        expect(textWidget.maxLines, equals(2));
      });
    });

    group('Layout structure', () {
      testWidgets('filledIcon style renders two-panel layout', (tester) async {
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              style: LayrzAlertStyle.filledIcon,
            ),
          ),
        );

        final clipRRects = find.byType(ClipRRect);
        expect(clipRRects, findsOneWidget);
        final intrinsicHeights = find.byType(IntrinsicHeight);
        expect(intrinsicHeights, findsOneWidget);
      });

      testWidgets('icon chip has rounded square border radius', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              style: LayrzAlertStyle.layrz,
            ),
          ),
        );

        // Find the icon chip Container by searching for one with the expected size
        final containers = find.byType(Container);
        Container? iconChipContainer;
        for (final element in containers.evaluate()) {
          final container = element.widget as Container;
          if (container.decoration is BoxDecoration &&
              container.constraints?.maxWidth == kLayrzAlertIconBoxSize &&
              container.constraints?.maxHeight == kLayrzAlertIconBoxSize) {
            iconChipContainer = container;
            break;
          }
        }

        expect(iconChipContainer, isNotNull);
        final decoration = iconChipContainer!.decoration! as BoxDecoration;
        expect(decoration.borderRadius, equals(BorderRadius.circular(tokens.radius.r10)));
      });
    });

    group('Color application', () {
      testWidgets('layrz style uses surface background with tonal border', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              type: LayrzAlertType.success,
              style: LayrzAlertStyle.layrz,
            ),
          ),
        );

        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.layrz,
          accent: tokens.colors.success.shade500,
          tokens: tokens,
        );

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration! as BoxDecoration;

        expect(decoration.color, equals(spec.backgroundColor));
        expect((decoration.border as Border?)?.top.color, equals(spec.borderColor));
      });

      testWidgets('filledTonal style uses tonal background', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              type: LayrzAlertType.warning,
              style: LayrzAlertStyle.filledTonal,
            ),
          ),
        );

        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filledTonal,
          accent: tokens.colors.warning.shade500,
          tokens: tokens,
        );

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration! as BoxDecoration;

        expect(decoration.color, equals(spec.backgroundColor));
      });

      testWidgets('filled style uses solid accent background', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              type: LayrzAlertType.danger,
              style: LayrzAlertStyle.filled,
            ),
          ),
        );

        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filled,
          accent: tokens.colors.danger.shade500,
          tokens: tokens,
        );

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration! as BoxDecoration;

        expect(decoration.color, equals(spec.backgroundColor));
      });

      testWidgets('outlined style uses transparent background with accent border', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              type: LayrzAlertType.info,
              style: LayrzAlertStyle.outlined,
            ),
          ),
        );

        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.outlined,
          accent: tokens.colors.info.shade500,
          tokens: tokens,
        );

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration! as BoxDecoration;

        expect(decoration.color, equals(spec.backgroundColor));
        expect((decoration.border as Border?)?.top.color, equals(spec.borderColor));
      });
    });

    group('Icon size resolution', () {
      testWidgets('filledIcon style renders icon at kLayrzAlertFilledIconSize', (tester) async {
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              style: LayrzAlertStyle.filledIcon,
            ),
          ),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.size, equals(kLayrzAlertFilledIconSize));
      });

      testWidgets('layrz style renders icon at kLayrzAlertIconSize', (tester) async {
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              style: LayrzAlertStyle.layrz,
            ),
          ),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.size, equals(kLayrzAlertIconSize));
      });

      testWidgets('explicit iconSize parameter overrides default', (tester) async {
        const customIconSize = 41.0;
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              iconSize: customIconSize,
            ),
          ),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.size, equals(customIconSize));
      });
    });

    group('Custom type color resolution', () {
      testWidgets('custom type with explicit color uses that color for icon', (tester) async {
        const customColor = Color(0xFFFF5733);
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              type: LayrzAlertType.custom,
              color: customColor,
              style: LayrzAlertStyle.filled,
            ),
          ),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, equals(customColor.contrastColor));
      });

      testWidgets('custom type without explicit color defaults to primary', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              type: LayrzAlertType.custom,
              style: LayrzAlertStyle.filled,
            ),
          ),
        );

        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filled,
          accent: tokens.colors.primary.shade500,
          tokens: tokens,
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, equals(spec.iconColor));
      });
    });

    group('Custom type icon resolution', () {
      testWidgets('custom type with explicit icon uses that icon', (tester) async {
        const customIcon = IconData(0xE001, fontFamily: 'MaterialIcons');
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              type: LayrzAlertType.custom,
              icon: customIcon,
            ),
          ),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon, equals(customIcon));
      });

      testWidgets('custom type without explicit icon defaults to solarOutlineInfoSquare', (tester) async {
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              type: LayrzAlertType.custom,
            ),
          ),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon?.codePoint, equals(LayrzIcons.solarOutlineInfoSquare.codePoint));
      });
    });

    group('Text styling', () {
      testWidgets('title renders with bold font weight', (tester) async {
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Bold Title',
              description: 'Description',
            ),
          ),
        );

        final titleWidget = tester.widget<Text>(find.text('Bold Title'));
        expect(titleWidget.style?.fontWeight, equals(FontWeight.bold));
      });

      testWidgets('description uses bodyMedium style', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Body text',
            ),
          ),
        );

        final descriptionWidget = tester.widget<Text>(find.text('Body text'));
        expect(descriptionWidget.style?.fontSize, equals(tokens.typography.bodyMedium.fontSize));
      });
    });
  });
}
