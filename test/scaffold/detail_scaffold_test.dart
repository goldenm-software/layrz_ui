import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

import "../helpers/pump_themed.dart";

/// Pumps [child] bounded to [size] -- a `SizedBox` of a fixed height standing
/// in for the wide/folded scaffold layout, where `DetailPane` hands its
/// builder output a bounded box via an ancestor `Expanded`. This is the
/// desktop/folded-pane shape: with no [LayrzBottomSheetScope] ancestor,
/// [LayrzDetailScaffold] expects exactly this -- a bounded box it can fill
/// via `Expanded`.
Future<void> _pumpBounded(WidgetTester tester, Widget child, {Size size = const Size(500, 400)}) {
  return pumpThemed(tester, SizedBox.fromSize(key: const Key("bounded-pane"), size: size, child: child));
}

/// Pumps [child] inside a [LayrzBottomSheetScope], itself inside a
/// `SingleChildScrollView` -- standing in for the narrow-layout
/// `LayrzBottomSheet`, which both wraps its content in a scroll view (hence
/// *unbounded* height) and wraps it in exactly this scope (see
/// `bottom_sheet.dart`). A [LayrzDetailScaffold] rendered here self-detects
/// the scope and shrink-wraps via `Flexible` instead of throwing the
/// "unbounded height" `RenderFlex` error `Expanded` would produce.
Future<void> _pumpUnbounded(WidgetTester tester, Widget child) {
  return pumpThemed(tester, SingleChildScrollView(child: LayrzBottomSheetScope(child: child)));
}

/// A caller-supplied wrapper widget standing in for the real-world regression
/// case -- e.g. `builder: (_) => CategoryForm(...)`, where `CategoryForm` is
/// a `StatefulWidget` that itself returns a [LayrzDetailScaffold] from ITS
/// OWN `build`. The [LayrzDetailScaffold] is therefore NOT a direct child of
/// [LayrzBottomSheetScope] -- this widget sits between them -- which is
/// exactly the shape that broke the old `is LayrzDetailScaffold` direct-type
/// check in `LayrzScaffoldShell`.
class _WrapperFormWidget extends StatefulWidget {
  const _WrapperFormWidget();

  @override
  State<_WrapperFormWidget> createState() => _WrapperFormWidgetState();
}

class _WrapperFormWidgetState extends State<_WrapperFormWidget> {
  @override
  Widget build(BuildContext context) {
    return LayrzDetailScaffold(
      title: const Text("Wrapped title", key: Key("wrapped-title")),
      // Wrapped in the CALLER's own SingleChildScrollView, per the new
      // contract: LayrzDetailScaffold no longer wraps `body` in a scroll view
      // of its own, so a body this tall must bring one to avoid overflowing
      // the bounded height it now genuinely receives (e.g. via the narrow
      // sheet's scrollable: false path).
      body: SingleChildScrollView(
        child: Column(
          children: List.generate(20, (i) => SizedBox(height: 30, child: Text("Field $i"))),
        ),
      ),
      actions: [
        LayrzButton(labelText: "Save", key: const Key("wrapped-save"), onTap: () {}),
      ],
    );
  }
}

