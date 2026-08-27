import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import '../shared/input_footer_slot.dart';
import 'slider_geometry.dart';
import 'slider_painter.dart';
import 'slider_style.dart';
import 'slider_track_area.dart';

/// A Material-free, hand-rolled single-value slider control in the layrz_ui design system.
///
/// [LayrzSlider] lets a user pick a numeric value from a continuous or
/// quantised `[min, max]` range by dragging or tapping a horizontal track, or
/// by using the keyboard once focused. There is no `RawSlider` in the Flutter
/// SDK and Material's `Slider` is unusable in this Material-free codebase, so
/// the track, thumb, hit-testing, drag handling, quantisation, and keyboard
/// interaction are all built from scratch on [GestureDetector] and
/// [CustomPaint] (via [LayrzSliderPainter]).
///
/// **Input-contract conformance (D63)**: this control does not compose
/// `LayrzTextInput` and does not compose the frozen `LayrzInputChrome`. Per
/// decision D63, a slider is "a control with a label, not a bordered field" —
/// the same category as `LayrzCheckboxInput`, `LayrzSwitchInput`, and
/// `LayrzRadioInput`, all of which own their visual state directly instead of
/// wrapping another input. [LayrzSlider] follows the same structural template
/// as those three: a `StatefulWidget` holding a mutable `Set<WidgetState>` for
/// interaction-state colour resolution, with `GestureDetector` → `Focus` →
/// `Semantics` nesting and a `_focusFromPointer` flag so a mouse click does not
/// paint a keyboard focus ring.
///
/// **Value contract**: [value] is always clamped to `[min, max]` and, when
/// [divisions] is set (2 or more), quantised to the nearest step via
/// [quantizeLayrzSliderValue]. [onChanged] fires with the already-quantised
/// value; the caller never receives an out-of-range or unsnapped value.
///
/// **Live value feedback (core, not decorative)**: per decision D15, the
/// thumb never changes size on hover, press, or focus — only colour, border
/// colour, and shadow may vary. Since the thumb cannot grow to confirm a drag
/// registered, this control instead shows the current value in a label
/// positioned above the track (so a dragging finger on a touch device does
/// not cover it), which updates live on every drag delta, not only on
/// release. This label is controlled by [showValueLabel] but defaults to
/// visible, because a visible current value is required, not optional, for v1.
///
/// **Drag value bubble**: while a drag is active, a small
/// [LayrzSliderValueBubble] additionally appears directly above the thumb,
/// its downward-pointing tail connecting it visually to the thumb it
/// tracks, and showing the same formatted value as the static label. It
/// supplements that static label rather than replacing it — the static
/// label stays the reliable fallback for touch users whose fingertip may be
/// covering the bubble, while desktop/mouse users get an affordance anchored
/// to the thing they are actually dragging. The bubble is
/// laid out as a [Positioned] child of a [Stack] configured with
/// `clipBehavior: Clip.none`, so it paints outside the track's normal layout
/// box instead of being counted in it — its appearance and disappearance
/// across a drag never changes the slider's laid-out height, which is the
/// exact reflow D15 exists to prevent. It honours [showValueLabel] (no
/// bubble when the caller has suppressed value display) and is wrapped in
/// [ExcludeSemantics] since the value is already announced via
/// `Semantics.value`.
///
/// **Hit-slop**: the invisible [GestureDetector] hit region is taller than the
/// painted track (see [_trackHeight] vs. the actual drawn line), so a touch
/// slightly above or below the thin track line still registers. This is
/// compatible with D15, which forbids *visual* geometry changes on
/// interaction state, not a track whose hit region is larger than its drawn
/// pixels in the first place.
///
/// **Keyboard interaction**: once focused, Left/Down decrease the value by one
/// step and Right/Up increase it by one step (one step is `(max - min) /
/// divisions` when [divisions] is set, or 1% of the range otherwise), Home
/// jumps to [min], and End jumps to [max]. Handled via `Focus.onKeyEvent`,
/// following the same pattern as `LayrzCheckboxInput`/`LayrzSwitchInput`
/// (there is no `Shortcuts`/`Actions` precedent for this in the codebase —
/// `lib/src/keyboard/` only holds a shortcut *display formatter*, not
/// intent-mapping helpers, so this is new).
///
/// **Accessibility**: exposes a [Semantics] node with `slider: true`, an
/// announced `value`, `increasedValue`/`decreasedValue`, and `onIncrease`/
/// `onDecrease` actions, so a screen reader user can operate the control
/// without a pointer. A drag-only slider with no semantics is unusable via
/// assistive technology, which decision context treats as non-negotiable.
///
/// **Range/dual-thumb is explicitly out of scope** for this widget. A future
/// `LayrzRangeSlider` is the intended home for a two-thumb range control,
/// mirroring the `LayrzDatePicker`/`LayrzDateRangePicker` split.
class LayrzSlider extends StatefulWidget {
  /// The label text displayed above the slider track.
  ///
  /// If null, no label row is rendered above the track.
  final String? labelText;

