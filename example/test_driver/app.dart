import 'package:flutter_driver/driver_extension.dart';
import 'package:example/main.dart' as app;

// Driver entrypoint: enables the Flutter Driver service extension before the
// real app boots, so flutter_driver / MCP driver commands can interact with it.
// Run with: flutter run -t test_driver/app.dart [--dart-define=API_HOST=...]
Future<void> main() async {
  enableFlutterDriverExtension();
  await app.main();
}
