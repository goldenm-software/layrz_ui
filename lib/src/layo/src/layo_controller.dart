import 'package:flutter/foundation.dart';

import 'layo_emotion.dart';

/// A controller that drives which [LayoEmotion] transition [TransitionedLayo]
/// is currently playing.
///
/// **Architecture, matching this codebase's other controllers** (e.g.
/// `LayrzStepperController`, `LayrzButtonController`): the controller owns
/// only *intent and state* — which emotion the transition started from, which
/// one it is headed to, and which one is the caller's current target — and
/// notifies its listeners on every change via [ChangeNotifier]. It owns no
/// [AnimationController] and no vsync of its own; [TransitionedLayo] is the
/// one that owns the ticker, listens to this controller, and drives the
/// actual `0..1` progress value fed to `LayoPainter.transitionT` each frame.
/// This mirrors `TabController`'s own split in spirit (a controller that
/// tracks *which* index is selected, with the animation itself owned by
/// whatever widget renders the transition) while keeping this controller
/// entirely animation-framework-agnostic — nothing here requires a
/// [TickerProvider], so it can be constructed anywhere, including outside a
/// widget's `State`, and reused across a widget disposal/recreation.
///
/// **Deliberately no queue.** [to] is the controller's only mutating method:
/// calling it again while a transition is already in flight does not enqueue
/// a second transition to play after the first finishes — it **re-bases**
/// immediately, discarding whatever the in-flight transition was headed
/// toward. The new [from] becomes whatever emotion was actually on screen at
/// the moment of the re-base (see [to]'s own doc comment for exactly which
/// emotion that is), and the new [target] becomes the just-requested target.
/// This is a deliberate design choice, not an oversight: a mascot reacting to
/// a live stream of state changes (e.g. one emotion per incoming event)
/// should always be racing toward the *latest* truth, never dutifully playing
/// out a backlog of stale intermediate ones.
class LayoController extends ChangeNotifier {
  /// Creates a new [LayoController], initially at rest on [initialEmotion]
  /// with no transition in progress.
  ///
  /// [initialEmotion] is the emotion this controller (and, through it,
  /// whichever [TransitionedLayo] instances attach to it) starts on before
  /// [to] is ever called. Defaults to [LayoEmotion.mrLayo], the same default
  /// [Layo] itself uses.
  LayoController({LayoEmotion initialEmotion = LayoEmotion.mrLayo})
    : _from = initialEmotion,
      _target = initialEmotion,
      _current = initialEmotion;

  /// The emotion the current (or most recently completed) transition started
  /// from.
  ///
  /// Equal to [target] (and [current]) whenever this controller is at rest —
  /// a transition's `from` and `target` only ever differ for the ~280ms
  /// [TransitionedLayo] itself takes to animate between them; this field
  /// simply holds whichever value that most recent [to] call captured, so it
  /// keeps reading as "where the last transition began" even after the
  /// transition finishes and [current] catches up to [target].
  LayoEmotion _from;

  /// The emotion the current (or most recently completed) transition is
  /// headed to — this controller's actual target, set by [to].
  LayoEmotion _target;

  /// This controller's own best estimate of the emotion currently visible:
  /// [target] once a transition completes, or whichever emotion a caller
  /// last reported as visible mid-transition via [reportCurrent]. Used only
  /// to compute the next [from] on a re-basing [to] call — see [to]'s own
  /// doc comment.
  LayoEmotion _current;

  /// The emotion the active (or just-completed) transition started from.
  ///
  /// Reads [target] itself once a transition finishes and no further [to]
  /// call has re-based it — see [_from]'s own doc comment.
  LayoEmotion get from => _from;

  /// The emotion this controller is currently targeting — the destination of
  /// the active (or just-completed) transition.
  ///
  /// This is this controller's single source of truth for "what should
  /// [TransitionedLayo] be showing, or animating toward, right now"; read it
  /// alongside [from] to know both ends of the transition in progress. Set by
  /// [to] — kept as its own `target` getter (rather than `to`, which the
  /// mutating method itself already claims as its name) so both can coexist.
  LayoEmotion get target => _target;

  /// Requests a transition to [emotion].
  ///
  /// This is the controller's **only** mutating method — deliberately, there
  /// is no `queue`/`enqueue` counterpart (see the class doc comment). Calling
  /// [to] while a previous transition is still in flight does not wait for
  /// it: the currently-visible, actually-interpolated emotion (as last
  /// reported to this controller by [TransitionedLayo] via [reportCurrent])
  /// becomes the new [from], and [emotion] becomes the new [target] — so the
  /// mascot smoothly re-directs from wherever it visually was, rather than
  /// snapping back to the old [from] or finishing the stale transition first.
  ///
  /// Calling [to] with the same value [target] already holds is a no-op: no
  /// new transition is started and no listener is notified, since nothing
  /// about the controller's target state actually changed.
  ///
  /// [emotion] is the [LayoEmotion] this controller should now transition
  /// toward.
  void to(LayoEmotion emotion) {
    if (emotion == _target) return;
    _from = _current;
    _target = emotion;
    notifyListeners();
  }

  /// Reports the emotion [TransitionedLayo] is actually showing right now —
  /// [target] itself once its transition has fully settled, or the nearer
  /// endpoint of an in-flight transition abandoned partway through by a new
  /// [to] call.
  ///
  /// [TransitionedLayo] calls this on every animation frame while a
  /// transition plays (and once more when a transition settles), so a
  /// re-basing [to] call always reads this controller's own best available
  /// estimate of the visible emotion as its new [from] — see [to]'s own doc
  /// comment. A caller driving this controller without ever attaching a
  /// [TransitionedLayo] to it (e.g. in a test) can simply never call this;
  /// [_current] then stays at whichever emotion [to] itself last targeted,
  /// which is the correct fallback for "no transition ever actually played".
  ///
  /// [emotion] is the [LayoEmotion] currently on screen, as observed by the
  /// caller (ordinarily [TransitionedLayo] itself).
  void reportCurrent(LayoEmotion emotion) {
    _current = emotion;
  }
}
