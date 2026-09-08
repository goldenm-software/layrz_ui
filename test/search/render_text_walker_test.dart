import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/search/src/render_text_walker.dart';

import '../helpers/root_render_object.dart';

void main() {
  group('findRenderTextSources', () {
    testWidgets('collects a RenderParagraph source per Text/RichText with its painted plain text', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('First mango paragraph'),
              Text('Second paragraph, no fruit here'),
            ],
          ),
        ),
      );

      final root = rootRenderObject();
      final sources = findRenderTextSources(root);

      final plainTexts = sources.map((s) => s.plainText).toList();
      expect(plainTexts, contains('First mango paragraph'));
      expect(plainTexts, contains('Second paragraph, no fruit here'));
    });

    testWidgets('a RichText source combines all of its spans into one plain text', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RichText(
            text: const TextSpan(
              children: [
                TextSpan(text: 'A rich text mentions '),
                TextSpan(
                  text: 'mango',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' here.'),
              ],
            ),
          ),
        ),
      );

      final root = rootRenderObject();
      final sources = findRenderTextSources(root);

      expect(sources, hasLength(1));
      expect(sources.single.plainText, 'A rich text mentions mango here.');
    });

    testWidgets(
      'plainText includes a placeholder for a WidgetSpan, and boxesForSelection stays aligned to it '
      '(DESIGN-109 offset-mismatch regression)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Mirrors the real bug this test guards against: a sidebar-style row
        // with an inline icon (a WidgetSpan) before its label. plainText
        // must count that WidgetSpan as exactly one 0xFFFC placeholder
        // character — the same single code unit TextSelection's own offset
        // space counts it as — or every occurrence found after it in
        // plainText will be searched for at the wrong index into
        // getBoxesForSelection, landing a highlight box on the wrong word.
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14),
                  children: [
                    const WidgetSpan(child: SizedBox(width: 16, height: 16)),
                    const TextSpan(text: ' mango label'),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final root = rootRenderObject();
        final source = findRenderTextSources(root).single;

        // Exactly one 0xFFFC per WidgetSpan — the placeholder-inclusive
        // plainText this module must build.
        expect(source.plainText, '￼ mango label');

        final occurrenceIndex = source.plainText.indexOf('mango');
        expect(occurrenceIndex, 2);

        final boxes = source.boxesForSelection(
          TextSelection(baseOffset: occurrenceIndex, extentOffset: occurrenceIndex + 'mango'.length),
        );
        expect(boxes, isNotEmpty);

        // The WidgetSpan is a 16-logical-pixel-wide placeholder painted
        // before the text — "mango" must start at or past that width, not
        // near x=0 (which is what a placeholder-stripped plainText's
        // now-too-small occurrence index would incorrectly select instead:
        // the leading space plus part of "mango" itself).
        expect(boxes.first.left, greaterThanOrEqualTo(15.5));
      },
    );

    testWidgets('collects a RenderEditable source for an EditableText, with its live text', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController(text: 'An editable field with mango inside.');
      addTearDown(controller.dispose);
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 14),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFF000000),
          ),
        ),
      );

      final root = rootRenderObject();
      final sources = findRenderTextSources(root);

      expect(sources.map((s) => s.plainText), contains('An editable field with mango inside.'));
    });

    testWidgets('a source globalRect matches the widget global paint bounds', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 40, top: 20),
              child: Text('Positioned mango text'),
            ),
          ),
        ),
      );

      final root = rootRenderObject();
      final sources = findRenderTextSources(root);

      expect(sources, hasLength(1));
      final rect = sources.single.globalRect;
      expect(rect.left, closeTo(40, 0.5));
      expect(rect.top, closeTo(20, 0.5));
    });

    testWidgets(
      'a source globalRect still includes a sidebar ancestor offset through a Navigator/Overlay boundary',
      (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Mirrors the real app's shell shape this investigation is about: a
        // fixed-width sidebar beside routed content that itself renders
        // through a Navigator (which always paints its pages inside an
        // Overlay/_Theater) — the concern under test is specifically whether
        // findRenderTextSources' render-tree walk still picks up the
        // sidebar's horizontal offset for a RenderParagraph nested inside
        // that routed content, or whether the Overlay boundary causes
        // RenderBox.localToGlobal to stop short of the true screen root.
        const sidebarWidth = 220.0;
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                const SizedBox(width: sidebarWidth, child: Text('Sidebar')),
                Expanded(
                  child: Navigator(
                    onGenerateRoute: (settings) => PageRouteBuilder<void>(
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return const Align(
                          alignment: Alignment.topLeft,
                          child: Text('Routed mango content'),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final root = rootRenderObject();
        final sources = findRenderTextSources(root);

        final routedSource = sources.firstWhere((s) => s.plainText == 'Routed mango content');

        // If the Overlay boundary silently truncated the transform chain,
        // this would come back at (or near) x=0 instead of past the
        // sidebar — this is the ~210px-class shift this test exists to
        // catch automatically, matching the on-device symptom this
        // investigation is chasing.
        expect(
          routedSource.globalRect.left,
          greaterThanOrEqualTo(sidebarWidth - 0.5),
          reason:
              'a RenderParagraph routed through a Navigator/Overlay must still resolve to a '
              'global rect that accounts for the sidebar ancestor sitting beside it — a rect '
              'left of the sidebar would mean the render-tree walk lost that ancestor offset',
        );
      },
    );

    testWidgets('boxesForSelection returns a rect at the selected offsets, in global coordinates', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: Text('mango kiwi', style: TextStyle(fontSize: 20)),
          ),
        ),
      );

      final root = rootRenderObject();
      final source = findRenderTextSources(root).single;

      // "mango" is offsets 0-5, "kiwi" is offsets 6-10.
      final mangoBoxes = source.boxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 5));
      final kiwiBoxes = source.boxesForSelection(const TextSelection(baseOffset: 6, extentOffset: 10));

      expect(mangoBoxes, isNotEmpty);
      expect(kiwiBoxes, isNotEmpty);
      // "mango" starts at the left edge of the paragraph; "kiwi" starts to
      // its right, after a space — the two boxes must not overlap and must
      // be in reading order.
      expect(mangoBoxes.first.left, lessThan(kiwiBoxes.first.left));
      expect(mangoBoxes.first.right, lessThanOrEqualTo(kiwiBoxes.first.left + 0.5));
    });

    testWidgets('returns const [] when the tree has no RenderParagraph/RenderEditable', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(width: 10, height: 10),
        ),
      );

      final root = rootRenderObject();
      expect(findRenderTextSources(root), isEmpty);
    });
  });

  group('resolveRenderTextSource', () {
    test('picks the source whose rect contains the target rect center', () {
      const farRect = Rect.fromLTWH(0, 0, 100, 20);
      const nearRect = Rect.fromLTWH(0, 100, 100, 20);
      final far = RenderTextSource(
        plainText: 'far away text',
        globalRect: farRect,
        boxesForSelection: (_) => const [],
        renderObject: RenderErrorBox(),
      );
      final near = RenderTextSource(
        plainText: 'nearby mango text',
        globalRect: nearRect,
        boxesForSelection: (_) => const [],
        renderObject: RenderErrorBox(),
      );

      final target = const Rect.fromLTWH(10, 102, 80, 16);
      final resolved = resolveRenderTextSource(target, [far, near]);

      expect(resolved, same(near));
    });

    test('returns null when no source contains the target rect center', () {
      final source = RenderTextSource(
        plainText: 'text',
        globalRect: const Rect.fromLTWH(0, 0, 10, 10),
        boxesForSelection: (_) => const [],
        renderObject: RenderErrorBox(),
      );

      final target = const Rect.fromLTWH(500, 500, 10, 10);
      expect(resolveRenderTextSource(target, [source]), isNull);
    });

    test('prefers the smallest-area containing source when more than one qualifies', () {
      const target = Rect.fromLTWH(10, 10, 5, 5);
      final outer = RenderTextSource(
        plainText: 'outer',
        globalRect: const Rect.fromLTWH(0, 0, 200, 200),
        boxesForSelection: (_) => const [],
        renderObject: RenderErrorBox(),
      );
      final inner = RenderTextSource(
        plainText: 'inner',
        globalRect: const Rect.fromLTWH(5, 5, 20, 20),
        boxesForSelection: (_) => const [],
        renderObject: RenderErrorBox(),
      );

      final resolved = resolveRenderTextSource(target, [outer, inner]);
      expect(resolved, same(inner));
    });
  });
}
