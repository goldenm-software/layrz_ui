import 'package:flutter/widgets.dart';

/// The thickness, in logical pixels, of a [LayrzTimelineConnector] line.
const double kLayrzTimelineConnectorThickness = 2.0;

/// A single vertical connector segment drawn between two adjacent
/// [LayrzTimelineMarker]s on a [LayrzTimeline]'s spine.
///
/// This is deliberately a plain colored [Container], the same painting
/// approach `LayrzStepper`'s `_Connector` (`stepper_wide.dart`) uses for its
/// horizontal segments — a straight line filling the flex space it is given.
/// **Only that approach is shared; the code is duplicated, not imported.**
/// Per the batch's implementation plan §5.3, `LayrzTimeline` must not depend
/// on `lib/src/steppers/`: `LayrzStepper` is still `Pending review by team`,
/// so anything imported from it would inherit that instability, and a
/// connector is two lines of code — not enough to justify coupling two
/// otherwise-unrelated modules over.
///
/// Unlike the stepper's connector, this one has no "progressed" vs. "neutral"
/// state to render — a timeline has no active/completed step to progress
/// through. Its only visual parameter is [color], resolved per-segment by the
/// caller from the entry's own [LayrzTimelineStyleSpec.connectorColor].
class LayrzTimelineConnector extends StatelessWidget {
  /// Creates a [LayrzTimelineConnector].
  const LayrzTimelineConnector({
    required this.color,
    super.key,
  });

  /// The color painted along this connector segment.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: kLayrzTimelineConnectorThickness,
        color: color,
      ),
    );
  }
}