  /// The current value of the slider.
  ///
  /// Always treated as clamped to `[min, max]` and, when [divisions] is set,
  /// quantised to the nearest step before being painted or announced.
  final double value;

  /// The minimum value the slider can represent.
  ///
  /// Must be less than or equal to [max]. When equal to [max], the slider
  /// represents a single degenerate point and the thumb is fixed at the
  /// track's start.
  final double min;

  /// The maximum value the slider can represent.
  ///
  /// Must be greater than or equal to [min].
  final double max;

  /// The number of discrete steps the value snaps to, or `null` for a
  /// continuous range.
  ///
  /// When set to `2` or greater, the track is divided into this many equal
  /// steps and the value snaps to the nearest one. Values of `null`, `0`, or
  /// `1` are all treated as "no quantisation" — a single division has no
  /// intermediate step to snap to.
  final int? divisions;

  /// Callback fired when the user drags, taps, or uses the keyboard to change
  /// the value.
  ///
  /// The callback receives the new value already clamped to `[min, max]` and
  /// quantised per [divisions]. Fires continuously during a drag (not only on
  /// release), which is what drives the live value-label feedback required by
  /// this control's interaction design. If null, the slider is disabled and
  /// does not respond to user input.
  final ValueChanged<double>? onChanged;

  /// Whether to show the current value as a label above the track.
  ///
  /// Defaults to `true`. A visible current value is a required affordance for
  /// this control (not optional), because the fixed-size thumb (per D15)
  /// cannot itself confirm that a drag registered — the caller may still
  /// suppress it via this flag when the value is shown elsewhere in the UI.
  final bool showValueLabel;

  /// Formats [value] for display in the value label and in the slider's
  /// semantics announcement.
  ///
  /// Defaults to a formatter that renders whole numbers without a decimal
  /// point and otherwise shows up to two decimal places.
  final String Function(double value)? valueFormatter;

  /// The focus node for the slider control.
  ///
  /// If null, a focus node is created and disposed by the widget.
  /// Caller-supplied focus nodes are never disposed.
  final FocusNode? focusNode;

  /// The list of error messages to display below the control.
  final List<String> errors;

  /// Whether to hide the error message block.
  final bool hideDetails;

  /// Whether the slider is disabled (read-only and non-interactive).
  final bool disabled;

  /// Whether this slider should request focus as soon as it is inserted into
  /// the widget tree, provided no other node is currently focused.
  ///
  /// Forwarded directly to the internal [Focus] widget. Defaults to `false`,
  /// matching `Focus.autofocus`'s own default.
  final bool autofocus;

  /// Creates a new [LayrzSlider] with the given properties.
  const LayrzSlider({
    super.key,
    this.labelText,
    required this.value,
    this.min = 0.0,
    this.max = 100.0,
    this.divisions,
    this.onChanged,
    this.showValueLabel = true,
    this.valueFormatter,
    this.focusNode,
    this.errors = const [],
    this.hideDetails = false,
    this.disabled = false,
    this.autofocus = false,
  });

  @override
  State<LayrzSlider> createState() => _LayrzSliderState();
}

class _LayrzSliderState extends State<LayrzSlider> {
  late FocusNode _focusNode;
  final Set<WidgetState> _states = {};

  /// Whether focus was gained from a pointer interaction (tap/click/drag).
  ///
  /// Used to implement :focus-visible semantics: focus visual effects
  /// (colour) are only shown when focus is gained from the keyboard, not from
  /// a pointer interaction. This matches `LayrzCheckboxInput`/
  /// `LayrzSwitchInput` exactly, so a mouse drag does not leave a stuck focus
  /// ring.
  bool _focusFromPointer = false;

