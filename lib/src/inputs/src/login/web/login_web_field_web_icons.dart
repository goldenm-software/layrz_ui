/// Icon SVG path data and inline `<svg>` construction for
/// [LayrzLoginWebField]'s prefix/suffix icons.
///
/// This has no dependency on the field state (every icon here is either a plain
/// constant or a pure function of its arguments), so it lives in its own standalone
/// library — imported normally by `login_web_field_web.dart` — rather than as a `part`
/// of it, matching this package's usual "extract standalone helpers into their own
/// file" convention.
///
/// Ported from `layrz_session`'s `native_autofill_field_web_icons.dart` — this file
/// already had no Material dependency in the source (`package:web` only), so the port
/// is a straight copy with layrz_ui-facing symbol names and doc-comment updates only.
library;

import 'package:web/web.dart' as web;

/// Shield-with-account outline path data, matching `MdiIcons.shieldAccountOutline`
/// exactly, used as the username field's prefix icon.
///
/// The exact `d` string, verified byte-for-byte against `assets/shield-account-outline
/// .svg` (the reference SVG committed alongside this file) and against the native
/// `MdiIcons.shieldAccountOutline` glyph the username field's native path
/// (`username_input.dart`) renders — this widget's earlier hand-approximated path
/// data has been replaced so the web prefix icon is pixel-identical to the native one,
/// not merely similar.
const String kShieldAccountIconPath =
    'M12,1L3,5V11C3,16.55 6.84,21.74 12,23C17.16,21.74 21,16.55 21,11V5L12,1M12,3.18L19,6.3V11.22C19,12.92 18.5,'
    '14.65 17.65,16.17C16,14.94 13.26,14.5 12,14.5C10.74,14.5 8,14.94 6.35,16.17C5.5,14.65 5,12.92 5,11.22V6.3L12,'
    '3.18M12,6A3.5,3.5 0 0,0 8.5,9.5A3.5,3.5 0 0,0 12,13A3.5,3.5 0 0,0 15.5,9.5A3.5,3.5 0 0,0 12,6M12,8A1.5,1.5 0 '
    '0,1 13.5,9.5A1.5,1.5 0 0,1 12,11A1.5,1.5 0 0,1 10.5,9.5A1.5,1.5 0 0,1 12,8M12,16.5C13.57,16.5 15.64,17.11 '
    '16.53,17.84C15.29,19.38 13.7,20.55 12,21C10.3,20.55 8.71,19.38 7.47,17.84C8.37,17.11 10.43,16.5 12,16.5Z';

/// Shield-with-keyhole outline path data, matching `MdiIcons.shieldKeyOutline` exactly,
/// used as the password field's prefix icon.
///
/// The exact `d` string, verified byte-for-byte against `assets/shield-key-outline.svg`
/// (the reference SVG committed alongside this file) and against the native
/// `MdiIcons.shieldKeyOutline` glyph the password field's native path
/// (`password_input.dart`) renders — see [kShieldAccountIconPath]'s doc comment for
/// why this replaced the earlier hand-approximated path data.
const String kShieldKeyIconPath =
    'M21,11C21,16.55 17.16,21.74 12,23C6.84,21.74 3,16.55 3,11V5L12,1L21,5V11M12,21C15.75,20 19,15.54 19,11.22V6.3L'
    '12,3.18L5,6.3V11.22C5,15.54 8.25,20 12,21M12,6A3,3 0 0,1 15,9C15,10.31 14.17,11.42 13,11.83V14H15V16H13V18H11V'
    '11.83C9.83,11.42 9,10.31 9,9A3,3 0 0,1 12,6M12,8A1,1 0 0,0 11,9A1,1 0 0,0 12,10A1,1 0 0,0 13,9A1,1 0 0,0 12,8Z';

/// Open-eye outline path data for the "show password" suffix icon state.
const String kEyeIconPath =
    'M12 5c-5 0-9.27 3.11-11 7 1.73 3.89 6 7 11 7s9.27-3.11 11-7c-1.73-3.89-6-7-11-7zm0 '
    '11.5A4.5 4.5 0 1 1 12 7.5a4.5 4.5 0 0 1 0 9zm0-7.2a2.7 2.7 0 1 0 0 5.4 2.7 2.7 0 0 0 0-5.4z';

/// Eye-with-slash outline path data for the "hide password" suffix icon state.
const String kEyeOffIconPath =
    'M3.28 2.22 2.22 3.28l3.2 3.2C3.6 7.79 2.06 9.68 1 12c1.73 3.89 6 7 11 7 1.77 0 '
    '3.44-.39 4.93-1.09l3.79 3.79 1.06-1.06L3.28 2.22zM12 16.5c-.62 0-1.2-.14-1.72-.38l1.29-1.29c.14.03.28.05.43.05a2.7 '
    '2.7 0 0 0 2.7-2.7c0-.15-.02-.29-.05-.43l1.29-1.29c.24.52.38 1.1.38 1.72a4.5 4.5 0 0 1-4.5 4.5zm0-11.7c1.77 0 '
    '3.44.39 4.93 1.09l-1.6 1.6A4.5 4.5 0 0 0 9.6 13.2l-2.02 2.02C6.03 14.06 4.62 12.66 3.7 12 5.43 9.36 8.5 6.5 12 '
    '6.5c0-.62.62-1.2 0-1.7z';

/// Builds an inline `<svg>` element rendering [pathData] as an outline icon of
/// [colorHex], sized to fill its container (18x18 via CSS).
///
/// 18px matches [LayrzInputChrome]'s own icon size — see `_InputComfortableSpec
/// .iconSize` in `input_chrome.dart` (`14.0 + tokens.spacing.sp1`, which resolves to
/// 18px with the house `sp1` default of 4px, matching the chrome's icon-slot sizing at
/// its default token values).
///
/// [pathData] is one of the `k*IconPath` constants above.
///
/// [colorHex] is a CSS color string (e.g. `'#9E9E9E'`), resolved by the caller from
/// [LayrzTokens] — this function has no theme knowledge of its own.
///
/// Returns both the `<svg>` element and its inner `<path>` — callers that need to
/// recolor the icon later (a theme change, or the password eye toggle swapping icons)
/// store the `<path>` and update its `fill` attribute directly, rather than rebuilding
/// the whole `<svg>`.
({web.SVGSVGElement svg, web.SVGPathElement path}) buildLoginIconSvg(String pathData, String colorHex) {
  final svg = web.document.createElementNS('http://www.w3.org/2000/svg', 'svg') as web.SVGSVGElement;
  svg.setAttribute('viewBox', '0 0 24 24');
  svg.style.width = '18px';
  svg.style.height = '18px';
  svg.style.display = 'block';
  svg.style.setProperty('flex-shrink', '0');

  final path = web.document.createElementNS('http://www.w3.org/2000/svg', 'path') as web.SVGPathElement;
  path.setAttribute('d', pathData);
  path.setAttribute('fill', colorHex);
  svg.appendChild(path);
  return (svg: svg, path: path);
}
