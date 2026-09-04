import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds the accordion section for the showroom.
///
/// Demonstrates [LayrzAccordion] as a controlled disclosure panel: three
/// independent panels, each holding its own `expanded` bool in local state,
/// showing the expand/collapse animation, a leading icon, and the disabled
/// (no [LayrzAccordion.onExpansionChanged]) form side by side with the
/// interactive ones.
class AccordionSection extends StatefulWidget {
  /// Creates a new [AccordionSection].
  const AccordionSection({super.key});

  @override
  State<AccordionSection> createState() => _AccordionSectionState();
}

class _AccordionSectionState extends State<AccordionSection> {
  /// Whether the "Shipping details" panel is expanded.
  bool _shippingExpanded = true;

  /// Whether the "Payment method" panel is expanded.
  bool _paymentExpanded = false;

  /// Whether the "Order history" panel is expanded.
  bool _historyExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Accordion',
      description:
          'A single controlled disclosure panel -- expanded state lives with the caller, '
          'never inside the widget itself.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Independent panels, each with its own expanded state', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          LayrzAccordion(
            titleText: 'Shipping details',
            leadingIcon: MdiIcons.truckOutline,
            expanded: _shippingExpanded,
            onExpansionChanged: (value) => setState(() => _shippingExpanded = value),
            body: Padding(
              padding: EdgeInsets.all(tokens.spacing.sp3),
              child: Text(
                'Ships to 1234 Market Street, Suite 500, San Francisco, CA. Estimated arrival: '
                '3-5 business days via ground carrier.',
                style: tokens.typography.body,
              ),
            ),
          ),
          SizedBox(height: tokens.spacing.sp2),
          LayrzAccordion(
            titleText: 'Payment method',
            leadingIcon: MdiIcons.creditCardOutline,
            expanded: _paymentExpanded,
            onExpansionChanged: (value) => setState(() => _paymentExpanded = value),
            body: Padding(
              padding: EdgeInsets.all(tokens.spacing.sp3),
              child: Text(
                'Visa ending in 4242, billed monthly. Update the card on file from account settings.',
                style: tokens.typography.body,
              ),
            ),
          ),
          SizedBox(height: tokens.spacing.sp2),
          LayrzAccordion(
            titleText: 'Order history',
            leadingIcon: MdiIcons.history,
            expanded: _historyExpanded,
            onExpansionChanged: (value) => setState(() => _historyExpanded = value),
            body: Padding(
              padding: EdgeInsets.all(tokens.spacing.sp3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#10492 -- Delivered Aug 12', style: tokens.typography.body),
                  SizedBox(height: tokens.spacing.sp1),
                  Text('#10201 -- Delivered Jul 03', style: tokens.typography.body),
                  SizedBox(height: tokens.spacing.sp1),
                  Text('#9987 -- Delivered Jun 21', style: tokens.typography.body),
                ],
              ),
            ),
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('No leading icon', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'When leadingIcon is omitted, no placeholder space is reserved for it.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzAccordion(
            titleText: 'Terms and conditions',
            expanded: _historyExpanded,
            onExpansionChanged: (value) => setState(() => _historyExpanded = value),
            body: Padding(
              padding: EdgeInsets.all(tokens.spacing.sp3),
              child: Text(
                'By continuing you agree to the sample terms of this showroom -- there are none, '
                'this is placeholder text.',
                style: tokens.typography.body,
              ),
            ),
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('Disabled (no onExpansionChanged)', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'The header does not respond to tap, hover, or keyboard activation when '
            'onExpansionChanged is null.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzAccordion(
            titleText: 'Archived (read-only)',
            leadingIcon: MdiIcons.lockOutline,
            expanded: false,
            body: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
