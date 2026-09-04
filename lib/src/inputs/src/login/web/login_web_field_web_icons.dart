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

/// Shield-with-account outline path data, approximating
/// `MdiIcons.shieldAccountOutline`, used as the username field's prefix icon.
///
/// Matches the brief's requested icon for the username field (a shield rather than a
/// plain account glyph, signalling "this identifies a protected credential") rather
/// than `layrz_session`'s plain person-in-circle icon — see the implementation plan's
/// icon note.
const String kShieldAccountIconPath =
    'M12 2 4 5v6c0 5.55 3.84 10.74 8 12 4.16-1.26 8-6.45 8-12V5l-8-3zm0 2.18 6 2.25V11c0 '
    '4.52-2.98 8.69-6 9.93C8.98 19.69 6 15.52 6 11V6.43l6-2.25zM9.5 12.5a2.5 2.5 0 1 1 '
    '4 2v-2h-4v2zm2.5-6a4 4 0 0 1 4 4c0 .35-.04.69-.12 1.02A4.49 4.49 0 0 0 12 10.5a4.49 '
    '4.49 0 0 0-3.88 1.02A3.97 3.97 0 0 1 8 10.5a4 4 0 0 1 4-4z';

/// Shield-with-keyhole outline path data, approximating
/// `MdiIcons.shieldKeyOutline`, used as the password field's prefix icon.
const String kShieldKeyIconPath =
    'M12 2 4 5v6c0 5.55 3.84 10.74 8 12 4.16-1.26 8-6.45 8-12V5l-8-3zm0 2.18 6 2.25V11c0 '
    '4.52-2.98 8.69-6 9.93C8.98 19.69 6 15.52 6 11V6.43l6-2.25zM12 8a2.5 2.5 0 0 0-1 '
    '4.79V15h2v-1h1v-2h-1v-.21A2.5 2.5 0 0 0 12 8z';

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
