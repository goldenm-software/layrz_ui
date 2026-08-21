import 'package:flutter/widgets.dart';

/// Layout design token constants for [LayrzLayout] component.
///
/// This file holds structural and non-tokenized layout dimensions.
/// Spacing, radii, icons, and font sizes are now sourced from LayrzTokens;
/// see the consuming widgets in lib/src/layout/src/ for how these are applied.

// ===== STRUCTURAL GEOMETRY (non-tokenized) =====

/// The width of the navigation rail in expanded presentation, measured in logical pixels.
///
/// The rail occupies a fixed 220-pixel column on the left side when the layout
/// is in expanded presentation (md, lg, xl breakpoints).
const double kLayrzLayoutRailWidth = 220.0;

/// The width of the off-canvas drawer in drawer presentation, in logical pixels.
const double kLayrzLayoutDrawerWidth = 260.0;

/// The height of the top bar in drawer presentation, in logical pixels.
const double kLayrzLayoutTopBarHeight = 56.0;

/// The height of the top bar in drawer presentation on compact viewports, in logical pixels.
///
/// Compact viewports (xs and sm breakpoints, width < 960) use a taller top bar (64 pixels)
/// to improve touch ergonomics and icon visibility compared to the regular 56-pixel height.
const double kLayrzLayoutCompactTopBarHeight = 64.0;

/// The maximum width of the body content in xl breakpoint band.
///
/// In the xl band (viewport width >= 1904px), the body is capped at 1440 logical
/// pixels and centered within the available space. This prevents excessively wide
/// content on ultra-wide displays.
const double kLayrzLayoutBodyMaxWidth = 1440.0;

/// The size of the user avatar (width × height) in the user chrome, in logical pixels.
const double kLayrzLayoutUserAvatarSize = 30.0;

/// The size of the user avatar on compact viewports, in logical pixels.
///
/// Compact viewports (xs and sm breakpoints, width < 960) use a larger avatar (40×40 pixels)
/// to improve touch target size and visibility compared to the regular 30-pixel avatar.
const double kLayrzLayoutCompactUserAvatarSize = 40.0;

/// The width of the logo in the top bar, in logical pixels.
///
/// The logo image is constrained to this fixed width in the top bar presentation.
const double kLayrzLayoutTopBarLogoWidth = 200.0;

/// The height of the logo in the top bar, in logical pixels.
///
/// The logo is constrained to this fixed height and scaled to fit within
/// the box while maintaining aspect ratio. Replaces the previous inline calculation
/// of `kLayrzLayoutTopBarHeight - 16` (56 - 16 = 40).
const double kLayrzLayoutTopBarLogoHeight = 40.0;

/// The size of the top bar icon button (width × height) in the top bar, in logical pixels.
///
/// The drawer trigger button in the top bar is 40×40 pixels, providing a 40px
/// hit target while fitting comfortably within the 56px top bar height.
const double kLayrzLayoutTopBarIconButtonSize = 40.0;

/// The size of the top bar icon button on compact viewports, in logical pixels.
///
/// Compact viewports (xs and sm breakpoints, width < 960) use larger icon buttons (48×48 pixels)
/// to improve touch target size and maintain visual proportion as the top bar grows to 64 pixels.
const double kLayrzLayoutCompactTopBarIconButtonSize = 48.0;

/// The size of every icon rendered inside the layout chrome, in logical pixels.
///
/// All icons in the navigation panel (rail and drawer), top bar, user chrome, and
/// notifications are standardized to this size for visual consistency.
///
/// In compact viewports (xs and sm breakpoints), use [kLayrzLayoutCompactIconSize] instead.
const double kLayrzLayoutIconSize = 18.0;

/// The size of every icon rendered inside the layout chrome on compact viewports, in logical pixels.
///
/// Compact viewports (xs and sm breakpoints, width < 960) use larger icons for improved
/// touch ergonomics and visibility. This size applies to icons in the navigation panel
/// (rail and drawer), top bar, user chrome, and notifications when the viewport is compact.
///
/// Used at 6+ sites: [LayrzLayoutTopBar], [LayrzLayoutTopBarIconButton], [LayrzLayoutRailItem],
/// [LayrzLayoutNavigatorPanel], [LayrzLayoutUserChrome], and [LayrzLayoutNotificationsPanel].
const double kLayrzLayoutCompactIconSize = 20.0;

/// The scale factor applied to the page when the drawer is fully open.
///
/// The page scales to 0.88 (scaled down by 12%) when the drawer is fully open.
/// The anchor is Alignment.centerLeft, so the left edge remains fixed while the
/// page compresses horizontally from the center and right edge.
const double kLayrzLayoutDrawerOpenScale = 0.88;

/// The velocity threshold for fling settle in the drawer drag handler, in pixels per second.
///
/// When a drag is released with velocity > 365 px/s in either direction, the drawer
/// settles toward that direction. Otherwise, it settles based on whether the current
/// position is > 0.5 (halfway open).
const double kLayrzLayoutDrawerDragSettleVelocity = 365.0;

/// The width of the active indicator bar on selected navigation items, in logical pixels.
///
/// The indicator is a small vertical rectangle rendered at the leading edge of
/// selected items, fully rounded.
const double kLayrzLayoutActiveIndicatorWidth = 3.0;

/// The height of the active indicator bar on selected navigation items, in logical pixels.
///
/// The indicator is a small vertical rectangle rendered at the leading edge of
/// selected items, fully rounded.
const double kLayrzLayoutActiveIndicatorHeight = 16.0;

/// The width reserved for the active indicator on selected rail items (leading and trailing reserved space), in logical pixels.
///
/// Both the leading indicator bar and the trailing reserved space total this width,
/// allowing geometry to be identical between selected and unselected items.
const double kLayrzLayoutActiveIndicatorReservedWidth = kLayrzLayoutActiveIndicatorWidth + 6.0;

