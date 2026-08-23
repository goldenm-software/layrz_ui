import 'package:flutter/widgets.dart';
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

  static const List<LayrzSelectItem<String>> _countryItems = [
    LayrzSelectItem(labelText: 'United States', value: 'us'),
    LayrzSelectItem(labelText: 'Canada', value: 'ca'),
    LayrzSelectItem(labelText: 'Mexico', value: 'mx'),
    LayrzSelectItem(labelText: 'United Kingdom', value: 'uk'),
    LayrzSelectItem(labelText: 'Germany', value: 'de'),
    LayrzSelectItem(labelText: 'France', value: 'fr'),
    LayrzSelectItem(labelText: 'Spain', value: 'es'),
    LayrzSelectItem(labelText: 'Italy', value: 'it'),
    LayrzSelectItem(labelText: 'Japan', value: 'jp'),
    LayrzSelectItem(labelText: 'Australia', value: 'au'),
  ];

  static const List<LayrzSelectItem<String>> _sizeItems = [
    LayrzSelectItem(labelText: 'Extra Small', value: 'xs'),
    LayrzSelectItem(labelText: 'Small', value: 'small'),
    LayrzSelectItem(labelText: 'Medium', value: 'medium'),
    LayrzSelectItem(labelText: 'Large', value: 'large'),
    LayrzSelectItem(labelText: 'Extra Large', value: 'xl'),
  ];

  static const List<LayrzSelectItem<String>> _categoryItems = [
    LayrzSelectItem(labelText: 'Electronics', value: 'electronics'),
    LayrzSelectItem(labelText: 'Clothing', value: 'clothing'),
    LayrzSelectItem(labelText: 'Books', value: 'books'),
    LayrzSelectItem(labelText: 'Home & Garden', value: 'home'),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp5,
      children: [
        // Default select input
        Text('Default Select Input', style: tokens.typography.title),
        LayrzSelectInput<String>(
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
          items: _countryItems,
          value: 'us',
          labelText: 'Origin Country',
          enableSearch: true,
          onChanged: (_) {},
        ),

        // Can unselect
        SizedBox(height: tokens.spacing.sp3),
        Text('Can Unselect', style: tokens.typography.title),
        LayrzSelectInput<String>(
          items: [
            const LayrzSelectItem(labelText: 'None', value: null),
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

        // Disabled
        SizedBox(height: tokens.spacing.sp3),
        Text('Disabled', style: tokens.typography.title),
        const LayrzSelectInput<String>(
          items: _sizeItems,
          value: 'medium',
          labelText: 'Size',
          disabled: true,
        ),

        // With error
        SizedBox(height: tokens.spacing.sp3),
        Text('With Error', style: tokens.typography.title),
        LayrzSelectInput<String>(
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
    );
  }
}
