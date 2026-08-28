import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTimelineOneSidedSurface', () {
    Widget buildCard(BuildContext context, LayrzTimelineEntry entry, LayrzTimelineStyleSpec spec) {
      return Text(entry.labelText);
    }

    guardedTestWidgets('renders one card per entry, all in a single column', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const entries = [
        LayrzTimelineEntry(labelText: 'A'),
        LayrzTimelineEntry(labelText: 'B'),
        LayrzTimelineEntry(labelText: 'C'),
      ];

      await pumpThemed(
        tester,
        SizedBox(
          width: 800,
          child: LayrzTimelineOneSidedSurface(entries: entries, cardBuilder: buildCard),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.byType(LayrzTimelineMarker), findsNWidgets(3));
    });

    guardedTestWidgets('first entry has no connector above, last entry has none below', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const entries = [
        LayrzTimelineEntry(labelText: 'A'),
        LayrzTimelineEntry(labelText: 'B'),
      ];

      await pumpThemed(
        tester,
        SizedBox(
          width: 800,
          child: LayrzTimelineOneSidedSurface(entries: entries, cardBuilder: buildCard),
        ),
      );

      // Two entries -> two connector segments between them: the segment below
      // A's marker and the segment above B's marker, each rendered by its own
      // row half.
      expect(find.byType(LayrzTimelineConnector), findsNWidgets(2));
    });

    guardedTestWidgets('renders no markers or cards for an empty entry list', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 800,
          child: LayrzTimelineOneSidedSurface(entries: const [], cardBuilder: buildCard),
        ),
      );

      expect(find.byType(LayrzTimelineMarker), findsNothing);
    });

    guardedTestWidgets('renders the icon-carrying marker for an entry with an icon', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const entries = [
        LayrzTimelineEntry(labelText: 'Has icon', icon: MdiIcons.truckOutline),
      ];

      await pumpThemed(
        tester,
        SizedBox(
          width: 800,
          child: LayrzTimelineOneSidedSurface(entries: entries, cardBuilder: buildCard),
        ),
      );

      final marker = tester.widget<LayrzTimelineMarker>(find.byType(LayrzTimelineMarker));
      expect(marker.icon, MdiIcons.truckOutline);
      expect(
        find.descendant(of: find.byType(LayrzTimelineMarker), matching: find.byType(Icon)),
        findsOneWidget,
      );
    });

    guardedTestWidgets('renders a plain dot marker (no Icon) for an entry with no icon', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const entries = [
        LayrzTimelineEntry(labelText: 'No icon'),
      ];

      await pumpThemed(
        tester,
        SizedBox(
          width: 800,
          child: LayrzTimelineOneSidedSurface(entries: entries, cardBuilder: buildCard),
        ),
      );

      final marker = tester.widget<LayrzTimelineMarker>(find.byType(LayrzTimelineMarker));
      expect(marker.icon, isNull);
      expect(
        find.descendant(of: find.byType(LayrzTimelineMarker), matching: find.byType(Icon)),
        findsNothing,
      );
    });
  });
}
