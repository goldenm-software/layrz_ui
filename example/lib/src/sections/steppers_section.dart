import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Which of the two [LayrzStepperDirection]s the demo page is currently showing.
enum _StepperDemoTab {
  /// [LayrzStepperDirection.horizontal] — the full-width step navigator with a
  /// persistent header band.
  horizontal,

  /// [LayrzStepperDirection.vertical] — the accordion layout.
  vertical,
}

/// Builds the steppers section for the showroom.
///
/// Demonstrates [LayrzStepper], a page-filling step navigator that has no
/// notion of managing its own height — the same way a [ListView] or a
/// [Scrollable] does not decide how tall it is allowed to be, [LayrzStepper]
/// expects its caller to hand it real, bounded space and fills exactly that.
/// That is why this component gets a **dedicated page** rather than a slot in
/// `InputsSection`'s list-detail pane: a list-detail right-hand pane is sized
/// for a form or a handful of controls, not for a component whose horizontal
/// layout wants the whole page.
///
/// Unlike every other section in this showroom, this page does **not** use
/// `ShowroomSection`: that shell wraps its child in a [SingleChildScrollView],
/// which hands its child *unbounded* height — the opposite of what a
/// page-filling component needs to prove it actually fills a page, and a
/// bounded-but-scrollable stand-in (a fixed or viewport-fraction height box)
/// would just re-create the same box the component was designed to avoid.
/// Instead this page builds its own non-scrolling shell: a title band, a
/// [_StepperDemoTab] toggle, and a single [Expanded] content area that
/// receives the page's own real, bounded constraints from `ShowroomLayout`
/// (which hands its body a full-size, non-scrolling [SizedBox]) and passes
/// them straight down to whichever [LayrzStepper] is selected. Because that
/// constraint chain is genuinely bounded end to end, both tabs render behind
/// a plain [Expanded] with no [MediaQuery] height arithmetic, no hardcoded
/// pixel estimates of sibling content, and no clamps anywhere in this file.
///
/// The two directions used to be stacked on top of each other; now they are
/// two tabs over the same content area, switched with a small pair of
/// [LayrzButton]s (no Material `TabBar` is available in this Material-free
/// library, and building a bespoke tab widget for a single example page is
/// more machinery than the demo needs). Both [LayrzStepperController]s are
/// created once in [State.initState] and disposed in [State.dispose], and an
/// [IndexedStack] keeps both tabs' widget subtrees mounted across a switch
/// (instead of rebuilding the inactive one from scratch), so switching tabs
/// never loses the in-progress step or forces a step transition to replay.
///
/// This page demonstrates, in order:
/// - The **horizontal** tab, with five steps, including one whose label
///   wraps to two lines — proving a wrapped label cannot shift its own
///   indicator out of line with its neighbours (see `stepper_wide.dart`'s
///   two-band layout, the fix for exactly that bug).
/// - The **vertical** (accordion) tab.
/// - Caller-supplied [LayrzStep.icon]s on upcoming/active/completed steps,
///   demonstrating that the state glyph always overrides the identity icon
///   once a step is completed or errored.
/// - A locked (upcoming) step and a tappable error step, since error steps
///   became tappable as part of the redesign that introduced this page.
class StepperSection extends StatefulWidget {
  /// Creates a new [StepperSection].
  const StepperSection({super.key});

  @override
  State<StepperSection> createState() => _StepperSectionState();
}

class _StepperSectionState extends State<StepperSection> {
  /// Controller for the horizontal-layout wizard tab.
  late LayrzStepperController _horizontalController;

  /// Controller for the vertical-accordion tab.
  late LayrzStepperController _verticalController;

  /// Which tab is currently visible. Starts on the horizontal layout.
  _StepperDemoTab _activeTab = _StepperDemoTab.horizontal;

