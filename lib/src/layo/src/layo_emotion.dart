/// The set of facial expressions [Layo] (the "MrLayo" brand mascot) can
/// render.
///
/// Every value shares the same base artwork — body, face shadow, screen,
/// ears, and head shell — and differs in the antenna-tip dot color and the
/// glyph(s) drawn on the screen, plus the bow-tie (worn by every emotion
/// except [comandante]). [comandante] is also the sole emotion with no
/// antenna at all, and the only one with an **overlay** glyph layer (its
/// beret) and a chest glyph layer (its ribbon rack) on top of the body,
/// rather than only a screen glyph. See `LayoPainter` for how each value is
/// dispatched to its own glyph-paint methods.
///
/// Twenty-two emotions are implemented so far: [mrLayo], [question], [sleep],
/// [dead], [love], [angry], [alert], [layo404], [idea], [comandante],
/// [money], [thinking], [listening], [sad], [success], [excited],
/// [searching], [working], [wink], [mindBlown], [smug], and [cool]. The full
/// set this mascot is eventually meant to support — a Santa hat, a party hat,
/// and a few others — will be added as further [LayoEmotion] values in a
/// later pass; do not treat this enum as exhaustive of the mascot's intended
/// range.
///
/// [comandante] is also the first emotion to wear an **overlay**: a glyph
/// layer drawn after the shared head shell, on top of the face, rather than
/// inside the dark screen window like every other emotion's glyphs. See
/// `LayoPainter`'s "Overlays" section for the reusable mechanism this
/// introduced. [cool] is the second emotion to use this same overlay
/// mechanism, for its sunglasses.
enum LayoEmotion {
  /// The original, default "MrLayo" face: a bow-tie, blue circular eyes, a
  /// blue smile, and a blue antenna-tip dot.
  ///
  /// This is the only emotion whose eye-blink is paired with a smiling
  /// mouth. Every [LayoEmotion] wears the bow-tie except [comandante].
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

  /// "Comandante" — the standard blue face (two open circular eyes, a blue
  /// smile) plus a tall, full red beret worn as an **overlay**, tilted over
  /// the top-left of the head shell and capping the head's full width. This
  /// is the first emotion to use the overlay mechanism (see `LayoPainter`'s
  /// "Overlays" section) rather than a screen glyph, since the beret sits on
  /// top of the head itself, not inside the dark screen window.
  ///
  /// [comandante] has **no antenna at all** — no stalk, no tip, and
  /// therefore no antenna pulse either — the only [LayoEmotion] this is true
  /// for; the beret's own crown sits exactly where the antenna would, and
  /// the maintainer asked for it omitted entirely rather than drawn around
  /// or through the beret (see `LayoPainter._hasAntenna`).
  ///
  /// It also wears a chest ribbon rack — two stacked rows of small,
  /// multi-color-striped service-ribbon bars painted directly on the body,
  /// well below the head — as this emotion's replacement for the bow-tie
  /// every other [LayoEmotion] wears.
  ///
  /// At rest both eyes are open, exactly like [mrLayo]. Idle motion is a
  /// periodic, brief wink of the **right eye alone** — a Chávez-style
  /// signature wink — on the same kind of jittered per-instance schedule as
  /// [mrLayo]'s own two-eye blink, but closing only one eye and leaving the
  /// left one open throughout (`LayoPainter.winkT`, distinct from [mrLayo]'s
  /// own `blinkT`).
  ///
  /// Unlike every other [LayoEmotion], [comandante] wears **no bow-tie** —
  /// "the Comandante does not stand on ceremony" — see [_wearsTie] on
  /// `LayoPainter`.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=_pbIkeZR24s
  /// (Chávez Corazón del Pueblo)
  comandante,

