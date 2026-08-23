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
                  LayrzSelectItem(labelText: 'Option 1', value: 'option1'),
                  LayrzSelectItem(labelText: 'Option 2', value: 'option2'),
                  LayrzSelectItem(labelText: 'Option 3', value: 'option3'),
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
                  LayrzSelectItem(labelText: 'Small', value: 'small'),
                  LayrzSelectItem(labelText: 'Medium', value: 'medium'),
                  LayrzSelectItem(labelText: 'Large', value: 'large'),
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
                  LayrzSelectItem(labelText: 'Standard (5-7 days)', value: 'standard'),
                  LayrzSelectItem(labelText: 'Express (2-3 days)', value: 'express'),
                  LayrzSelectItem(labelText: 'Overnight', value: 'overnight'),
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
                  LayrzSelectItem(labelText: 'Disabled option 1', value: 'option1'),
                  LayrzSelectItem(labelText: 'Disabled option 2', value: 'option2'),
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
                      LayrzSelectItem(labelText: 'I agree', value: 'agree'),
                      LayrzSelectItem(labelText: 'I disagree', value: 'disagree'),
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