/// The height of the notifications row in the footer, in logical pixels.
const double kLayrzLayoutNotificationsRowHeight = 32.0;

/// The height of the notifications row in the footer on compact viewports, in logical pixels.
///
/// Compact viewports (xs and sm breakpoints, width < 960) use a taller notifications row (40 pixels)
/// to improve touch target size compared to the regular 32-pixel height.
const double kLayrzLayoutCompactNotificationsRowHeight = 40.0;

// ===== OPACITY (non-tokenized) =====

/// The opacity factor for selected item background highlight, as a fraction from 0 to 1.
///
/// Selected items show the primary colour at 7% opacity as the background.
const double kLayrzLayoutItemSelectedBackgroundOpacity = 0.07;

/// The opacity factor for hovered item background highlight, as a fraction from 0 to 1.
///
/// Hovered items show the primary colour at approximately 4% opacity (used only as
/// visual feedback on hover; no geometry change per D15).
const double kLayrzLayoutItemHoverBackgroundOpacity = 0.04;

// ===== FONT WEIGHTS =====

/// The font weight of a selected rail item label.
///
/// Selected items use [FontWeight.w600] (semi-bold).
const FontWeight kLayrzLayoutItemLabelSelectedFontWeight = FontWeight.w600;

/// The font weight of an unselected rail item label.
///
/// Unselected items use [FontWeight.w400] (normal).
const FontWeight kLayrzLayoutItemLabelUnselectedFontWeight = FontWeight.w400;

/// The font weight of a section caption.
///
/// Section captions use [FontWeight.w700] (bold).
const FontWeight kLayrzLayoutSectionCaptionFontWeight = FontWeight.w700;

/// The font weight of the initials text in the user avatar.
///
/// Initials use [FontWeight.w600] (semi-bold).
const FontWeight kLayrzLayoutUserAvatarInitialsFontWeight = FontWeight.w600;

/// The font weight of the user name in the user chrome.
///
/// User name uses [FontWeight.w600] (semi-bold).
const FontWeight kLayrzLayoutUserNameFontWeight = FontWeight.w600;

/// The font weight of the notifications label text.
///
/// Notifications label uses [FontWeight.w600] (semi-bold).
const FontWeight kLayrzLayoutNotificationsLabelFontWeight = FontWeight.w600;

/// The font weight of the "No results" placeholder text.
///
/// "No results" text uses [FontWeight.w700] (bold).
const FontWeight kLayrzLayoutNoResultsFontWeight = FontWeight.w700;

// ===== FLAGGED FOR REVIEW =====

/// The bottom margin of a rail item row, in logical pixels.
///
/// FLAGGED: This is a 1px hairline gap between items. The nearest spacing token level
/// is sp1 (4.0), which would quadruple it. Consider updating the design or keeping this
/// as a special case.
const double kLayrzLayoutItemMarginBottom = 1.0;

/// The width of the edge drag zone when the drawer is closed, in logical pixels.
///
/// When the drawer is closed, a 20-pixel strip along the left edge is tappable
/// to open the drawer. When open, the entire page area is draggable to close.
///
/// FLAGGED: This is a gesture hit area dimension, not a spacing token. It may not need
/// token-sourcing; review the gesture handler for alternative approaches.
const double kLayrzLayoutDrawerEdgeDragWidth = 20.0;

// ===== TOKEN-DERIVED DIMENSIONS =====
//
// The following dimensions are now sourced from LayrzTokens in their consuming widgets:
//
// Spacing (sourced from tokens.spacing):
//   - Rail padding vertical        (14 → sp3 / 16)
//   - Rail padding horizontal      (10 → sp2 / 8)
//   - Logo bottom padding          (8 → sp2)
//   - Item padding vertical        (8 → sp2)
//   - Item padding horizontal      (9 → sp2)
//   - Item gap                     (9 → sp2)
//   - Section caption padding top  (16 → sp3)
//   - Section caption padding left (9 → sp2)
//   - Section caption padding bottom (6 → sp2)
//   - Footer padding top           (10 → sp2)
//   - Footer gap                   (6 → sp2)
//   - User chrome padding vertical (6 → sp2)
//   - User chrome padding horizontal (8 → sp2)
//   - User chrome padding bottom   (8 → sp2)
//   - Top bar padding horizontal   (12 → sp3)
//   - Top bar gap                  (12 → sp3)
//   - Navigator label band padding vertical   (8 → sp2)
//   - Navigator label band padding horizontal (12 → sp3)
//   - Navigator label margin bottom (8 → sp2)
//   - Search to items gap          (8 → sp2)
//
// Radii (sourced from tokens.radius):
//   - Item radius (9 → r2 / 8)
//   - User chrome radius (9 → r2 / 8)
//
// Font sizes (sourced from tokens.typography):
//   - Item label font size (12.5 → label.fontSize / 14)
//   - Item count font size (10 → label.fontSize / 14)
//   - Section caption font size (9.5 → label.fontSize / 14)
//   - User avatar initials font size (10.5 → label.fontSize / 14)
//   - User name font size (12 → label.fontSize / 14)
//   - Notifications label font size (12 → label.fontSize / 14)
//   - Notifications count font size (10 → label.fontSize / 14)
//
// Icon sizes (derived from typography):
//   - Item icon size (15 → label.fontSize)
//   - User chrome chevron size (13 → label.fontSize)
//   - Notifications bell icon size (20 → label.fontSize + sp1)
//
// Letter spacing (computed from label font size):
//   - Section caption letter spacing (0.11 × 14 = 1.54)
