import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Widget that renders all sections of the search input demo.
///
/// Pure rendering: every controller and every piece of live state (the two
/// displayed query strings) is owned by [SearchInputDemo] and handed in here.
/// Lays examples out with [LayrzRow]/[LayrzCol] in a responsive grid, `md`-sized,
/// mirroring [NumberInputDemoSections]'s structure.
class SearchInputDemoSections extends StatelessWidget {
  /// Controller for the auto mode example (picks field or icon by viewport width).
  final TextEditingController autoController;

  /// Controller for the icon mode example.
  final TextEditingController iconController;

  /// Controller for the field mode example.
  final TextEditingController fieldController;

  /// Controller for the custom debounce example.
  final TextEditingController debounceController;

  /// The last query fired by the field mode example's [LayrzSearchInput.onSearch].
  final String fieldQuery;

  /// The last query fired by the debounce example's [LayrzSearchInput.onSearch].
  final String debounceQuery;

  /// Callback fired when the field mode example searches.
  final ValueChanged<String> onFieldSearch;

  /// Callback fired when the debounce example searches.
  final ValueChanged<String> onDebounceSearch;

  /// Creates the search input demo sections widget.
  const SearchInputDemoSections({
    super.key,
    required this.autoController,
    required this.iconController,
    required this.fieldController,
    required this.debounceController,
    required this.fieldQuery,
    required this.debounceQuery,
    required this.onFieldSearch,
    required this.onDebounceSearch,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SizedBox(
      height: double.infinity,
      child: SingleChildScrollView(
        child: Container(
          padding: tokens.spacing.pd2,
          child: Column(
            crossAxisAlignment: .start,
            mainAxisAlignment: .start,
            spacing: tokens.spacing.sp1,
            children: [
              // Presentation modes: auto, icon, field
              Text('Presentation Modes', style: tokens.typography.title),
              Text(
                'Auto picks between field and icon by viewport width; icon and field can also be forced explicitly.',
                style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
              ),
              tokens.spacing.sb2,
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 4,
                    child: LayrzSearchInput(
                      mode: LayrzSearchInputMode.auto,
                      labelText: 'Auto',
                      hintText: 'Resizes with the viewport',
                      controller: autoController,
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 4,
                    child: LayrzSearchInput(
                      mode: LayrzSearchInputMode.icon,
                      labelText: 'Icon',
                      hintText: 'Opens in a floating panel',
                      controller: iconController,
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 4,
                    child: LayrzSearchInput(
                      mode: LayrzSearchInputMode.field,
                      labelText: 'Field',
                      hintText: 'Always inline',
                      controller: fieldController,
                      onSearch: onFieldSearch,
                      debounce: Duration.zero,
                    ),
                  ),
                ],
              ),
              if (fieldQuery.isNotEmpty) Text('Field query: $fieldQuery', style: tokens.typography.label),

              tokens.spacing.sb3,
              Text('States', style: tokens.typography.title),
              Text(
                'Demonstrates disabled and readOnly.',
                style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
              ),
              tokens.spacing.sb2,
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: const LayrzSearchInput(
                      mode: LayrzSearchInputMode.field,
                      labelText: 'Disabled',
                      hintText: 'Cannot search',
                      disabled: true,
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: const LayrzSearchInput(
                      mode: LayrzSearchInputMode.field,
                      labelText: 'Read-only',
                      value: 'read-only query',
                      readOnly: true,
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('Validation and Help', style: tokens.typography.title),
              Text(
                'Demonstrates isRequired, errors, helpTitleText, and helpContentText.',
                style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
              ),
              tokens.spacing.sb2,
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: const LayrzSearchInput(
                      mode: LayrzSearchInputMode.field,
                      labelText: 'Search catalog',
                      isRequired: true,
                      errors: ['Enter at least 3 characters'],
                    ),
                  ),
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: const LayrzSearchInput(
                      mode: LayrzSearchInputMode.field,
                      labelText: 'Search',
                      helpTitleText: 'About search',
                      helpContentText: 'Searches across every field in the record, not just its name.',
                    ),
                  ),
                ],
              ),

              tokens.spacing.sb3,
              Text('Custom Debounce', style: tokens.typography.title),
              Text(
                'Controls how long to wait after typing before calling onSearch.',
                style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
              ),
              tokens.spacing.sb2,
              LayrzRow(
                spacing: tokens.spacing.sp3,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: LayrzSearchInput(
                      mode: LayrzSearchInputMode.field,
                      labelText: 'Search',
                      hintText: 'Type to search (500ms debounce)',
                      controller: debounceController,
                      debounce: const Duration(milliseconds: 500),
                      onSearch: onDebounceSearch,
                    ),
                  ),
                ],
              ),
              if (debounceQuery.isNotEmpty) Text('Debounced query: $debounceQuery', style: tokens.typography.label),
            ],
          ),
        ),
      ),
    );
  }
}
