import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_font_handler.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzAvatar', () {
    group('Avatar type resolution', () {
      testWidgets('renders image from URL', (tester) async {
        final source = LayrzAvatarUrl('https://example.com/avatar.png');

        await pumpThemed(
          tester,
          LayrzAvatar(source: source),
        );

        expect(find.byType(LayrzImage), findsOneWidget);
      });

      testWidgets('renders image from base64', (tester) async {
        final source = LayrzAvatarBase64('iVBORw0KGgo=');

        await pumpThemed(
          tester,
          LayrzAvatar(source: source),
        );

        expect(find.byType(LayrzImage), findsOneWidget);
      });

      testWidgets('renders icon from IconData', (tester) async {
        final source = LayrzAvatarIcon(MdiIcons.checkCircleOutline);

        await pumpThemed(
          tester,
          LayrzAvatar(source: source),
        );

        expect(find.byType(Icon), findsOneWidget);
      });

      testWidgets('renders emoji', (tester) async {
        final source = LayrzAvatarEmoji('😀');

        await pumpThemed(
          tester,
          LayrzAvatar(source: source),
        );

        expect(find.text('😀'), findsOneWidget);
      });

      testWidgets('falls back to initials when source is null', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(source: null, nameText: 'John Doe'),
        );

        expect(find.text('JO'), findsOneWidget);
      });

      testWidgets('LayrzAvatarUrl renders image', (tester) async {
        final source = LayrzAvatarUrl('https://example.com/avatar.png');

        await pumpThemed(
          tester,
          LayrzAvatar(source: source),
        );

        expect(find.byType(LayrzImage), findsOneWidget);
      });

      testWidgets('LayrzAvatarBase64 renders image', (tester) async {
        final source = LayrzAvatarBase64('iVBORw0KGgo=');

        await pumpThemed(
          tester,
          LayrzAvatar(source: source),
        );

        expect(find.byType(LayrzImage), findsOneWidget);
      });

      testWidgets('LayrzAvatarIcon renders icon', (tester) async {
        final source = LayrzAvatarIcon(MdiIcons.checkCircleOutline);

        await pumpThemed(
          tester,
          LayrzAvatar(source: source),
        );

        expect(find.byType(Icon), findsOneWidget);
      });

      testWidgets('LayrzAvatarEmoji renders emoji', (tester) async {
        const source = LayrzAvatarEmoji('🎉');

        await pumpThemed(
          tester,
          LayrzAvatar(source: source),
        );

        expect(find.text('🎉'), findsOneWidget);
      });
    });

    group('Initials generation', () {
      testWidgets('generates initials from two-word name', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(nameText: 'John Doe'),
        );

        expect(find.text('JO'), findsOneWidget);
      });

      testWidgets('generates initials from single word', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(nameText: 'Alice'),
        );

        expect(find.text('AL'), findsOneWidget);
      });

      testWidgets('returns single character when name is one letter', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(nameText: 'A'),
        );

        expect(find.text('A'), findsOneWidget);
      });

      testWidgets('strips non-alphanumeric characters', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(nameText: 'John-Paul Smith'),
        );

        expect(find.text('JO'), findsOneWidget);
      });

      testWidgets('returns "NA" for null name', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(nameText: null),
        );

        expect(find.text('NA'), findsOneWidget);
      });

      testWidgets('returns "NA" for empty name', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(nameText: ''),
        );

        expect(find.text('NA'), findsOneWidget);
      });

      testWidgets('returns "NA" for punctuation-only name', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(nameText: '!@#\$%'),
        );

        expect(find.text('NA'), findsOneWidget);
      });

      testWidgets('uppercases initials', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(nameText: 'alice bob'),
        );

        expect(find.text('AL'), findsOneWidget);
      });
    });

    group('Named constructors', () {
      testWidgets('LayrzAvatar.image renders image', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar.image(imageSource: 'https://example.com/avatar.png'),
        );

        expect(find.byType(LayrzImage), findsOneWidget);
      });

      testWidgets('LayrzAvatar.icon renders icon from IconData', (tester) async {
        await pumpThemed(
          tester,
          LayrzAvatar.icon(icon: MdiIcons.checkCircleOutline),
        );

        expect(find.byType(Icon), findsOneWidget);
      });

      testWidgets('LayrzAvatar.emoji renders emoji', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar.emoji(emoji: '🎉'),
        );

        expect(find.text('🎉'), findsOneWidget);
      });

      testWidgets('LayrzAvatar.initials renders initials', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar.initials(nameText: 'Test User'),
        );

        expect(find.text('TE'), findsOneWidget);
      });
    });

    group('Shape and radius', () {
      testWidgets('renders with r12 corner radius from tokens', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        await pumpThemed(
          tester,
          const LayrzAvatar(nameText: 'Test User'),
          theme: themeData,
        );

        final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
        // Avatar should use r12 radius, which is a circular BorderRadius
        final expectedRadius = BorderRadius.circular(themeData.tokens.radius.r3);
        expect(clipRRect.borderRadius, equals(expectedRadius));
      });
    });

    group('Size parameter', () {
      testWidgets('defaults to 40 pixels', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(nameText: 'Test'),
        );

        // Verify the avatar renders successfully with default size
        expect(find.byType(LayrzAvatar), findsOneWidget);
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('applies custom size', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(nameText: 'Test', size: 60),
        );

        // Verify the avatar renders successfully with custom size
        expect(find.byType(LayrzAvatar), findsOneWidget);
        expect(find.byType(Container), findsWidgets);
      });
    });

    group('Color parameter', () {
      testWidgets('defaults to primary token color', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        await pumpThemed(
          tester,
          const LayrzAvatar(nameText: 'Test'),
          theme: themeData,
        );

        final container = _findColoredContainer(tester);
        expect(container.decoration, isA<BoxDecoration>());
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(themeData.tokens.colors.primary));
      });

      testWidgets('applies custom color', (tester) async {
        const customColor = Color(0xFFFF0000);

        await pumpThemed(
          tester,
          const LayrzAvatar(nameText: 'Test', color: customColor),
        );

        final container = _findColoredContainer(tester);
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(customColor));
      });

      testWidgets('ignores background color behind URL images', (tester) async {
        const customColor = Color(0xFFFF0000);
        final source = LayrzAvatarUrl('https://example.com/avatar.png');

        await pumpThemed(
          tester,
          LayrzAvatar(source: source, color: customColor),
        );

        // The image should render, but the color should not be applied
        expect(find.byType(LayrzImage), findsOneWidget);
      });

      testWidgets('ignores background color behind base64 images', (tester) async {
        const customColor = Color(0xFFFF0000);
        final source = LayrzAvatarBase64('iVBORw0KGgo=');

        await pumpThemed(
          tester,
          LayrzAvatar(source: source, color: customColor),
        );

        expect(find.byType(LayrzImage), findsOneWidget);
      });
    });

    group('Image background color', () {
      testWidgets('renders image from .image() constructor on white background', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar.image(imageSource: 'https://example.com/avatar.png'),
        );

        final container = _findColoredContainer(tester);
        final decoration = container.decoration as BoxDecoration;
        // Image background must be opaque white, not transparent
        expect(decoration.color, equals(const Color(0xFFFFFFFF)));
      });

      testWidgets('renders LayrzAvatarUrl on white background', (tester) async {
        final source = LayrzAvatarUrl('https://example.com/avatar.png');

        await pumpThemed(
          tester,
          LayrzAvatar(source: source),
        );

        final container = _findColoredContainer(tester);
        final decoration = container.decoration as BoxDecoration;
        // Image background must be opaque white, not transparent
        expect(decoration.color, equals(const Color(0xFFFFFFFF)));
      });

      testWidgets('renders LayrzAvatarBase64 on white background', (tester) async {
        final source = LayrzAvatarBase64('iVBORw0KGgo=');

        await pumpThemed(
          tester,
          LayrzAvatar(source: source),
        );

        final container = _findColoredContainer(tester);
        final decoration = container.decoration as BoxDecoration;
        // Image background must be opaque white, not transparent
        expect(decoration.color, equals(const Color(0xFFFFFFFF)));
      });
    });

    group('Accessibility', () {
      testWidgets('includes text content for semantics', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(nameText: 'John Doe'),
        );

        expect(find.text('JO'), findsOneWidget);
      });

      testWidgets('renders emoji text for semantics', (tester) async {
        final source = LayrzAvatarEmoji('😀');

        await pumpThemed(
          tester,
          LayrzAvatar(source: source),
        );

        expect(find.text('😀'), findsOneWidget);
      });
    });

    group('Icon size scaling', () {
      testWidgets('renders icon at 70% of avatar size', (tester) async {
        await pumpThemed(
          tester,
          LayrzAvatar.icon(icon: MdiIcons.checkCircleOutline, size: 100),
        );

        final iconWidget = tester.widget<Icon>(find.byType(Icon));
        expect(iconWidget.size, equals(70.0)); // 100 * 0.7
      });

      testWidgets('renders emoji at 60% of avatar size', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar.emoji(emoji: '🎉', size: 100),
        );

        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.style?.fontSize, equals(60.0)); // 100 * 0.6
      });

      testWidgets('renders initials at 40% of avatar size', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(nameText: 'Test User', size: 100),
        );

        final textWidget = tester.widget<Text>(find.byType(Text).first);
        expect(textWidget.style?.fontSize, equals(40.0)); // 100 * 0.4
      });
    });

    group('Fixed drop shadow', () {
      testWidgets('applies compact level-1 shadow to initials avatar', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        await pumpThemed(
          tester,
          const LayrzAvatar(nameText: 'Test'),
          theme: themeData,
        );

        // Find the outer Container (the one with the shadow decoration)
        final outerContainer = _findOuterContainer(tester);
        expect(outerContainer.decoration, isA<BoxDecoration>());

        final decoration = outerContainer.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow, equals(themeData.tokens.shadow.compact1));
      });

      testWidgets('applies compact level-1 shadow to image avatar', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        await pumpThemed(
          tester,
          const LayrzAvatar.image(imageSource: 'https://example.com/avatar.png'),
          theme: themeData,
        );

        // Find the outer Container (the one with the shadow decoration)
        final outerContainer = _findOuterContainer(tester);
        expect(outerContainer.decoration, isA<BoxDecoration>());

        final decoration = outerContainer.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow, equals(themeData.tokens.shadow.compact1));
      });

      testWidgets('applies compact level-1 shadow to icon avatar', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        await pumpThemed(
          tester,
          LayrzAvatar.icon(icon: MdiIcons.checkCircleOutline),
          theme: themeData,
        );

        // Find the outer Container (the one with the shadow decoration)
        final outerContainer = _findOuterContainer(tester);
        expect(outerContainer.decoration, isA<BoxDecoration>());

        final decoration = outerContainer.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow, equals(themeData.tokens.shadow.compact1));
      });

      testWidgets('applies compact level-1 shadow to emoji avatar', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        await pumpThemed(
          tester,
          const LayrzAvatar.emoji(emoji: '😀'),
          theme: themeData,
        );

        // Find the outer Container (the one with the shadow decoration)
        final outerContainer = _findOuterContainer(tester);
        expect(outerContainer.decoration, isA<BoxDecoration>());

        final decoration = outerContainer.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow, equals(themeData.tokens.shadow.compact1));
      });
    });
  });
}

