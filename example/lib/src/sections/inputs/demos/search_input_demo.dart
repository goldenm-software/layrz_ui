import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

class SearchInputDemo extends StatefulWidget {
  const SearchInputDemo({super.key});

  @override
  State<SearchInputDemo> createState() => _SearchInputDemoState();
}

class _SearchInputDemoState extends State<SearchInputDemo> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      child: Padding(
        padding: tokens.spacing.pd2,
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

            // Required, with an error message
            SizedBox(height: tokens.spacing.sp5),
            Text('Required with Error', style: tokens.typography.title),
            Text(
              'Demonstrates isRequired and errors',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            const LayrzSearchInput(
              mode: LayrzSearchInputMode.field,
              labelText: 'Search catalog',
              isRequired: true,
              errors: ['Enter at least 3 characters'],
            ),

            // Help affordance
            SizedBox(height: tokens.spacing.sp5),
            Text('Help Affordance', style: tokens.typography.title),
            Text(
              'Demonstrates helpTitleText and helpContentText',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            const LayrzSearchInput(
              mode: LayrzSearchInputMode.field,
              labelText: 'Search',
              helpTitleText: 'About search',
              helpContentText: 'Searches across every field in the record, not just its name.',
            ),

            // Read-only
            SizedBox(height: tokens.spacing.sp5),
            Text('Read-only', style: tokens.typography.title),
            Text(
              'Demonstrates readOnly, which renders a lock affordance',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            const LayrzSearchInput(
              mode: LayrzSearchInputMode.field,
              labelText: 'Search',
              value: 'read-only query',
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }
}
