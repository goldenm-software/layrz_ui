// Structural constants for [LayrzScaffoldShell] layout and styling.
// These constants define exact pixel values, spacing, and typography
// specifications for the scaffold list panel, detail pane, and interactive elements.

/// The list panel's default width in logical pixels, used by [ListPanel] when
/// its caller does not pass an explicit `width` (see `ListPanel.width`).
///
/// A fold-aware layout (`LayrzScaffoldShell._buildFoldedSideBySideLayout`) still
/// overrides this with the physical seam's mapped leading extent, so this value
/// only governs the panel's ordinary, non-folded default.
const double kLayrzScaffoldListWidth = 400.0;

/// List panel filter field height in logical pixels.
const double kLayrzScaffoldFilterHeight = 30.0;

/// List panel filter field horizontal padding in logical pixels.
const double kLayrzScaffoldFilterHorizontalPadding = 10.0;

/// List panel filter field leading icon size in logical pixels.
const double kLayrzScaffoldFilterIconSize = 12.0;

/// List panel body padding in logical pixels.
const double kLayrzScaffoldBodyPadding = 6.0;

/// List item vertical padding in logical pixels.
const double kLayrzScaffoldListItemVerticalPadding = 9.0;

/// List item border radius in logical pixels.
const double kLayrzScaffoldListItemRadius = 9.0;

/// List item gap between title/subtitle and actions in logical pixels.
const double kLayrzScaffoldListItemGap = 10.0;

/// List item selected row background opacity (7%).
const double kLayrzScaffoldListItemSelectedRowBackgroundOpacity = 0.07;

/// List item hover background opacity (4%).
const double kLayrzScaffoldListItemHoverBackgroundOpacity = 0.04;

/// Detail pane body padding in logical pixels.
const double kLayrzScaffoldDetailBodyPadding = 26.0;

/// Detail pane maximum content width in logical pixels.
const double kLayrzScaffoldDetailMaxWidth = 1080.0;
