import 'package:flutter/widgets.dart';

/// Layout design token constants for [LayrzLayout] component.
///
/// All numeric design values used by [LayrzLayout] are defined here to centralize
/// styling, reduce duplication, and make adjustments to spacing, sizing, or
/// dimensions easy. These constants match the detailed specification in the
/// Notion row DESIGN-61.

/// The width of the navigation rail in expanded presentation, measured in logical pixels.
///
/// The rail occupies a fixed 178-pixel column on the left side when the layout
/// is in expanded presentation (md, lg, xl breakpoints).
const double kLayrzLayoutRailWidth = 178.0;

/// The vertical padding inside the rail, in logical pixels.
const double kLayrzLayoutRailPaddingVertical = 14.0;

/// The horizontal padding inside the rail, in logical pixels.
const double kLayrzLayoutRailPaddingHorizontal = 10.0;

/// The bottom padding of the logo block, in logical pixels.
const double kLayrzLayoutLogoBottomPadding = 8.0;

/// The vertical padding of a rail item row, in logical pixels.
const double kLayrzLayoutItemPaddingVertical = 8.0;

/// The horizontal padding of a rail item row, in logical pixels.
const double kLayrzLayoutItemPaddingHorizontal = 9.0;

/// The border radius of a rail item row, in logical pixels.
const double kLayrzLayoutItemRadius = 9.0;

/// The gap between icon and label in a rail item row, in logical pixels.
const double kLayrzLayoutItemGap = 9.0;

/// The size of the icon in a rail item row, in logical pixels.
const double kLayrzLayoutItemIconSize = 15.0;

/// The font size of the label text in a rail item row, in logical pixels.
const double kLayrzLayoutItemLabelFontSize = 12.5;

/// The font weight of a selected rail item label.
///
/// Selected items use [FontWeight.w600] (semi-bold).
const FontWeight kLayrzLayoutItemLabelSelectedFontWeight = FontWeight.w600;

/// The font weight of an unselected rail item label.
///
/// Unselected items use [FontWeight.w400] (normal).
const FontWeight kLayrzLayoutItemLabelUnselectedFontWeight = FontWeight.w400;

/// The font size of the trailing count badge in a rail item row, in logical pixels.
const double kLayrzLayoutItemCountFontSize = 10.0;

/// The bottom margin of a rail item row, in logical pixels.
const double kLayrzLayoutItemMarginBottom = 1.0;

/// The opacity factor for selected item background highlight, as a fraction from 0 to 1.
///
/// Selected items show the primary colour at 7% opacity as the background.
const double kLayrzLayoutItemSelectedBackgroundOpacity = 0.07;

/// The opacity factor for hovered item background highlight, as a fraction from 0 to 1.
///
/// Hovered items show the primary colour at approximately 4% opacity (used only as
/// visual feedback on hover; no geometry change per D15).
const double kLayrzLayoutItemHoverBackgroundOpacity = 0.04;

/// The top padding of a section caption (rail label) row, in logical pixels.
const double kLayrzLayoutSectionCaptionPaddingTop = 16.0;

/// The left padding of a section caption row, in logical pixels.
const double kLayrzLayoutSectionCaptionPaddingLeft = 9.0;

/// The bottom padding of a section caption row, in logical pixels.
const double kLayrzLayoutSectionCaptionPaddingBottom = 6.0;

/// The font size of a section caption, in logical pixels.
const double kLayrzLayoutSectionCaptionFontSize = 9.5;

/// The font weight of a section caption.
///
/// Section captions use [FontWeight.w700] (bold).
const FontWeight kLayrzLayoutSectionCaptionFontWeight = FontWeight.w700;

/// The letter spacing of a section caption, in logical pixels.
const double kLayrzLayoutSectionCaptionLetterSpacing = 0.11 * 9.5;

/// The vertical padding of the rail footer, in logical pixels.
const double kLayrzLayoutFooterPaddingTop = 10.0;

/// The gap between footer elements (user chrome and notifications), in logical pixels.
const double kLayrzLayoutFooterGap = 6.0;

/// The vertical padding of the user chrome block, in logical pixels.
const double kLayrzLayoutUserChromePaddingVertical = 6.0;

/// The horizontal padding of the user chrome block, in logical pixels.
const double kLayrzLayoutUserChromePaddingHorizontal = 8.0;

/// The border radius of the user chrome block, in logical pixels.
const double kLayrzLayoutUserChromeRadius = 9.0;

