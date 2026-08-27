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

  /// The [LayrzPreferredSide] currently applied to the "Preferred Side" example's
  /// icon-mode [LayrzSearchInput], driven by [onIconPreferredSideChanged].
  final LayrzPreferredSide iconPreferredSide;

  /// Callback fired when the field mode example searches.
  final ValueChanged<String> onFieldSearch;

  /// Callback fired when the debounce example searches.
  final ValueChanged<String> onDebounceSearch;

  /// Callback fired when the user picks a different side in the "Preferred Side"
  /// example's radio control.
  final ValueChanged<LayrzPreferredSide> onIconPreferredSideChanged;

  /// Creates the search input demo sections widget.
  const SearchInputDemoSections({
    super.key,
    required this.autoController,
    required this.iconController,
    required this.fieldController,
    required this.debounceController,
    required this.fieldQuery,
    required this.debounceQuery,
    required this.iconPreferredSide,
    required this.onFieldSearch,
    required this.onDebounceSearch,
    required this.onIconPreferredSideChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
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
                    hintText: 'Resizes with the viewport',
                    controller: autoController,
                  ),
                ),
                LayrzCol(
                  xs: 12,
                  md: 4,
                  child: LayrzSearchInput(
                    mode: LayrzSearchInputMode.icon,
                    hintText: 'Opens in a floating panel',
                    controller: iconController,
                  ),
                ),
                LayrzCol(
                  xs: 12,
                  md: 4,
                  child: LayrzSearchInput(
                    mode: LayrzSearchInputMode.field,
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
                    hintText: 'Cannot search',
                    disabled: true,
                  ),
                ),
                LayrzCol(
                  xs: 12,
                  md: 6,
                  child: const LayrzSearchInput(
                    mode: LayrzSearchInputMode.field,
                    value: 'read-only query',
                    readOnly: true,
                  ),
                ),
              ],
            ),

            tokens.spacing.sb3,
            Text('Validation and Help', style: tokens.typography.title),
            Text(
              'Demonstrates errors, helpTitleText, and helpContentText.',
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
                    errors: ['Enter at least 3 characters'],
                  ),
                ),
                LayrzCol(
                  xs: 12,
                  md: 6,
                  child: const LayrzSearchInput(
                    mode: LayrzSearchInputMode.field,
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
                    hintText: 'Type to search (500ms debounce)',
                    controller: debounceController,
                    debounce: const Duration(milliseconds: 500),
                    onSearch: onDebounceSearch,
                  ),
                ),
              ],
            ),
            if (debounceQuery.isNotEmpty) Text('Debounced query: $debounceQuery', style: tokens.typography.label),

            tokens.spacing.sb3,
            Text('Preferred Side (Icon Mode)', style: tokens.typography.title),
            Text(
              'preferredSide controls which side of the trigger button the panel opens on. '
              'Pick a side below and open the panel to see it move. Defaults to right; it flips '
              'to the opposite side when it does not fit, and is clamped into the overlay if '
              'neither does.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            tokens.spacing.sb2,
            LayrzRow(
              spacing: tokens.spacing.sp3,
              children: [
                LayrzCol(
                  xs: 12,
                  md: 6,
                  child: LayrzRadioInput<LayrzPreferredSide>(
                    labelText: 'preferredSide',
                    value: iconPreferredSide,
                    onChanged: (side) {
                      if (side != null) onIconPreferredSideChanged(side);
                    },
                    items: const [
                      LayrzSelectItem(value: LayrzPreferredSide.top, child: Text('Top'), searchableStrings: {'Top'}),
                      LayrzSelectItem(
                        value: LayrzPreferredSide.bottom,
                        child: Text('Bottom'),
                        searchableStrings: {'Bottom'},
                      ),
                      LayrzSelectItem(
                        value: LayrzPreferredSide.left,
                        child: Text('Left'),
                        searchableStrings: {'Left'},
                      ),
                      LayrzSelectItem(
                        value: LayrzPreferredSide.right,
                        child: Text('Right'),
                        searchableStrings: {'Right'},
                      ),
                    ],
                    xs: 6,
                  ),
                ),
                LayrzCol(
                  xs: 12,
                  md: 6,
                  child: LayrzSearchInput(
                    mode: LayrzSearchInputMode.icon,
                    hintText: 'Opens on the side selected at left',
                    preferredSide: iconPreferredSide,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
