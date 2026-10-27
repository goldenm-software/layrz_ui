import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

/// Minimal domain object used to exercise [LayrzScaffoldShell] in isolation.
class _TestItem {
  /// Creates a test item with the given [id].
  const _TestItem(this.id);

  /// Stable identifier, mirrored by the [LayrzScaffoldItem.key] used in tests.
  final String id;
}

/// Pumps a narrow [LayrzScaffoldShell] inside a real [LayrzApp] so opening an
/// item presents the detail in a [LayrzBottomSheet], then opens one item.
Future<DraggableScrollableSheet> _openNarrowSheet(WidgetTester tester, {double? sheetInitialSize}) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final controller = LayrzScaffoldController();
  addTearDown(controller.dispose);
  final tableController = LayrzTableController<_TestItem>();
  addTearDown(tableController.dispose);

  final shell = sheetInitialSize == null
      ? LayrzScaffoldShell<_TestItem>(
          controller: controller,
          items: const [],
          itemExtent: 56.0,
          title: const Text('Title'),
          tableColumns: [
            LayrzColumn<_TestItem>(key: const ValueKey('c'), headerText: 'C', valueBuilder: (item) => '', width: 200),
          ],
          tableController: tableController,
        )
      : LayrzScaffoldShell<_TestItem>(
          controller: controller,
          items: const [],
          itemExtent: 56.0,
          title: const Text('Title'),
          tableColumns: [
            LayrzColumn<_TestItem>(key: const ValueKey('c'), headerText: 'C', valueBuilder: (item) => '', width: 200),
          ],
          tableController: tableController,
          sheetInitialSize: sheetInitialSize,
        );

  await tester.pumpWidget(
    LayrzApp(
      theme: LayrzThemeData.light(),
      home: SizedBox.expand(child: shell),
    ),
  );
  await tester.pump();

  controller.open(key: const ValueKey('a'), builder: (_) => const Text('detail'));
  await tester.pumpAndSettle();

  return tester.widget<DraggableScrollableSheet>(find.byType(DraggableScrollableSheet));
}

void main() {
  group('LayrzScaffoldShell narrow detail sheet — sheetInitialSize', () {
    testWidgets('defaults to half the screen with the historical snap points', (tester) async {
      final sheet = await _openNarrowSheet(tester);

      expect(sheet.initialChildSize, 0.5);
      expect(sheet.snapSizes, [0.5, 0.95]);
    });

    testWidgets('opens at the given size and keeps it as a snap point', (tester) async {
      final sheet = await _openNarrowSheet(tester, sheetInitialSize: 0.85);

      expect(sheet.initialChildSize, 0.85);
      expect(sheet.snapSizes, [0.5, 0.85, 0.95]);
    });

    testWidgets('a size equal to an existing snap point is not duplicated', (tester) async {
      final sheet = await _openNarrowSheet(tester, sheetInitialSize: 0.95);

      expect(sheet.initialChildSize, 0.95);
      expect(sheet.snapSizes, [0.5, 0.95]);
    });

    test('asserts a size outside the sheet bounds', () {
      expect(
        () => LayrzScaffoldShell<_TestItem>(
          controller: LayrzScaffoldController(),
          items: const [],
          itemExtent: 56.0,
          title: const Text('Title'),
          tableColumns: const [],
          tableController: LayrzTableController<_TestItem>(),
          sheetInitialSize: 1.2,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
