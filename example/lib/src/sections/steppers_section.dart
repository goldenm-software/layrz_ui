import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds the steppers section for the showroom.
///
/// Demonstrates [LayrzStepper], a page-filling step navigator that has no
/// notion of managing its own height — the same way a [ListView] or a
/// [Scrollable] does not decide how tall it is allowed to be, [LayrzStepper]
/// expects its caller to hand it real, bounded space and fills exactly that.
/// That is why this component gets a **dedicated page** rather than a slot in
/// `InputsSection`'s list-detail pane: a list-detail right-hand pane is sized
/// for a form or a handful of controls, not for a component whose wide layout
/// wants the whole page.
///
/// Unlike [DialogsSection] and [SheetsSection] — whose demos are buttons that
/// *open* a component elsewhere — this page renders [LayrzStepper] inline, so
/// it cannot lean on [ShowroomSection]'s [SingleChildScrollView] for its
/// height the way every other section here does: a scroll view hands its
/// child unbounded height, which is the opposite of what a page-filling
/// component needs to prove it actually fills a page. Instead, the wide
/// wizard below sizes itself from the live viewport height via
/// [MediaQuery.sizeOf], minus a reserved allowance for the heading and the
/// second demo beneath it, so resizing the window resizes the stepper the
/// same way a real caller's page would.
///
/// This page demonstrates, in order:
/// - The **wide layout** at genuine full width with five steps, including one
///   whose label wraps to two lines — proving a wrapped label cannot shift
///   its own indicator out of line with its neighbours (see
///   `stepper_wide.dart`'s two-band layout, the fix for exactly that bug).
/// - The **compact accordion**, forced via `isCompact: true` regardless of
///   window width, so the vertical layout is visible without resizing.
/// - Caller-supplied [LayrzStep.icon]s on upcoming/active/completed steps,
///   demonstrating that the state glyph always overrides the identity icon
///   once a step is completed or errored.
/// - A locked (upcoming) step and a tappable error step, since error steps
///   became tappable as part of this same redesign.
class StepperSection extends StatefulWidget {
  /// Creates a new [StepperSection].
  const StepperSection({super.key});

  @override
  State<StepperSection> createState() => _StepperSectionState();
}

class _StepperSectionState extends State<StepperSection> {
  /// Controller for the full-height wide-layout wizard.
  late LayrzStepperController _wideController;

  /// Controller for the compact-accordion demo, forced to `isCompact: true`
  /// so its layout is visible regardless of the window's actual width.
  late LayrzStepperController _compactController;

  @override
  void initState() {
    super.initState();
    _wideController = LayrzStepperController();
    _compactController = LayrzStepperController();
  }

