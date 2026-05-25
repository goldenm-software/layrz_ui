import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  testWidgets('LayrzTheme.of returns the injected LayrzThemeData', (tester) async {
    final themeData = LayrzThemeData.light();
    late LayrzThemeData resolved;

    await tester.pumpWidget(
      LayrzTheme(
        data: themeData,
        child: Builder(
          builder: (context) {
            resolved = LayrzTheme.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolved, equals(themeData));
  });

  testWidgets('LayrzThemeData.dark has Brightness.dark', (tester) async {
    final dark = LayrzThemeData.dark();
    expect(dark.brightness, Brightness.dark);
  });

  testWidgets('LayrzThemeData.light has Brightness.light', (tester) async {
    final light = LayrzThemeData.light();
    expect(light.brightness, Brightness.light);
  });

  testWidgets('LayrzThemeData.copyWith overrides only specified fields', (tester) async {
    final original = LayrzThemeData.light();
    final copy = original.copyWith(borderRadius: 16.0);

    expect(copy.borderRadius, 16.0);
    expect(copy.primaryColor, original.primaryColor);
    expect(copy.brightness, original.brightness);
  });
}
