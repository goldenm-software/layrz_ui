import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_font_handler.dart';

Future<void> _pumpToolbar(
  WidgetTester tester,
  LayrzSelectionToolbar toolbar,
) async {
  await tester.pumpWidget(
    LayrzApp(
      theme: LayrzThemeData.light(fontHandler: const FakeFontHandler()),
      home: Center(child: toolbar),
    ),
  );
  await tester.pump();
}

void main() {
  group('LayrzSelectionToolbar', () {
    late LayrzTokens tokens;

    setUp(() {
      tokens = LayrzTokens.light();
    });

    testWidgets('renders toolbar with action buttons', (WidgetTester tester) async {
      final toolbar = LayrzSelectionToolbar(
        actions: {LayrzSelectableAction.copy, LayrzSelectableAction.cut},
        anchorAbove: Offset.zero,
        tokens: tokens,
        onActionPressed: (_) {},
      );

      await _pumpToolbar(tester, toolbar);
      expect(find.byType(LayrzSelectionToolbar), findsOneWidget);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('displays action label text', (WidgetTester tester) async {
      final toolbar = LayrzSelectionToolbar(
        actions: {LayrzSelectableAction.copy},
        anchorAbove: Offset.zero,
        tokens: tokens,
        onActionPressed: (_) {},
      );

      await _pumpToolbar(tester, toolbar);
      expect(find.byType(Text), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('calls onActionPressed when button is tapped', (WidgetTester tester) async {
      String? pressedAction;

      final toolbar = LayrzSelectionToolbar(
        actions: {LayrzSelectableAction.copy},
        anchorAbove: Offset.zero,
        tokens: tokens,
        onActionPressed: (actionType) {
          pressedAction = actionType;
        },
      );

      await _pumpToolbar(tester, toolbar);
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      expect(pressedAction, 'copy');
    });

    testWidgets('renders custom action with label and icon', (WidgetTester tester) async {
      final testIcon = IconData(0xe3aa, fontFamily: 'MaterialIcons');
      final customAction = LayrzSelectableAction(
        label: (l10n) => 'Custom',
        onPressed: () {},
        icon: testIcon,
      );

      final toolbar = LayrzSelectionToolbar(
        actions: {customAction},
        anchorAbove: Offset.zero,
        tokens: tokens,
        onActionPressed: (_) {},
      );

      await _pumpToolbar(tester, toolbar);
      expect(find.byIcon(testIcon), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('displays correct number of buttons for actions', (WidgetTester tester) async {
      final toolbar = LayrzSelectionToolbar(
        actions: {
          LayrzSelectableAction.copy,
          LayrzSelectableAction.cut,
          LayrzSelectableAction.paste,
          LayrzSelectableAction.selectAll,
        },
        anchorAbove: Offset.zero,
        tokens: tokens,
        onActionPressed: (_) {},
      );

      await _pumpToolbar(tester, toolbar);
      expect(find.byType(GestureDetector), findsNWidgets(4));
    });

    testWidgets('renders with proper styling from tokens', (WidgetTester tester) async {
      final toolbar = LayrzSelectionToolbar(
        actions: {LayrzSelectableAction.copy},
        anchorAbove: Offset.zero,
        tokens: tokens,
        onActionPressed: (_) {},
      );

      await _pumpToolbar(tester, toolbar);
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Text), findsOneWidget);
    });
  });
}