  /// Whether a drag gesture is currently in progress.
  ///
  /// Tracked as its own [WidgetState]-adjacent flag (rather than folded into
  /// `pressed`) because the live value label (see class doc) is shown while
  /// dragging regardless of whether the pointer is still down over the thumb
  /// specifically — a drag that has moved off the thumb's paint bounds but
  /// stayed within the larger hit-slop region must keep updating the value.
  bool _isDragging = false;

  static const double _trackVisualHeight = 8.0;

  /// The edge length, in logical pixels, of the painted thumb square.
  ///
  /// Raised from an earlier `16.0` to `28.0` so the thumb is comfortably
  /// grabbable on touch devices — a 16px hit target is too small to drag
  /// reliably with a fingertip. This is a shared constant applied identically
  /// across every interaction state (per D15: only colour/border/shadow vary
  /// with state, never size), not a per-state value.
  static const double _thumbSize = 28.0;
  static const double _thumbBorderWidth = 2.0;

  /// The half-height of the thumb, kept for the track/hit-test geometry that
  /// used to read off a circular thumb's radius directly.
  ///
  /// The thumb itself is now a rounded square (see `LayrzSliderPainter`), but
  /// its bounding box is still square, so half of [_thumbSize] is exactly the
  /// inset the track and hit-test math need on each side.
  static const double _thumbHalfSize = _thumbSize / 2;

  /// The bubble's vertical gap above the top of the thumb, and its own
  /// height allowance reserved in the invisible overlay region above the
  /// track — see the class doc's "Live value feedback" section and the
  /// `_buildBubbleOverlay` doc for why this never affects layout height.
  ///
  /// Derived so the bubble's downward tail tip lands 3px above the thumb's
  /// painted top edge (close enough to read as attached, without overlapping
  /// it). Re-worked from the actual stacking in [LayrzSliderTrackArea] after
  /// [_trackVisualHeight] moved from `4.0` to `8.0`:
  /// - The [CustomPaint] (track+thumb) is centred in a
  ///   `SizedBox(height: _hitSlopHeight)` (44) and sized to `paintHeight =
  ///   _trackVisualHeight + _thumbSize` (8 + 28 = 36).
  /// - Centring that 36px paint box inside the 44px `SizedBox` leaves 4px of
  ///   slack above it: `(44 - 36) / 2 = 4`.
  /// - Inside the paint box, `LayrzSliderPainter` draws the track centreline
  ///   at `paintHeight / 2` (18) and the thumb's top edge at
  ///   `trackY - thumbSize / 2 == _trackVisualHeight / 2` (4px) below the
  ///   paint box's own top — this identity holds for any track thickness,
  ///   since `paintHeight / 2 - thumbSize / 2` always reduces to
  ///   `_trackVisualHeight / 2` given `paintHeight = _trackVisualHeight +
  ///   _thumbSize`.
  /// - So the thumb's top edge sits `4 + 4 = 8px` below the `SizedBox`'s top
  ///   — the same origin the bubble's `Positioned(top: -bubbleClearance)` is
  ///   measured from in [LayrzSliderTrackArea]. Note this 8px figure is
  ///   unchanged from the old 4px-track geometry: it algebraically reduces to
  ///   `(_hitSlopHeight - _thumbSize) / 2` (`(44 - 28) / 2 = 8`), which never
  ///   involves the track thickness at all — only the intermediate slack/
  ///   thumb-top-offset split between them changed.
  /// - [LayrzSliderValueBubble] itself renders at a fixed 24px tall (18px
  ///   body + the 6px tail reserved by its own bottom padding), regardless of
  ///   the formatted value's text — unaffected by the track-thickness change,
  ///   since the bubble has no dependency on [_trackVisualHeight] — so its
  ///   bottom edge (the tail's tip) sits at `-bubbleClearance + 24` in the
  ///   same coordinate space.
  /// - Solving `-bubbleClearance + 24 == 8 - 3` (tip 3px above the thumb top)
  ///   gives `bubbleClearance == 19.0` — the same numeric value as before the
  ///   track-thickness change, because the thumb-top-offset it is solved
  ///   against did not move.
  static const double _bubbleClearance = 19.0;

