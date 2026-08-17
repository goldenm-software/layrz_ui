/// Exports the [WidgetState] family from `package:flutter/widgets.dart`.
///
/// This module re-exports Flutter's interactive state types, which are already
/// design-system-agnostic and suitable for use in any widget system. layrz_ui
/// does not wrap or reimplement these types — they are exported verbatim.
///
/// Interactive layrz_ui components (buttons, inputs, chips, and other controls)
/// resolve their hover, press, focus, disabled, and other interactive visuals
/// through these state types. The two main abstractions are:
///
/// - [WidgetStateProperty<T>] — an interface for values that resolve to different
///   output depending on a widget's current set of [WidgetState]s (e.g., a
///   [WidgetStateColor] that returns one color when pressed and another at rest).
/// - [WidgetStatesController] — a mutable [ValueNotifier] that tracks the set of
///   active states and notifies listeners of changes.
///
/// Convenience implementations include [WidgetStateColor], [WidgetStateTextStyle],
/// [WidgetStateMouseCursor], [WidgetStateBorderSide], and [WidgetStateOutlinedBorder],
/// which allow a widget to accept either a concrete value (e.g., a [Color]) or a
/// state-aware property that resolves to that value type.
///
/// Refer to the Flutter documentation for [WidgetState] and [WidgetStateProperty]
/// for detailed usage examples.
library;

export 'package:flutter/widgets.dart'
    show
        WidgetState,
        WidgetStateProperty,
        WidgetStateMapper,
        WidgetStatePropertyAll,
        WidgetStatesController,
        WidgetStatesConstraint,
        WidgetStateMap,
        WidgetPropertyResolver,
        WidgetStateColor,
        WidgetStateTextStyle,
        WidgetStateBorderSide,
        WidgetStateMouseCursor,
        WidgetStateOutlinedBorder;
