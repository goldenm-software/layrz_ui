import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzContextMenuEntry label selection boundary (DESIGN-135 follow-up)', () {
    testWidgets(
      'the entry label sees a disabled SelectionContainer, shadowing the panel\'s own',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzContextMenu(
            entries: const [
              LayrzContextMenuEntry(labelText: 'Entry label', onTap: _noop),
            ],
            child: const SizedBox(width: 200, height: 100, child: Text('Target')),
          ),
        );

        await tester.tap(
          find.text('Target'),
          buttons: kSecondaryMouseButton,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();

        final labelContext = tester.element(find.text('Entry label'));

        // The panel itself sits inside a real SelectionArea/registrar
        // hierarchy in a host app; here it is enough to prove the label's
        // own scope is the disabled one this fix introduces, which shadows
        // whatever selection ancestor a caller wraps the menu in.
        final nearestScope = SelectionContainer.maybeOf(labelContext);
        expect(nearestScope, isNull);
      },
    );

    testWidgets(
      'structural: the entry label has a SelectionContainer ancestor once the panel opens',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzContextMenu(
            entries: const [
              LayrzContextMenuEntry(labelText: 'Structural entry', onTap: _noop),
            ],
            child: const SizedBox(width: 200, height: 100, child: Text('Target')),
          ),
        );

        await tester.tap(
          find.text('Target'),
          buttons: kSecondaryMouseButton,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();

        expect(
          find.ancestor(of: find.text('Structural entry'), matching: find.byType(SelectionContainer)),
          findsOneWidget,
        );
      },
    );
  });

  group('LayrzContextMenuLabel heading selection boundary (DESIGN-135 follow-up)', () {
    testWidgets(
      'the section heading sees a disabled SelectionContainer, shadowing the panel\'s own',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzContextMenu(
            entries: const [
              LayrzContextMenuLabel(labelText: 'Section heading'),
              LayrzContextMenuEntry(labelText: 'Entry label', onTap: _noop),
            ],
            child: const SizedBox(width: 200, height: 100, child: Text('Target')),
          ),
        );

        await tester.tap(
          find.text('Target'),
          buttons: kSecondaryMouseButton,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();

        final headingContext = tester.element(find.text('Section heading'));

        expect(SelectionContainer.maybeOf(headingContext), isNull);
      },
    );

    testWidgets(
      'structural: the section heading has a SelectionContainer ancestor once the panel opens',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzContextMenu(
            entries: const [
              LayrzContextMenuLabel(labelText: 'Structural heading'),
              LayrzContextMenuEntry(labelText: 'Entry label', onTap: _noop),
            ],
            child: const SizedBox(width: 200, height: 100, child: Text('Target')),
          ),
        );

        await tester.tap(
          find.text('Target'),
          buttons: kSecondaryMouseButton,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();

        expect(
          find.ancestor(of: find.text('Structural heading'), matching: find.byType(SelectionContainer)),
          findsOneWidget,
        );
      },
    );
  });
}

void _noop() {}
