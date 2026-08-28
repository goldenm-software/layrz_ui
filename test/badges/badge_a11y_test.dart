import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzBadge accessibility (matchesSemantics)', () {
    // This suite exists to close the false-green risk named explicitly in
    // the implementation plan for this unit: a test that merely confirms a
    // number renders (see badge_test.dart) would pass while the component
    // ships inaccessible -- a screen reader announcing a detached "3" next
    // to an unlabelled icon. Every test here asserts the actual merged
    // Semantics properties via matchesSemantics, not just that some text
    // exists in the tree.

    testWidgets('a numbered badge merges into one node: label + count + no separate child node', (tester) async {
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

        expect(
          tester.getSemantics(find.byType(LayrzBadge)),
          matchesSemantics(label: 'Notifications, 3 unread'),
        );

        // The child's own semantics must not surface as an independent node
        // -- ExcludeSemantics folds it away so nothing reads "bell" or an
        // unlabelled icon back separately from the merged announcement.
        expect(find.bySemanticsLabel('bell'), findsNothing);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('a bare presence dot never announces as an empty node', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzBadge(
            label: 'Account status',
            child: Icon(MdiIcons.account, size: 24),
          ),
        );

        // A bare dot must announce what it signifies -- an unlabelled dot
        // read as an empty node would be worse than not announcing at all.
        expect(
          tester.getSemantics(find.byType(LayrzBadge)),
          matchesSemantics(label: 'Account status, new'),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('an icon-content badge still merges into a single labelled node', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzBadge(
            label: 'Sync status',
            icon: MdiIcons.sync,
            child: Icon(MdiIcons.cloud, size: 24),
          ),
        );

        expect(
          tester.getSemantics(find.byType(LayrzBadge)),
          matchesSemantics(label: 'Sync status, new'),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('the 99+ overflow form is what gets announced for a count of 999', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzBadge(
            label: 'Notifications',
            count: 999,
            child: Icon(MdiIcons.bell, size: 24),
          ),
        );

        expect(
          tester.getSemantics(find.byType(LayrzBadge)),
          matchesSemantics(label: 'Notifications, 99+ unread'),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('an invisible badge merges to just the label, no phantom count', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzBadge(
            label: 'Notifications',
            count: 7,
            isVisible: false,
            child: Icon(MdiIcons.bell, size: 24),
          ),
        );

        expect(
          tester.getSemantics(find.byType(LayrzBadge)),
          matchesSemantics(label: 'Notifications'),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