  @override
  void initState() {
    super.initState();
    _horizontalController = LayrzStepperController();
    _verticalController = LayrzStepperController();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Steppers', style: tokens.typography.headline),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'A page-filling step navigator. Switch tabs to compare the horizontal and vertical '
            'directions, each filling the full page area below with no scrolling.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: tokens.spacing.sp3),
          _buildTabToggle(tokens),
          SizedBox(height: tokens.spacing.sp3),
          Expanded(
            child: LayrzCard(
              elevation: 1,
              child: IndexedStack(
                index: _activeTab.index,
                children: [
                  _buildHorizontalDemo(),
                  _buildVerticalDemo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the row of two [LayrzButton]s used to switch between the
  /// horizontal and vertical demo tabs.
  ///
  /// The active tab is rendered [LayrzButtonStyle.filled] (filled, matching
  /// the "selected" affordance used elsewhere in the design system) and the
  /// inactive tab [LayrzButtonStyle.outlined], so the current selection is
  /// legible at a glance without introducing a dedicated tab component.
  ///
  /// [LayrzButton]'s width is intrinsic and not caller-configurable (see its
  /// class doc), so on a narrow enough window the two buttons' combined width
  /// can exceed the space available. Wrapping the row in a horizontally
  /// scrolling [SingleChildScrollView] lets it overflow into a scroll instead
  /// of into the render tree — this is a two-button control, not the
  /// page-filling component under demonstration, so scrolling it is a plain
  /// UI affordance rather than a compromise on the "no scrolling" rule that
  /// applies to the stepper content area below.
  Widget _buildTabToggle(LayrzTokens tokens) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: tokens.spacing.sp2,
        children: [
          LayrzButton(
            labelText: 'Horizontal',
            style: _activeTab == _StepperDemoTab.horizontal ? LayrzButtonStyle.filled : LayrzButtonStyle.outlined,
            onTap: () => setState(() => _activeTab = _StepperDemoTab.horizontal),
          ),
          LayrzButton(
            labelText: 'Vertical',
            style: _activeTab == _StepperDemoTab.vertical ? LayrzButtonStyle.filled : LayrzButtonStyle.outlined,
            onTap: () => setState(() => _activeTab = _StepperDemoTab.vertical),
          ),
        ],
      ),
    );
  }

  /// Builds the horizontal-direction tab's content: [LayrzStepper] with
  /// `direction: LayrzStepperDirection.horizontal`, filling the space
  /// [Expanded] gives it.
  Widget _buildHorizontalDemo() {
    return LayrzStepper(
      controller: _horizontalController,
      direction: LayrzStepperDirection.horizontal,
      steps: [
        LayrzStep(
          labelText: 'Account',
          icon: MdiIcons.accountOutline,
          body: _buildStepContent('Enter your name and email'),
        ),
        LayrzStep(
          labelText: 'Confirm shipping address for delivery',
          icon: MdiIcons.mapMarkerOutline,
          body: _buildStepContent(
            'This label is long enough to wrap to two lines -- its circle above must '
            'stay aligned with every other step\'s circle regardless.',
          ),
        ),
        LayrzStep(
          labelText: 'Billing',
          icon: MdiIcons.creditCardOutline,
          body: _buildStepContent('Provide payment details'),
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
          ),
        ),
      ],
    );
  }

  /// Builds the vertical-direction tab's content: [LayrzStepper] with
  /// `direction: LayrzStepperDirection.vertical`, filling the space
  /// [Expanded] gives it.
  ///
  /// Unlike the horizontal layout, the accordion's natural content can be
  /// taller than the space available on a short viewport: only the active
  /// step's body is ever open, but the header rows for every other step, plus
  /// that one open body, still have to fit somewhere. `LayrzStepper` itself
  /// makes no attempt to scroll or clip that content — it is a `Column`, not
  /// a `ListView` — so this demo wraps it in its own [SingleChildScrollView]
  /// to let it grow past the box by scrolling instead of overflowing. This is
  /// the same accommodation a real caller embedding a vertical stepper in a
  /// fixed-height container would have to make; it is not a workaround for a
  /// bug in the component.
  Widget _buildVerticalDemo() {
    return SingleChildScrollView(
      child: LayrzStepper(
        controller: _verticalController,
        direction: LayrzStepperDirection.vertical,
        backButtonLabel: 'Previous',
        nextButtonLabel: 'Continue',
        steps: [
          LayrzStep(
            labelText: 'Agreement',
            icon: MdiIcons.fileDocumentOutline,
            body: _buildStepContent('Read and accept terms of service'),
          ),
          const LayrzStep(
            labelText: 'Verification failed',
            state: LayrzStepperState.error,
            body: _ErrorStepBody(),
          ),
          LayrzStep(
            labelText: 'Setup',
            icon: MdiIcons.cogOutline,
            body: _buildStepContent('Configure your account settings'),
          ),
          LayrzStep(
            labelText: 'Done',
            icon: MdiIcons.checkCircleOutline,
            body: _buildStepContent(
              'Your account is ready! This step\'s icon above is overridden by the '
              'checkmark glyph once it is completed -- the state glyph always wins.',
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the shared placeholder body content shown for a healthy
  /// (non-error) step: a short description line followed by a sample input
  /// field.
  Widget _buildStepContent(String text) {
    final tokens = context.tokens;
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
/// Error steps are tappable, so this body exists to make that reachable:
/// tapping the error step's header or indicator opens this explanatory copy
/// instead of leaving the state undemonstrated.
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
