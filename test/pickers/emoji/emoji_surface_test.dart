import 'package:emojis/emoji.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/emoji/emoji_surface.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

/// Scrolls the group-filter chip row (a horizontal `ListView.separated`)
/// left by a fixed, generous offset so the trailing chips ("Flags",
/// "Component") are laid out and reachable by [find.text].
///
/// Not [WidgetController.ensureVisible]: that helper requires the target
/// [Element] to already exist in the tree, but the chip row's combined
/// content width (~2050px, measured) exceeds a 1600px-wide test viewport --
/// the last few chips are genuinely never built until a real scroll gesture
/// moves them into the `ListView`'s viewport + cache extent. A manual
/// [WidgetController.drag] reproduces that real scroll; [ensureVisible]
/// cannot bootstrap it because it can't find an [Element] that isn't built
/// yet.
Future<void> _scrollGroupFilterRow(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(-1000, 0));
  await tester.pumpAndSettle();
}

void main() {
  group('LayrzEmojiSurface — rendering', () {
    guardedTestWidgets('renders the group filter row and search field with no crash', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzEmojiSurface(onEmojiSelected: (_) {}));

      expect(find.byType(LayrzEmojiSurface), findsOneWidget);
      expect(find.text('All emoji'), findsOneWidget);
      expect(find.text('Smileys & Emotion'), findsOneWidget);
    });

    guardedTestWidgets('renders without overflow at a narrow (compact) viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzEmojiSurface(onEmojiSelected: (_) {}));

      expect(find.byType(LayrzEmojiSurface), findsOneWidget);
    });

    guardedTestWidgets('renders at least one emoji cell by default (all emoji, no search)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzEmojiSurface(onEmojiSelected: (_) {}));

      final firstChar = Emoji.all().first.char;
      expect(find.text(firstChar), findsWidgets);
    });
  });

  group('LayrzEmojiSurface — group filter', () {
    guardedTestWidgets('tapping a group chip switches the rendered emoji set to that group', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzEmojiSurface(onEmojiSelected: (_) {}));

      // An emoji that exists only in the Flags group must be absent while
      // "All emoji" (or any other group) is selected, and present once the
      // Flags chip is tapped -- this is the concrete proxy for "the group
      // filter switches the rendered set", not merely "some chip visually
      // looks selected".
      final flagEmoji = Emoji.byGroup(EmojiGroup.flags).first;

      expect(find.text(flagEmoji.char), findsNothing);

      // "Flags" is the last entry in the eleven-item group-filter row, so it
      // sits off-screen in the horizontally scrollable `ListView` until
      // scrolled into view.
      await _scrollGroupFilterRow(tester);
      await tester.tap(find.text('Flags'));
      await tester.pump();

      expect(find.text(flagEmoji.char), findsWidgets);
    });

    guardedTestWidgets('tapping the already-selected group chip is a no-op (no onTap wired)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzEmojiSurface(onEmojiSelected: (_) {}));

      // "All emoji" is selected by default -- tapping it again must not
      // throw and must leave the set unchanged (still shows the first
      // overall emoji).
      await tester.tap(find.text('All emoji'));
      await tester.pump();

      final firstChar = Emoji.all().first.char;
      expect(find.text(firstChar), findsWidgets);
    });
  });

  group('LayrzEmojiSurface — search', () {
    guardedTestWidgets('typing a shortName search term filters the grid to matching emoji', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzEmojiSurface(onEmojiSelected: (_) {}));

      final target = Emoji.byShortName('grinning')!;
      // Something that does NOT match "grinning" by shortName or keyword, to
      // prove the grid actually narrowed rather than merely re-rendering
      // everything.
      final nonMatch = Emoji.all().firstWhere(
        (e) => !e.shortName.toLowerCase().contains('grin') && !e.keywords.any((k) => k.toLowerCase().contains('grin')),
      );

      expect(find.text(nonMatch.char), findsWidgets);

      await tester.enterText(find.byType(EditableText).first, 'grinning');
      await tester.pump();

      expect(find.text(target.char), findsWidgets);
      expect(find.text(nonMatch.char), findsNothing);
    });

    guardedTestWidgets('search is case-insensitive', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzEmojiSurface(onEmojiSelected: (_) {}));

      final target = Emoji.byShortName('grinning')!;

      await tester.enterText(find.byType(EditableText).first, 'GRINNING');
      await tester.pump();

      expect(find.text(target.char), findsWidgets);
    });

    guardedTestWidgets('matches by keyword, not only shortName', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzEmojiSurface(onEmojiSelected: (_) {}));

      // Pick an emoji whose shortName does NOT contain one of its own
      // keywords, then search by that keyword -- proving the keyword branch
      // of the filter (not just shortName) drives a match.
      final withKeyword = Emoji.all().firstWhere(
        (e) => e.keywords.isNotEmpty && !e.shortName.toLowerCase().contains(e.keywords.first.toLowerCase()),
      );

      await tester.enterText(find.byType(EditableText).first, withKeyword.keywords.first);
      await tester.pump();

      expect(find.text(withKeyword.char), findsWidgets);
    });

    guardedTestWidgets('an unmatched search shows the empty state', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzEmojiSurface(onEmojiSelected: (_) {}));

      await tester.enterText(find.byType(EditableText).first, 'zzzznonexistentquery');
      await tester.pump();

      expect(find.text('No emoji found'), findsOneWidget);
    });

    guardedTestWidgets('search narrows within the currently selected group', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzEmojiSurface(onEmojiSelected: (_) {}));

      await _scrollGroupFilterRow(tester);
      await tester.tap(find.text('Flags'));
      await tester.pump();

      final nonFlag = Emoji.byShortName('grinning')!;
      await tester.enterText(find.byType(EditableText).first, 'grinning');
      await tester.pump();

      // "grinning" is not a Flags-group emoji, so with Flags selected the
      // search must find nothing even though it would match under "All
      // emoji" -- proving the group filter and search compose rather than
      // search alone deciding the result.
      expect(find.text(nonFlag.char), findsNothing);
      expect(find.text('No emoji found'), findsOneWidget);
    });
  });

  group('LayrzEmojiSurface — group chip restyle', () {
    // User testing feedback: the selected chip must paint the full primary
    // fill (matching the color picker's restyled tabs), and the unselected
    // chip must paint the background/canvas token (`sf1`) as a solid fill,
    // not transparent -- a transparent unselected chip produced a visible
    // transition artifact per the user's own report. The selected chip has
    // no `onTap` wired (it is already selected), so `LayrzTappable` takes
    // its inert `DecoratedBox` path; the unselected chip is interactive, so
    // it takes the `AnimatedContainer` path -- both are asserted via their
    // own actual rendered `decoration`, not merely "some chip looks right".
    guardedTestWidgets('the selected chip paints the full primary color', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzEmojiSurface(onEmojiSelected: (_) {}));

      // "All emoji" is selected by default.
      final chipFinder = find.ancestor(
        of: find.text('All emoji'),
        matching: find.byType(LayrzTappable),
      );
      final decoratedBox = tester.widget<DecoratedBox>(
        find.descendant(of: chipFinder, matching: find.byType(DecoratedBox)).first,
      );
      final decoration = decoratedBox.decoration as BoxDecoration;

      final tokens = LayrzTokens.light();
      expect(decoration.color, tokens.colors.primary.shade500);
    });

    guardedTestWidgets('an unselected chip paints a solid background color, not transparent', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzEmojiSurface(onEmojiSelected: (_) {}));

      // "Smileys & Emotion" is not selected by default (only "All emoji" is).
      final chipFinder = find.ancestor(
        of: find.text('Smileys & Emotion'),
        matching: find.byType(LayrzTappable),
      );
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.descendant(of: chipFinder, matching: find.byType(AnimatedContainer)),
      );
      final decoration = animatedContainer.decoration as BoxDecoration;

      final tokens = LayrzTokens.light();
      expect(decoration.color, tokens.colors.sf1);
      expect(decoration.color!.a, 1.0, reason: 'the unselected chip must paint a fully opaque fill, not transparent');
    });
  });

  group('LayrzEmojiSurface — commit on tap', () {
    guardedTestWidgets('tapping an emoji cell invokes onEmojiSelected with that character', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? selected;
      await pumpThemed(tester, LayrzEmojiSurface(onEmojiSelected: (char) => selected = char));

      final target = Emoji.byShortName('grinning')!;
      await tester.enterText(find.byType(EditableText).first, 'grinning');
      await tester.pump();

      await tester.tap(find.text(target.char).first);
      await tester.pump();

      expect(selected, target.char);
    });
  });
}
