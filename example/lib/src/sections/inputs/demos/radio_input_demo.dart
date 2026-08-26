import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

class RadioInputDemo extends StatefulWidget {
  const RadioInputDemo({super.key});

  @override
  State<RadioInputDemo> createState() => _RadioInputDemoState();
}

class _RadioInputDemoState extends State<RadioInputDemo> {
  String? _selectedOption;
  String? _selectedSize = 'medium';
  String? _selectedShipping = 'standard';

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SizedBox(
      height: double.infinity,
      child: SingleChildScrollView(
        child: Padding(
          padding: tokens.spacing.pd2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic radio group
              Text('Single Selection', style: tokens.typography.title),
              LayrzRadioInput<String>(
                value: _selectedOption,
                items: const [
                  LayrzSelectItem(value: 'option1', child: Text('Option 1'), searchableStrings: {'Option 1'}),
                  LayrzSelectItem(value: 'option2', child: Text('Option 2'), searchableStrings: {'Option 2'}),
                  LayrzSelectItem(value: 'option3', child: Text('Option 3'), searchableStrings: {'Option 3'}),
                ],
                onChanged: (v) {
                  setState(() {
                    _selectedOption = v;
                  });
                },
              ),

              // With custom labels
              tokens.spacing.sb3,
              Text('Size Selection', style: tokens.typography.title),
              LayrzRadioInput<String>(
                value: _selectedSize,
                items: const [
                  LayrzSelectItem(value: 'small', child: Text('Small'), searchableStrings: {'Small'}),
                  LayrzSelectItem(value: 'medium', child: Text('Medium'), searchableStrings: {'Medium'}),
                  LayrzSelectItem(value: 'large', child: Text('Large'), searchableStrings: {'Large'}),
                ],
                onChanged: (v) {
                  setState(() {
                    _selectedSize = v;
                  });
                },
              ),

              // With responsive grid spans
              tokens.spacing.sb3,
              Text('Shipping Method', style: tokens.typography.title),
              Text(
                'Uses responsive grid spans for better layout on different screen sizes',
                style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
              ),
              SizedBox(height: tokens.spacing.sp2),
              LayrzRadioInput<String>(
                value: _selectedShipping,
                items: const [
                  LayrzSelectItem(
                    value: 'standard',
                    child: Text('Standard (5-7 days)'),
                    searchableStrings: {'Standard (5-7 days)'},
                  ),
                  LayrzSelectItem(
                    value: 'express',
                    child: Text('Express (2-3 days)'),
                    searchableStrings: {'Express (2-3 days)'},
                  ),
                  LayrzSelectItem(value: 'overnight', child: Text('Overnight'), searchableStrings: {'Overnight'}),
                ],
                onChanged: (v) {
                  setState(() {
                    _selectedShipping = v;
                  });
                },
                md: 4,
              ),

              // Disabled
              tokens.spacing.sb3,
              Text('Disabled', style: tokens.typography.title),
              const LayrzRadioInput<String>(
                value: 'option1',
                disabled: true,
                items: [
                  LayrzSelectItem(
                    value: 'option1',
                    child: Text('Disabled option 1'),
                    searchableStrings: {'Disabled option 1'},
                  ),
                  LayrzSelectItem(
                    value: 'option2',
                    child: Text('Disabled option 2'),
                    searchableStrings: {'Disabled option 2'},
                  ),
                ],
              ),

              // With error
              tokens.spacing.sb3,
              Text('Error State', style: tokens.typography.title),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.spacing.sp2,
                children: [
                  Text('Please select an option *', style: tokens.typography.body),
                  SizedBox(height: tokens.spacing.sp2),
                  const LayrzRadioInput<String>(
                    value: null,
                    items: [
                      LayrzSelectItem(value: 'agree', child: Text('I agree'), searchableStrings: {'I agree'}),
                      LayrzSelectItem(value: 'disagree', child: Text('I disagree'), searchableStrings: {'I disagree'}),
                    ],
                    errors: ['You must make a selection'],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
