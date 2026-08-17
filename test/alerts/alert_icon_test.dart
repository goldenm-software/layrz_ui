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
  group('LayrzAlertIcon', () {
    group('Glyph size resolution', () {
      testWidgets('iconSize defaults to kLayrzAlertIconWidgetIconSize', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAlertIcon(),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.size, equals(kLayrzAlertIconWidgetIconSize));
      });

      testWidgets('iconSize parameter controls glyph size', (tester) async {
        const iconSize = 25.0;
        await pumpThemed(
          tester,
          const LayrzAlertIcon(iconSize: iconSize),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.size, equals(iconSize));
      });

      testWidgets('explicit iconSize overrides default', (tester) async {
        const customSize = 37.0;
        await pumpThemed(
          tester,
          const LayrzAlertIcon(iconSize: customSize),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.size, equals(customSize));
      });
    });

    group('Type-resolved icon colours', () {
      testWidgets('info type renders icon in info colour', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          const LayrzAlertIcon(type: LayrzAlertType.info),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, equals(tokens.colors.info.shade500));
      });

      testWidgets('success type renders icon in success colour', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          const LayrzAlertIcon(type: LayrzAlertType.success),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, equals(tokens.colors.success.shade500));
      });

      testWidgets('warning type renders icon in warning colour', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          const LayrzAlertIcon(type: LayrzAlertType.warning),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, equals(tokens.colors.warning.shade500));
      });

      testWidgets('danger type renders icon in danger colour', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          const LayrzAlertIcon(type: LayrzAlertType.danger),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, equals(tokens.colors.danger.shade500));
      });

      testWidgets('context type renders icon in contextual colour', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          const LayrzAlertIcon(type: LayrzAlertType.context),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, equals(tokens.colors.contextual.shade500));
      });
    });

    group('Custom type colour resolution', () {
      testWidgets('custom type with explicit color uses that colour', (tester) async {
        const customColor = Color(0xFFFF5733);
        await pumpThemed(
          tester,
          const LayrzAlertIcon(
            type: LayrzAlertType.custom,
            color: customColor,
          ),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, equals(customColor));
      });

      testWidgets('custom type without explicit color defaults to primary', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          const LayrzAlertIcon(
            type: LayrzAlertType.custom,
          ),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, equals(tokens.colors.primary.shade500));
      });
    });

    group('Custom type icon resolution', () {
      testWidgets('custom type with explicit icon uses that icon', (tester) async {
        const customIcon = IconData(0xE001, fontFamily: 'MaterialIcons');
        await pumpThemed(
          tester,
          const LayrzAlertIcon(
            type: LayrzAlertType.custom,
            icon: customIcon,
          ),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon, equals(customIcon));
      });

      testWidgets('custom type without explicit icon defaults to solarOutlineInfoSquare', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAlertIcon(
            type: LayrzAlertType.custom,
          ),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon?.codePoint, equals(LayrzIcons.solarOutlineInfoSquare.codePoint));
      });
    });

    group('Chip background colour', () {
      testWidgets('info type chip uses tonal background', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          const LayrzAlertIcon(type: LayrzAlertType.info),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration! as BoxDecoration;

        expect(
          decoration.color,
          equals(tokens.colors.info.shade500.withOpacityValue(tokens.colors.tonalOpacity)),
        );
      });

      testWidgets('custom type chip uses custom colour with tonal opacity', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        const customColor = Color(0xFFFF5733);
        await pumpThemed(
          tester,
          const LayrzAlertIcon(
            type: LayrzAlertType.custom,
            color: customColor,
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration! as BoxDecoration;

        expect(
          decoration.color,
          equals(customColor.withOpacityValue(tokens.colors.tonalOpacity)),
        );
      });
    });

    group('Padding', () {
      testWidgets('custom padding parameter is applied', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAlertIcon(
            padding: EdgeInsets.all(8.0),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        expect(container.padding, equals(const EdgeInsets.all(8.0)));
      });
    });

    group('Border radius', () {
      testWidgets('icon chip has rounded square border radius', (tester) async {
        final tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
        await pumpThemed(
          tester,
          const LayrzAlertIcon(),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.borderRadius, equals(BorderRadius.circular(tokens.radius.r10)));
      });
    });
  });
}
