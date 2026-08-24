import 'package:flutter/widgets.dart';

import 'search_input_demo_sections.dart';

/// Thin stateful container for the [LayrzSearchInput] showcase.
///
/// Owns and disposes every [TextEditingController] the demo needs, and tracks the
/// live query text for the two examples that display it back to the user. All layout
/// and example composition lives in [SearchInputDemoSections], which renders purely
/// from the parameters it is given.
class SearchInputDemo extends StatefulWidget {
  /// Creates the search input showcase.
  const SearchInputDemo({super.key});

  @override
  State<SearchInputDemo> createState() => _SearchInputDemoState();
}

class _SearchInputDemoState extends State<SearchInputDemo> {
  // Presentation modes
  late TextEditingController _autoController;
  late TextEditingController _iconController;
  late TextEditingController _fieldController;

  // Debounce example
  late TextEditingController _debounceController;

  String _fieldQuery = '';
  String _debounceQuery = '';

  @override
  void initState() {
    super.initState();
    _autoController = TextEditingController();
    _iconController = TextEditingController();
    _fieldController = TextEditingController();
    _debounceController = TextEditingController();
  }

  @override
  void dispose() {
    _autoController.dispose();
    _iconController.dispose();
    _fieldController.dispose();
    _debounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SearchInputDemoSections(
      autoController: _autoController,
      iconController: _iconController,
      fieldController: _fieldController,
      debounceController: _debounceController,
      fieldQuery: _fieldQuery,
      debounceQuery: _debounceQuery,
      onFieldSearch: (query) => setState(() => _fieldQuery = query),
      onDebounceSearch: (query) => setState(() => _debounceQuery = query),
    );
  }
}
