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

/// The size of the logo tile (width × height) in the rail header, in logical pixels.
const double kLayrzLayoutLogoTileSize = 26.0;

/// The border radius of the logo tile, in logical pixels.
const double kLayrzLayoutLogoTileRadius = 8.0;

/// The gap between the logo tile and the label in the rail header, in logical pixels.
const double kLayrzLayoutLogoGap = 9.0;

/// The bottom padding of the logo block, in logical pixels.
const double kLayrzLayoutLogoBottomPadding = 14.0;

/// The left padding of the logo block, in logical pixels.
const double kLayrzLayoutLogoLeftPadding = 6.0;

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

/// The size of the user avatar in the top bar, in logical pixels.
const double kLayrzLayoutTopBarUserAvatarSize = 28.0;

/// The width of the off-canvas drawer in drawer presentation, in logical pixels.
const double kLayrzLayoutDrawerWidth = 260.0;

/// The opacity of the scrim behind the off-canvas drawer, as a fraction from 0 to 1.
///
/// The scrim uses overlay colour at this opacity to darken the background.
const double kLayrzLayoutDrawerScrimOpacity = 1.0;

/// The maximum width of the body content in xl breakpoint band.
///
/// In the xl band (viewport width >= 1904px), the body is capped at 1440 logical
/// pixels and centered within the available space. This prevents excessively wide
/// content on ultra-wide displays.
const double kLayrzLayoutBodyMaxWidth = 1440.0;
