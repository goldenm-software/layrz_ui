import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

class SelectInputDemo extends StatefulWidget {
  const SelectInputDemo({super.key});

  @override
  State<SelectInputDemo> createState() => _SelectInputDemoState();
}

class _SelectInputDemoState extends State<SelectInputDemo> {
  String? _selectedCountry;
  String? _selectedSize = 'medium';
  String? _selectedCategory;
  String? _selectedFlaggedCountry;

  static const List<LayrzSelectItem<String>> _countryItems = [
    LayrzSelectItem(value: 'us', child: Text('United States'), searchableStrings: {'United States'}),
    LayrzSelectItem(value: 'ca', child: Text('Canada'), searchableStrings: {'Canada'}),
    LayrzSelectItem(value: 'mx', child: Text('Mexico'), searchableStrings: {'Mexico'}),
    LayrzSelectItem(value: 'uk', child: Text('United Kingdom'), searchableStrings: {'United Kingdom'}),
    LayrzSelectItem(value: 'de', child: Text('Germany'), searchableStrings: {'Germany'}),
    LayrzSelectItem(value: 'fr', child: Text('France'), searchableStrings: {'France'}),
    LayrzSelectItem(value: 'es', child: Text('Spain'), searchableStrings: {'Spain'}),
    LayrzSelectItem(value: 'it', child: Text('Italy'), searchableStrings: {'Italy'}),
    LayrzSelectItem(value: 'jp', child: Text('Japan'), searchableStrings: {'Japan'}),
    LayrzSelectItem(value: 'au', child: Text('Australia'), searchableStrings: {'Australia'}),
  ];

  static const List<LayrzSelectItem<String>> _sizeItems = [
    LayrzSelectItem(value: 'xs', child: Text('Extra Small'), searchableStrings: {'Extra Small'}),
    LayrzSelectItem(value: 'small', child: Text('Small'), searchableStrings: {'Small'}),
    LayrzSelectItem(value: 'medium', child: Text('Medium'), searchableStrings: {'Medium'}),
    LayrzSelectItem(value: 'large', child: Text('Large'), searchableStrings: {'Large'}),
    LayrzSelectItem(value: 'xl', child: Text('Extra Large'), searchableStrings: {'Extra Large'}),
  ];

  static const List<LayrzSelectItem<String>> _categoryItems = [
    LayrzSelectItem(value: 'electronics', child: Text('Electronics'), searchableStrings: {'Electronics'}),
    LayrzSelectItem(value: 'clothing', child: Text('Clothing'), searchableStrings: {'Clothing'}),
    LayrzSelectItem(value: 'books', child: Text('Books'), searchableStrings: {'Books'}),
    LayrzSelectItem(value: 'home', child: Text('Home & Garden'), searchableStrings: {'Home & Garden'}),
  ];

  // Demonstrates a custom `child` combining an icon with text -- the item defines its own
  // presentation, and the surface's list shows this exact same flag+name row, not a
  // degraded plain-text label.
  //
  // Deliberately built with `Text.rich`, not the raw `RichText` widget: `Text.rich` applies
  // the ambient `DefaultTextStyle` to its `TextSpan` the same way a plain `Text` does, so it
  // correctly picks up the theme's title style wherever it renders. `RichText` does not -- it
  // renders its span's own style only, so a bare `RichText` used as a `child` here would
  // render with no color, which the engine then paints solid white regardless of theme.
  // Reach for `Text.rich` whenever a `child` needs multiple styled runs; never `RichText`
  // directly.
  static List<LayrzSelectItem<String>> get _flaggedCountryItems => [
    _flaggedCountryItem(code: 'us', flag: '🇺🇸', name: 'United States'),
    _flaggedCountryItem(code: 'ca', flag: '🇨🇦', name: 'Canada'),
    _flaggedCountryItem(code: 'mx', flag: '🇲🇽', name: 'Mexico'),
    _flaggedCountryItem(code: 'jp', flag: '🇯🇵', name: 'Japan'),
  ];

