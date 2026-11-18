import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

/// A parent that calls setState on every keystroke and stores the value as a double.
///
/// Rebuilding the parent per keystroke is not the recommended pattern, but forms do it when they
/// must evaluate the number live and run a function with it (e.g. a difference shown next to the
/// field). The input must not rewrite what the user is typing in that case.
class _Host extends StatefulWidget {
  final ValueNotifier<num?> external;

  const _Host({required this.external});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  num? value;

  @override
  void initState() {
    super.initState();
    widget.external.addListener(_onExternal);
  }

  @override
  void dispose() {
    widget.external.removeListener(_onExternal);
    super.dispose();
  }

  void _onExternal() => setState(() => value = widget.external.value);

  @override
  Widget build(BuildContext context) {
    return LayrzNumberInput(
      value: value,
      decimalSeparator: LayrzDecimalSeparator.comma,
      onChanged: (v) => setState(() => value = v?.toDouble()),
    );
  }
}

String _text(WidgetTester tester) => tester.widget<EditableText>(find.byType(EditableText)).controller.text;

void main() {
  group('LayrzNumberInput value sync while typing', () {
    late ValueNotifier<num?> external;

    setUp(() => external = ValueNotifier<num?>(null));
    tearDown(() => external.dispose());

    testWidgets('keeps an integer the user typed when the parent stores it as a double', (tester) async {
      await pumpThemedApp(tester, _Host(external: external));

      await tester.enterText(find.byType(EditableText), '22');
      await tester.pump();

      expect(_text(tester), '22');
    });

    testWidgets('keeps a trailing decimal separator the user typed', (tester) async {
      await pumpThemedApp(tester, _Host(external: external));

      await tester.enterText(find.byType(EditableText), '2,');
      await tester.pump();

      expect(_text(tester), '2,');
    });

    testWidgets('still shows a different value set from outside', (tester) async {
      await pumpThemedApp(tester, _Host(external: external));
      await tester.enterText(find.byType(EditableText), '22');
      await tester.pump();

      external.value = 5.5;
      await tester.pump();

      expect(_text(tester), '5,5');
    });

    testWidgets('clears the text when the value is reset to null from outside', (tester) async {
      await pumpThemedApp(tester, _Host(external: external));
      external.value = 7;
      await tester.pump();
      expect(_text(tester), '7');

      external.value = null;
      await tester.pump();

      expect(_text(tester), '');
    });
  });
}
