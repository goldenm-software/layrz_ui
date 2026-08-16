import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/app.dart';
import 'package:layrz_ui/constants.dart';
import 'package:layrz_ui/theme.dart';

import 'package:example/src/showroom.dart';

void main() {
  testWidgets('Example app smoke test', (tester) async {
    await tester.pumpWidget(LayrzApp(title: kAppTitle, theme: LayrzThemeData.light(), home: const Showroom()));
    expect(find.text('Design System Showroom'), findsOneWidget);
    expect(find.text('Typography'), findsOneWidget);
  });
}
