import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_selection_registrar.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzAvatar text glyph selection boundary', () {
    testWidgets(
      'emoji constructor: disabled selection registrar shadows an enabled ancestor',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: const LayrzAvatar.emoji(emoji: '😀'),
          ),
        );

        final emojiContext = tester.element(find.text('😀'));

        expect(SelectionContainer.maybeOf(emojiContext), isNull);
      },
    );

    testWidgets(
      'initials fallback: disabled selection registrar shadows an enabled ancestor',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: const LayrzAvatar.initials(nameText: 'Jane Doe'),
          ),
        );

        final initialsContext = tester.element(find.text('JA'));

        expect(SelectionContainer.maybeOf(initialsContext), isNull);
      },
    );

    testWidgets(
      'LayrzAvatarEmoji source: disabled selection registrar shadows an enabled ancestor',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final source = LayrzAvatarEmoji('🎉');

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: LayrzAvatar(source: source, semanticLabel: 'Celebration'),
          ),
        );

        final emojiContext = tester.element(find.text('🎉'));

        expect(SelectionContainer.maybeOf(emojiContext), isNull);
      },
    );

    testWidgets(
      'structural: the initials Text has a SelectionContainer ancestor',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          const LayrzAvatar.initials(nameText: 'Structural Check'),
        );

        expect(
          find.ancestor(of: find.text('ST'), matching: find.byType(SelectionContainer)),
          findsOneWidget,
        );
      },
    );
  });
}
