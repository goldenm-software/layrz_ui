import 'button.dart';

/// Painted outer height, in logical pixels, of a standard text-field input on regular viewports.
///
/// Matches [kLayrzButtonHeight] so inputs and buttons align when shared in a row (find bar,
/// table toolbar, forms). The height includes the 1.5px border.
const double kLayrzInputHeight = kLayrzButtonHeight;

/// Painted outer height of a standard text-field input on compact (viewport < 960px) layouts.
///
/// Matches [kLayrzButtonCompactHeight]. Dense inputs (used inside picker panels) keep their own
/// smaller height and are not affected by this constant.
const double kLayrzInputCompactHeight = kLayrzButtonCompactHeight;
