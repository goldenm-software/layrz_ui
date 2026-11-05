import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  double? value;

  void setValue(double? next) => setState(() => value = next);

  @override
  Widget build(BuildContext context) => SizedBox(width: 200, child: LayrzProgressBar(value: value));
}

void main() {
  testWidgets('switching indeterminate -> determinate -> indeterminate twice does not throw', (tester) async {
    await pumpThemed(tester, const _Host());
    final host = tester.state<_HostState>(find.byType(_Host));

    for (final next in <double?>[0.5, null, 0.3, null]) {
      host.setValue(next);
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(tester.takeException(), isNull);
    expect(find.byType(LayrzProgressBar), findsOneWidget);
  });
}