  @override
  void dispose() {
    _wideController.dispose();
    _compactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final viewportHeight = MediaQuery.sizeOf(context).height;

    // Reserves room for everything ShowroomSection renders above and below
    // the wizard on this page -- its own title/description, this demo's own
    // heading and caption, the section's outer padding, and the compact demo
    // that follows -- so the wide wizard genuinely fills the remainder of the
    // viewport instead of a value picked to merely look full. There is no
    // spacing token above sp5 (32px) to compose an exact figure from, so this
    // is a deliberate estimate, clamped to a sane floor for very short
    // viewports.
    const reservedForRestOfPage = 620.0;
    final wizardHeight = (viewportHeight - reservedForRestOfPage).clamp(420.0, double.infinity);

    return ShowroomSection(
      title: 'Steppers',
      description: 'A page-filling step navigator with wide and compact layouts',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spacing.sp5,
        children: [
          Text('Wide layout -- full page width', style: tokens.typography.title),
          Text(
            'Five steps sized to the live viewport height via MediaQuery, not a fixed box. '
            'The "Confirm shipping address for delivery" step has a label long enough to wrap '
            'to two lines -- watch that its circle stays aligned with its neighbours instead of '
            'shifting downward, which is the bug this layout was redesigned to fix.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(
            height: wizardHeight,
            child: LayrzStepper(
              controller: _wideController,
              steps: [
                LayrzStep(
                  labelText: 'Account',
                  icon: MdiIcons.accountOutline,
                  body: _buildStepContent(
                    'Enter your name and email',
                    tokens,
                  ),
                ),
                LayrzStep(
                  labelText: 'Confirm shipping address for delivery',
                  icon: MdiIcons.mapMarkerOutline,
                  body: _buildStepContent(
                    'This label is long enough to wrap to two lines -- its circle above must '
                    'stay aligned with every other step\'s circle regardless.',
                    tokens,
                  ),
                ),
                LayrzStep(
                  labelText: 'Billing',
                  icon: MdiIcons.creditCardOutline,
                  body: _buildStepContent(
                    'Provide payment details',
                    tokens,
                  ),
                ),
                const LayrzStep(
                  labelText: 'Payment declined',
                  state: LayrzStepperState.error,
                  body: _ErrorStepBody(),
                ),
                LayrzStep(
                  labelText: 'Review',
                  icon: MdiIcons.clipboardCheckOutline,
                  body: _buildStepContent(
                    'This step has not been reached yet -- it stays locked (lock glyph, no '
                    'chevron, not tappable) until every step before it is completed.',
                    tokens,
                  ),
                ),
              ],
            ),
          ),

          Text('Compact accordion -- forced isCompact: true', style: tokens.typography.title),
          Text(
            'The same states rendered as a vertical accordion, regardless of this window\'s '
            'actual width. Only the active step is open; completed and error rows are tappable '
            'and carry a chevron, the locked row carries a lock glyph instead.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          LayrzStepper(
            controller: _compactController,
            isCompact: true,
            backButtonLabel: 'Previous',
            nextButtonLabel: 'Continue',
            steps: [
              LayrzStep(
                labelText: 'Agreement',
                icon: MdiIcons.fileDocumentOutline,
                body: _buildStepContent(
                  'Read and accept terms of service',
                  tokens,
                ),
              ),
              const LayrzStep(
                labelText: 'Verification failed',
                state: LayrzStepperState.error,
                body: _ErrorStepBody(),
              ),
              LayrzStep(
                labelText: 'Setup',
                icon: MdiIcons.cogOutline,
                body: _buildStepContent(
                  'Configure your account settings',
                  tokens,
                ),
              ),
              LayrzStep(
                labelText: 'Done',
                icon: MdiIcons.checkCircleOutline,
                body: _buildStepContent(
                  'Your account is ready! This step\'s icon above is overridden by the '
                  'checkmark glyph once it is completed -- the state glyph always wins.',
                  tokens,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the shared placeholder body content shown for a healthy (non-error) step: a
  /// short description line followed by a sample input field.
  Widget _buildStepContent(String text, LayrzTokens tokens) {
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spacing.sp3,
        children: [
          Text(text, style: tokens.typography.body),
          const LayrzTextInput(
            labelText: 'Input field',
            hintText: 'Enter some information',
          ),
        ],
      ),
    );
  }
}

/// The body shown for a step forced into [LayrzStepperState.error].
///
/// Error steps are tappable -- new as of this redesign -- so this body exists
/// to make that reachable: tapping the error step's header or indicator opens
/// this explanatory copy instead of leaving the state undemonstrated.
class _ErrorStepBody extends StatelessWidget {
  /// Creates a new [_ErrorStepBody].
  const _ErrorStepBody();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spacing.sp2,
        children: [
          Text(
            'This step is in LayrzStepperState.error',
            style: tokens.typography.body.copyWith(color: tokens.colors.danger),
          ),
          Text(
            'Its indicator shows the alert glyph regardless of any caller-supplied icon, and -- '
            'unlike an upcoming/locked step -- it stays tappable so it can be jumped to directly '
            'for correction.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
        ],
      ),
    );
  }
}
