import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

class ComboBoxInputDemo extends StatefulWidget {
  const ComboBoxInputDemo({super.key});

  @override
  State<ComboBoxInputDemo> createState() => _ComboBoxInputDemoState();
}

class _ComboBoxInputDemoState extends State<ComboBoxInputDemo> {
  late TextEditingController _countryController;
  late TextEditingController _freeFormController;

  @override
  void initState() {
    super.initState();
    _countryController = TextEditingController();
    _freeFormController = TextEditingController();
  }

  @override
  void dispose() {
    _countryController.dispose();
    _freeFormController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
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
            debugPrint('Selected: $value');
          },
        ),

        // With custom options
        SizedBox(height: tokens.spacing.sp5),
        Text('Programming Language', style: tokens.typography.title),
        const LayrzComboBoxInput(
          labelText: 'Language',
          hintText: 'Type or select a language',
          options: [
            'Dart',
            'Flutter',
            'Java',
            'Kotlin',
            'Swift',
            'Objective-C',
            'Python',
            'JavaScript',
          ],
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
            debugPrint('Custom input: $value');
          },
        ),

        // Disable free form
        SizedBox(height: tokens.spacing.sp5),
        Text('Only Predefined Options', style: tokens.typography.title),
        Text(
          'allowFreeForm: false - users must select from the list',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        const LayrzComboBoxInput(
          labelText: 'Status',
          hintText: 'Select a status',
          allowFreeForm: false,
          options: ['Active', 'Inactive', 'Pending', 'Archived'],
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
        const LayrzComboBoxInput(
          labelText: 'Category',
          hintText: 'Select a category',
          isRequired: true,
          options: ['General', 'Feedback', 'Bug Report', 'Feature Request'],
          errors: ['Please select a valid category'],
        ),
      ],
    );
  }
}
