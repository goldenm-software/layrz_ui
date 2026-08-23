import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Global test configuration, picked up automatically by `flutter test`.
///
/// Initializes the binding before any test runs, so widgets that construct the
/// default font handler from a plain `test()` do not fail on
/// `ServicesBinding.instance`.
///
/// Also configures [WidgetController.hitTestWarningShouldBeFatal] to treat missed
/// hit test gestures as fatal failures rather than warnings. A gesture that does
/// not reach its intended target is a broken test, not a warning to ignore: the
/// test is asserting a behaviour that does not depend on the interaction it
/// claims to exercise.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  await testMain();
}