/// The bottom padding of the user chrome block, in logical pixels.
///
/// Provides spacing between the user chrome and the rail/drawer bottom edge,
/// preventing visual collision with the container edge.
const double kLayrzLayoutUserChromePaddingBottom = 8.0;

/// The size of the user avatar (width × height) in the user chrome, in logical pixels.
const double kLayrzLayoutUserAvatarSize = 28.0;

/// The font size of the initials text in the user avatar, in logical pixels.
const double kLayrzLayoutUserAvatarInitialsFontSize = 10.5;

/// The font weight of the initials text in the user avatar.
///
/// Initials use [FontWeight.w600] (semi-bold).
const FontWeight kLayrzLayoutUserAvatarInitialsFontWeight = FontWeight.w600;

/// The font size of the user name in the user chrome, in logical pixels.
const double kLayrzLayoutUserNameFontSize = 12.0;

/// The font weight of the user name in the user chrome.
///
/// User name uses [FontWeight.w600] (semi-bold).
const FontWeight kLayrzLayoutUserNameFontWeight = FontWeight.w600;

/// The size of the trailing chevron icon in the user chrome, in logical pixels.
const double kLayrzLayoutUserChromeChevronSize = 13.0;

/// The height of the top bar in drawer presentation, in logical pixels.
const double kLayrzLayoutTopBarHeight = 56.0;

/// The horizontal padding of the top bar, in logical pixels.
const double kLayrzLayoutTopBarPaddingHorizontal = 12.0;

/// The gap between elements in the top bar, in logical pixels.
const double kLayrzLayoutTopBarGap = 12.0;

/// The size of the drawer trigger icon in the top bar, in logical pixels.
const double kLayrzLayoutDrawerTriggerIconSize = 24.0;

/// The size of the notifications bell icon in the top bar, in logical pixels.
const double kLayrzLayoutNotificationsBellIconSize = 20.0;

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

/// The width of the off-canvas drawer in drawer presentation, in logical pixels.
const double kLayrzLayoutDrawerWidth = 260.0;

/// The width of the edge drag zone when the drawer is closed, in logical pixels.
///
/// When the drawer is closed, a 20-pixel strip along the left edge is tappable
/// to open the drawer. When open, the entire page area is draggable to close.
const double kLayrzLayoutDrawerEdgeDragWidth = 20.0;

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

/// The maximum width of the body content in xl breakpoint band.
///
/// In the xl band (viewport width >= 1904px), the body is capped at 1440 logical
/// pixels and centered within the available space. This prevents excessively wide
/// content on ultra-wide displays.
const double kLayrzLayoutBodyMaxWidth = 1440.0;

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

/// The height of the notifications row in the footer, in logical pixels.
const double kLayrzLayoutNotificationsRowHeight = 32.0;

/// The font size of the notifications label text, in logical pixels.
const double kLayrzLayoutNotificationsLabelFontSize = 12.0;

/// The font weight of the notifications label text.
///
/// Notifications label uses [FontWeight.w600] (semi-bold).
const FontWeight kLayrzLayoutNotificationsLabelFontWeight = FontWeight.w600;

/// The font size of the notifications count badge, in logical pixels.
const double kLayrzLayoutNotificationsCountFontSize = 10.0;

/// The gap between the search field and the first navigation item, in logical pixels.
///
/// Tight spacing after search to maintain compact layout rhythm.
const double kLayrzLayoutSearchToItemsGap = 8.0;

/// The width reserved for the active indicator on selected rail items (leading and trailing reserved space), in logical pixels.
///
/// Both the leading indicator bar and the trailing reserved space total this width,
/// allowing geometry to be identical between selected and unselected items.
const double kLayrzLayoutActiveIndicatorReservedWidth = kLayrzLayoutActiveIndicatorWidth + 6.0;

/// The vertical padding (top and bottom) of a navigator label band, in logical pixels.
///
/// The band spans the full width of the sidebar and uses this padding to establish
/// visual weight as a section divider.
const double kLayrzLayoutNavigatorLabelBandPaddingVertical = 8.0;

/// The horizontal padding of a navigator label band, in logical pixels.
///
/// The band spans the full width of the sidebar, so this padding determines the
/// distance between text and the band edges.
const double kLayrzLayoutNavigatorLabelBandPaddingHorizontal = 12.0;

/// The bottom margin (breathing room) below a navigator label band, in logical pixels.
///
/// Applied outside the band so the band itself maintains its fixed height while
/// providing visual spacing before the items beneath it. Margin (not padding)
/// ensures the grey background ends at the band's edge while the gap follows.
const double kLayrzLayoutNavigatorLabelMarginBottom = 8.0;
