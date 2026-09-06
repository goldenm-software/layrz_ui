/// Image Input namespace, covering strings for `LayrzImageInput`
/// (`lib/src/pickers/src/image/`) — the drop-zone hint, the fallback shown
/// when the current preview fails to decode, the rejection message for a
/// file that exceeds the configured maximum size, and the replace/clear
/// affordance labels shown once an image is loaded.
mixin LayrzUiL10nImageInputMixin {
  /// Localized hint text shown in the empty drop zone, inviting the user to
  /// click or drop a file.
  ///
  /// Default: "Click or drop an image here"
  String get imageInputHint => 'Click or drop an image here';

  /// Localized fallback text shown in place of the preview when the current
  /// value (URL, `data:` URI, or bare base64) fails to decode as an image.
  ///
  /// Default: "Couldn't load image"
  String get imageInputLoadError => "Couldn't load image";

  /// Localized rejection message shown when a picked or dropped file
  /// exceeds the input's configured maximum size.
  ///
  /// [maxSizeLabel] is a caller-formatted, human-readable size (e.g.
  /// "5 MB") describing the configured limit; formatting bytes into that
  /// label is the caller's responsibility, matching how
  /// `LayrzUiL10nHelpersMixin.helperDurationDays` and friends take the
  /// already-computed unit rather than raw byte counts.
  ///
  /// Default: "Image too large. Maximum size is {maxSizeLabel}."
  String imageInputTooLarge(String maxSizeLabel) => 'Image too large. Maximum size is $maxSizeLabel.';

  /// Localized label for the affordance that lets the user replace the
  /// currently loaded image with a new one.
  ///
  /// Default: "Replace"
  String get imageInputReplace => 'Replace';

  /// Localized label for the affordance that clears the currently loaded
  /// image, leaving the field empty.
  ///
  /// Default: "Clear"
  String get imageInputClear => 'Clear';
}
