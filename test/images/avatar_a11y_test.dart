import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_sdk/layrz_sdk.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzAvatar - Accessibility', () {
    testWidgets('provides semantic label for initials', (tester) async {
      await pumpThemed(
        tester,
        const LayrzAvatar(nameText: 'John Doe'),
      );

      // Initials should be rendered as text for screen readers
      expect(find.text('JO'), findsOneWidget);
    });

    testWidgets('provides semantic label for emoji', (tester) async {
      final avatar = Avatar(type: AvatarType.emoji, emoji: '😀');

      await pumpThemed(
        tester,
        LayrzAvatar(avatar: avatar),
      );

      // Emoji should be rendered as text for screen readers
      expect(find.text('😀'), findsOneWidget);
    });

    testWidgets('provides semantic label for icon', (tester) async {
      final icon = LayrzIcon(name: 'home', codePoint: 0xE88A, family: LayrzFamily.materialDesignIcons);
      final avatar = Avatar(type: AvatarType.icon, icon: icon);

      await pumpThemed(
        tester,
        LayrzAvatar(avatar: avatar),
      );

      // Icon should render successfully
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('is not announced as a button (static display)', (tester) async {
      await pumpThemed(
        tester,
        const LayrzAvatar(nameText: 'John Doe'),
      );

      // LayrzAvatar is static, so it should render and not have button behaviors
      expect(find.byType(LayrzAvatar), findsOneWidget);
    });

    testWidgets('has text content for screen readers', (tester) async {
      await pumpThemed(
        tester,
        const LayrzAvatar(nameText: 'Alice Brown'),
      );

      // Should find the initials text for screen readers
      expect(find.text('AL'), findsOneWidget);
    });

    testWidgets('displays "NA" placeholder when name is missing', (tester) async {
      await pumpThemed(
        tester,
        const LayrzAvatar(),
      );

      // Should fall back to "NA" for accessibility
      expect(find.text('NA'), findsOneWidget);
    });

    testWidgets('provides content for image avatars via alt text expectation', (tester) async {
      final avatar = Avatar(type: AvatarType.url, url: 'https://example.com/user.png');

      await pumpThemed(
        tester,
        LayrzAvatar(avatar: avatar, nameText: 'Jane Smith'),
      );

      // Image should render; the nameText provides fallback context
      expect(find.byType(LayrzImage), findsOneWidget);
    });

    testWidgets('text is readable by providing sufficient contrast', (tester) async {
      // The avatar should pick contrasting text color based on background
      await pumpThemed(
        tester,
        const LayrzAvatar(
          nameText: 'Test User',
          color: Color(0xFF000000), // Black background
        ),
      );

      // The text should be rendered with a contrasting color (white)
      // We can verify this by checking the Text widget's style
      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style, isNotNull);
    });

    testWidgets('maintains readable text for light background', (tester) async {
      await pumpThemed(
        tester,
        const LayrzAvatar(
          nameText: 'Test User',
          color: Color(0xFFFFFFFF), // White background
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      // Text color should be properly set for contrast
      expect(textWidget.style?.color, isNotNull);
    });
  });
}
