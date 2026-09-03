import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Minimal domain object used to exercise [LayrzScaffoldShell] in isolation.
class _TestItem {
  /// Creates a test item with the given [id] and [name].
  const _TestItem(this.id, this.name);

  /// Stable identifier, mirrored by the [LayrzScaffoldItem.key] used in tests.
  final String id;

  /// Display name rendered by the tile and detail builder.
  final String name;
}

void main() {
  group('LayrzScaffoldShell composed under LayrzLayout (the showroom\'s real shape)', () {
    // Every other LayrzScaffoldShell test in this directory pumps the shell
    // directly as `home`, with no LayrzLayout ancestor -- but the showroom
    // (example/lib/layout.dart's ShowroomLayout) always wraps every section,
    // including LayrzScaffoldShell-based ones, in LayrzLayout. That gap in
    // coverage let a real regression (990d504's clearSelection() call,
    // reverted) reach `development`: LayrzLayout's default
    // selectableContent: true gives the shell a genuine ancestor
    // SelectableRegion, which none of the other shell tests exercise at
    // all -- context.findAncestorStateOfType<SelectableRegionState>() always
    // returned null in every existing test, silently skipping any code path
    // that depended on finding one.
    //
    // This test pins down the showroom's actual composition as a permanent
    // regression guard: LayrzLayout(selectableContent: true) wrapping
    // LayrzScaffoldShell, at a narrow width, opening the narrow detail
    // sheet via a row tap. It must pass on a clean `development` and must
    // keep passing for any future change in this area.
    testWidgets(
      'opening the narrow detail sheet succeeds with a genuine ancestor SelectableRegion present',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        // Pin DPR before physicalSize: ambient DPR is 3.0, so a naive
        // physicalSize would resolve to an unintended logical size.
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, 800); // narrow (< 960 logical)

        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);

        final items = [
          LayrzScaffoldItem<_TestItem>(
            key: const ValueKey('text-input'),
            item: const _TestItem('text-input', 'Text Input'),
            tile: const SizedBox(height: 40, child: Text('Text Input')),
            searchableStrings: const {'Text Input'},
          ),
          LayrzScaffoldItem<_TestItem>(
            key: const ValueKey('combobox-input'),
            item: const _TestItem('combobox-input', 'ComboBox Input'),
            tile: const SizedBox(height: 40, child: Text('ComboBox Input')),
            searchableStrings: const {'ComboBox Input'},
          ),
        ];

        await tester.pumpWidget(
          LayrzApp(
            theme: LayrzThemeData.light(),
            debugShowCheckedModeBanner: false,
            // The real shape: LayrzLayout wraps LayrzScaffoldShell, exactly
            // as example/lib/layout.dart's ShowroomLayout wraps
            // InputsSection. selectableContent defaults to true, so this
            // genuinely gives the shell an ancestor SelectableRegion, unlike
            // every other LayrzScaffoldShell test in this directory.
            home: LayrzLayout(
              logo: 'assets/test-logo.png',
              items: [
                LayrzNavigatorPage(id: 'home', labelText: 'Home'),
              ],
              body: LayrzScaffoldShell<_TestItem>(
                controller: controller,
                items: items,
                itemExtent: 56.0,
                onDetailsBuild: (item) => Text('Detail for ${item.name}'),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.byType(SelectableRegion),
          findsOneWidget,
          reason: 'LayrzLayout must provide a genuine ancestor SelectableRegion for this test to be meaningful',
        );

        final rowFinder = find.text('Text Input');
        expect(rowFinder, findsOneWidget);

        await tester.tap(rowFinder);
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'opening the narrow detail sheet must not throw with an ancestor SelectableRegion present',
        );
        expect(find.text('Detail for Text Input'), findsOneWidget, reason: 'the narrow detail sheet must open');
      },
    );

    testWidgets(
      'the narrow detail sheet still dismisses normally in this composition',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, 800);

        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);

        final items = [
          LayrzScaffoldItem<_TestItem>(
            key: const ValueKey('text-input'),
            item: const _TestItem('text-input', 'Text Input'),
            tile: const SizedBox(height: 40, child: Text('Text Input')),
            searchableStrings: const {'Text Input'},
          ),
        ];

        await tester.pumpWidget(
          LayrzApp(
            theme: LayrzThemeData.light(),
            debugShowCheckedModeBanner: false,
            home: LayrzLayout(
              logo: 'assets/test-logo.png',
              items: [
                LayrzNavigatorPage(id: 'home', labelText: 'Home'),
              ],
              body: LayrzScaffoldShell<_TestItem>(
                controller: controller,
                items: items,
                itemExtent: 56.0,
                onDetailsBuild: (item) => Text('Detail for ${item.name}'),
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.tap(find.text('Text Input'));
        await tester.pumpAndSettle();
        expect(find.text('Detail for Text Input'), findsOneWidget);

        // A point visibly above the sheet's own content, so it lands on the
        // barrier.
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Detail for Text Input'), findsNothing);
      },
    );

    testWidgets(
      'COMPOSITION SMOKE TEST: opening the LayrzLayout drawer with a fold injected does not throw '
      'mid-animation -- the real composition a device crash was measured in',
      (tester) async {
        // The real crash, from a real device, was measured in exactly this
        // composition (LayrzLayout's drawer presentation, LayrzScaffoldShell
        // as the body, mid drawer-open animation):
        //
        //   RenderBox was not laid out: RenderTransform#... NEEDS-LAYOUT
        //   'hasSize': is not true.
        //     #3 RenderTransform._effectiveTransform
        //     #4 RenderTransform.applyPaintTransform
        //     #5 RenderObject.getTransformTo
        //     #6 RenderBox.localToGlobal
        //     #7 _LayrzScaffoldShellState._resolveFoldSplit
        //     #8 _LayrzScaffoldShellState.build.<anonymous closure>
        //
        // NOTE ON WHAT THIS TEST DOES AND DOES NOT PROVE: this drives the
        // real LayrzLayout drawer-open animation, pumped frame-by-frame with
        // a fold injected, and is a genuine end-to-end smoke test of that
        // composition. It is intentionally NOT relied on as the regression
        // guard for the crash, because it was verified NOT to discriminate:
        // it passes both before and after the fix in this harness.
        // TestWidgetsFlutterBinding.pump() always drains the entire
        // pipeline's layout phase to completion before returning, so there
        // is no way, from outside a pump() call, to observe an ancestor
        // mid-`performLayout` the way a real device's frame scheduling can
        // leave it. The actual discriminating regression test -- proven to
        // fail against the pre-fix implementation with this exact assertion,
        // and to pass against the fix -- is
        // "REGRESSION (crash on device): the shell does not throw when
        // reparented under a fresh RenderTransform in a single rebuild,
        // with a fold active" in test/scaffold/scaffold_shell_fold_test.dart,
        // which forces the actual structural condition (an already-laid-out
        // shell element reparented under a brand-new RenderTransform in a
        // single rebuild) directly rather than relying on animation timing.
        // This test stays as an end-to-end sanity check of the real
        // composition, not a substitute for that one.
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetDisplayFeatures);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, 800); // narrow (< 960 logical) -> drawer presentation

        final feature = const DisplayFeature(
          bounds: Rect.fromLTRB(200, 0, 200, 800),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureFlat,
        );
        tester.view.displayFeatures = [feature];

        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);

        final items = [
          LayrzScaffoldItem<_TestItem>(
            key: const ValueKey('text-input'),
            item: const _TestItem('text-input', 'Text Input'),
            tile: const SizedBox(height: 40, child: Text('Text Input')),
            searchableStrings: const {'Text Input'},
          ),
        ];

        await tester.pumpWidget(
          LayrzApp(
            theme: LayrzThemeData.light(),
            debugShowCheckedModeBanner: false,
            home: Builder(
              builder: (context) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(displayFeatures: [feature]),
                  child: LayrzLayout(
                    logo: 'assets/test-logo.png',
                    items: [
                      LayrzNavigatorPage(id: 'home', labelText: 'Home'),
                    ],
                    body: LayrzScaffoldShell<_TestItem>(
                      controller: controller,
                      items: items,
                      itemExtent: 56.0,
                      onDetailsBuild: (item) => Text('Detail for ${item.name}'),
                    ),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        // Open the drawer -- this starts the animated Transform.translate /
        // Transform.scale reveal in drawer_scaffold.dart, with the shell
        // (and its fold-aware LayoutBuilder) as a descendant of that
        // animating ancestor.
        final triggerFinder = find.byKey(const ValueKey('drawer_trigger_button'));
        expect(triggerFinder, findsOneWidget, reason: 'Drawer trigger button must be present');
        await tester.tap(triggerFinder);

        // Pump partial frames through the drawer's open animation -- NOT
        // pumpAndSettle, which would jump straight to the resting state and
        // skip every mid-animation frame where the ancestor Transform is
        // actually dirty. This is the actual mechanism the crash requires.
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(tester.takeException(), isNull, reason: 'must not throw mid drawer-open animation, tick $i');
        }

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
