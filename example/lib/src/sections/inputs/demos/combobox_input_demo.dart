import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Showroom demo for [LayrzComboBoxInput].
///
/// Every example below is wired to a [TextEditingController] and an `onChanged` callback
/// that feeds the committed value back into a visible "Selected: …" line, so the picker,
/// free-form entry, and error-clearing behaviour are all genuinely interactive rather than
/// static illustrations.
class ComboBoxInputDemo extends StatefulWidget {
  /// Creates a new [ComboBoxInputDemo].
  const ComboBoxInputDemo({super.key});

  @override
  State<ComboBoxInputDemo> createState() => _ComboBoxInputDemoState();
}

class _ComboBoxInputDemoState extends State<ComboBoxInputDemo> {
  late TextEditingController _countryController;
  late TextEditingController _languageController;
  late TextEditingController _freeFormController;
  late TextEditingController _statusController;
  late TextEditingController _categoryController;

  String _selectedCountry = '';
  String _selectedLanguage = '';
  String _customTag = '';
  String _selectedStatus = '';
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _countryController = TextEditingController();
    _languageController = TextEditingController();
    _freeFormController = TextEditingController();
    _statusController = TextEditingController();
    _categoryController = TextEditingController();
  }

  @override
  void dispose() {
    _countryController.dispose();
    _languageController.dispose();
    _freeFormController.dispose();
    _statusController.dispose();
    _categoryController.dispose();
    super.dispose();
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
            // Basic combo box
            Text('Combo Box with Fixed Options', style: tokens.typography.title),
            LayrzComboBoxInput(
              labelText: 'Country',
              hintText: 'Select or type a country',
              controller: _countryController,
              options: const [
                'United States',
                'Canada',
                'Mexico',
                'United Kingdom',
                'Germany',
                'France',
                'Spain',
                'Italy',
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCountry = value;
                });
              },
            ),
            Text(
              'Selected: ${_selectedCountry.isEmpty ? '(none yet)' : _selectedCountry}',
              style: tokens.typography.label,
            ),

            // With custom options
            SizedBox(height: tokens.spacing.sp5),
            Text('Programming Language', style: tokens.typography.title),
            LayrzComboBoxInput(
              labelText: 'Language',
              hintText: 'Type or select a language',
              controller: _languageController,
              options: const [
                'Dart',
                'Flutter',
                'Java',
                'Kotlin',
                'Swift',
                'Objective-C',
                'Python',
                'JavaScript',
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value;
                });
              },
            ),
            Text(
              'Selected: ${_selectedLanguage.isEmpty ? '(none yet)' : _selectedLanguage}',
              style: tokens.typography.label,
            ),

            // Allow free form input
            SizedBox(height: tokens.spacing.sp5),
            Text('With Free Form Input', style: tokens.typography.title),
            Text(
              'Users can enter custom values not in the list (allowFreeForm: true is the default)',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzComboBoxInput(
              labelText: 'Custom Tag',
              hintText: 'Select or type a custom value',
              controller: _freeFormController,
              allowFreeForm: true,
              options: const ['Tag1', 'Tag2', 'Tag3'],
              onChanged: (value) {
                setState(() {
                  _customTag = value;
                });
              },
            ),
            Text(
              'Current value: ${_customTag.isEmpty ? '(none yet)' : _customTag}',
              style: tokens.typography.label,
            ),

            // Disable free form
            SizedBox(height: tokens.spacing.sp5),
            Text('Only Predefined Options', style: tokens.typography.title),
            Text(
              'allowFreeForm: false - users must select from the list',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzComboBoxInput(
              labelText: 'Status',
              hintText: 'Select a status',
              controller: _statusController,
              allowFreeForm: false,
              options: const ['Active', 'Inactive', 'Pending', 'Archived'],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            Text(
              'Selected: ${_selectedStatus.isEmpty ? '(none yet)' : _selectedStatus}',
              style: tokens.typography.label,
            ),

            // Disabled state
            SizedBox(height: tokens.spacing.sp5),
            Text('Disabled State', style: tokens.typography.title),
            const LayrzComboBoxInput(
              labelText: 'Disabled',
              disabled: true,
              hintText: 'Cannot select',
              options: ['Option 1', 'Option 2'],
            ),

            // With errors
            SizedBox(height: tokens.spacing.sp5),
            Text('Error State', style: tokens.typography.title),
            Text(
              'The error clears as soon as a valid category is selected.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            LayrzComboBoxInput(
              labelText: 'Category',
              hintText: 'Select a category',
              controller: _categoryController,
              isRequired: true,
              options: const ['General', 'Feedback', 'Bug Report', 'Feature Request'],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              errors: _selectedCategory.isEmpty ? const ['Please select a valid category'] : const [],
            ),
          ],
        ),
      ),
    );
  }
}