  static LayrzSelectItem<String> _flaggedCountryItem({
    required String code,
    required String flag,
    required String name,
  }) {
    return LayrzSelectItem<String>(
      value: code,
      searchableStrings: {name, code},
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$flag  '),
            TextSpan(text: name),
          ],
        ),
      ),
    );
  }

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
            // Default select input
            Text('Default Select Input', style: tokens.typography.title),
            LayrzSelectInput<String>(
              itemExtent: 30,
              items: _countryItems,
              value: _selectedCountry,
              hintText: 'Choose a country',
              onChanged: (item) {
                setState(() {
                  _selectedCountry = item?.value;
                });
              },
            ),

            // With label and hint
            SizedBox(height: tokens.spacing.sp3),
            Text('With Label and Hint', style: tokens.typography.title),
            LayrzSelectInput<String>(
              itemExtent: 30,
              items: _sizeItems,
              value: _selectedSize,
              labelText: 'Size',
              hintText: 'Select a size',
              isRequired: true,
              onChanged: (item) {
                setState(() {
                  _selectedSize = item?.value;
                });
              },
            ),

            // Searchable with preselected value
            SizedBox(height: tokens.spacing.sp3),
            Text('Searchable (with Preselection)', style: tokens.typography.title),
            LayrzSelectInput<String>(
              itemExtent: 30,
              items: _countryItems,
              value: 'us',
              labelText: 'Origin Country',
              enableSearch: true,
              onChanged: (_) {},
            ),

            // Custom item child (icon + text) -- the surface's list shows this row for
            // each option. See `_flaggedCountryItem` above for why this uses `Text.rich`,
            // never a bare `RichText`.
            SizedBox(height: tokens.spacing.sp3),
            Text('Custom Item Child (flag + name)', style: tokens.typography.title),
            LayrzSelectInput<String>(
              itemExtent: 30,
              items: _flaggedCountryItems,
              value: _selectedFlaggedCountry,
              labelText: 'Country',
              hintText: 'Choose a country',
              onChanged: (item) {
                setState(() {
                  _selectedFlaggedCountry = item?.value;
                });
              },
            ),

            // Can unselect
            SizedBox(height: tokens.spacing.sp3),
            Text('Can Unselect', style: tokens.typography.title),
            LayrzSelectInput<String>(
              itemExtent: 30,
              items: [
                const LayrzSelectItem(value: null, child: Text('None'), searchableStrings: {'None'}),
                ..._categoryItems,
              ],
              value: _selectedCategory,
              labelText: 'Category',
              hintText: 'Select or clear a category',
              canUnselect: true,
              onChanged: (item) {
                setState(() {
                  _selectedCategory = item?.value;
                });
              },
            ),

            // Pure picker (enableSearch: false) -- not editable, but still
            // self-displays a pick from internal state (DESIGN-40/144).
            SizedBox(height: tokens.spacing.sp3),
            Text('Pure Picker (search disabled)', style: tokens.typography.title),
            LayrzSelectInput<String>(
              itemExtent: 30,
              items: _sizeItems,
              value: _selectedSize,
              labelText: 'Size',
              hintText: 'Not editable, still self-displays',
              enableSearch: false,
              onChanged: (item) {
                setState(() {
                  _selectedSize = item?.value;
                });
              },
            ),

            // Caller-supplied suffix, alongside the widget's own dropdown caret.
            // Before the caret moved to an external sibling, this suffix would
            // have replaced the caret entirely.
            SizedBox(height: tokens.spacing.sp3),
            Text('With a Caller Suffix', style: tokens.typography.title),
            LayrzSelectInput<String>(
              itemExtent: 30,
              items: _countryItems,
              value: _selectedCountry,
              labelText: 'Country',
              suffixIcon: MdiIcons.earth,
              onChanged: (item) {
                setState(() {
                  _selectedCountry = item?.value;
                });
              },
            ),

            // Disabled
            SizedBox(height: tokens.spacing.sp3),
            Text('Disabled', style: tokens.typography.title),
            const LayrzSelectInput<String>(
              itemExtent: 30,
              items: _sizeItems,
              value: 'medium',
              labelText: 'Size',
              disabled: true,
            ),

            // With error
            SizedBox(height: tokens.spacing.sp3),
            Text('With Error', style: tokens.typography.title),
            LayrzSelectInput<String>(
              itemExtent: 30,
              items: _countryItems,
              value: null,
              labelText: 'Country',
              hintText: 'Please select a country',
              errors: const ['Country is required'],
              onChanged: (item) {
                setState(() {
                  _selectedCountry = item?.value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
