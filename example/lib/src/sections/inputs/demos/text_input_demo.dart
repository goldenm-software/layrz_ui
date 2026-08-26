import 'package:flutter/widgets.dart';

import 'text_input_demo_sections.dart';

/// Showroom demo for [LayrzTextInput].
///
/// Owns all mutable state -- controllers, focus nodes, and the prefix/suffix tap
/// counters -- and hands it down to [TextInputDemoSections], which renders every
/// section. Splitting the state holder from the stateless renderer keeps this file
/// small and mirrors the reference shape used by `NumberInputDemo`.
class TextInputDemo extends StatefulWidget {
  /// Creates a new [TextInputDemo].
  const TextInputDemo({super.key});

  @override
  State<TextInputDemo> createState() => _TextInputDemoState();
}

class _TextInputDemoState extends State<TextInputDemo> {
  late TextEditingController _restController;
  late TextEditingController _errorController;
  late TextEditingController _disabledController;
  late TextEditingController _readOnlyController;
  late FocusNode _restFocusNode;
  int _prefixTapCount = 0;
  int _suffixTapCount = 0;

  @override
  void initState() {
    super.initState();
    _restController = TextEditingController(text: 'Rest state');
    _errorController = TextEditingController(text: 'Invalid input');
    _disabledController = TextEditingController(text: 'Disabled text');
    _readOnlyController = TextEditingController(text: 'Read-only text');
    _restFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _restController.dispose();
    _errorController.dispose();
    _disabledController.dispose();
    _readOnlyController.dispose();
    _restFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextInputDemoSections(
      restController: _restController,
      errorController: _errorController,
      disabledController: _disabledController,
      readOnlyController: _readOnlyController,
      restFocusNode: _restFocusNode,
      prefixTapCount: _prefixTapCount,
      suffixTapCount: _suffixTapCount,
      onPrefixTap: () => setState(() => _prefixTapCount++),
      onSuffixTap: () => setState(() => _suffixTapCount++),
    );
  }
}
