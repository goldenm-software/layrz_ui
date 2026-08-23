import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Global test configuration, picked up automatically by `flutter test`.
///
/// Initializes the binding before any test runs, so widgets that construct the
/// default font handler from a plain `test()` do not fail on
/// `ServicesBinding.instance`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await testMain();
}
