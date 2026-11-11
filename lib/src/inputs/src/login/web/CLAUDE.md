# login/web — DOM-backed login fields (web only)

`LayrzLoginWebField` renders a real HTML `<input>` through a platform view so password managers can see it. `LayrzUsernameInput` and `LayrzPasswordInput` use it when `kIsWeb`. The OTP kind also goes through it (`isOtp` branches).

## File layout
`login_web_field_web.dart` is the library. `_dom.dart` and `_theme.dart` are `part` files that extend the same private state class, so they share its private fields (`_inputElement`, `_placeholderElement`, `_selectionStyleElement`, …). The `_stub.dart` file is the native version and throws `UnsupportedError`. There are no VM tests for the web implementation, only `test/inputs/login/web/login_web_field_stub_test.dart`. Web behaviour has to be checked by hand in Chrome and Firefox (`cd example && flutter run -d chrome`).

## The placeholder is a separate `<span>`, not the input's `placeholder`
It is absolutely positioned over the `<input>`. JS hides it only when `input.value.isEmpty` (`applyPlaceholderVisibility`, run on the `input` event).

**Autofill breaks that check.** Autofill preview (hovering a suggestion) and fill-on-load paint text into the input without exposing `input.value` and without firing `input`. The span then stays visible under the autofilled text. The fix is CSS, not JS: `_buildStyleSheet` adds `.<input>:-webkit-autofill ~ .<placeholder>` and `:autofill` rules that set `visibility: hidden !important`.

Rules that keep this working:
- The placeholder must come **after** the `<input>` in `stack` (`~` only matches later siblings). It is `position: absolute`, so the order has no layout effect.
- Keep the two pseudo-class rules **separate**. An unknown pseudo-class in a selector list makes the browser drop the whole rule.
- Put new CSS in `_buildStyleSheet`, never in a one-off `textContent` assignment. `_applyThemeStyles` rewrites the `<style>` contents on every focus and theme change, which would erase anything added elsewhere.
- Hide with `visibility`, not `display`, because the JS path owns the inline `display`.

## Honeypot rules (do not break)
Never give the `<input>` zero size, `display: none`, or `opacity: 0`. Password managers skip such fields as decoys, and zero-size inputs trigger flutter/flutter#105485. The OTP kind hides its text with `color: transparent`, never with opacity.
