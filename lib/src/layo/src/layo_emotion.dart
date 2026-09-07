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
/// Nine emotions are implemented so far: [mrLayo], [question], [sleep],
/// [dead], [love], [angry], [alert], [layo404], and [idea]. The full set this
/// mascot is eventually meant to support — "bolivariano" and a few others —
/// will be added as further [LayoEmotion] values in a later pass; do not
/// treat this enum as exhaustive of the mascot's intended range.
enum LayoEmotion {
  /// The original, default "MrLayo" face: a bow-tie, blue circular eyes, a
  /// blue smile, and a blue antenna-tip dot.
  ///
  /// This is the only emotion wearing the bow-tie, and the only one whose
  /// glyphs blink is paired with a smiling mouth.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=ozXIAg7zp9I
  /// (High — Rawayana)
  mrLayo,

  /// A puzzled face: two blue question-mark glyphs (stem + dot each) stand
  /// in for the eyes, no mouth is drawn, and the antenna-tip dot is grey
  /// rather than blue. Wears no bow-tie.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=6g-qZIktAtc
  /// (Mentiras — Los Amigos Invisibles)
  question,

  /// A sleeping face: two short grey closed-eye lines, a single grey mouth
  /// line, and three ascending grey "zzz" parallelograms drifting off to the
  /// upper right. The antenna-tip dot is grey. Wears no bow-tie.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=aJ5hf5aYiaU
  /// (Tonada de Luna Llena — Simón Díaz)
  sleep,

  /// A "knocked out" face: two grey "X" marks stand in for the eyes and no
  /// mouth is drawn. The antenna-tip dot is grey. Wears no bow-tie.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=-bzWSJG93P8
  /// (The Imperial March / Darth Vader's Theme — Star Wars)
  dead,

  /// A smitten face: two red heart shapes stand in for the eyes, and the
  /// antenna-tip dot is bright red rather than blue. Wears no mouth.
  ///
  /// Idle motion is a "heartbeat": both hearts (and the antenna dot in sync)
  /// pulse through a double-thump scale rhythm rather than a blink.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=AMTAQ-AJS4Y
  /// (Andas en mi cabeza — Chino y Nacho)
  love,

  /// A furious face: two angled crimson brow shapes and a flat crimson mouth
  /// bar. The antenna-tip dot is crimson rather than blue.
  ///
  /// Idle motion is a periodic "furrow + tremble": the brows lower and the
  /// whole face briefly shakes, on a jittered schedule, then relaxes back to
  /// a static rest pose.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=sq6oc066w14
  /// (Es Épico — Canserbero)
  angry,

  /// An alarmed face: two orange "!" glyphs (stem + dot each) stand in for
  /// the eyes. The antenna-tip dot is orange rather than blue.
  ///
  /// Idle motion is a snappy squash-stretch attention pulse on both "!"
  /// glyphs, on a punchy short loop.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=IcrbM1l_BoI
  /// (Wake Me Up — Avicii)
  alert,

  /// An error face: the digits "404" plus an underline bar, all grey. The
  /// antenna-tip dot is grey, matching [sleep] and [dead].
  ///
  /// Idle motion is an occasional glitch/flicker — a brief opacity drop plus
  /// a tiny horizontal jitter — reading as a broken display.
  ///
  /// This emotion was based on these songs:
  /// - https://www.youtube.com/watch?v=dQw4w9WgXcQ (Never Gonna Give You Up — Rick Astley)
  /// - https://www.youtube.com/watch?v=zhHB4dZTChw (404 (New Era) — KiiiKiii)
  layo404,

  /// An inspired face: a yellow lightbulb glyph (outline, base, and
  /// filament bars). The antenna-tip dot is yellow rather than blue.
  ///
  /// Idle motion is a soft continuous glow-pulse on the bulb, with an
  /// occasional stronger "insight" flash the antenna dot syncs to.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=KNexS61fjus
  /// (SMART — LE SSERAFIM)
  idea,
}
