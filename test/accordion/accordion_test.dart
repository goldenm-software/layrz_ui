import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';
import '../helpers/pump_themed_app.dart';

/// A marker widget used as the accordion body so tests can assert its
/// presence/absence in the tree without depending on incidental descendants
/// (like [Text]) that other parts of the header also render.
class _BodyMarker extends StatelessWidget {
  const _BodyMarker();

  @override
  Widget build(BuildContext context) => const Text('body-marker-content');
}

/// Pumps [LayrzAccordion] at both a wide (1600x1200) and a narrow (400x800)
/// viewport, running [verify] against each. The accordion's layout does not
/// branch on `context.isCompact`, but both directions are exercised anyway to
/// guard against a future regression that makes it start doing so silently.
Future<void> _pumpAtBothViewports(
  WidgetTester tester,
  Widget Function() build,
  Future<void> Function() verify,
) async {
  for (final size in [const Size(1600, 1200), const Size(400, 800)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpThemed(tester, build());
    await verify();
  }
}

void main() {
  group('LayrzAccordion', () {
    testWidgets('renders title and leading icon in the header', (tester) async {
      await _pumpAtBothViewports(
        tester,
        () => LayrzAccordion(
          titleText: 'Section title',
          leadingIcon: MdiIcons.folderOutline,
          expanded: false,
          onExpansionChanged: (_) {},
          body: const _BodyMarker(),
        ),
        () async {
          expect(find.text('Section title'), findsOneWidget);
          expect(find.byIcon(MdiIcons.folderOutline), findsOneWidget);
        },
      );
    });

    testWidgets('omits leading icon space when leadingIcon is null', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzAccordion(
          titleText: 'No icon',
          expanded: false,
          onExpansionChanged: (_) {},
          body: const _BodyMarker(),
        ),
      );

      // Only the trailing chevron icon should be present -- no leading icon.
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('collapsed body is genuinely absent from the tree', (tester) async {
      await pumpThemed(
        tester,
        LayrzAccordion(
          titleText: 'Collapsible',
          expanded: false,
          onExpansionChanged: (_) {},
          body: const _BodyMarker(),
        ),
      );

      expect(find.byType(_BodyMarker), findsNothing);
    });

    testWidgets('expanded body is present in the tree', (tester) async {
      await pumpThemed(
        tester,
        LayrzAccordion(
          titleText: 'Expanded',
          expanded: true,
          onExpansionChanged: (_) {},
          body: const _BodyMarker(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(_BodyMarker), findsOneWidget);
    });

    testWidgets('body is removed again after collapsing from expanded', (tester) async {
      bool expanded = true;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzAccordion(
            titleText: 'Toggle me',
            expanded: expanded,
            onExpansionChanged: (value) => setState(() => expanded = value),
            body: const _BodyMarker(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(_BodyMarker), findsOneWidget);

      await tester.tap(find.text('Toggle me'));
      await tester.pumpAndSettle();

      expect(expanded, isFalse);
      expect(find.byType(_BodyMarker), findsNothing);
    });

    testWidgets('tapping anywhere on the header toggles -- not only the chevron', (tester) async {
      bool? lastValue;

      await pumpThemedApp(
        tester,
        LayrzAccordion(
          titleText: 'Whole header target',
          expanded: false,
          onExpansionChanged: (value) => lastValue = value,
          body: const _BodyMarker(),
        ),
      );

      // Tap directly on the title text, nowhere near the chevron.
      await tester.tap(find.text('Whole header target'));
      await tester.pumpAndSettle();

      expect(lastValue, isTrue);
    });

    testWidgets('tapping the chevron also toggles', (tester) async {
      bool? lastValue;

      await pumpThemedApp(
        tester,
        LayrzAccordion(
          titleText: 'Chevron target',
          expanded: false,
          onExpansionChanged: (value) => lastValue = value,
          body: const _BodyMarker(),
        ),
      );

      await tester.tap(find.byIcon(MdiIcons.chevronDown));
      await tester.pumpAndSettle();

      expect(lastValue, isTrue);
    });

    testWidgets('is a fully controlled component -- expanded does not change without a rebuild', (tester) async {
      int callCount = 0;

      await pumpThemedApp(
        tester,
        LayrzAccordion(
          titleText: 'Controlled',
          expanded: false,
          onExpansionChanged: (_) => callCount++,
          body: const _BodyMarker(),
        ),
      );

      await tester.tap(find.text('Controlled'));
      await tester.pumpAndSettle();

      // The callback fired, but since the test never fed the new value back in,
      // the widget's own `expanded` prop is still false -- so the body stays absent.
      expect(callCount, equals(1));
      expect(find.byType(_BodyMarker), findsNothing);
    });

    testWidgets('disabled (onExpansionChanged null) does not toggle on tap', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzAccordion(
          titleText: 'Disabled',
          expanded: false,
          body: const _BodyMarker(),
        ),
      );

      await tester.tap(find.text('Disabled'));
      await tester.pumpAndSettle();

      expect(find.byType(_BodyMarker), findsNothing);
    });

    testWidgets('toggles when Enter is pressed while focused', (tester) async {
      bool? lastValue;

      await pumpThemedApp(
        tester,
        LayrzAccordion(
          titleText: 'Keyboard target',
          expanded: false,
          onExpansionChanged: (value) => lastValue = value,
          body: const _BodyMarker(),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(lastValue, isTrue);
    });

    testWidgets('toggles when Space is pressed while focused', (tester) async {
      bool? lastValue;

      await pumpThemedApp(
        tester,
        LayrzAccordion(
          titleText: 'Space target',
          expanded: false,
          onExpansionChanged: (value) => lastValue = value,
          body: const _BodyMarker(),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(lastValue, isTrue);
    });

    testWidgets('does not respond to keyboard activation when disabled', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzAccordion(
          titleText: 'Disabled keyboard',
          expanded: false,
          body: const _BodyMarker(),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(_BodyMarker), findsNothing);
    });

    testWidgets('reacts to an externally-driven expanded flip', (tester) async {
      final expandedNotifier = ValueNotifier<bool>(false);
      addTearDown(expandedNotifier.dispose);

      await pumpThemedApp(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: expandedNotifier,
          builder: (context, expanded, _) => LayrzAccordion(
            titleText: 'External control',
            expanded: expanded,
            onExpansionChanged: (value) => expandedNotifier.value = value,
            body: const _BodyMarker(),
          ),
        ),
      );

      expect(find.byType(_BodyMarker), findsNothing);

      // Flip programmatically, as if driven by state outside the accordion --
      // not via a tap on the header itself.
      expandedNotifier.value = true;
      await tester.pumpAndSettle();

      expect(find.byType(_BodyMarker), findsOneWidget);
    });

    testWidgets('header background color does not change size across hover/press (D15)', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzAccordion(
          titleText: 'Geometry check',
          expanded: false,
          onExpansionChanged: (_) {},
          body: const _BodyMarker(),
        ),
      );

      final beforeSize = tester.getSize(find.byType(LayrzAccordion));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final afterSize = tester.getSize(find.byType(LayrzAccordion));

      expect(beforeSize, equals(afterSize));
    });

    testWidgets('expanded body surface shares the header background color -- no seam', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzAccordion(
          titleText: 'Continuous surface',
          expanded: true,
          onExpansionChanged: (_) {},
          body: const _BodyMarker(),
        ),
      );
      await tester.pumpAndSettle();

      final headerContainer = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final headerColor = (headerContainer.decoration as BoxDecoration).color;

      final bodyDecoratedBox = tester.widget<DecoratedBox>(
        find.ancestor(of: find.byType(_BodyMarker), matching: find.byType(DecoratedBox)).first,
      );
      final bodyColor = (bodyDecoratedBox.decoration as BoxDecoration).color;

      expect(bodyColor, equals(headerColor));
    });

    testWidgets(
      'header bottom-edge geometry animates on the body reveal timeline, not a separate one (no blink)',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        bool expanded = false;

        await pumpThemedApp(
          tester,
          StatefulBuilder(
            builder: (context, setState) => LayrzAccordion(
              titleText: 'Timeline check',
              expanded: expanded,
              onExpansionChanged: (value) => setState(() => expanded = value),
              body: const _BodyMarker(),
            ),
          ),
        );

        BorderRadius headerBorderRadius() {
          final decoratedBox = tester.widget<DecoratedBox>(
            find.ancestor(of: find.byType(AnimatedContainer), matching: find.byType(DecoratedBox)).first,
          );
          return (decoratedBox.decoration as BoxDecoration).borderRadius! as BorderRadius;
        }

        BorderSide headerBottomBorder() {
          final decoratedBox = tester.widget<DecoratedBox>(
            find.ancestor(of: find.byType(AnimatedContainer), matching: find.byType(DecoratedBox)).first,
          );
          return (decoratedBox.decoration as BoxDecoration).border!.bottom;
        }

        // Fully collapsed: bottom corners are rounded and the bottom border
        // is present, matching the closed panel's outline.
        expect(headerBorderRadius().bottomLeft, equals(const Radius.circular(10.0)));
        expect(headerBottomBorder().width, greaterThan(0.0));

        await tester.tap(find.text('Timeline check'));
        await tester.pump();

        // Pump to roughly the midpoint of the 200ms dTransition reveal, well
        // past the 100ms dHover duration a header-only color animation would
        // already have finished within. If header geometry were still driven
        // by dHover, the bottom radius/border would already have snapped to
        // their fully-expanded values (Radius.zero / BorderSide.none) here --
        // the very blink this fix removes.
        await tester.pump(const Duration(milliseconds: 100));

        final midRadius = headerBorderRadius().bottomLeft;
        expect(
          midRadius,
          isNot(equals(Radius.zero)),
          reason: 'header bottom radius must not have reached its expanded value before the body reveal finishes',
        );
        expect(
          midRadius,
          isNot(equals(const Radius.circular(10.0))),
          reason: 'header bottom radius must be interpolating, not stuck at its collapsed value',
        );
        expect(
          headerBottomBorder().width,
          allOf(greaterThan(0.0), lessThan(1.5)),
          reason: 'header bottom border width must be interpolating in step with the radius',
        );

        await tester.pumpAndSettle();

        // Fully expanded and settled: bottom corners are square and the
        // bottom border has been removed, landing in the same frame the body
        // finished revealing.
        expect(headerBorderRadius().bottomLeft, equals(Radius.zero));
        expect(headerBottomBorder(), equals(BorderSide.none));
      },
    );

    testWidgets('rotates the chevron between collapsed and expanded', (tester) async {
      bool expanded = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzAccordion(
            titleText: 'Rotation check',
            expanded: expanded,
            onExpansionChanged: (value) => setState(() => expanded = value),
            body: const _BodyMarker(),
          ),
        ),
      );

      final collapsedRotation = tester.widget<RotationTransition>(find.byType(RotationTransition));
      expect(collapsedRotation.turns.value, equals(0.0));

      await tester.tap(find.text('Rotation check'));
      await tester.pumpAndSettle();

      final expandedRotation = tester.widget<RotationTransition>(find.byType(RotationTransition));
      expect(expandedRotation.turns.value, equals(0.5));
    });
  });
}
