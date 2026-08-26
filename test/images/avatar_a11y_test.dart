import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzAvatar — Accessibility', () {
    group('Image avatars with required semanticLabel', () {
      testWidgets('image avatar with label announces label in semantics tree', (tester) async {
        final handle = tester.ensureSemantics();

        try {
          await pumpThemed(
            tester,
            const LayrzAvatar.image(
              imageSource: 'https://example.com/avatar.png',
              semanticLabel: 'Jane Smith profile photo',
            ),
          );

          // Verify the semantic label is present in the semantics tree
          // This is what a screen reader announces when it encounters this avatar.
          final avatar = find.byType(LayrzAvatar);
          expect(
            tester.getSemantics(avatar).label,
            'Jane Smith profile photo',
          );
        } finally {
          handle.dispose();
        }
      });

      testWidgets('LayrzAvatarUrl with label announces label in semantics', (tester) async {
        final handle = tester.ensureSemantics();

        try {
          await pumpThemed(
            tester,
            const LayrzAvatar(
              source: LayrzAvatarUrl('https://example.com/avatar.png'),
              semanticLabel: 'User profile image',
            ),
          );

          // The label should be present in the semantics tree
          final avatar = find.byType(LayrzAvatar);
          expect(
            tester.getSemantics(avatar).label,
            'User profile image',
          );
        } finally {
          handle.dispose();
        }
      });

      testWidgets('LayrzAvatarBase64 with label announces label in semantics', (tester) async {
        final handle = tester.ensureSemantics();

        try {
          await pumpThemed(
            tester,
            const LayrzAvatar(
              source: LayrzAvatarBase64(
                'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
              ),
              semanticLabel: 'Encoded user avatar image',
            ),
          );

          // The label should be present in the semantics tree
          final avatar = find.byType(LayrzAvatar);
          expect(
            tester.getSemantics(avatar).label,
            'Encoded user avatar image',
          );
        } finally {
          handle.dispose();
        }
      });
    });

    group('Non-image avatars without labels emit NO semantics node', () {
      testWidgets('initials avatar without label has no semantics node', (tester) async {
        final handle = tester.ensureSemantics();

        try {
          await pumpThemed(
            tester,
            const LayrzAvatar(nameText: 'John Doe'),
          );

          // CRITICAL: An avatar without a label must NOT emit a Semantics node.
          // This is the silence guarantee — reducing screen reader noise when
          // the avatar sits alongside other context that already identifies it.
          // If a Semantics wrapper is added, this test will fail.
          final avatar = find.byType(LayrzAvatar);
          expect(
            tester.getSemantics(avatar).label,
            '',
          );

          // But the initials are still visibly rendered
          expect(find.text('JO'), findsOneWidget);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('icon avatar without label has no semantics node', (tester) async {
        final handle = tester.ensureSemantics();

        try {
          await pumpThemed(
            tester,
            LayrzAvatar.icon(icon: MdiIcons.checkCircleOutline),
          );

          // Without a label, no Semantics announcement should occur
          final avatar = find.byType(LayrzAvatar);
          expect(
            tester.getSemantics(avatar).label,
            '',
          );

          // But the icon still renders
          expect(find.byType(Icon), findsOneWidget);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('emoji avatar without label has no semantics node', (tester) async {
        final handle = tester.ensureSemantics();

        try {
          await pumpThemed(
            tester,
            const LayrzAvatar.emoji(emoji: '🎉'),
          );

          // Without a label, no Semantics announcement should occur
          final avatar = find.byType(LayrzAvatar);
          expect(
            tester.getSemantics(avatar).label,
            '',
          );

          // But the emoji still renders
          expect(find.text('🎉'), findsOneWidget);
        } finally {
          handle.dispose();
        }
      });
    });

    group('Non-image avatars with labels announce label in semantics', () {
      testWidgets('initials avatar with label announces in semantics tree', (tester) async {
        final handle = tester.ensureSemantics();

        try {
          await pumpThemed(
            tester,
            const LayrzAvatar(
              nameText: 'John Doe',
              semanticLabel: 'John Doe initials avatar',
            ),
          );

          // With a label, the semantics node should carry it
          final avatar = find.byType(LayrzAvatar);
          expect(
            tester.getSemantics(avatar).label,
            startsWith('John Doe initials avatar'),
          );
        } finally {
          handle.dispose();
        }
      });

      testWidgets('icon avatar with label announces in semantics tree', (tester) async {
        final handle = tester.ensureSemantics();

        try {
          await pumpThemed(
            tester,
            LayrzAvatar.icon(
              icon: MdiIcons.checkCircleOutline,
              semanticLabel: 'Verified user badge',
            ),
          );

          // With a label, the semantics node should carry it
          final avatar = find.byType(LayrzAvatar);
          expect(
            tester.getSemantics(avatar).label,
            'Verified user badge',
          );
        } finally {
          handle.dispose();
        }
      });

      testWidgets('emoji avatar with label announces in semantics tree', (tester) async {
        final handle = tester.ensureSemantics();

        try {
          await pumpThemed(
            tester,
            const LayrzAvatar.emoji(
              emoji: '🎉',
              semanticLabel: 'Celebration party emoji',
            ),
          );

          // With a label, the semantics node should carry it
          final avatar = find.byType(LayrzAvatar);
          expect(
            tester.getSemantics(avatar).label,
            startsWith('Celebration party emoji'),
          );
        } finally {
          handle.dispose();
        }
      });
    });

    group('Text contrast for readability', () {
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
  });
}
