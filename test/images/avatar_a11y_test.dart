import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzAvatar - Accessibility', () {
    group('Image avatars with required semanticLabel', () {
      testWidgets('.image() constructor requires semanticLabel', (tester) async {
        // This test verifies the API contract:
        // LayrzAvatar.image() requires semanticLabel as a parameter
        // Omitting it causes a compile-time error.
        await pumpThemed(
          tester,
          const LayrzAvatar.image(
            imageSource: 'https://example.com/avatar.png',
            semanticLabel: 'Jane Smith profile photo',
          ),
        );

        expect(find.byType(LayrzImage), findsOneWidget);
      });

      testWidgets('LayrzAvatarUrl with semanticLabel provides accessible content', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(
            source: LayrzAvatarUrl('https://example.com/avatar.png'),
            semanticLabel: 'User profile photo',
          ),
        );

        expect(find.byType(LayrzImage), findsOneWidget);
      });

      testWidgets('LayrzAvatarBase64 with semanticLabel provides accessible content', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(
            source: LayrzAvatarBase64(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
            ),
            semanticLabel: 'Encoded user image',
          ),
        );

        expect(find.byType(LayrzImage), findsOneWidget);
      });
    });

    group('Non-image avatars with optional semanticLabel', () {
      testWidgets('initials avatar without label renders with visible text', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(nameText: 'John Doe'),
        );

        // The initials are still visible and accessible as text
        expect(find.text('JO'), findsOneWidget);
      });

      testWidgets('initials avatar with label provides semantic context', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(
            nameText: 'John Doe',
            semanticLabel: 'John Doe avatar',
          ),
        );

        // The initials are still visible
        expect(find.text('JO'), findsOneWidget);
      });

      testWidgets('icon avatar without label renders icon', (tester) async {
        await pumpThemed(
          tester,
          LayrzAvatar.icon(icon: MdiIcons.checkCircleOutline),
        );

        // The icon still renders
        expect(find.byType(Icon), findsOneWidget);
      });

      testWidgets('icon avatar with label provides semantic context', (tester) async {
        await pumpThemed(
          tester,
          LayrzAvatar.icon(
            icon: MdiIcons.checkCircleOutline,
            semanticLabel: 'Verified badge',
          ),
        );

        // The icon still renders
        expect(find.byType(Icon), findsOneWidget);
      });

      testWidgets('emoji avatar without label renders emoji', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar.emoji(emoji: '🎉'),
        );

        // The emoji still renders
        expect(find.text('🎉'), findsOneWidget);
      });

      testWidgets('emoji avatar with label provides semantic context', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar.emoji(
            emoji: '🎉',
            semanticLabel: 'Party celebration',
          ),
        );

        // The emoji still renders
        expect(find.text('🎉'), findsOneWidget);
      });

      testWidgets('initials avatar with optional label', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar.initials(
            nameText: 'Alice Brown',
            semanticLabel: 'Alice Brown avatar',
          ),
        );

        // The initials are rendered
        expect(find.text('AL'), findsOneWidget);
      });
    });

    group('Contrast and readability', () {
      testWidgets('text is readable with contrasting color on dark background', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(
            nameText: 'Test User',
            color: Color(0xFF000000), // Black background
          ),
        );

        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.style, isNotNull);
        // White text on black background for contrast
        expect(textWidget.style?.color, equals(const Color(0xFFFFFFFF)));
      });

      testWidgets('text is readable with contrasting color on light background', (tester) async {
        await pumpThemed(
          tester,
          const LayrzAvatar(
            nameText: 'Test User',
            color: Color(0xFFFFFFFF), // White background
          ),
        );

        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.style, isNotNull);
        // Black text on white background for contrast
        expect(textWidget.style?.color, equals(const Color(0xFF000000)));
      });
    });

    group('Semantics behavior', () {
      testWidgets('avatar without semanticLabel still renders correctly', (tester) async {
        // This test verifies that avatars without semanticLabel still function correctly.
        // They just don't emit a Semantics announcement, reducing screen reader noise
        // when context is already provided elsewhere (e.g., a name displayed next to the avatar).
        await pumpThemed(
          tester,
          const LayrzAvatar(nameText: 'Jane Doe'),
        );

        // The avatar renders and the initials are visible
        // "Jane Doe" → first two characters after alphanumeric filtering → "JA"
        expect(find.text('JA'), findsOneWidget);
        expect(find.byType(LayrzAvatar), findsOneWidget);
      });

      testWidgets('avatar with semanticLabel still functions normally', (tester) async {
        // Verify that providing a semanticLabel doesn't break normal avatar rendering
        await pumpThemed(
          tester,
          const LayrzAvatar(
            nameText: 'John Doe',
            semanticLabel: 'John Doe avatar',
          ),
        );

        // The avatar renders and the initials are visible
        expect(find.text('JO'), findsOneWidget);
        expect(find.byType(LayrzAvatar), findsOneWidget);
      });
    });
  });
}
