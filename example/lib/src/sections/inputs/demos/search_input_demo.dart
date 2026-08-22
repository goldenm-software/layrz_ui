import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Builds a comprehensive showcase of [LayrzSearchInput] variants.
Widget buildSearchInputDemo(BuildContext context) {
  return _SearchInputDemo();
}

class _SearchInputDemo extends StatefulWidget {
  const _SearchInputDemo();

  @override
  State<_SearchInputDemo> createState() => _SearchInputDemoState();
}

class _SearchInputDemoState extends State<_SearchInputDemo> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spacing.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spacing.sp5,
        children: [
          // Auto mode (expands on interaction)
          Text('Auto Mode (Compact)', style: tokens.typography.title),
          Text(
            'Displays as an icon button, expands to full field on tap',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzSearchInput(
            mode: LayrzSearchInputMode.auto,
            labelText: 'Search',
            hintText: 'Type to search...',
            onSearch: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
          ),

          // Icon mode (always icon button)
          SizedBox(height: tokens.spacing.sp5),
          Text('Icon Mode (Icon Button)', style: tokens.typography.title),
          Text(
            'Always shows as an icon button',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
            labelText: 'Search',
            hintText: 'Type to search...',
            onSearch: (query) {
              debugPrint('Search: $query');
            },
          ),

          // Field mode (always visible)
          SizedBox(height: tokens.spacing.sp5),
          Text('Field Mode (Full Width)', style: tokens.typography.title),
          Text(
            'Always shows the full input field',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            labelText: 'Search users',
            hintText: 'Enter name or email',
            value: _searchQuery,
            onSearch: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
          ),

          // Disabled
          SizedBox(height: tokens.spacing.sp5),
          Text('Disabled State', style: tokens.typography.title),
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            labelText: 'Search',
            disabled: true,
            hintText: 'Cannot search',
          ),

          // With debounce
          SizedBox(height: tokens.spacing.sp5),
          Text('Custom Debounce', style: tokens.typography.title),
          Text(
            'Controls how long to wait after typing before calling onSearch',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            labelText: 'Search',
            hintText: 'Type to search (500ms debounce)',
            debounce: const Duration(milliseconds: 500),
            onSearch: (query) {
              debugPrint('Search query: $query');
            },
          ),
        ],
      ),
    );
  }
}