  /// The height of the invisible gesture-detection region.
  ///
  /// Deliberately taller than [_trackVisualHeight] — this is the "real
  /// hit-slop" required by the spec: hit-testing must not equal the drawn
  /// pixels, since a thin painted line that only responds to exact-pixel
  /// hits is unusable on touch. The extra region is invisible (no paint
  /// changes), so this does not conflict with D15, which forbids *visual*
  /// geometry changes on interaction state, not an invisible hit target
  /// being larger than the drawn track to begin with.
  static const double _hitSlopHeight = 44.0;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(LayrzSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The focus node must be swapped in step with the widget's final
    // ownership state: `dispose()` decides what to dispose based on the
    // *current* `widget.focusNode`, so leaving `_focusNode` stale here would
    // let a later dispose() either leak an internally-created node or dispose
    // a node the caller still owns. Matches LayrzCheckboxInput exactly.
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  bool get _isDisabled => widget.disabled || widget.onChanged == null;

  double get _clampedValue => quantizeLayrzSliderValue(
    value: widget.value,
    min: widget.min,
    max: widget.max,
    divisions: widget.divisions,
  );

  /// The size of one keyboard/step increment.
  ///
  /// Equal to one division width when [LayrzSlider.divisions] is set, or 1%
  /// of the total range for a continuous slider — a conventional default that
  /// gives ~100 keyboard steps across the whole range.
  double get _stepSize {
    final range = widget.max - widget.min;
    if (range <= 0) return 0;
    final divisions = widget.divisions;
    if (divisions != null && divisions >= 2) {
      return range / divisions;
    }
    return range / 100;
  }

  void _commit(double rawValue) {
    if (_isDisabled) return;
    final next = quantizeLayrzSliderValue(
      value: rawValue,
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
    );
    if (next != _clampedValue) {
      widget.onChanged!(next);
    }
  }

  void _handleTapDown(TapDownDetails details, double trackWidth) {
    if (_isDisabled) return;
    _focusNode.requestFocus();
    final fraction = layrzSliderValueToFraction(
      value: _positionToValue(details.localPosition.dx, trackWidth),
      min: widget.min,
      max: widget.max,
    );
    _commit(layrzSliderFractionToValue(fraction: fraction, min: widget.min, max: widget.max));
  }

  double _positionToValue(double dx, double trackWidth) {
    final usableWidth = trackWidth - _thumbSize;
    if (usableWidth <= 0) return widget.min;
    final fraction = ((dx - _thumbHalfSize) / usableWidth).clamp(0.0, 1.0);
    return layrzSliderFractionToValue(fraction: fraction, min: widget.min, max: widget.max);
  }

  void _handleDragUpdate(DragUpdateDetails details, double trackWidth) {
    if (_isDisabled) return;
    _commit(_positionToValue(details.localPosition.dx, trackWidth));
  }

  void _increase() => _commit(_clampedValue + _stepSize);

  void _decrease() => _commit(_clampedValue - _stepSize);

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (_isDisabled) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.arrowUp:
        _increase();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowDown:
        _decrease();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        _commit(widget.min);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        _commit(widget.max);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  String _formatValue(double value) {
    final formatter = widget.valueFormatter;
    if (formatter != null) return formatter(value);
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDisabled = _isDisabled;
    final fraction = layrzSliderValueToFraction(value: _clampedValue, min: widget.min, max: widget.max);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          ExcludeSemantics(
            child: Text(
              widget.labelText!,
              style: tokens.typography.label.copyWith(
                color: isDisabled ? tokens.colors.fg4 : tokens.colors.fg2,
              ),
            ),
          ),
          SizedBox(height: tokens.spacing.sp1),
        ],
        if (widget.showValueLabel) ...[
          ExcludeSemantics(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatValue(_clampedValue),
                style: tokens.typography.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDisabled ? tokens.colors.fg4 : tokens.colors.fg1,
                ),
              ),
            ),
          ),
          SizedBox(height: tokens.spacing.sp1),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            return Focus(
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              onKeyEvent: _handleKeyEvent,
              onFocusChange: (hasFocus) {
                setState(() {
                  if (hasFocus) {
                    _states.add(WidgetState.focused);
                  } else {
                    _states.remove(WidgetState.focused);
                    _focusFromPointer = false;
                  }
                });
              },
              child: MouseRegion(
                cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
                onEnter: isDisabled ? null : (_) => setState(() => _states.add(WidgetState.hovered)),
                onExit: isDisabled ? null : (_) => setState(() => _states.remove(WidgetState.hovered)),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: isDisabled ? null : (details) => _handleTapDown(details, trackWidth),
                  onHorizontalDragStart: isDisabled
                      ? null
                      : (_) {
                          _focusNode.requestFocus();
                          setState(() {
                            _focusFromPointer = true;
                            _isDragging = true;
                            _states.add(WidgetState.pressed);
                          });
                        },
                  onHorizontalDragUpdate: isDisabled ? null : (details) => _handleDragUpdate(details, trackWidth),
                  onHorizontalDragEnd: isDisabled
                      ? null
                      : (_) => setState(() {
                          _isDragging = false;
                          _states.remove(WidgetState.pressed);
                        }),
                  onHorizontalDragCancel: isDisabled
                      ? null
                      : () => setState(() {
                          _isDragging = false;
                          _states.remove(WidgetState.pressed);
                        }),
                  child: Semantics(
                    slider: true,
                    enabled: !isDisabled,
                    label: widget.labelText,
                    value: _formatValue(_clampedValue),
                    increasedValue: _formatValue((_clampedValue + _stepSize).clamp(widget.min, widget.max)),
                    decreasedValue: _formatValue((_clampedValue - _stepSize).clamp(widget.min, widget.max)),
                    onIncrease: isDisabled ? null : _increase,
                    onDecrease: isDisabled ? null : _decrease,
                    child: LayrzSliderTrackArea(
                      trackWidth: trackWidth,
                      hitSlopHeight: _hitSlopHeight,
                      paintHeight: _trackVisualHeight + _thumbSize,
                      fraction: fraction,
                      painter: _buildPainter(tokens, isDisabled, fraction),
                      thumbHalfSize: _thumbHalfSize,
                      bubbleClearance: _bubbleClearance,
                      isDragging: _isDragging,
                      showValueLabel: widget.showValueLabel,
                      formattedValue: _formatValue(_clampedValue),
                      isDisabled: isDisabled,
                      tokens: tokens,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        LayrzInputFooterSlot(
          errors: widget.errors,
          hideDetails: widget.hideDetails,
        ),
      ],
    );
  }

  LayrzSliderPainter _buildPainter(LayrzTokens tokens, bool isDisabled, double fraction) {
    /// Derived focus-visible state: border colour shows primary only for
    /// keyboard focus, not pointer, matching `LayrzCheckboxInput`.
    final isFocusVisible = _states.contains(WidgetState.focused) && !_focusFromPointer;

    final colors = resolveLayrzSliderColors(
      tokens: tokens,
      states: _states,
      isDisabled: isDisabled,
      hasErrors: widget.errors.isNotEmpty,
      isDragging: _isDragging,
      isFocusVisible: isFocusVisible,
    );

    final shadowTokens = tokens.shadow;
    final thumbShadows = colors.thumbElevation > 0
        ? shadowTokens.elevation(elevation: colors.thumbElevation, radius: 0).boxShadow ?? const []
        : const <BoxShadow>[];

    return LayrzSliderPainter(
      fraction: fraction,
      trackThickness: _trackVisualHeight,
      thumbSize: _thumbSize,
      // r2 (10px), not r1 (6px): on the old 16px thumb, r1 gave a
      // corner-to-edge ratio of 6/16 = 0.375. Keeping that literal radius on
      // the new 28px thumb would drop the ratio to 6/28 ~= 0.21, reading as
      // nearly square. r2's 10px keeps 10/28 ~= 0.36 -- close to the original
      // roundness character at the new size.
      thumbCornerRadius: tokens.radius.r2,
      thumbBorderWidth: _thumbBorderWidth,
      trackColor: colors.trackColor,
      activeTrackColor: colors.activeTrackColor,
      thumbColor: colors.thumbColor,
      thumbBorderColor: colors.thumbBorderColor,
      thumbShadows: thumbShadows,
    );
  }
}
