import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('Example app smoke test', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('layrz_ui Example'), findsOneWidget);
    expect(find.text('Button taps: 0'), findsOneWidget);
  });
}