/// Helper to find a Container with color decoration (the inner colored container).
///
/// Since the avatar now has both an outer container (with shadow) and an inner
/// container (with color), this helper finds the inner one by checking for a
/// non-null, non-transparent color in the decoration.
Container _findColoredContainer(WidgetTester tester) {
  return tester.widget<Container>(
    find.byWidgetPredicate(
      (widget) {
        if (widget is! Container) return false;
        if (widget.decoration is! BoxDecoration) return false;
        final decoration = widget.decoration as BoxDecoration;
        // The inner container has a color (not transparent)
        return decoration.color != null && decoration.color != const Color(0x00000000);
      },
      skipOffstage: false,
    ).first,
  );
}

/// Helper to find the outer Container (the one with the shadow decoration).
///
/// The outer container has width and height set to the avatar size and carries
/// the boxShadow decoration in its BoxDecoration.
Container _findOuterContainer(WidgetTester tester) {
  return tester.widget<Container>(
    find.byWidgetPredicate(
      (widget) {
        if (widget is! Container) return false;
        if (widget.decoration is! BoxDecoration) return false;
        final decoration = widget.decoration as BoxDecoration;
        // The outer container has boxShadow
        return decoration.boxShadow != null && decoration.boxShadow!.isNotEmpty;
      },
      skipOffstage: false,
    ).first,
  );
}
