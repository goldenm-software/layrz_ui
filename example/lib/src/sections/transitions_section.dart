import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds the page-transitions section for the showroom.
///
/// Demonstrates every [LayrzPageTransitions] builder by actually pushing and
/// popping routes on a nested [Navigator], rather than only describing the
/// transitions in prose. A demo that never drives a real route push would
/// prove nothing about whether the builders integrate with [PageRouteBuilder]
/// — this section is that integration test made visible.
///
/// A [LayrzTransitionType] selector picks which [LayrzPageTransitions]
/// builder the nested [Navigator] uses for its next push; "Push" and "Back"
/// buttons drive the navigation so the selected transition can be watched
/// end to end. A separate toggle simulates the platform's reduced-motion
/// setting via a [MediaQuery] override, so a viewer can confirm every
/// transition collapses to [LayrzPageTransitions.none] under it without
/// needing to change their own OS accessibility setting.
class TransitionsSection extends StatefulWidget {
  /// Creates a new [TransitionsSection].
  const TransitionsSection({super.key});

  @override
  State<TransitionsSection> createState() => _TransitionsSectionState();
}

class _TransitionsSectionState extends State<TransitionsSection> {
  /// The nested [Navigator] the demo pushes routes onto, kept alive across
  /// rebuilds of this section so the pushed page survives a selector change.
  final _navigatorKey = GlobalKey<NavigatorState>();

  /// Which [LayrzTransitionType] the next push uses.
  LayrzTransitionType _selectedType = LayrzTransitionType.fade;

  /// Whether the demo simulates a reduced-motion platform setting.
  bool _reduceMotion = false;

  /// Which demo "page" (1 or 2) is on top of the nested navigator's stack,
  /// used only to alternate the pushed content so consecutive pushes are
  /// visually distinguishable.
  int _pageCounter = 1;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Page transitions',
      description:
          'Builder functions for PageRouteBuilder and go_router\'s CustomTransitionPage -- '
          'fade, slide, scale, rotation, and none. Select one and push to watch it run.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spacing.sp4,
        children: [
          _buildTypeSelector(tokens),
          _buildReduceMotionToggle(tokens),
          _buildControls(tokens),
          _buildStage(tokens),
        ],
      ),
    );
  }

  /// Builds the row of [LayrzButton]s that select which [LayrzTransitionType]
  /// the next push uses. The active selection renders
  /// [LayrzButtonStyle.filled]; the rest render
  /// [LayrzButtonStyle.outlined] — the same selected/unselected convention
  /// used by the steppers showroom page.
  Widget _buildTypeSelector(LayrzTokens tokens) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: tokens.spacing.sp2,
        children: [
          for (final type in LayrzTransitionType.values)
            LayrzButton(
              labelText: type.name,
              style: _selectedType == type ? LayrzButtonStyle.filled : LayrzButtonStyle.outlined,
              onTap: () => setState(() => _selectedType = type),
            ),
        ],
      ),
    );
  }

  /// Builds the toggle that simulates [MediaQuery.disableAnimationsOf]
  /// reporting a reduced-motion request, so a viewer can confirm every
  /// selected transition collapses to [LayrzPageTransitions.none] under it.
  Widget _buildReduceMotionToggle(LayrzTokens tokens) {
    return LayrzButton(
      labelText: _reduceMotion ? 'Reduce motion: on' : 'Reduce motion: off',
      style: _reduceMotion ? LayrzButtonStyle.filled : LayrzButtonStyle.outlined,
      onTap: () => setState(() => _reduceMotion = !_reduceMotion),
    );
  }

  /// Builds the "Push" and "Back" controls that drive the nested
  /// [Navigator] using the currently selected [LayrzTransitionType].
  Widget _buildControls(LayrzTokens tokens) {
    return Row(
      spacing: tokens.spacing.sp2,
      children: [
        LayrzButton(
          labelText: 'Push',
          onTap: () {
            _pageCounter++;
            final builder = LayrzPageTransitions.resolve(_selectedType);
            _navigatorKey.currentState?.push(
              PageRouteBuilder<void>(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    _DemoPage(pageNumber: _pageCounter, transitionType: _selectedType),
                transitionsBuilder: builder,
                transitionDuration: LayrzPageTransitions.durationOf(context),
              ),
            );
          },
        ),
        LayrzButton(
          labelText: 'Back',
          onTap: () {
            if (_navigatorKey.currentState?.canPop() ?? false) {
              _navigatorKey.currentState?.pop();
            }
          },
        ),
      ],
    );
  }

  /// Builds the bounded stage the nested [Navigator] renders into.
  ///
  /// A fixed height is required here (unlike a page-filling component such
  /// as `LayrzStepper`) because this stage lives inside `ShowroomSection`'s
  /// unbounded-height [SingleChildScrollView] — the nested [Navigator] needs
  /// real, bounded constraints to lay out its pages, so this [SizedBox]
  /// supplies them rather than leaving the navigator to size itself against
  /// infinite height.
  Widget _buildStage(LayrzTokens tokens) {
    return SizedBox(
      height: 220,
      child: LayrzCard(
        elevation: 1,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: _reduceMotion),
          child: Navigator(
            key: _navigatorKey,
            onGenerateRoute: (settings) => PageRouteBuilder<void>(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const _DemoPage(pageNumber: 1, transitionType: null),
              transitionsBuilder: LayrzPageTransitions.none,
            ),
          ),
        ),
      ),
    );
  }
}

/// The content pushed onto the demo's nested [Navigator].
///
/// Purely decorative — it exists to give each pushed route distinguishable
/// content (its [pageNumber] and, when pushed via the demo controls, the
/// [transitionType] that animated it in) so a viewer can tell that a push
/// actually happened rather than the same page re-rendering in place.
class _DemoPage extends StatelessWidget {
  /// Creates a new [_DemoPage].
  const _DemoPage({required this.pageNumber, required this.transitionType});

  /// The ordinal of this pushed page, shown so consecutive pushes are
  /// visually distinguishable from one another.
  final int pageNumber;

  /// The [LayrzTransitionType] that animated this page in, or `null` for the
  /// nested [Navigator]'s initial route (which is never animated in, since
  /// there is nothing before it to transition from).
  final LayrzTransitionType? transitionType;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ColoredBox(
      color: tokens.colors.sf2,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spacing.sp2,
          children: [
            Text('Page $pageNumber', style: tokens.typography.title),
            Text(
              transitionType == null ? 'initial route' : 'via ${transitionType!.name}',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
          ],
        ),
      ),
    );
  }
}