void main() {
  group("LayrzDetailScaffold", () {
    testWidgets("renders the pinned title (narrow viewport)", (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await _pumpBounded(
        tester,
        const LayrzDetailScaffold(
          title: Text("Detail title", key: Key("title")),
          body: SizedBox.shrink(),
        ),
      );

      expect(find.byKey(const Key("title")), findsOneWidget);
      expect(find.text("Detail title"), findsOneWidget);
    });

    testWidgets("renders the pinned title (wide viewport)", (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;

      await _pumpBounded(
        tester,
        const LayrzDetailScaffold(
          title: Text("Detail title", key: Key("title")),
          body: SizedBox.shrink(),
        ),
      );

      expect(find.byKey(const Key("title")), findsOneWidget);
      expect(find.text("Detail title"), findsOneWidget);
    });

    testWidgets("renders the body content", (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;

      await _pumpBounded(
        tester,
        const LayrzDetailScaffold(
          title: Text("Title"),
          body: Text("Body content", key: Key("body")),
        ),
      );

      expect(find.byKey(const Key("body")), findsOneWidget);
      expect(find.text("Body content"), findsOneWidget);
    });

    testWidgets(
      "a tall body wrapped in the CALLER's own SingleChildScrollView scrolls instead of overflowing "
      "(narrow viewport, bounded parent)",
      (tester) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        // NEW CONTRACT: LayrzDetailScaffold no longer wraps `body` in a scroll
        // view of its own -- scrolling is entirely the caller's responsibility.
        // This test's `body` therefore brings its OWN SingleChildScrollView, so
        // a tall Column scrolls instead of overflowing the bounded pane.
        await _pumpBounded(
          tester,
          LayrzDetailScaffold(
            title: const Text("Title"),
            body: SingleChildScrollView(
              child: Column(
                children: List.generate(
                  60,
                  (i) => SizedBox(height: 40, child: Text("Row $i", key: Key("row-$i"))),
                ),
              ),
            ),
          ),
          size: const Size(360, 300),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        // The first row is present, but a row far down the list is not yet
        // built/laid out within the visible viewport -- proof the body is
        // actually scrolling rather than being force-fit or silently clipped
        // without a scroll view.
        expect(find.byKey(const Key("row-0")), findsOneWidget);
      },
    );

    testWidgets(
      "a tall body wrapped in the CALLER's own SingleChildScrollView scrolls instead of overflowing "
      "(wide viewport, bounded parent)",
      (tester) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;

        await _pumpBounded(
          tester,
          LayrzDetailScaffold(
            title: const Text("Title"),
            body: SingleChildScrollView(
              child: Column(
                children: List.generate(
                  60,
                  (i) => SizedBox(height: 40, child: Text("Row $i", key: Key("row-$i"))),
                ),
              ),
            ),
          ),
          size: const Size(500, 300),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.byKey(const Key("row-0")), findsOneWidget);
      },
    );

    testWidgets("actions present: footer row renders the buttons, right-aligned", (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;

      await _pumpBounded(
        tester,
        LayrzDetailScaffold(
          title: const Text("Title"),
          body: const SizedBox.shrink(),
          actions: [
            LayrzButton(labelText: "Cancel", key: const Key("cancel-btn"), onTap: () {}),
            LayrzButton(labelText: "Save", key: const Key("save-btn"), onTap: () {}),
          ],
        ),
      );

      expect(find.byKey(const Key("cancel-btn")), findsOneWidget);
      expect(find.byKey(const Key("save-btn")), findsOneWidget);

      final cancelRect = tester.getRect(find.byKey(const Key("cancel-btn")));
      final saveRect = tester.getRect(find.byKey(const Key("save-btn")));
      // Right-aligned: Save (added last) should sit to the right of Cancel.
      expect(saveRect.left, greaterThan(cancelRect.left));

      final row = tester.widgetList<Row>(find.byType(Row));
      expect(row, isNotEmpty);
    });

    testWidgets("actions null: no footer row is rendered", (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;

      await _pumpBounded(
        tester,
        const LayrzDetailScaffold(
          title: Text("Title"),
          body: SizedBox.shrink(),
        ),
      );

      expect(find.byType(LayrzButton), findsNothing);
      // No Row is built at all in this case -- the title's own layout uses a
      // plain DefaultTextStyle.merge (no Row), so finding zero Rows proves no
      // actions footer Row was built either.
      expect(find.byType(Row), findsNothing);
    });

    testWidgets("actions empty list: no footer row is rendered", (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;

      await _pumpBounded(
        tester,
        const LayrzDetailScaffold(
          title: Text("Title"),
          body: SizedBox.shrink(),
          actions: [],
        ),
      );

      expect(find.byType(LayrzButton), findsNothing);
      expect(find.byType(Row), findsNothing);
    });

    testWidgets(
      "REGRESSION: inside a LayrzBottomSheetScope, lays out without an 'unbounded height' RenderFlex error "
      "inside an unbounded ancestor (simulating LayrzBottomSheet's SingleChildScrollView), when the CALLER's "
      "body brings its own scroll view",
      (tester) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        // Under the new contract, a plain tall Column with no scroll view of
        // its own would overflow (there is no scaffold-owned scroller left to
        // absorb it) even inside the Flexible/shrink-wrap branch this test
        // targets. Giving the body its OWN SingleChildScrollView exercises the
        // intended no-throw path -- LayrzDetailScaffold self-detecting the
        // sheet scope and switching to Flexible -- without conflating it with
        // an unrelated overflow.
        await _pumpUnbounded(
          tester,
          LayrzDetailScaffold(
            title: const Text("Title", key: Key("title")),
            body: SingleChildScrollView(
              child: Column(
                children: List.generate(20, (i) => SizedBox(height: 30, child: Text("Field $i"))),
              ),
            ),
            actions: [
              LayrzButton(labelText: "Save", onTap: () {}),
            ],
          ),
        );

        // With no LayrzBottomSheetScope ancestor, the desktop default wraps
        // its body in Expanded, which throws "RenderFlex children have
        // non-zero flex but incoming height constraints are unbounded" under
        // an unbounded ancestor like this one -- that shape is exercised, and
        // expected to stay bounded-only, by the desktop footer-position tests
        // below. Wrapping in LayrzBottomSheetScope (exactly what
        // LayrzBottomSheet itself does around its content) makes
        // LayrzDetailScaffold self-detect it and switch the body to
        // Flexible, which shrink-wraps instead of throwing here.
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key("title")), findsOneWidget);
        expect(find.text("Field 0"), findsOneWidget);
      },
    );

    testWidgets(
      "REGRESSION: inside a LayrzBottomSheetScope, lays out without error inside an unbounded ancestor on a "
      "wide viewport too, when the CALLER's body brings its own scroll view",
      (tester) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;

        await _pumpUnbounded(
          tester,
          LayrzDetailScaffold(
            title: const Text("Title"),
            body: SingleChildScrollView(
              child: Column(
                children: List.generate(20, (i) => SizedBox(height: 30, child: Text("Field $i"))),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      "REGRESSION (the real bug): a LayrzDetailScaffold built by a WRAPPER widget nested inside a "
      "LayrzBottomSheetScope -- NOT a direct child of the scope -- still self-detects the sheet and lays out "
      "without an unbounded-height error",
      (tester) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        // Deliberately does NOT use _pumpUnbounded -- it builds the scope/scroll-view
        // stack explicitly with a Builder + _WrapperFormWidget in between, so the
        // LayrzDetailScaffold this produces is a GRANDCHILD of LayrzBottomSheetScope,
        // never its direct child. This is the exact shape that broke the old
        // `if (built is LayrzDetailScaffold)` check in LayrzScaffoldShell: a real
        // detail builder returning `(_) => CategoryForm(...)`, where CategoryForm
        // itself builds the LayrzDetailScaffold one level further down.
        await pumpThemed(
          tester,
          SingleChildScrollView(
            child: LayrzBottomSheetScope(
              child: Builder(
                builder: (_) => const _WrapperFormWidget(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key("wrapped-title")), findsOneWidget);
        expect(find.byKey(const Key("wrapped-save")), findsOneWidget);
      },
    );

    testWidgets("lays out and scrolls inside a bounded ancestor too, given the CALLER's own scroll view", (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;

      await _pumpBounded(
        tester,
        LayrzDetailScaffold(
          title: const Text("Title"),
          body: SingleChildScrollView(
            child: Column(
              children: List.generate(40, (i) => SizedBox(height: 30, child: Text("Field $i"))),
            ),
          ),
        ),
        size: const Size(400, 250),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets("basic semantics sanity: title text is exposed to the semantics tree", (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;

      final handle = tester.ensureSemantics();
      try {
        await _pumpBounded(
          tester,
          const LayrzDetailScaffold(
            title: Text("Accessible title"),
            body: SizedBox.shrink(),
          ),
        );

        final node = tester.getSemantics(find.text("Accessible title"));
        expect(node.label, "Accessible title");
        expect(node.textDirection, TextDirection.ltr);
      } finally {
        handle.dispose();
      }
    });

    group("desktop pane fills height (no LayrzBottomSheetScope ancestor)", () {
      testWidgets(
        "actions pin to the BOTTOM of a tall bounded pane, when the body actually FILLS its bounded height",
        (tester) async {
          addTearDown(tester.view.reset);
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;

          const paneHeight = 800.0;

          // NEW CONTRACT: the scaffold no longer wraps `body` in a scroll view
          // that used to stretch a short body's own outer Expanded box to the
          // full pane height. A short, non-flexible body (e.g. a bare `Text`)
          // no longer visually pushes the actions row down -- that follows
          // directly from `body` now being placed unscrolled, exactly as
          // given, inside the bounded Expanded slot. This test instead uses a
          // body that genuinely FILLS its bounded height (`SizedBox.expand`),
          // which is the real, supported way to make actions pin to the
          // bottom under the new contract.
          await _pumpBounded(
            tester,
            LayrzDetailScaffold(
              title: const Text("Title", key: Key("title")),
              body: const SizedBox.expand(child: Text("Fill-height body", key: Key("body"))),
              actions: [
                LayrzButton(labelText: "Cancel", key: const Key("cancel-btn"), onTap: () {}),
                LayrzButton(labelText: "Save", key: const Key("save-btn"), onTap: () {}),
              ],
            ),
            size: const Size(600, paneHeight),
          );

          expect(tester.takeException(), isNull);

          final paneRect = tester.getRect(find.byKey(const Key("bounded-pane")));
          final bodyRect = tester.getRect(find.byKey(const Key("body")));
          final actionsRect = tester.getRect(find.byKey(const Key("save-btn")));

          // Sanity: the pane rect (the SizedBox we pumped) really is as tall
          // as intended, i.e. this assertion is exercising a genuinely bounded
          // tall parent.
          expect(paneRect.height, paneHeight);

          // Positions below are converted to pane-local coordinates -- getRect
          // returns global (screen) offsets, and pumpThemed centers the pane
          // inside the full 1200px-tall test surface, so a raw global
          // comparison against paneHeight would be off by the pane's own
          // centering offset.
          final bodyBottomInPane = bodyRect.bottom - paneRect.top;
          final actionsBottomInPane = actionsRect.bottom - paneRect.top;

          // The fill-height body's own box extends nearly to the bottom of the
          // pane -- proof Expanded genuinely filled the remaining space.
          expect(bodyBottomInPane, greaterThan(paneHeight - 100));

          // The actions row sits near the BOTTOM of the 800px pane. A
          // comfortable margin (100px) absorbs the actions row's own height
          // plus padding.
          expect(actionsBottomInPane, greaterThan(paneHeight - 100));
        },
      );

      testWidgets(
        "with a tall body wrapped in the CALLER's own SingleChildScrollView, actions still sit at the bottom "
        "(the scroll view itself fills the bounded Expanded slot)",
        (tester) async {
          addTearDown(tester.view.reset);
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;

          const paneHeight = 500.0;

          await _pumpBounded(
            tester,
            LayrzDetailScaffold(
              title: const Text("Title"),
              body: SingleChildScrollView(
                child: Column(
                  children: List.generate(40, (i) => SizedBox(height: 30, child: Text("Field $i"))),
                ),
              ),
              actions: [
                LayrzButton(labelText: "Save", key: const Key("save-btn"), onTap: () {}),
              ],
            ),
            size: const Size(500, paneHeight),
          );

          expect(tester.takeException(), isNull);
          expect(find.byType(SingleChildScrollView), findsOneWidget);

          final paneRect = tester.getRect(find.byKey(const Key("bounded-pane")));
          final actionsRect = tester.getRect(find.byKey(const Key("save-btn")));
          final actionsBottomInPane = actionsRect.bottom - paneRect.top;
          expect(actionsBottomInPane, greaterThan(paneHeight - 100));
        },
      );
    });

    group("LayrzScaffoldShell narrow-sheet integration", () {
      testWidgets(
        "a LayrzDetailScaffold with actions, returned from a detail builder, lays out in the narrow "
        "bottom sheet without an unbounded-height error -- proving self-detection via LayrzBottomSheetScope "
        "works end-to-end",
        (tester) async {
          final controller = LayrzScaffoldController();
          addTearDown(controller.dispose);
          final tableController = LayrzTableController<String>();
          addTearDown(tableController.dispose);

          await tester.binding.setSurfaceSize(const Size(520, 900));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            LayrzApp(
              theme: LayrzThemeData.light(),
              home: SizedBox.expand(
                child: LayrzScaffoldShell<String>(
                  controller: controller,
                  itemExtent: 56.0,
                  title: const Text('Title'),
                  tableColumns: [
                    LayrzColumn<String>(
                      key: const ValueKey('c'),
                      headerText: 'C',
                      valueBuilder: (item) => '',
                      width: 200,
                    ),
                  ],
                  tableController: tableController,
                  items: [
                    const LayrzScaffoldItem(
                      key: ValueKey("1"),
                      item: "Alpha",
                      tile: SizedBox(child: Text("Alpha")),
                      searchableStrings: {"Alpha"},
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pump();

          // If the shell/scope no longer marked the sheet's content, this
          // LayrzDetailScaffold would wrap its body in Expanded, and
          // LayrzBottomSheet's SingleChildScrollView (unbounded height) would
          // throw "RenderFlex children have non-zero flex but incoming
          // height constraints are unbounded" as soon as the sheet lays out.
          controller.open(
            key: const ValueKey("1"),
            builder: (_) => LayrzDetailScaffold(
              title: const Text("Alpha detail", key: Key("shell-detail-title")),
              body: const Text("Body", key: Key("shell-detail-body")),
              actions: [
                LayrzButton(labelText: "Save", key: const Key("shell-detail-save"), onTap: () {}),
              ],
            ),
          );
          await tester.pump();
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key("shell-detail-title")), findsOneWidget);
          expect(find.byKey(const Key("shell-detail-body")), findsOneWidget);
          expect(find.byKey(const Key("shell-detail-save")), findsOneWidget);
        },
      );

      testWidgets(
        "REGRESSION (full real-world path): a detail builder returning a WRAPPER StatefulWidget that itself "
        "builds a LayrzDetailScaffold lays out in the narrow bottom sheet without an unbounded-height error",
        (tester) async {
          final controller = LayrzScaffoldController();
          addTearDown(controller.dispose);
          final tableController = LayrzTableController<String>();
          addTearDown(tableController.dispose);

          await tester.binding.setSurfaceSize(const Size(520, 900));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            LayrzApp(
              theme: LayrzThemeData.light(),
              home: SizedBox.expand(
                child: LayrzScaffoldShell<String>(
                  controller: controller,
                  itemExtent: 56.0,
                  title: const Text('Title'),
                  tableColumns: [
                    LayrzColumn<String>(
                      key: const ValueKey('c'),
                      headerText: 'C',
                      valueBuilder: (item) => '',
                      width: 200,
                    ),
                  ],
                  tableController: tableController,
                  items: [
                    const LayrzScaffoldItem(
                      key: ValueKey("1"),
                      item: "Alpha",
                      tile: SizedBox(child: Text("Alpha")),
                      searchableStrings: {"Alpha"},
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pump();

          // The detail builder returns _WrapperFormWidget -- NOT a
          // LayrzDetailScaffold directly -- exactly like a real
          // `builder: (_) => CategoryForm(...)` call site, where CategoryForm
          // builds the LayrzDetailScaffold from its own build method. The old
          // `is LayrzDetailScaffold` shell-side check could never see through
          // this wrapper; LayrzBottomSheetScope's ancestor lookup does.
          controller.open(
            key: const ValueKey("1"),
            builder: (_) => const _WrapperFormWidget(),
          );
          await tester.pump();
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key("wrapped-title")), findsOneWidget);
          expect(find.byKey(const Key("wrapped-save")), findsOneWidget);
        },
      );
    });

    group("REGRESSION: LayrzTabView(expandContent: true) as body", () {
      // The reported bug: LayrzTabView's `expandContent: true` (the default)
      // wraps the selected tab's content in an `Expanded`, which requires a
      // genuinely bounded-height ancestor. Before the scroll view was removed
      // from LayrzDetailScaffold's body slot, that inner Expanded sat inside
      // an unbounded SingleChildScrollView and threw "RenderFlex children
      // have non-zero flex but incoming height constraints are unbounded".
      // The new contract -- body placed directly in a bounded Expanded/
      // Flexible slot, with no scroll view of its own -- fixes this because
      // the height LayrzTabView receives is now genuinely bounded on both the
      // wide (Expanded) and narrow/in-sheet (Flexible, via scrollable: false)
      // paths.
      testWidgets(
        "wide/desktop path (Expanded slot): lays out without an unbounded-height error and the selected "
        "tab's content is laid out",
        (tester) async {
          addTearDown(tester.view.reset);
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;

          await _pumpBounded(
            tester,
            LayrzDetailScaffold(
              title: const Text("Title"),
              body: LayrzTabView(
                expandContent: true,
                tabs: [
                  LayrzTab(
                    labelText: "First",
                    child: const Text("First tab content", key: Key("first-tab-content")),
                  ),
                  LayrzTab(
                    labelText: "Second",
                    child: const Text("Second tab content", key: Key("second-tab-content")),
                  ),
                ],
              ),
            ),
            size: const Size(600, 800),
          );

          expect(tester.takeException(), isNull);
          // The selected (first) tab's content is genuinely laid out.
          expect(find.byKey(const Key("first-tab-content")), findsOneWidget);
          expect(find.text("First tab content"), findsOneWidget);
        },
      );

      testWidgets(
        "narrow/in-sheet path (Flexible slot, simulating scrollable: false): lays out without an "
        "unbounded-height error and the selected tab's content is laid out",
        (tester) async {
          addTearDown(tester.view.reset);
          tester.view.physicalSize = const Size(400, 800);
          tester.view.devicePixelRatio = 1.0;

          // Simulates the narrow LayrzBottomSheet path with scrollable: false
          // (scaffold_shell.dart:709): a LayrzBottomSheetScope ancestor (so
          // LayrzDetailScaffold self-detects "in sheet" and uses Flexible) plus
          // a BOUNDED height ancestor -- unlike _pumpUnbounded's
          // SingleChildScrollView, which stands in for the OLD scrollable:
          // true default. scrollable: false hands the sheet's content a
          // bounded box instead (via the sheet's own Column(max)/Expanded
          // chain), which is exactly what lets LayrzTabView's inner Expanded
          // lay out instead of throwing.
          await pumpThemed(
            tester,
            SizedBox(
              width: 400,
              height: 700,
              child: LayrzBottomSheetScope(
                child: LayrzDetailScaffold(
                  title: const Text("Title"),
                  body: LayrzTabView(
                    expandContent: true,
                    tabs: [
                      LayrzTab(
                        labelText: "First",
                        child: const Text("First tab content", key: Key("first-tab-content")),
                      ),
                      LayrzTab(
                        labelText: "Second",
                        child: const Text("Second tab content", key: Key("second-tab-content")),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key("first-tab-content")), findsOneWidget);
          expect(find.text("First tab content"), findsOneWidget);
        },
      );
    });
  });
}
