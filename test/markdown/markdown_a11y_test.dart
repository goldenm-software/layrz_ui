import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  const wideSize = Size(1600, 1200);

  group('LayrzMarkdown Accessibility', () {
    testWidgets('heading and paragraph text are reachable in the semantics tree', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          const LayrzMarkdown(data: '# Section Title\n\nA readable paragraph of body content.'),
        );

        final rootSemantics = tester.getSemantics(find.byType(LayrzMarkdown));
        final labels = <String>[];
        void collect(SemanticsNode node) {
          if (node.label.isNotEmpty) {
            labels.add(node.label);
          }
          node.visitChildren((child) {
            collect(child);
            return true;
          });
        }

        collect(rootSemantics);
        final joined = labels.join(' | ');

        expect(joined, contains('Section Title'));
        expect(joined, contains('A readable paragraph of body content.'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('a link is reachable in the semantics tree with its visible text', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzMarkdown(
            data: 'Read the [documentation](https://example.com) for more.',
            onTapLink: (_, _) {},
          ),
        );

        final rootSemantics = tester.getSemantics(find.byType(LayrzMarkdown));
        final labels = <String>[];
        void collect(SemanticsNode node) {
          if (node.label.isNotEmpty) {
            labels.add(node.label);
          }
          node.visitChildren((child) {
            collect(child);
            return true;
          });
        }

        collect(rootSemantics);
        final joined = labels.join(' | ');

        expect(joined, contains('documentation'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('an unordered list item is reachable in the semantics tree', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzMarkdown(data: '- first bullet\n- second bullet'));

        final rootSemantics = tester.getSemantics(find.byType(LayrzMarkdown));
        final labels = <String>[];
        void collect(SemanticsNode node) {
          if (node.label.isNotEmpty) {
            labels.add(node.label);
          }
          node.visitChildren((child) {
            collect(child);
            return true;
          });
        }

        collect(rootSemantics);
        final joined = labels.join(' | ');

        expect(joined, contains('first bullet'));
        expect(joined, contains('second bullet'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('rendering survives 2x text scale without throwing and keeps text reachable', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: const LayrzMarkdown(data: '# Scaled Title\n\nScaled paragraph body.'),
          ),
        );

        expect(tester.takeException(), isNull);

        final rootSemantics = tester.getSemantics(find.byType(LayrzMarkdown));
        final labels = <String>[];
        void collect(SemanticsNode node) {
          if (node.label.isNotEmpty) {
            labels.add(node.label);
          }
          node.visitChildren((child) {
            collect(child);
            return true;
          });
        }

        collect(rootSemantics);
        final joined = labels.join(' | ');
        expect(joined, contains('Scaled Title'));
      } finally {
        handle.dispose();
      }
    });
  });
}
