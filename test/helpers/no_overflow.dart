import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Drop-in replacement for [testWidgets] that additionally asserts, after
/// [callback] returns, that no [RenderFlex] (or other layout) overflow was
/// reported during the test -- unless [expectOverflow] is `true`.
///
/// A layout overflow is reported through [FlutterError.reportError], which
/// [TestWidgetsFlutterBinding] captures into [WidgetTester.takeException]
/// rather than by throwing. A `testWidgets` body that never calls
/// [WidgetTester.takeException] is structurally blind to this: the test
/// passes while the widget tree visibly overflows in a real app -- Flutter
/// only prints the yellow-and-black overflow banner to the console. This
/// wrapper exists to make that class of bug loud in CI instead of silent.
///
/// [expectOverflow] should be `true` only for a test that deliberately
/// drives content into overflow (a capacity trip-wire proving a real
/// rendering limit exists) and itself asserts on the exception via
/// [WidgetTester.takeException] -- in that case this wrapper's own check is
/// skipped, since the test already consumed and asserted on the exception
/// itself. Defaults to `false`, so ordinary tests get the guard automatically
/// with no change to their own body.
///
/// All other parameters are forwarded verbatim to [testWidgets]; see its own
/// documentation for their meaning.
void guardedTestWidgets(
  String description,
  WidgetTesterCallback callback, {
  bool skip = false,
  Timeout? timeout,
  bool semanticsEnabled = true,
  TestVariant<Object?> variant = const DefaultTestVariant(),
  dynamic tags,
  int? retry,
  bool expectOverflow = false,
}) {
  testWidgets(
    description,
    (tester) async {
      await callback(tester);

      if (expectOverflow) {
        // The test body already consumed and asserted on the overflow
        // exception via WidgetTester.takeException() -- nothing left for this
        // wrapper to check, and calling takeException() again here would
        // find nothing (it drains the pending exception on first call).
        return;
      }

      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason:
            'Unexpected layout overflow (or other unhandled exception) during "$description":\n'
            '$exception\n'
            'A RenderFlex overflow does not fail a test on its own unless something calls '
            'WidgetTester.takeException() -- this wrapper exists specifically to catch that. If this '
            'overflow is deliberate (a capacity trip-wire), pass expectOverflow: true and assert on '
            'the exception in the test body via tester.takeException().',
      );
    },
    skip: skip,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    variant: variant,
    tags: tags,
    retry: retry,
  );
}
