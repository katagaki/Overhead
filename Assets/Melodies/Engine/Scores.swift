// Melody scores for Overhead.
//
// 01-17 are melodies: four bars, cadencing onto the tonic, minimum tempo 100 BPM.
// 18-21 are chimes and bells, which are short signals and follow neither rule.
//
// Most are original compositions. Where a piece is arranged from an existing work
// the source is named above it, and all such sources are public domain.

let scores: [(name: String, score: Score)] = [

    // MARK: 01-asagiri  朝霧
    // C major pentatonic, gentle morning lilt.
    ("01-asagiri", Score(
        bpm: 128,
        melody: [
            Note(pitch: "G5", beat: 0, length: 0.5), Note(pitch: "A5", beat: 0.5, length: 0.5),
            Note(pitch: "C6", beat: 1, length: 1), Note(pitch: "A5", beat: 2, length: 0.5),
            Note(pitch: "G5", beat: 2.5, length: 0.5), Note(pitch: "E5", beat: 3, length: 1),
            Note(pitch: "D5", beat: 4, length: 0.5), Note(pitch: "E5", beat: 4.5, length: 0.5),
            Note(pitch: "G5", beat: 5, length: 1), Note(pitch: "E5", beat: 6, length: 0.5),
            Note(pitch: "D5", beat: 6.5, length: 0.5), Note(pitch: "B4", beat: 7, length: 1),
            Note(pitch: "E5", beat: 8, length: 0.5), Note(pitch: "G5", beat: 8.5, length: 0.5),
            Note(pitch: "A5", beat: 9, length: 1), Note(pitch: "C6", beat: 10, length: 0.5),
            Note(pitch: "A5", beat: 10.5, length: 0.5), Note(pitch: "G5", beat: 11, length: 1),
            Note(pitch: "A5", beat: 12, length: 0.5),
            Note(pitch: "G5", beat: 12.5, length: 0.5), Note(pitch: "F5", beat: 13, length: 1),
            Note(pitch: "E5", beat: 14, length: 0.5),
            Note(pitch: "C5", beat: 14.5, length: 1.5)
        ],
        chords: [
            ChordSpan(beat: 0, length: 4, notes: ["C4", "E4", "G4"]),
            ChordSpan(beat: 4, length: 4, notes: ["G3", "B3", "D4"]),
            ChordSpan(beat: 8, length: 4, notes: ["A3", "C4", "E4"]),
            ChordSpan(beat: 12, length: 2, notes: ["F3", "A3", "C4"]),
            ChordSpan(beat: 14, length: 2, notes: ["C4", "E4", "G4"])
        ],
        bass: [
            Note(pitch: "C3", beat: 0, length: 4), Note(pitch: "G2", beat: 4, length: 4),
            Note(pitch: "A2", beat: 8, length: 4), Note(pitch: "F2", beat: 12, length: 2),
            Note(pitch: "C3", beat: 14, length: 2)
        ],
        arpDiv: 0.5, arpAmp: 0.115, arpPattern: [0, 1, 2, 1],
        melAmp: 0.46, bassAmp: 0.17)),

    // MARK: 02-hasshin  発進
    // G major, quick and buoyant, the "doors are closing" one.
    // Rhythm: syncopation: notes anticipate the beat and tie across it.
    ("02-hasshin", Score(
        bpm: 142,
        melody: [
            Note(pitch: "D5", beat: 0, length: 0.5), Note(pitch: "G5", beat: 0.5, length: 1),
            Note(pitch: "B5", beat: 1.5, length: 0.5), Note(pitch: "A5", beat: 2, length: 1),
            Note(pitch: "G5", beat: 3, length: 0.5), Note(pitch: "B5", beat: 3.5, length: 0.5),
            Note(pitch: "A5", beat: 4, length: 1), Note(pitch: "D5", beat: 5, length: 0.5),
            Note(pitch: "F#5", beat: 5.5, length: 1),
            Note(pitch: "A5", beat: 6.5, length: 0.5), Note(pitch: "B5", beat: 7, length: 1),
            Note(pitch: "G5", beat: 8, length: 0.5), Note(pitch: "E5", beat: 8.5, length: 1),
            Note(pitch: "G5", beat: 9.5, length: 0.5), Note(pitch: "B5", beat: 10, length: 1),
            Note(pitch: "G5", beat: 11, length: 1), Note(pitch: "G5", beat: 12, length: 0.5),
            Note(pitch: "E5", beat: 12.5, length: 1),
            Note(pitch: "F#5", beat: 13.5, length: 0.5),
            Note(pitch: "G5", beat: 14, length: 2)
        ],
        chords: [
            ChordSpan(beat: 0, length: 4, notes: ["G3", "B3", "D4"]),
            ChordSpan(beat: 4, length: 4, notes: ["D4", "F#4", "A4"]),
            ChordSpan(beat: 8, length: 4, notes: ["E3", "G3", "B3"]),
            ChordSpan(beat: 12, length: 1, notes: ["C4", "E4", "G4"]),
            ChordSpan(beat: 13, length: 1, notes: ["D4", "F#4", "A4"]),
            ChordSpan(beat: 14, length: 2, notes: ["G3", "B3", "D4"])
        ],
        bass: [
            Note(pitch: "G2", beat: 0, length: 4), Note(pitch: "D3", beat: 4, length: 4),
            Note(pitch: "E2", beat: 8, length: 4), Note(pitch: "C3", beat: 12, length: 1),
            Note(pitch: "D3", beat: 13, length: 1), Note(pitch: "G2", beat: 14, length: 2)
        ],
        arpDiv: 0.5, arpAmp: 0.105, arpPattern: [0, 1, 2, 1],
        melAmp: 0.46, bassAmp: 0.17)),

    // MARK: 03-kasukeki  幽けき軌道
    // A minor, i-bVII-bVI-V descent, G# raised 7th at the cadence.
    // Rhythm: dotted quarter plus eighth throughout, a long-short limp.
    ("03-kasukeki", Score(
        bpm: 138,
        melody: [
            Note(pitch: "A5", beat: 0, length: 1.5), Note(pitch: "C6", beat: 1.5, length: 0.5),
            Note(pitch: "B5", beat: 2, length: 1.5), Note(pitch: "A5", beat: 3.5, length: 0.5),
            Note(pitch: "G5", beat: 4, length: 1.5), Note(pitch: "B5", beat: 5.5, length: 0.5),
            Note(pitch: "A5", beat: 6, length: 1.5), Note(pitch: "G5", beat: 7.5, length: 0.5),
            Note(pitch: "F5", beat: 8, length: 1), Note(pitch: "A5", beat: 9, length: 0.5),
            Note(pitch: "C6", beat: 9.5, length: 0.5),
            Note(pitch: "B5", beat: 10, length: 1.5),
            Note(pitch: "A5", beat: 11.5, length: 0.5),
            Note(pitch: "G#5", beat: 12, length: 1.5),
            Note(pitch: "B5", beat: 13.5, length: 0.5), Note(pitch: "A5", beat: 14, length: 2)
        ],
        chords: [
            ChordSpan(beat: 0, length: 4, notes: ["A3", "C4", "E4"]),
            ChordSpan(beat: 4, length: 4, notes: ["G3", "B3", "D4"]),
            ChordSpan(beat: 8, length: 4, notes: ["F3", "A3", "C4"]),
            ChordSpan(beat: 12, length: 2, notes: ["E4", "G#4", "B4"]),
            ChordSpan(beat: 14, length: 2, notes: ["A3", "C4", "E4"])
        ],
        bass: [
            Note(pitch: "A2", beat: 0, length: 4), Note(pitch: "G2", beat: 4, length: 4),
            Note(pitch: "F2", beat: 8, length: 4), Note(pitch: "E2", beat: 12, length: 2),
            Note(pitch: "A2", beat: 14, length: 2)
        ],
        arpDiv: 0.5, arpAmp: 0.11, arpPattern: [0, 1, 2, 1],
        melAmp: 0.46, bassAmp: 0.17)),

    // MARK: 04-hananoeki  花の駅
    // B minor lifting toward its relative major, bittersweet turning bright.
    // Rhythm: call and response: every bar ends in a half-beat of silence.
    ("04-hananoeki", Score(
        bpm: 132,
        melody: [
            Note(pitch: "B5", beat: 0, length: 1), Note(pitch: "A5", beat: 1, length: 0.5),
            Note(pitch: "F#5", beat: 1.5, length: 1), Note(pitch: "D5", beat: 3, length: 1),
            Note(pitch: "G5", beat: 4, length: 1), Note(pitch: "F#5", beat: 5, length: 0.5),
            Note(pitch: "E5", beat: 5.5, length: 1), Note(pitch: "D5", beat: 7, length: 1),
            Note(pitch: "F#5", beat: 8, length: 1), Note(pitch: "A5", beat: 9, length: 0.5),
            Note(pitch: "B5", beat: 9.5, length: 1), Note(pitch: "F#5", beat: 11, length: 1),
            Note(pitch: "E5", beat: 12, length: 1), Note(pitch: "F#5", beat: 13, length: 0.5),
            Note(pitch: "A#5", beat: 13.5, length: 0.5),
            Note(pitch: "B5", beat: 14, length: 2)
        ],
        chords: [
            ChordSpan(beat: 0, length: 4, notes: ["B3", "D4", "F#4"]),
            ChordSpan(beat: 4, length: 4, notes: ["G3", "B3", "D4"]),
            ChordSpan(beat: 8, length: 4, notes: ["D4", "F#4", "A4"]),
            ChordSpan(beat: 12, length: 2, notes: ["F#3", "A#3", "C#4"]),
            ChordSpan(beat: 14, length: 2, notes: ["B3", "D4", "F#4"])
        ],
        bass: [
            Note(pitch: "B2", beat: 0, length: 4), Note(pitch: "G2", beat: 4, length: 4),
            Note(pitch: "D3", beat: 8, length: 4), Note(pitch: "F#2", beat: 12, length: 2),
            Note(pitch: "B2", beat: 14, length: 2)
        ],
        arpDiv: 0.5, arpAmp: 0.108, arpPattern: [0, 1, 2, 1],
        melAmp: 0.46, bassAmp: 0.17)),

    // MARK: 05-tokoyo  常世の路
    // G Dorian. The raised 6th gives a bright IV major inside a minor key.
    // Rhythm: sixteenth-note riff on a repeated pitch, then a turn.
    ("05-tokoyo", Score(
        bpm: 144,
        melody: [
            Note(pitch: "D5", beat: 0, length: 0.25),
            Note(pitch: "D5", beat: 0.25, length: 0.25),
            Note(pitch: "D5", beat: 0.5, length: 0.5), Note(pitch: "G5", beat: 1, length: 1),
            Note(pitch: "A#5", beat: 2, length: 0.25),
            Note(pitch: "A5", beat: 2.25, length: 0.25),
            Note(pitch: "G5", beat: 2.5, length: 0.5), Note(pitch: "D5", beat: 3, length: 1),
            Note(pitch: "C5", beat: 4, length: 0.25),
            Note(pitch: "C5", beat: 4.25, length: 0.25),
            Note(pitch: "C5", beat: 4.5, length: 0.5), Note(pitch: "F5", beat: 5, length: 1),
            Note(pitch: "A5", beat: 6, length: 0.25),
            Note(pitch: "G5", beat: 6.25, length: 0.25),
            Note(pitch: "F5", beat: 6.5, length: 0.5), Note(pitch: "C5", beat: 7, length: 1),
            Note(pitch: "D5", beat: 8, length: 0.25),
            Note(pitch: "D5", beat: 8.25, length: 0.25),
            Note(pitch: "D5", beat: 8.5, length: 0.5), Note(pitch: "A#5", beat: 9, length: 1),
            Note(pitch: "C6", beat: 10, length: 0.25),
            Note(pitch: "A#5", beat: 10.25, length: 0.25),
            Note(pitch: "A5", beat: 10.5, length: 0.5), Note(pitch: "F5", beat: 11, length: 1),
            Note(pitch: "E5", beat: 12, length: 0.25),
            Note(pitch: "E5", beat: 12.25, length: 0.25),
            Note(pitch: "E5", beat: 12.5, length: 0.5), Note(pitch: "C6", beat: 13, length: 1),
            Note(pitch: "A5", beat: 14, length: 0.5),
            Note(pitch: "G5", beat: 14.5, length: 1.5)
        ],
        chords: [
            ChordSpan(beat: 0, length: 4, notes: ["G3", "A#3", "D4"]),
            ChordSpan(beat: 4, length: 4, notes: ["F3", "A3", "C4"]),
            ChordSpan(beat: 8, length: 4, notes: ["A#3", "D4", "F4"]),
            ChordSpan(beat: 12, length: 2, notes: ["C4", "E4", "G4"]),
            ChordSpan(beat: 14, length: 2, notes: ["G3", "A#3", "D4"])
        ],
        bass: [
            Note(pitch: "G2", beat: 0, length: 4), Note(pitch: "F2", beat: 4, length: 4),
            Note(pitch: "A#2", beat: 8, length: 4), Note(pitch: "C3", beat: 12, length: 2),
            Note(pitch: "G2", beat: 14, length: 2)
        ],
        arpDiv: 0.5, arpAmp: 0.108, arpPattern: [0, 1, 2, 1],
        melAmp: 0.46, bassAmp: 0.17)),

    // MARK: 06-kouen  紅炎
    // C harmonic minor, driving. B natural leading tone over the major V.
    // Rhythm: held note answered by a sixteenth-note flourish.
    ("06-kouen", Score(
        bpm: 136,
        melody: [
            Note(pitch: "G5", beat: 0, length: 2), Note(pitch: "C6", beat: 2, length: 0.25),
            Note(pitch: "A#5", beat: 2.25, length: 0.25),
            Note(pitch: "G5", beat: 2.5, length: 0.25),
            Note(pitch: "D#5", beat: 2.75, length: 0.25),
            Note(pitch: "G5", beat: 3, length: 1), Note(pitch: "G#5", beat: 4, length: 2),
            Note(pitch: "C6", beat: 6, length: 0.25),
            Note(pitch: "A#5", beat: 6.25, length: 0.25),
            Note(pitch: "G#5", beat: 6.5, length: 0.25),
            Note(pitch: "G5", beat: 6.75, length: 0.25),
            Note(pitch: "D#5", beat: 7, length: 1), Note(pitch: "A#5", beat: 8, length: 2),
            Note(pitch: "F5", beat: 10, length: 0.25),
            Note(pitch: "G5", beat: 10.25, length: 0.25),
            Note(pitch: "A#5", beat: 10.5, length: 0.25),
            Note(pitch: "C6", beat: 10.75, length: 0.25),
            Note(pitch: "A#5", beat: 11, length: 1), Note(pitch: "D5", beat: 12, length: 1),
            Note(pitch: "B5", beat: 13, length: 1), Note(pitch: "C6", beat: 14, length: 2)
        ],
        chords: [
            ChordSpan(beat: 0, length: 4, notes: ["C4", "D#4", "G4"]),
            ChordSpan(beat: 4, length: 4, notes: ["G#3", "C4", "D#4"]),
            ChordSpan(beat: 8, length: 4, notes: ["A#3", "D4", "F4"]),
            ChordSpan(beat: 12, length: 2, notes: ["G3", "B3", "D4"]),
            ChordSpan(beat: 14, length: 2, notes: ["C4", "D#4", "G4"])
        ],
        bass: [
            Note(pitch: "C3", beat: 0, length: 4), Note(pitch: "G#2", beat: 4, length: 4),
            Note(pitch: "A#2", beat: 8, length: 4), Note(pitch: "G2", beat: 12, length: 2),
            Note(pitch: "C3", beat: 14, length: 2)
        ],
        arpDiv: 0.5, arpAmp: 0.104, arpPattern: [0, 1, 2, 1],
        melAmp: 0.47, bassAmp: 0.17)),

    // MARK: 07-kagerou  陽炎
    // D minor. The device is Phrygian dominant on the V: the melody hits the b9
    // (A#) over the A chord at bar 4 and sighs down to A before the C# leading
    // tone resolves. That flattened second over the dominant is the whole flavour.
    // Rhythm: angular zigzag: wide leaps reversing direction each time.
    ("07-kagerou", Score(
        bpm: 152,
        melody: [
            Note(pitch: "D5", beat: 0, length: 1), Note(pitch: "A5", beat: 1, length: 0.5),
            Note(pitch: "D5", beat: 1.5, length: 0.5), Note(pitch: "F5", beat: 2, length: 1),
            Note(pitch: "A5", beat: 3, length: 0.5), Note(pitch: "D5", beat: 3.5, length: 0.5),
            Note(pitch: "A#5", beat: 4, length: 1), Note(pitch: "F5", beat: 5, length: 0.5),
            Note(pitch: "A#5", beat: 5.5, length: 0.5), Note(pitch: "A5", beat: 6, length: 1),
            Note(pitch: "F5", beat: 7, length: 1), Note(pitch: "G5", beat: 8, length: 1),
            Note(pitch: "D5", beat: 9, length: 0.5),
            Note(pitch: "A#5", beat: 9.5, length: 0.5), Note(pitch: "A5", beat: 10, length: 1),
            Note(pitch: "G5", beat: 11, length: 1), Note(pitch: "A#5", beat: 12, length: 1),
            Note(pitch: "A5", beat: 13, length: 0.5),
            Note(pitch: "C#5", beat: 13.5, length: 0.5),
            Note(pitch: "E5", beat: 14, length: 0.5),
            Note(pitch: "D5", beat: 14.5, length: 1.5)
        ],
        chords: [
            ChordSpan(beat: 0, length: 4, notes: ["D4", "F4", "A4"]),
            ChordSpan(beat: 4, length: 4, notes: ["A#3", "D4", "F4"]),
            ChordSpan(beat: 8, length: 4, notes: ["G3", "A#3", "D4"]),
            ChordSpan(beat: 12, length: 2, notes: ["A3", "C#4", "E4"]),
            ChordSpan(beat: 14, length: 2, notes: ["D4", "F4", "A4"])
        ],
        bass: [
            Note(pitch: "D3", beat: 0, length: 4), Note(pitch: "A#2", beat: 4, length: 4),
            Note(pitch: "G2", beat: 8, length: 4), Note(pitch: "A2", beat: 12, length: 2),
            Note(pitch: "D3", beat: 14, length: 2)
        ],
        arpDiv: 0.5, arpAmp: 0.105, arpPattern: [0, 1, 2, 1],
        melAmp: 0.47, bassAmp: 0.17)),

    // MARK: 08-rinbu  輪舞
    // F minor in 3/4, the only minor waltz here. The arpeggio climbs
    // root-third-fifth once per bar, which is what gives the lilt.
    //
    // Structure is rhythmic acceleration: two notes in bar 1, three in bar 2, four
    // in bar 3, five in bar 4, so the tune tightens as it goes and the cadence
    // arrives at double the opening speed. Nothing else in the set is shaped that
    // way, and it keeps the waltz clear of the even-quarter tune in 10.
    //
    // Progression is i-bIII-iv-V-i, avoiding the i-bVI-iv-V that 07 and 10 share.
    // Cadence uses the harmonic-minor raised 7th (E natural) over the major V.
    ("08-rinbu", Score(
        bpm: 120,
        melody: [
            Note(pitch: "C5", beat: 0, length: 2), Note(pitch: "F5", beat: 2, length: 1),
            Note(pitch: "G#5", beat: 3, length: 1.5), Note(pitch: "G5", beat: 4.5, length: 0.5),
            Note(pitch: "D#5", beat: 5, length: 1),
            Note(pitch: "F5", beat: 6, length: 1), Note(pitch: "A#5", beat: 7, length: 0.5),
            Note(pitch: "G#5", beat: 7.5, length: 0.5), Note(pitch: "F5", beat: 8, length: 1),
            Note(pitch: "G5", beat: 9, length: 0.5), Note(pitch: "A#5", beat: 9.5, length: 0.5),
            Note(pitch: "G5", beat: 10, length: 0.5), Note(pitch: "E5", beat: 10.5, length: 0.5),
            Note(pitch: "F5", beat: 11, length: 1)
        ],
        chords: [
            ChordSpan(beat: 0, length: 3, notes: ["F3", "G#3", "C4"]),
            ChordSpan(beat: 3, length: 3, notes: ["G#3", "C4", "D#4"]),
            ChordSpan(beat: 6, length: 3, notes: ["A#3", "C#4", "F4"]),
            ChordSpan(beat: 9, length: 2, notes: ["C4", "E4", "G4"]),
            ChordSpan(beat: 11, length: 1, notes: ["F3", "G#3", "C4"])
        ],
        bass: [
            Note(pitch: "F2", beat: 0, length: 3), Note(pitch: "G#2", beat: 3, length: 3),
            Note(pitch: "A#2", beat: 6, length: 3), Note(pitch: "C3", beat: 9, length: 2),
            Note(pitch: "F2", beat: 11, length: 1)
        ],
        arpDiv: 1, arpAmp: 0.13, arpPattern: [0, 1, 2, 1],
        melAmp: 0.45, bassAmp: 0.17)),

    // MARK: 09-zankyou  残響
    // Bb minor, weighty and slow-moving. Bar 3 is the Neapolitan bII (spelled B
    // major here), the big flat sidestep, and bar 4 answers it with the raised 7th
    // over the major V.
    ("09-zankyou", Score(
        bpm: 132,
        melody: [
            Note(pitch: "F5", beat: 0, length: 1.5), Note(pitch: "D#5", beat: 1.5, length: 0.5),
            Note(pitch: "C#5", beat: 2, length: 2),
            Note(pitch: "C5", beat: 4, length: 1), Note(pitch: "D#5", beat: 5, length: 1),
            Note(pitch: "G#5", beat: 6, length: 1.5), Note(pitch: "F5", beat: 7.5, length: 0.5),
            Note(pitch: "F#5", beat: 8, length: 1), Note(pitch: "D#5", beat: 9, length: 1),
            Note(pitch: "B5", beat: 10, length: 2),
            Note(pitch: "A5", beat: 12, length: 1), Note(pitch: "F5", beat: 13, length: 1),
            Note(pitch: "A#5", beat: 14, length: 2)
        ],
        chords: [
            ChordSpan(beat: 0, length: 4, notes: ["A#3", "C#4", "F4"]),
            ChordSpan(beat: 4, length: 4, notes: ["G#3", "C4", "D#4"]),
            ChordSpan(beat: 8, length: 4, notes: ["B3", "D#4", "F#4"]),
            ChordSpan(beat: 12, length: 2, notes: ["F3", "A3", "C4"]),
            ChordSpan(beat: 14, length: 2, notes: ["A#3", "C#4", "F4"])
        ],
        bass: [
            Note(pitch: "A#2", beat: 0, length: 4), Note(pitch: "G#2", beat: 4, length: 4),
            Note(pitch: "B2", beat: 8, length: 4), Note(pitch: "F2", beat: 12, length: 2),
            Note(pitch: "A#2", beat: 14, length: 2)
        ],
        arpDiv: 1, arpAmp: 0.135, arpPattern: [0, 2, 1, 2],
        melAmp: 0.45, bassAmp: 0.17)),

    // MARK: 10-akatsuki  暁
    // C# minor that ends major: a Picardy third. The melody spells it out, landing
    // on E# (written F) in the last bar before the tonic, so the piece turns bright
    // exactly at the cadence. Still chord I, just the major form of it.
    // Rhythm: even quarters climbing in sequence, peak held late in bar 3.
    ("10-akatsuki", Score(
        bpm: 140,
        melody: [
            Note(pitch: "C#5", beat: 0, length: 1), Note(pitch: "E5", beat: 1, length: 1),
            Note(pitch: "G#5", beat: 2, length: 1), Note(pitch: "F#5", beat: 3, length: 1),
            Note(pitch: "E5", beat: 4, length: 1), Note(pitch: "G#5", beat: 5, length: 1),
            Note(pitch: "A5", beat: 6, length: 1), Note(pitch: "G#5", beat: 7, length: 1),
            Note(pitch: "F#5", beat: 8, length: 1), Note(pitch: "A5", beat: 9, length: 1),
            Note(pitch: "C#6", beat: 10, length: 1.5),
            Note(pitch: "A5", beat: 11.5, length: 0.5),
            Note(pitch: "G#5", beat: 12, length: 1), Note(pitch: "C5", beat: 13, length: 0.5),
            Note(pitch: "D#5", beat: 13.5, length: 0.5),
            Note(pitch: "F5", beat: 14, length: 0.5),
            Note(pitch: "C#5", beat: 14.5, length: 1.5)
        ],
        chords: [
            ChordSpan(beat: 0, length: 4, notes: ["C#4", "E4", "G#4"]),
            ChordSpan(beat: 4, length: 4, notes: ["A3", "C#4", "E4"]),
            ChordSpan(beat: 8, length: 4, notes: ["F#3", "A3", "C#4"]),
            ChordSpan(beat: 12, length: 2, notes: ["G#3", "C4", "D#4"]),
            ChordSpan(beat: 14, length: 2, notes: ["C#4", "F4", "G#4"])
        ],
        bass: [
            Note(pitch: "C#3", beat: 0, length: 4), Note(pitch: "A2", beat: 4, length: 4),
            Note(pitch: "F#2", beat: 8, length: 4), Note(pitch: "G#2", beat: 12, length: 2),
            Note(pitch: "C#3", beat: 14, length: 2)
        ],
        arpDiv: 0.5, arpAmp: 0.108, arpPattern: [0, 1, 2, 1],
        melAmp: 0.46, bassAmp: 0.17)),

    // MARK: 11-sonata  ソナタ
    // After Mozart, Piano Sonata No. 16 in C, K. 545 (1788), public domain.
    // The opening subject sits over a broken-chord left hand, which is what the
    // accompaniment layer already plays, so it needs very little adapting.
    ("11-sonata", Score(
        bpm: 126,
        melody: [
            Note(pitch: "C5", beat: 0, length: 1), Note(pitch: "E5", beat: 1, length: 1),
            Note(pitch: "G5", beat: 2, length: 0.5), Note(pitch: "B4", beat: 2.5, length: 0.5),
            Note(pitch: "C5", beat: 3, length: 0.5), Note(pitch: "D5", beat: 3.5, length: 0.5),
            Note(pitch: "C5", beat: 4, length: 2),
            Note(pitch: "B4", beat: 6, length: 0.5), Note(pitch: "C5", beat: 6.5, length: 0.5),
            Note(pitch: "D5", beat: 7, length: 0.5), Note(pitch: "B4", beat: 7.5, length: 0.5),
            Note(pitch: "A4", beat: 8, length: 1), Note(pitch: "C5", beat: 9, length: 1),
            Note(pitch: "F5", beat: 10, length: 0.5), Note(pitch: "E5", beat: 10.5, length: 0.5),
            Note(pitch: "D5", beat: 11, length: 0.5), Note(pitch: "C5", beat: 11.5, length: 0.5),
            Note(pitch: "D5", beat: 12, length: 1), Note(pitch: "B4", beat: 13, length: 1),
            Note(pitch: "C5", beat: 14, length: 2)
        ],
        chords: [
            ChordSpan(beat: 0, length: 4, notes: ["C4", "E4", "G4"]),
            ChordSpan(beat: 4, length: 2, notes: ["C4", "E4", "G4"]),
            ChordSpan(beat: 6, length: 2, notes: ["G3", "B3", "D4"]),
            ChordSpan(beat: 8, length: 4, notes: ["F3", "A3", "C4"]),
            ChordSpan(beat: 12, length: 2, notes: ["G3", "B3", "D4"]),
            ChordSpan(beat: 14, length: 2, notes: ["C4", "E4", "G4"])
        ],
        bass: [
            Note(pitch: "C3", beat: 0, length: 4), Note(pitch: "C3", beat: 4, length: 2),
            Note(pitch: "G2", beat: 6, length: 2), Note(pitch: "F2", beat: 8, length: 4),
            Note(pitch: "G2", beat: 12, length: 2), Note(pitch: "C3", beat: 14, length: 2)
        ],
        arpDiv: 0.5, arpAmp: 0.112, arpPattern: [0, 1, 2, 1],
        melAmp: 0.45, bassAmp: 0.17)),

    // MARK: 12-canon  カノン
    // After Pachelbel, Canon in D (c.1680), public domain. Built on an
    // arpeggiated ground, which the accompaniment layer already does.
    ("12-canon", Score(
        bpm: 118,
        melody: [
            Note(pitch: "F#5", beat: 0, length: 1), Note(pitch: "E5", beat: 1, length: 1),
            Note(pitch: "D5", beat: 2, length: 1), Note(pitch: "C#5", beat: 3, length: 1),
            Note(pitch: "B4", beat: 4, length: 1), Note(pitch: "A4", beat: 5, length: 1),
            Note(pitch: "B4", beat: 6, length: 1), Note(pitch: "C#5", beat: 7, length: 1),
            Note(pitch: "D5", beat: 8, length: 1), Note(pitch: "F#5", beat: 9, length: 1),
            Note(pitch: "A5", beat: 10, length: 1), Note(pitch: "F#5", beat: 11, length: 1),
            Note(pitch: "G5", beat: 12, length: 1), Note(pitch: "F#5", beat: 13, length: 1),
            Note(pitch: "E5", beat: 14, length: 0.5),
            Note(pitch: "D5", beat: 14.5, length: 1.5)
        ],
        chords: [
            ChordSpan(beat: 0, length: 4, notes: ["D4", "F#4", "A4"]),
            ChordSpan(beat: 4, length: 4, notes: ["A3", "C#4", "E4"]),
            ChordSpan(beat: 8, length: 4, notes: ["B3", "D4", "F#4"]),
            ChordSpan(beat: 12, length: 1, notes: ["G3", "B3", "D4"]),
            ChordSpan(beat: 13, length: 1, notes: ["A3", "C#4", "E4"]),
            ChordSpan(beat: 14, length: 2, notes: ["D4", "F#4", "A4"])
        ],
        bass: [
            Note(pitch: "D3", beat: 0, length: 4), Note(pitch: "A2", beat: 4, length: 4),
            Note(pitch: "B2", beat: 8, length: 4), Note(pitch: "G2", beat: 12, length: 1),
            Note(pitch: "A2", beat: 13, length: 1), Note(pitch: "D3", beat: 14, length: 2)
        ],
        arpDiv: 0.5, arpAmp: 0.118, arpPattern: [0, 1, 2, 1],
        melAmp: 0.45, bassAmp: 0.17)),

    // MARK: 13-sakura  さくら
    // After the traditional "Sakura Sakura" (Edo period), public domain. Built on
    // the in scale (1, 2, b3, 5, b6), the only piece here not using a Western
    // mode, which is where its colour comes from. Transposed to D, so the scale is
    // exactly D E F A A#, and every melody note must come from that set: the
    // opening figure is degrees 1 1 2, and degree 4 does not exist in this mode.
    // Cadenced iv to i rather than V to i, since a raised leading tone would pull
    // it straight out of the scale.
    ("13-sakura", Score(
        bpm: 120,
        melody: [
            Note(pitch: "D5", beat: 0, length: 1), Note(pitch: "D5", beat: 1, length: 1),
            Note(pitch: "E5", beat: 2, length: 2),
            Note(pitch: "D5", beat: 4, length: 1), Note(pitch: "D5", beat: 5, length: 1),
            Note(pitch: "E5", beat: 6, length: 2),
            Note(pitch: "F5", beat: 8, length: 1), Note(pitch: "A5", beat: 9, length: 1),
            Note(pitch: "A#5", beat: 10, length: 2),
            Note(pitch: "A5", beat: 12, length: 1), Note(pitch: "F5", beat: 13, length: 1),
            Note(pitch: "D5", beat: 14, length: 2)
        ],
        chords: [
            ChordSpan(beat: 0, length: 4, notes: ["D4", "F4", "A4"]),
            ChordSpan(beat: 4, length: 4, notes: ["D4", "F4", "A4"]),
            ChordSpan(beat: 8, length: 2, notes: ["D4", "F4", "A4"]),
            ChordSpan(beat: 10, length: 2, notes: ["A#3", "D4", "F4"]),
            ChordSpan(beat: 12, length: 2, notes: ["G3", "A#3", "D4"]),
            ChordSpan(beat: 14, length: 2, notes: ["D4", "F4", "A4"])
        ],
        bass: [
            Note(pitch: "D3", beat: 0, length: 4), Note(pitch: "D3", beat: 4, length: 4),
            Note(pitch: "D3", beat: 8, length: 2), Note(pitch: "A#2", beat: 10, length: 2),
            Note(pitch: "G2", beat: 12, length: 2), Note(pitch: "D3", beat: 14, length: 2)
        ],
        arpDiv: 1, arpAmp: 0.135, arpPattern: [0, 2, 1, 2],
        melAmp: 0.45, bassAmp: 0.17)),

    // MARK: 14-kanki  歓喜の歌
    // After Beethoven, "Ode an die Freude" (Symphony No. 9, 1824), public domain.
    // The theme's opening phrase closes on the dominant, so bar 4 borrows the
    // consequent phrase's descent to land on the tonic as the house rules require.
    ("14-kanki", Score(
        bpm: 126,
        melody: [
            Note(pitch: "F#5", beat: 0, length: 1), Note(pitch: "F#5", beat: 1, length: 1),
            Note(pitch: "G5", beat: 2, length: 1), Note(pitch: "A5", beat: 3, length: 1),
            Note(pitch: "A5", beat: 4, length: 1), Note(pitch: "G5", beat: 5, length: 1),
            Note(pitch: "F#5", beat: 6, length: 1), Note(pitch: "E5", beat: 7, length: 1),
            Note(pitch: "D5", beat: 8, length: 1), Note(pitch: "D5", beat: 9, length: 1),
            Note(pitch: "E5", beat: 10, length: 1), Note(pitch: "F#5", beat: 11, length: 1),
            Note(pitch: "F#5", beat: 12, length: 1.5),
            Note(pitch: "E5", beat: 13.5, length: 0.5),
            Note(pitch: "D5", beat: 14, length: 2)
        ],
        chords: [
            ChordSpan(beat: 0, length: 4, notes: ["D4", "F#4", "A4"]),
            ChordSpan(beat: 4, length: 2, notes: ["D4", "F#4", "A4"]),
            ChordSpan(beat: 6, length: 2, notes: ["A3", "C#4", "E4"]),
            ChordSpan(beat: 8, length: 4, notes: ["D4", "F#4", "A4"]),
            ChordSpan(beat: 12, length: 2, notes: ["A3", "C#4", "E4"]),
            ChordSpan(beat: 14, length: 2, notes: ["D4", "F#4", "A4"])
        ],
        bass: [
            Note(pitch: "D3", beat: 0, length: 4), Note(pitch: "D3", beat: 4, length: 2),
            Note(pitch: "A2", beat: 6, length: 2), Note(pitch: "D3", beat: 8, length: 4),
            Note(pitch: "A2", beat: 12, length: 2), Note(pitch: "D3", beat: 14, length: 2)
        ],
        arpDiv: 0.5, arpAmp: 0.112, arpPattern: [0, 1, 2, 1],
        melAmp: 0.45, bassAmp: 0.17)),

    // MARK: 15-hotaru  蛍の光
    // After the traditional Scottish air "Auld Lang Syne" (in print by the 1790s),
    // public domain, and the melody Japan uses for 蛍の光. Transposed to D.
    //
    // The tune is major pentatonic: degrees 1 2 3 5 6 only, so no G and no C#
    // may appear in the melody. The dotted figure opening each bar is the
    // characteristic rhythm and is what carries the recognition.
    //
    // Its own first phrase peaks on degree 6 and stays open, so bar 4 descends
    // through the tonic triad to close V-I, as the house rules require.
    ("15-hotaru", Score(
        bpm: 120,
        melody: [
            Note(pitch: "D5", beat: 0, length: 1.5), Note(pitch: "D5", beat: 1.5, length: 0.5),
            Note(pitch: "D5", beat: 2, length: 1), Note(pitch: "F#5", beat: 3, length: 1),
            Note(pitch: "E5", beat: 4, length: 1.5), Note(pitch: "D5", beat: 5.5, length: 0.5),
            Note(pitch: "E5", beat: 6, length: 1), Note(pitch: "F#5", beat: 7, length: 1),
            Note(pitch: "D5", beat: 8, length: 1.5), Note(pitch: "D5", beat: 9.5, length: 0.5),
            Note(pitch: "F#5", beat: 10, length: 1), Note(pitch: "A5", beat: 11, length: 1),
            Note(pitch: "B5", beat: 12, length: 1), Note(pitch: "A5", beat: 13, length: 1),
            Note(pitch: "F#5", beat: 14, length: 0.5), Note(pitch: "D5", beat: 14.5, length: 1.5)
        ],
        chords: [
            ChordSpan(beat: 0, length: 4, notes: ["D4", "F#4", "A4"]),
            ChordSpan(beat: 4, length: 2, notes: ["A3", "C#4", "E4"]),
            ChordSpan(beat: 6, length: 2, notes: ["D4", "F#4", "A4"]),
            ChordSpan(beat: 8, length: 4, notes: ["D4", "F#4", "A4"]),
            ChordSpan(beat: 12, length: 2, notes: ["A3", "C#4", "E4"]),
            ChordSpan(beat: 14, length: 2, notes: ["D4", "F#4", "A4"])
        ],
        bass: [
            Note(pitch: "D3", beat: 0, length: 4), Note(pitch: "A2", beat: 4, length: 2),
            Note(pitch: "D3", beat: 6, length: 2), Note(pitch: "D3", beat: 8, length: 4),
            Note(pitch: "A2", beat: 12, length: 2), Note(pitch: "D3", beat: 14, length: 2)
        ],
        arpDiv: 0.5, arpAmp: 0.112, arpPattern: [0, 1, 2, 1],
        melAmp: 0.45, bassAmp: 0.17)),

    // MARK: 16-minuet  メヌエット
    // After the Minuet in G, BWV Anh. 114 (Petzold, c.1725), public
    // domain. The only piece in 3/4, so chord spans and arpeggio run in threes.
    ("16-minuet", Score(
        bpm: 126,
        melody: [
            Note(pitch: "D5", beat: 0, length: 1), Note(pitch: "G4", beat: 1, length: 0.5),
            Note(pitch: "A4", beat: 1.5, length: 0.5), Note(pitch: "B4", beat: 2, length: 0.5),
            Note(pitch: "C5", beat: 2.5, length: 0.5), Note(pitch: "D5", beat: 3, length: 1),
            Note(pitch: "G4", beat: 4, length: 1), Note(pitch: "G4", beat: 5, length: 1),
            Note(pitch: "E5", beat: 6, length: 1), Note(pitch: "C5", beat: 7, length: 0.5),
            Note(pitch: "D5", beat: 7.5, length: 0.5), Note(pitch: "E5", beat: 8, length: 0.5),
            Note(pitch: "F#5", beat: 8.5, length: 0.5), Note(pitch: "G5", beat: 9, length: 1),
            Note(pitch: "G4", beat: 10, length: 1), Note(pitch: "G4", beat: 11, length: 1)
        ],
        chords: [
            ChordSpan(beat: 0, length: 3, notes: ["G3", "B3", "D4"]),
            ChordSpan(beat: 3, length: 3, notes: ["G3", "B3", "D4"]),
            ChordSpan(beat: 6, length: 3, notes: ["C4", "E4", "G4"]),
            ChordSpan(beat: 9, length: 1, notes: ["C4", "E4", "G4"]),
            ChordSpan(beat: 10, length: 1, notes: ["D4", "F#4", "A4"]),
            ChordSpan(beat: 11, length: 1, notes: ["G3", "B3", "D4"])
        ],
        bass: [
            Note(pitch: "G2", beat: 0, length: 3), Note(pitch: "G2", beat: 3, length: 3),
            Note(pitch: "C3", beat: 6, length: 3), Note(pitch: "C3", beat: 9, length: 1),
            Note(pitch: "D3", beat: 10, length: 1), Note(pitch: "G2", beat: 11, length: 1)
        ],
        arpDiv: 0.5, arpAmp: 0.112, arpPattern: [0, 1, 2, 1],
        melAmp: 0.45, bassAmp: 0.17)),

    // MARK: 17-spring  春
    // After Vivaldi, "La primavera" Op. 8 No. 1 (1725), public domain. Transcribed
    // against a source rather than from memory, which corrected three errors in an
    // earlier version of this score: the theme opens E then a repeated G#, not on
    // repeated E's; the movement is 12/8, not 4/4; and it uses D# and C#, which
    // were missing entirely.
    //
    // Metre is handled by making one beat an eighth note, so bpm here is the
    // eighth-note pulse: 176 eighths is a dotted-quarter around 59, the usual
    // Allegro for this movement. A 12/8 bar is therefore 12 beats, felt as four
    // dotted-quarters of 3.
    //
    // The rhythm is the whole character: the theme sits on long notes landing on
    // the dotted-quarter pulse, with quick three-eighth runs between them. Writing
    // it as a stream of even eighths, as an earlier version did, flattens it into
    // something mechanical no matter how correct the pitches are.
    ("17-spring", Score(
        bpm: 176,
        melody: [
            // bar 1: three dotted-quarters, then a run of three eighths
            Note(pitch: "E5", beat: 0, length: 3), Note(pitch: "G#5", beat: 3, length: 3),
            Note(pitch: "G#5", beat: 6, length: 3),
            Note(pitch: "G#5", beat: 9, length: 1), Note(pitch: "F#5", beat: 10, length: 1),
            Note(pitch: "E5", beat: 11, length: 1),
            // bar 2: held B, the descent, then the tonic held over the cadence
            Note(pitch: "B5", beat: 12, length: 3),
            Note(pitch: "B5", beat: 15, length: 1), Note(pitch: "A5", beat: 16, length: 1),
            Note(pitch: "G#5", beat: 17, length: 1),
            Note(pitch: "F#5", beat: 18, length: 1), Note(pitch: "D#5", beat: 19, length: 1),
            Note(pitch: "E5", beat: 20, length: 4)
        ],
        chords: [
            ChordSpan(beat: 0, length: 6, notes: ["E4", "G#4", "B4"]),
            ChordSpan(beat: 6, length: 6, notes: ["E4", "G#4", "B4"]),
            ChordSpan(beat: 12, length: 3, notes: ["E4", "G#4", "B4"]),
            ChordSpan(beat: 15, length: 5, notes: ["B3", "D#4", "F#4"]),
            ChordSpan(beat: 20, length: 4, notes: ["E4", "G#4", "B4"])
        ],
        bass: [
            Note(pitch: "E3", beat: 0, length: 6), Note(pitch: "E3", beat: 6, length: 6),
            Note(pitch: "E3", beat: 12, length: 3), Note(pitch: "B2", beat: 15, length: 5),
            Note(pitch: "E3", beat: 20, length: 4)
        ],
        arpDiv: 1, arpAmp: 0.095, arpPattern: [0, 1, 2, 1],
        melAmp: 0.45, bassAmp: 0.17)),


    // Chimes and bells. Short signals rather than tunes, so the four-bar and
    // cadence-onto-I rules do not apply. These use `strikes` and `bells` rather
    // than `melody`, which routes them to the struck-bell and trembler voices
    // instead of the electric piano. That distinction is the whole point: the
    // same notes on the piano voice sound like a piano playing two notes, not
    // like a chime.

    // MARK: 18-tobira  扉
    // Door chime: ding-dong, ding-doooong. The interval is a descending perfect
    // fourth, which is what the JR-type chimes use (commonly cited as G/D, the
    // exact pitch drifting unit to unit). A major third, the first thing this
    // reached for, is a doorbell interval and reads as domestic rather than rail.
    //
    // Every strike is given far more ring than the gap before the next one, so the
    // four tones overlap and decay together the way struck metal actually does.
    // Cutting each strike at its notated length is what made an earlier version
    // sound like a held key being released.
    ("18-tobira", Score(
        bpm: 140,
        melody: [], chords: [], bass: [],
        melAmp: 0.62,
        strikes: [
            Note(pitch: "G5", beat: 0, length: 7),
            Note(pitch: "D5", beat: 0.7, length: 7),
            Note(pitch: "G5", beat: 1.8, length: 7),
            Note(pitch: "D5", beat: 2.5, length: 8)
        ],
        reverb: Tone(mix: 0.34, rt: 0.85, tail: 3400))),

    // MARK: 19-kane  鐘
    // A single large bell: one strike, voiced in three octaves, left to ring out
    // completely. strikeDecay stretches the partial decays because a physically
    // bigger bell rings longer, and the wetter reverb puts it in a hall.
    ("19-kane", Score(
        bpm: 120,
        melody: [], chords: [], bass: [],
        melAmp: 0.58,
        strikes: [
            Note(pitch: "A3", beat: 0, length: 10),
            Note(pitch: "E4", beat: 0.02, length: 9.6),
            Note(pitch: "A4", beat: 0.04, length: 9.2)
        ],
        strikeDecay: 1.9,
        reverb: Tone(mix: 0.42, rt: 0.88, tail: 3200))),

    // MARK: 20-nobori  昇り
    // Rising three-note chime up the tonic triad. Each strike rings well past the
    // next, so the triad accumulates and is still sounding together at the end
    // rather than arriving as three separate notes.
    ("20-nobori", Score(
        bpm: 132,
        melody: [], chords: [], bass: [],
        melAmp: 0.55,
        strikes: [
            Note(pitch: "E4", beat: 0, length: 9),
            Note(pitch: "G#4", beat: 0.7, length: 8.6),
            Note(pitch: "B4", beat: 1.4, length: 8.2)
        ],
        reverb: Tone(mix: 0.34, rt: 0.85, tail: 3400))),

    // MARK: 21-hassha  発車ベル
    // The departure bell: a striker beating a gong at 19 Hz for three seconds.
    // Deliberately not tuned prettily, because this one is a signal, not music.
    // It stops dead when the strikes stop, the way it does when the circuit opens,
    // and the platform reverb is what carries the ring out afterwards.
    ("21-hassha", Score(
        bpm: 120,
        melody: [], chords: [], bass: [],
        reverb: Tone(mix: 0.40, rt: 0.87, tail: 3000),
        bells: [Ring(pitch: "A4", beat: 0, length: 6, rate: 19, jitter: 0.16, amp: 0.5)])),
]
