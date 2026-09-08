import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_selection_registrar.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzFileInput selection boundary (DESIGN-135 follow-up)', () {
    testWidgets(
      'the empty-state hint sees a disabled selection registrar, not the ancestor\'s own',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: const LayrzFileInput(hintText: 'Drop files here'),
          ),
        );

        final hintContext = tester.element(find.text('Drop files here'));

        expect(SelectionContainer.maybeOf(hintContext), isNull);
      },
    );

    testWidgets(
      'structural: the empty-state hint has a SelectionContainer ancestor',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          const LayrzFileInput(hintText: 'Structural hint'),
        );

        expect(
          find.ancestor(of: find.text('Structural hint'), matching: find.byType(SelectionContainer)),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'the label text sees a disabled selection registrar, not the ancestor\'s own',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: const LayrzFileInput(labelText: 'Attachments'),
          ),
        );

        final labelContext = tester.element(find.text('Attachments', findRichText: true));

        expect(SelectionContainer.maybeOf(labelContext), isNull);
      },
    );

    testWidgets(
      'the picked-file name sees a disabled selection registrar, not the ancestor\'s own',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: LayrzFileInput(
              value: [
                LayrzFileInputResult(
                  name: 'report.pdf',
                  mimeType: 'application/pdf',
                  bytes: Uint8List.fromList([1, 2, 3]),
                ),
              ],
            ),
          ),
        );

        final nameContext = tester.element(find.text('report.pdf'));

        expect(SelectionContainer.maybeOf(nameContext), isNull);
      },
    );

    testWidgets(
      'the "Add more" affordance label sees a disabled selection registrar',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: LayrzFileInput(
              value: [
                LayrzFileInputResult(
                  name: 'report.pdf',
                  mimeType: 'application/pdf',
                  bytes: Uint8List.fromList([1, 2, 3]),
                ),
              ],
            ),
          ),
        );

        final addMoreContext = tester.element(find.text('Add more'));

        expect(SelectionContainer.maybeOf(addMoreContext), isNull);
      },
    );

    testWidgets(
      'the "Clear all" affordance label sees a disabled selection registrar',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: LayrzFileInput(
              value: [
                LayrzFileInputResult(
                  name: 'report.pdf',
                  mimeType: 'application/pdf',
                  bytes: Uint8List.fromList([1, 2, 3]),
                ),
                LayrzFileInputResult(
                  name: 'invoice.pdf',
                  mimeType: 'application/pdf',
                  bytes: Uint8List.fromList([4, 5, 6]),
                ),
              ],
            ),
          ),
        );

        // The populated box is a fixed-height ListView; with two file rows
        // plus "Add more", the trailing "Clear all" row sits below the
        // initial viewport and is not yet built -- scroll it into view first.
        await tester.scrollUntilVisible(find.text('Clear all'), 50, scrollable: find.byType(Scrollable));
        await tester.pump();

        final clearAllContext = tester.element(find.text('Clear all'));

        expect(SelectionContainer.maybeOf(clearAllContext), isNull);
      },
    );
  });
}
