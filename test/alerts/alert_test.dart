import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
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

      testWidgets('layrz style renders split-panel layout', (tester) async {
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

        final clipRRects = find.byType(ClipRRect);
        expect(clipRRects, findsOneWidget);
        final intrinsicHeights = find.byType(IntrinsicHeight);
        expect(intrinsicHeights, findsOneWidget);
      });

      testWidgets('both surviving styles render split-panel structure', (tester) async {
        final styles = [LayrzAlertStyle.layrz, LayrzAlertStyle.filledIcon];

        for (final style in styles) {
          await pumpThemed(
            tester,
            SizedBox(
              width: 300,
              child: LayrzAlert(
                title: 'Title',
                description: 'Description',
                style: style,
              ),
            ),
          );

          // Both styles should render ClipRRect (split-panel wrapper)
          final clipRRects = find.byType(ClipRRect);
          expect(clipRRects, findsOneWidget, reason: '$style should render split-panel ClipRRect');

          // Both styles should render IntrinsicHeight (split-panel row container)
          final intrinsicHeights = find.byType(IntrinsicHeight);
          expect(intrinsicHeights, findsOneWidget, reason: '$style should render split-panel IntrinsicHeight');

          await tester.pumpWidget(const SizedBox());
        }
      });
    });

    group('Color application', () {
      testWidgets('layrz style uses split-panel with solid accent border', (tester) async {
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
          isInteractive: false,
        );

        // Find the border container with foregroundDecoration
        final containers = find.byType(Container);
        Container? borderContainer;
        for (final element in containers.evaluate()) {
          final container = element.widget as Container;
          if (container.foregroundDecoration is BoxDecoration) {
            final foregroundDecoration = container.foregroundDecoration! as BoxDecoration;
            if (foregroundDecoration.border is Border) {
              borderContainer = container;
              break;
            }
          }
        }

        expect(borderContainer, isNotNull, reason: 'layrz should have split-panel with border');
        final foregroundDecoration = borderContainer!.foregroundDecoration! as BoxDecoration;
        expect((foregroundDecoration.border as Border?)?.top.color, equals(spec.borderColor));
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

      testWidgets('layrz style renders icon at kLayrzAlertFilledIconSize (same as filledIcon)', (tester) async {
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
        expect(icon.size, equals(kLayrzAlertFilledIconSize));
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
              style: LayrzAlertStyle.filledIcon,
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
              style: LayrzAlertStyle.filledIcon,
            ),
          ),
        );

        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filledIcon,
          accent: tokens.colors.primary.shade500,
          tokens: tokens,
          isInteractive: false,
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

      testWidgets('description uses body style', (tester) async {
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
        expect(descriptionWidget.style?.fontSize, equals(tokens.typography.body.fontSize));
      });
    });

    group('filledIcon border rendering', () {
      testWidgets('inert filledIcon alert renders accent border on foregroundDecoration', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        const accentColor = Color(0xFF2E7D32); // Custom green accent
        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Success',
              description: 'Operation completed',
              type: LayrzAlertType.custom,
              color: accentColor,
              style: LayrzAlertStyle.filledIcon,
            ),
          ),
        );

        // Find the outermost Container that wraps the content for inert filledIcon
        final containers = find.byType(Container);
        Container? borderContainer;
        for (final element in containers.evaluate()) {
          final container = element.widget as Container;
          if (container.foregroundDecoration is BoxDecoration) {
            final foregroundDecoration = container.foregroundDecoration! as BoxDecoration;
            if (foregroundDecoration.border is Border) {
              borderContainer = container;
              break;
            }
          }
        }

        expect(
          borderContainer,
          isNotNull,
          reason: 'Should find Container with foregroundDecoration border for inert filledIcon',
        );
        final foregroundDecoration = borderContainer!.foregroundDecoration! as BoxDecoration;
        final border = foregroundDecoration.border! as Border;
        expect(border.top.color, equals(accentColor));
        expect(border.top.width, equals(tokens.border.base));
      });

      testWidgets('interactive filledIcon alert renders accent border on foregroundDecoration', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        const accentColor = Color(0xFFD32F2F); // Custom red accent
        await pumpThemed(
          tester,
          SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Error',
              description: 'An error occurred',
              type: LayrzAlertType.custom,
              color: accentColor,
              style: LayrzAlertStyle.filledIcon,
              onTap: () {},
            ),
          ),
        );

        // For interactive alerts, find the AnimatedContainer with the foregroundDecoration border
        final animatedContainers = find.byType(AnimatedContainer);
        AnimatedContainer? borderContainer;
        for (final element in animatedContainers.evaluate()) {
          final container = element.widget as AnimatedContainer;
          if (container.foregroundDecoration is BoxDecoration) {
            final foregroundDecoration = container.foregroundDecoration! as BoxDecoration;
            if (foregroundDecoration.border is Border) {
              borderContainer = container;
              break;
            }
          }
        }

        expect(
          borderContainer,
          isNotNull,
          reason: 'Should find AnimatedContainer with foregroundDecoration border for interactive filledIcon',
        );
        final foregroundDecoration = borderContainer!.foregroundDecoration! as BoxDecoration;
        final border = foregroundDecoration.border! as Border;
        expect(border.top.color, equals(accentColor));
        expect(border.top.width, equals(tokens.border.base));
      });

      testWidgets('filledIcon border colour matches accent across severity types', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        const width = 300.0;

        final severities = [
          (type: LayrzAlertType.info, color: tokens.colors.info.shade500),
          (type: LayrzAlertType.success, color: tokens.colors.success.shade500),
          (type: LayrzAlertType.warning, color: tokens.colors.warning.shade500),
          (type: LayrzAlertType.danger, color: tokens.colors.danger.shade500),
          (type: LayrzAlertType.context, color: tokens.colors.contextual.shade500),
        ];

        for (final severity in severities) {
          await pumpThemed(
            tester,
            SizedBox(
              width: width,
              child: LayrzAlert(
                title: 'Test',
                description: 'Test alert',
                type: severity.type,
                style: LayrzAlertStyle.filledIcon,
              ),
            ),
          );

          // Find the border Container with foregroundDecoration
          final containers = find.byType(Container);
          Container? borderContainer;
          for (final element in containers.evaluate()) {
            final container = element.widget as Container;
            if (container.foregroundDecoration is BoxDecoration) {
              final foregroundDecoration = container.foregroundDecoration! as BoxDecoration;
              if (foregroundDecoration.border is Border) {
                borderContainer = container;
                break;
              }
            }
          }

          expect(
            borderContainer,
            isNotNull,
            reason: 'Should find foregroundDecoration border container for ${severity.type}',
          );
          final foregroundDecoration = borderContainer!.foregroundDecoration! as BoxDecoration;
          final border = foregroundDecoration.border! as Border;
          expect(
            border.top.color,
            equals(severity.color),
            reason: 'filledIcon border should be accent color for ${severity.type}',
          );

          await tester.pumpWidget(const SizedBox());
        }
      });

      testWidgets('split-panel ClipRRect uses outer r12 radius', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
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

        final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
        final expectedOuterRadius = BorderRadius.circular(tokens.radius.r12);

        expect(clipRRect.borderRadius, equals(expectedOuterRadius));
      });

      testWidgets('filledIcon border width matches base border token', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
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

        // Find border container with foregroundDecoration
        final containers = find.byType(Container);
        Container? borderContainer;
        for (final element in containers.evaluate()) {
          final container = element.widget as Container;
          if (container.foregroundDecoration is BoxDecoration) {
            final foregroundDecoration = container.foregroundDecoration! as BoxDecoration;
            if (foregroundDecoration.border is Border) {
              borderContainer = container;
              break;
            }
          }
        }

        expect(borderContainer, isNotNull);
        final foregroundDecoration = borderContainer!.foregroundDecoration! as BoxDecoration;
        final border = foregroundDecoration.border! as Border;
        expect(border.top.width, equals(tokens.border.base));
      });
    });

    group('border styles unchanged assertion', () {
      testWidgets('layrz style renders split-panel with solid accent border', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          const SizedBox(
            width: 300,
            child: LayrzAlert(
              title: 'Title',
              description: 'Description',
              type: LayrzAlertType.info,
              style: LayrzAlertStyle.layrz,
            ),
          ),
        );

        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.layrz,
          accent: tokens.colors.info.shade500,
          tokens: tokens,
          isInteractive: false,
        );

        // layrz now uses split-panel with foregroundDecoration border
        final containers = find.byType(Container);
        Container? borderContainer;
        for (final element in containers.evaluate()) {
          final container = element.widget as Container;
          if (container.foregroundDecoration is BoxDecoration) {
            final foregroundDecoration = container.foregroundDecoration! as BoxDecoration;
            if (foregroundDecoration.border is Border) {
              borderContainer = container;
              break;
            }
          }
        }

        expect(borderContainer, isNotNull, reason: 'layrz should have split-panel with border on foregroundDecoration');
        final foregroundDecoration = borderContainer!.foregroundDecoration! as BoxDecoration;
        final border = foregroundDecoration.border! as Border;
        expect(border.top.color, equals(spec.borderColor));
        expect(border.top.width, equals(spec.borderWidth));
      });
    });
  });
}
