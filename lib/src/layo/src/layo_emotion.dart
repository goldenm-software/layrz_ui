/// The set of facial expressions [Layo] (the "MrLayo" brand mascot) can
/// render.
///
/// Every value shares the same base artwork — body, face shadow, screen,
/// antenna stalk, ears, and head shell, all drawn identically regardless of
/// [LayoEmotion] — and differs only in the antenna-tip dot color and the
/// glyph(s) drawn on the screen (and, for [mrLayo] alone, the bow-tie). See
/// `LayoPainter` for how each value is dispatched to its own glyph-paint
/// method.
///
/// Only four emotions are implemented so far: [mrLayo], [question], [sleep],
/// and [dead]. The full set this mascot is eventually meant to support —
/// angry, love, idea, warning, "bolivariano", a 404/error variant, and a
/// neutral "standard" face — will be added as further [LayoEmotion] values in
/// a later pass; do not treat this enum as exhaustive of the mascot's
/// intended range.
enum LayoEmotion {
  /// The original, default "MrLayo" face: a bow-tie, blue circular eyes, a
  /// blue smile, and a blue antenna-tip dot.
  ///
  /// This is the only emotion wearing the bow-tie, and the only one whose
  /// glyphs blink is paired with a smiling mouth.
  mrLayo,

  /// A puzzled face: two blue question-mark glyphs (stem + dot each) stand
  /// in for the eyes, no mouth is drawn, and the antenna-tip dot is grey
  /// rather than blue. Wears no bow-tie.
  question,

  /// A sleeping face: two short grey closed-eye lines, a single grey mouth
  /// line, and three ascending grey "zzz" parallelograms drifting off to the
  /// upper right. The antenna-tip dot is grey. Wears no bow-tie.
  sleep,

  /// A "knocked out" face: two grey "X" marks stand in for the eyes and no
  /// mouth is drawn. The antenna-tip dot is grey. Wears no bow-tie.
  dead,
}
