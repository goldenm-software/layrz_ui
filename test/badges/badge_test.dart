import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzBadge', () {
    guardedTestWidgets('renders its child', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzBadge(
          label: 'Notifications',
          count: 3,
          child: Icon(MdiIcons.bell, size: 24),
        ),
      );

      expect(find.byWidgetPredicate((w) => w is Icon && w.icon == MdiIcons.bell), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    guardedTestWidgets('wrapping a child does not change its layout size', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const childKey = Key('bare-icon');
      const badgedKey = Key('badged-icon');

      await pumpThemed(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(MdiIcons.bell, size: 24, key: childKey),
            LayrzBadge(
              label: 'Notifications',
              count: 3,
              child: Icon(MdiIcons.bell, size: 24, key: badgedKey),
            ),
          ],
        ),
      );

      final bareSize = tester.getSize(find.byKey(childKey));
      final badgedSize = tester.getSize(find.byKey(badgedKey));

      expect(badgedSize, equals(bareSize));
    });

    guardedTestWidgets('renders a bare presence dot when count and icon are both null', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzBadge(
          label: 'Status',
          child: Icon(MdiIcons.account, size: 24),
        ),
      );

      expect(find.byType(LayrzBadgeVisual), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    guardedTestWidgets('isVisible false hides the badge visual entirely', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzBadge(
          label: 'Notifications',
          count: 3,
          isVisible: false,
          child: Icon(MdiIcons.bell, size: 24),
        ),
      );

      expect(find.byType(LayrzBadgeVisual), findsNothing);
      expect(find.text('3'), findsNothing);
      expect(find.byWidgetPredicate((w) => w is Icon && w.icon == MdiIcons.bell), findsOneWidget);
    });

    /// Verifies the badge's overlay `Align` matches [alignment]'s corner.
    ///
    /// A single `testWidgets` body that calls `pumpThemed` repeatedly in a
    /// loop does not work here: `pumpThemed` re-pumps into the same
    /// `Overlay`/`OverlayEntry` tree each call, and the framework does not
    /// rebuild the entry's child on a bare `pumpWidget` re-pump, so every
    /// iteration after the first keeps observing the first alignment. Each
    /// corner therefore gets its own test with a fresh pump.
    Future<void> expectCorner(WidgetTester tester, LayrzBadgeAlignment alignment) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzBadge(
          label: 'Notifications',
          count: 1,
          alignment: alignment,
          child: SizedBox(width: 40, height: 40, child: Icon(MdiIcons.bell)),
        ),
      );

      // LayrzBadgeVisual's own Container(alignment: Alignment.center) also
      // resolves to an Align descendant, so match on the corner alignment
      // itself (never Alignment.center) to isolate the overlay's Align.
      final align = tester.widget<Align>(
        find.descendant(
          of: find.byType(LayrzBadge),
          matching: find.byWidgetPredicate((w) => w is Align && w.alignment == alignment.alignment),
        ),
      );
      expect(align.alignment, equals(alignment.alignment));
    }

    guardedTestWidgets('positions the badge at topRight', (tester) async {
      await expectCorner(tester, LayrzBadgeAlignment.topRight);
    });

    guardedTestWidgets('positions the badge at topLeft', (tester) async {
      await expectCorner(tester, LayrzBadgeAlignment.topLeft);
    });

    guardedTestWidgets('positions the badge at bottomRight', (tester) async {
      await expectCorner(tester, LayrzBadgeAlignment.bottomRight);
    });

    guardedTestWidgets('positions the badge at bottomLeft', (tester) async {
      await expectCorner(tester, LayrzBadgeAlignment.bottomLeft);
    });
  });

  group('LayrzBadge accessibility', () {
    testWidgets('merges child and badge into one announced node with the count', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzBadge(
            label: 'Notifications',
            count: 3,
            child: Icon(MdiIcons.bell, size: 24),
          ),
        );

        final semantics = tester.getSemantics(find.byType(LayrzBadge));
        expect(semantics.label, equals('Notifications, 3 unread'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('the icon child does not expose its own detached semantics node', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzBadge(
            label: 'Notifications',
            count: 3,
            child: Semantics(label: 'bell icon', child: Icon(MdiIcons.bell, size: 24)),
          ),
        );

        // ExcludeSemantics over the child means only the merged LayrzBadge
        // node should carry a label -- the inner "bell icon" node must not
        // surface as a second, detached announcement.
        final badgeSemantics = tester.getSemantics(find.byType(LayrzBadge));
        expect(badgeSemantics.label, equals('Notifications, 3 unread'));
        expect(badgeSemantics.label, isNot(contains('bell icon')));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('announces presence without a count for a bare dot', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzBadge(
            label: 'Status',
            child: Icon(MdiIcons.account, size: 24),
          ),
        );

        final semantics = tester.getSemantics(find.byType(LayrzBadge));
        expect(semantics.label, equals('Status, new'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('announces the 99+ overflow form, not the raw count', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzBadge(
            label: 'Notifications',
            count: 250,
            child: Icon(MdiIcons.bell, size: 24),
          ),
        );

        final semantics = tester.getSemantics(find.byType(LayrzBadge));
        expect(semantics.label, equals('Notifications, 99+ unread'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('a hidden badge announces only the label, with no unread suffix', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzBadge(
            label: 'Notifications',
            count: 3,
            isVisible: false,
            child: Icon(MdiIcons.bell, size: 24),
          ),
        );

        final semantics = tester.getSemantics(find.byType(LayrzBadge));
        expect(semantics.label, equals('Notifications'));
      } finally {
        handle.dispose();
      }
    });
  });
}
