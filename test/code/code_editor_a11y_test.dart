import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/code/src/code_editor.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzCodeEditor accessibility', () {
    testWidgets('editable field exposes a focusable, enabled text field (wide)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          const LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1'),
        );

        expect(
          tester.getSemantics(find.byType(EditableText)),
          matchesSemantics(
            isTextField: true,
            isMultiline: true,
            isFocusable: true,
            hasEnabledState: true,
            isEnabled: true,
            isReadOnly: false,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('editable field exposes a focusable, enabled text field (compact)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          const LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1'),
        );

        expect(
          tester.getSemantics(find.byType(EditableText)),
          matchesSemantics(
            isTextField: true,
            isMultiline: true,
            isFocusable: true,
            hasEnabledState: true,
            isEnabled: true,
            isReadOnly: false,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('readOnly editor exposes no EditableText semantics node', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          const LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1', readOnly: true),
        );

        expect(find.byType(EditableText), findsNothing);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('disabled editor exposes no EditableText semantics node', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          const LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1', disabled: true),
        );

        expect(find.byType(EditableText), findsNothing);
      } finally {
        handle.dispose();
      }
    });
  });
}
