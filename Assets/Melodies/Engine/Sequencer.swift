import Foundation

// MARK: - Score model

struct Note {
    let pitch: String, beat: Double, length: Double
}

struct ChordSpan {
    let beat: Double, length: Double, notes: [String]
}

/// One ring of an electric trembler bell: a pitch beaten at `rate` strikes per
/// second for `length` beats.
struct Ring {
    let pitch: String, beat: Double, length: Double
    var rate = 19.0
    var jitter = 0.14
    var amp = 0.5
}

struct Score {
    let bpm: Double
    let melody: [Note]
    let chords: [ChordSpan]
    let bass: [Note]
    var arpDiv = 0.5
    var arpAmp = 0.115
    var arpPattern = [0, 1, 2, 1]
    var melAmp = 0.46
    var bassAmp = 0.17
    /// Struck bell tones, voiced on CHIME_PARTIALS rather than the piano.
    var strikes: [Note] = []
    /// Stretches strike decays for a physically larger bell.
    var strikeDecay = 1.0
    /// Overrides the global tone, so bells can sit in a wetter space than tunes.
    var reverb: Tone? = nil
    /// Trembler bell rings.
    var bells: [Ring] = []

    /// Seconds of audio the score occupies, before the reverb tail.
    var duration: Double {
        let m = melody.map { $0.beat + $0.length }.max() ?? 0
        let s = strikes.map { $0.beat + $0.length }.max() ?? 0
        let b = bells.map { $0.beat + $0.length }.max() ?? 0
        return max(m, max(s, b)) * (60.0 / bpm) + 1.4
    }
}

// MARK: - Voicing

enum Layer {
    case melody, arp, bass

    /// Tine amount and decay stretch when voiced as electric piano.
    var ep: (tine: Double, stretch: Double) {
        switch self {
        case .melody: return (1.00, 1.35)
        case .arp:    return (0.55, 1.15)
        case .bass:   return (0.30, 1.30)
        }
    }

    var partials: [Partial] {
        switch self {
        case .melody: return MELODY
        case .arp:    return ARP
        case .bass:   return BASS
        }
    }
}

enum Voice { case celesta, electricPiano }

private func put(_ L: inout [Double], _ R: inout [Double], voice: Voice,
                 t: Double, freq: Double, amp: Double, dur: Double,
                 layer: Layer, attack: Double, pan: Double) {
    switch voice {
    case .electricPiano:
        let (tine, stretch) = layer.ep
        let d = dur * stretch
        eptone(&L, start: t, freq: freq, amp: amp * (1 - pan) * 1.4, dur: d,
               attack: 0.005, tine: tine)
        eptone(&R, start: t + 0.004, freq: freq, amp: amp * pan * 1.4, dur: d,
               attack: 0.005, tine: tine)
    case .celesta:
        tone(&L, start: t, freq: freq, amp: amp * (1 - pan) * 1.4, dur: dur,
             partials: layer.partials, attack: attack)
        tone(&R, start: t + 0.004, freq: freq, amp: amp * pan * 1.4, dur: dur,
             partials: layer.partials, attack: attack)
    }
}

func build(_ score: Score, voice: Voice) -> (inout [Double], inout [Double]) -> Void {
    return { L, R in
        let spb = 60.0 / score.bpm

        for note in score.melody {
            let d = min(2.3, max(1.15, note.length * spb * 1.7))
            let onBeat = note.beat.truncatingRemainder(dividingBy: 1) == 0
            let amp = score.melAmp * (onBeat ? 1.0 : 0.87)
            put(&L, &R, voice: voice, t: note.beat * spb, freq: noteFreq(note.pitch),
                amp: amp, dur: d, layer: .melody, attack: 0.026, pan: 0.5)
        }

        for span in score.chords {
            var k = 0
            var b = span.beat
            while b < span.beat + span.length - 1e-9 {
                let idx = score.arpPattern[k % score.arpPattern.count] % span.notes.count
                let pan = 0.5 + (k % 2 == 1 ? 0.17 : -0.17)
                put(&L, &R, voice: voice, t: b * spb, freq: noteFreq(span.notes[idx]),
                    amp: score.arpAmp, dur: 1.15, layer: .arp, attack: 0.020, pan: pan)
                b += score.arpDiv
                k += 1
            }
        }

        for note in score.bass {
            put(&L, &R, voice: voice, t: note.beat * spb, freq: noteFreq(note.pitch),
                amp: score.bassAmp, dur: min(2.6, note.length * spb * 1.3),
                layer: .bass, attack: 0.045, pan: 0.5)
        }

        // Struck bells ignore the voice setting: a chime is a chime either way.
        for n in score.strikes {
            let f = noteFreq(n.pitch), d = n.length * spb
            bellTone(&L, start: n.beat * spb, freq: f, amp: score.melAmp * 0.7, dur: d,
                     decayScale: score.strikeDecay)
            bellTone(&R, start: n.beat * spb + 0.004, freq: f * 1.0007,
                     amp: score.melAmp * 0.7, dur: d, decayScale: score.strikeDecay)
        }

        for r in score.bells {
            let f = noteFreq(r.pitch), d = r.length * spb
            trembler(&L, start: r.beat * spb, freq: f, amp: r.amp * 0.7, dur: d,
                     rate: r.rate, jitter: r.jitter, seed: 0x9E3779B97F4A7C15)
            trembler(&R, start: r.beat * spb + 0.005, freq: f * 1.0011, amp: r.amp * 0.7,
                     dur: d, rate: r.rate, jitter: r.jitter, seed: 0x85EBCA77C2B2AE63)
        }
    }
}