  /// A "big win" face: two green `$` glyphs stand in for the eyes. The
  /// antenna-tip dot is green rather than blue.
  ///
  /// Idle motion has two parts: the `$` eyes themselves play a subtle
  /// scale-pulse/shimmer, and — separately — a looping "rain of bills"
  /// plays as a **background layer**, behind the whole mascot figure (body,
  /// head, everything): small green banknote rectangles (each carrying a
  /// tiny `$` mark) fall and loop, clipped to this painter's own paint
  /// bounds. See `LayoPainter`'s "Background layers" section for the
  /// reusable mechanism this introduced, and `paintMoneyBackdrop` for the
  /// bill-rain glyph itself.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=dNCWe_6HAM8
  /// (MONEY — LISA)
  money,

  /// A pensive face: a white thought-bubble cloud (with its small trailing
  /// white connector circles) drawn inside the screen, standing in for this
  /// emotion's whole face. The antenna-tip dot — and the bow-tie every
  /// emotion wears — stay blue, matching [mrLayo]'s own accent, decoupled
  /// from the cloud's own white fill (a white dot would vanish against the
  /// light head shell, but white reads cleanly for the cloud against the
  /// dark screen behind it).
  ///
  /// Idle motion is on the **connector circles** alone — the cloud itself
  /// stays static — which pulse/appear in ascending sequence (smallest,
  /// closest to the head, first) on a loop, reading as a thought
  /// continuously forming.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=KMq5p5t-Yi0
  /// (Tick-Tack — ILLIT)
  thinking,

  /// An "actively listening" face: a small vertical-bar audio equalizer
  /// glyph inside the screen, standing in for this emotion's whole face.
  /// The antenna-tip dot is teal rather than blue.
  ///
  /// Idle motion is a classic EQ bounce: each bar's height oscillates
  /// independently and continuously, out of phase with its neighbors, like
  /// a live audio level meter.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=vo2p352SOaM
  /// (Super Yuppers! — WJSN Chocome)
  listening,

  /// A downcast face: two plain open eyes (the same circular shape and
  /// vertical position as [mrLayo]'s own eyes, but spaced closer together
  /// since this emotion draws no mouth to visually anchor [mrLayo]'s own
  /// wider gap) and no mouth at all — this emotion's sadness reads entirely
  /// through the tear rather than through a downturned eye or frown shape.
  /// The antenna-tip dot is grey, matching [sleep], [dead], and [layo404].
  ///
  /// Idle motion is a single tear that periodically wells up in one eye and
  /// slides down the face, on the same kind of jittered per-instance
  /// schedule as [mrLayo]'s own blink — a subtle, one-shot drip rather than
  /// a continuous stream.
  ///
  /// This emotion was based on these songs:
  /// - https://www.youtube.com/watch?v=ADKDX-H8SJg (FEARNOT (Between You, Me and the Lamppost) — LE SSERAFIM)
  /// - https://www.youtube.com/watch?v=aDCcLQto5BM (Me Rehúso — Danny Ocean)
  sad,

  /// A "done!" face: a bold green double check mark (✓✓, a messaging-style
  /// "read receipt" — two overlapping strokes, the second offset to the
  /// right) inside the screen, standing in for this emotion's whole face.
  /// The antenna-tip dot is green, matching [money].
  ///
  /// Idle motion is both checks drawing themselves on together (each stroke
  /// animates in from its own short leg to its own long one, in lockstep)
  /// with a quick pop/bounce settle at the end, both on appearance and
  /// periodically thereafter, on the same kind of jittered per-instance
  /// schedule as [mrLayo]'s own blink.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=6ZUIwj3FgUY
  /// (I AM — IVE)
  success,

  /// An overjoyed face: two star-shaped eyes alone, spaced closer together
  /// than [mrLayo]'s own eyes since this emotion draws no mouth to visually
  /// anchor that wider gap, and no mouth at all. The antenna-tip dot is
  /// yellow, matching [idea].
  ///
  /// Idle motion is a continuous twinkle/sparkle on both star eyes
  /// (scale-pulse plus a slight rotation, offset out of phase with each
  /// other) paired with a small energetic bounce of the whole glyph group,
  /// looping.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=pyf8cbqyfPs
  /// (ANTIFRAGILE — LE SSERAFIM)
  excited,

