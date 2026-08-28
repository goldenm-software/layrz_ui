import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzProgressBar Accessibility', () {
    testWidgets('determinate mode announces a value alongside its label', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzProgressBar(value: 0.42));

        expect(
          tester.getSemantics(find.byType(LayrzProgressBar)),
          matchesSemantics(label: 'Progress', value: '42%', isLiveRegion: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('indeterminate mode announces a busy/loading label with no value', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzProgressBar());

        expect(
          tester.getSemantics(find.byType(LayrzProgressBar)),
          matchesSemantics(label: 'Loading', isLiveRegion: true),
        );
        // A busy/loading announcement, never a stray percentage.
        expect(tester.getSemantics(find.byType(LayrzProgressBar)).value, isEmpty);
      } finally {
        handle.dispose();
        // Stop the repeating ticker before the test ends.
        await tester.pump(const Duration(milliseconds: 10));
      }
    });

    testWidgets('an explicit semanticLabel overrides the generic default', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          const LayrzProgressBar(value: 0.75, semanticLabel: 'Upload progress'),
        );

        expect(
          tester.getSemantics(find.byType(LayrzProgressBar)),
          matchesSemantics(label: 'Upload progress', value: '75%', isLiveRegion: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('an explicit semanticLabel is honoured in indeterminate mode too', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          const LayrzProgressBar(semanticLabel: 'Syncing files'),
        );

        expect(
          tester.getSemantics(find.byType(LayrzProgressBar)),
          matchesSemantics(label: 'Syncing files', isLiveRegion: true),
        );
      } finally {
        handle.dispose();
        // Stop the repeating ticker before the test ends.
        await tester.pump(const Duration(milliseconds: 10));
      }
    });

    testWidgets('zero value renders 0% rather than being treated as indeterminate', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzProgressBar(value: 0.0));

        expect(
          tester.getSemantics(find.byType(LayrzProgressBar)),
          matchesSemantics(label: 'Progress', value: '0%', isLiveRegion: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('full value renders 100%', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzProgressBar(value: 1.0));

        expect(
          tester.getSemantics(find.byType(LayrzProgressBar)),
          matchesSemantics(label: 'Progress', value: '100%', isLiveRegion: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('semantics node is a live region so value changes are announced', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzProgressBar(value: 0.2));

        expect(
          tester.getSemantics(find.byType(LayrzProgressBar)),
          matchesSemantics(label: 'Progress', value: '20%', isLiveRegion: true),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