  /// An "actively looking" face: a single blue magnifying-glass glyph (a
  /// ringed lens plus a short angled handle) stands in for this emotion's
  /// whole face, no mouth drawn. The antenna-tip dot stays blue, matching
  /// [mrLayo].
  ///
  /// Idle motion is a continuous side-to-side (and slight up-down) scan of
  /// the magnifier across the screen, looping, reading as actively searching
  /// rather than merely displayed.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=jOTfBlKSQYY
  /// (ETA — NewJeans)
  searching,

  /// A "hard at it" face: two amber gears (a larger one and a smaller one
  /// meshed beside it) stand in for this emotion's whole face, no mouth
  /// drawn. The antenna-tip dot is amber rather than blue — a distinctly
  /// different shade from [alert]'s own orange.
  ///
  /// Idle motion is a continuous rotation of both gears, looping, with the
  /// smaller gear counter-rotating against the larger one like real meshed
  /// teeth.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=VGnOpZhsPk4
  /// (WORK — ATEEZ)
  working,

  /// A one-eyed-wink face: the same blue eyes and blue smile as [mrLayo], but
  /// the **right** eye periodically winks shut while the left stays open —
  /// unlike [comandante] (whose wink is paired with a beret overlay and no
  /// tie at all), this emotion wears the ordinary tie and antenna like
  /// [mrLayo]. Since it has a mouth, it keeps [mrLayo]'s own canonical eye
  /// spacing. The antenna-tip dot stays blue.
  ///
  /// Idle motion is a periodic, brief wink of the right eye alone, on a
  /// jittered per-instance schedule identical in shape to [mrLayo]'s own
  /// two-eye blink and [comandante]'s own wink, while the left eye and the
  /// smile stay static throughout.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=JYRO4Abh6NI
  /// (La Vecina — Los Amigos Invisibles)
  wink,

  /// A "whoa" face: two magenta spiral eyes plus an open "O" mouth, standing
  /// in for shock/astonishment. Because it has a mouth, it keeps [mrLayo]'s
  /// own canonical eye spacing. The antenna-tip dot is magenta rather than
  /// blue.
  ///
  /// Idle motion is a continuous spin of both spirals, plus a periodic
  /// jittered "pop" burst (a quick scale/shake) on the whole glyph group,
  /// reading as a recurring mind-blown jolt.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=3GWscde8rM8
  /// (O.O — NMIXX)
  mindBlown,

  /// A self-satisfied face: two blue half-lidded eyes (a lid line across the
  /// top of each) plus an asymmetric smirk (one corner raised higher than the
  /// other), reading as smug/confident. Because it has a mouth, it keeps
  /// [mrLayo]'s own canonical eye spacing. The antenna-tip dot stays blue,
  /// matching the [mrLayo] family this emotion belongs to.
  ///
  /// Idle motion is a subtle, understated periodic lid/smirk raise — a small
  /// jittered pulse rather than any large motion — keeping the expression
  /// composed throughout.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=mjKBjRevfq0
  /// (Rubia Sol, Morena Luna — Caramelos de Cianuro)
  smug,

  /// "Cool" — the standard blue face (mouth and eyes, like [mrLayo]) with a
  /// blue sunglasses bar drawn as an **overlay** across the eyes — two
  /// lenses joined by a bridge, filled in this emotion's own blue accent so
  /// they read clearly against the dark screen behind them, on top of the
  /// head shell exactly like [comandante]'s beret (see `LayoPainter`'s
  /// "Overlays" section) — hiding the eyes underneath entirely. The
  /// antenna-tip dot and tie stay blue too.
  ///
  /// Idle motion is a subtle periodic gleam sweeping across one lens, on a
  /// jittered per-instance schedule noticeably more frequent than
  /// [mrLayo]'s own blink (a 1.5-3s interval rather than 3-6s), rather than
  /// any large motion — this emotion keeps its overlay understated but its
  /// shine frequent.
  ///
  /// This emotion was based on this song: https://www.youtube.com/watch?v=11cta61wi0g
  /// (Hype Boy — NewJeans)
  cool,
}
