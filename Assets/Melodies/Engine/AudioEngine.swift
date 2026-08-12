import Foundation

let SR = 44100.0

// MARK: - Pitch

private let pitchClasses: [String: Int] = [
    "C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5,
    "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11,
]

func noteFreq(_ name: String) -> Double {
    let octave = Int(String(name.last!))!
    let pc = pitchClasses[String(name.dropLast())]!
    return 440.0 * pow(2.0, Double(pc - 9 + (octave - 4) * 12) / 12.0)
}

// MARK: - Envelopes

@inline(__always) func env(_ t: Double, _ attack: Double, _ decay: Double) -> Double {
    if t < attack {
        let a = t / attack
        return a * a * (3 - 2 * a)
    }
    return exp(-(t - attack) / decay)
}

@inline(__always) func smoothstep(_ x: Double) -> Double {
    let c = min(max(x, 0), 1)
    return c * c * (3 - 2 * c)
}

/// Fade the last `rel` seconds to zero. Without this a note stops while its
/// envelope is still ~30% open, and that step is a click on every note.
@inline(__always) func release(_ t: Double, _ dur: Double, _ rel: Double) -> Double {
    t < dur - rel ? 1.0 : smoothstep((dur - t) / rel)
}

// MARK: - Voices

typealias Partial = (ratio: Double, amp: Double, decay: Double)

let MELODY: [Partial] = [(1.0, 1.0, 0.95), (2.0, 0.075, 0.17)]
let ARP: [Partial]    = [(1.0, 1.0, 0.55), (2.0, 0.050, 0.12)]
let BASS: [Partial]   = [(1.0, 1.0, 1.30), (2.0, 0.045, 0.35)]

let EP_BODY: [Partial] = [(2.0, 0.32, 0.85), (3.0, 0.095, 0.42), (5.0, 0.030, 0.22)]
let EP_TINE: [Partial] = [(4.0, 0.260, 0.115), (6.0, 0.165, 0.080),
                          (9.0, 0.070, 0.050), (13.0, 0.022, 0.032)]

func tone(_ ch: inout [Double], start: Double, freq: Double, amp: Double,
          dur: Double, partials: [Partial], attack: Double = 0.028) {
    let i0 = Int(start * SR), ns = Int(dur * SR)
    let rel = min(0.030, dur * 0.3)
    for i in 0..<ns {
        let j = i0 + i
        if j >= ch.count { break }
        let t = Double(i) / SR
        var s = 0.0
        for p in partials {
            s += p.amp * sin(2 * .pi * freq * p.ratio * t) * env(t, attack, p.decay)
        }
        ch[j] += s * amp * env(t, attack, dur * 0.85) * release(t, dur, rel)
    }
}

/// Rhodes-style electric piano: long-decaying detuned body plus a short tine
/// cluster for the attack bell. The tine is faded rather than switched off: a
/// hard cut at 4-13x the fundamental is an audible high tick.
func eptone(_ ch: inout [Double], start: Double, freq: Double, amp: Double,
            dur: Double, attack: Double = 0.005, tine: Double = 1.0,
            trem: Double = 4.6, depth: Double = 0.12, detune: Double = 0.0013) {
    let i0 = Int(start * SR), ns = Int(dur * SR)
    let f1 = freq * (1 - detune), f2 = freq * (1 + detune)
    let w1 = 2 * .pi * f1, w2 = 2 * .pi * f2, w = 2 * Double.pi * freq
    let tineHold = 0.26, tineFade = 0.12
    let tineEnd = Int((tineHold + tineFade) * SR)
    let rel = min(0.030, dur * 0.3)
    for i in 0..<ns {
        let j = i0 + i
        if j >= ch.count { break }
        let t = Double(i) / SR
        var s = 0.5 * (sin(w1 * t) + sin(w2 * t)) * env(t, attack, dur * 0.62)
        for p in EP_BODY {
            s += p.amp * sin(w * p.ratio * t) * env(t, attack, p.decay)
        }
        if i < tineEnd && tine > 0 {
            let tw = t < tineHold ? 1.0 : smoothstep((tineHold + tineFade - t) / tineFade)
            for p in EP_TINE {
                s += tine * tw * p.amp * sin(w * p.ratio * t) * env(t, 0.004, p.decay)
            }
        }
        let lfo = 1.0 - depth * 0.5 * (1 - cos(2 * .pi * trem * t))
        ch[j] += s * amp * env(t, attack, dur * 0.85) * lfo * release(t, dur, rel)
    }
}

// MARK: - Struck bell

// Tubular-bell partials: mildly inharmonic, so it reads as struck metal rather
// than a pitched instrument. The fundamental rings for seconds while the upper
// partials die almost at once, which is what gives a chime its bright attack and
// hollow tail. Playing a chime on the piano voice instead just sounds like a
// piano, no matter what notes it uses.
let CHIME_PARTIALS: [Partial] = [
    (1.00, 1.00, 1.60), (2.00, 0.45, 0.80), (3.01, 0.22, 0.42),
    (4.17, 0.12, 0.25), (5.43, 0.07, 0.16), (6.79, 0.04, 0.11),
]

/// `dur` is how long the strike is allowed to ring, not how long a key is held.
/// It must comfortably exceed the partial decays or the bell gets chopped off
/// while still sounding, which reads as a held note stopping rather than a bell
/// dying away. `decayScale` stretches the decays for a physically larger bell.
func bellTone(_ ch: inout [Double], start: Double, freq: Double, amp: Double,
              dur: Double, attack: Double = 0.002, decayScale: Double = 1.0) {
    let i0 = Int(start * SR), ns = Int(dur * SR)
    // long, gentle release: by the time it engages the bell is already faint, so
    // it removes the cutoff without audibly shortening the ring
    let rel = min(0.9, dur * 0.35)
    for i in 0..<ns {
        let j = i0 + i
        if j >= ch.count { break }
        let t = Double(i) / SR
        var s = 0.0
        for p in CHIME_PARTIALS {
            s += p.amp * sin(2 * .pi * freq * p.ratio * t)
                 * env(t, attack, p.decay * decayScale)
        }
        ch[j] += s * amp * release(t, dur, rel)
    }
}

// MARK: - Electric trembler bell

// A departure bell is a striker beating a gong roughly twenty times a second.
// The "brrrr" is not a timbre, it is that restrike rate: one gong hit sounds like
// a chime, and the same hit repeated at 19 Hz is a bell. Partials are inharmonic
// (a struck metal disc has no harmonic series) and each strike dies in under a
// tenth of a second, so the overlap between strikes is what fills the sound in.
let BELL_PARTIALS: [Partial] = [
    (1.00, 1.00, 0.090), (2.41, 0.62, 0.070), (3.83, 0.40, 0.055),
    (5.17, 0.26, 0.045), (7.02, 0.15, 0.035), (9.31, 0.08, 0.028),
]

func trembler(_ ch: inout [Double], start: Double, freq: Double, amp: Double,
              dur: Double, rate: Double, jitter: Double, seed: UInt64) {
    // deterministic PRNG so renders stay reproducible
    var state = seed
    func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(UInt64(1) << 53)
    }
    let period = 1.0 / rate
    let tail = 0.18
    let tailSamples = Int(tail * SR)
    var k = 0
    while Double(k) * period < dur {
        let t0 = Double(k) * period
        // a real striker does not hit identically twice; without this it buzzes
        // like a synth tone instead of rattling like a bell
        let a = amp * (1.0 - jitter * next())
        let detune = 1.0 + (next() - 0.5) * 0.004
        let i0 = Int((start + t0) * SR)
        for i in 0..<tailSamples {
            let j = i0 + i
            if j >= ch.count { break }
            let t = Double(i) / SR
            var s = 0.0
            for p in BELL_PARTIALS {
                s += p.amp * sin(2 * .pi * freq * detune * p.ratio * t) * env(t, 0.0012, p.decay)
            }
            // only a fade-in: the ring ends by the last strike decaying, which is
            // what happens when the circuit opens
            ch[j] += s * a * smoothstep((t0 + t) / 0.015)
        }
        k += 1
    }
}

// MARK: - Filters (RBJ biquads)

func biquad(_ ch: inout [Double], _ b0: Double, _ b1: Double, _ b2: Double,
            _ a1: Double, _ a2: Double) {
    var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0
    for i in 0..<ch.count {
        let x0 = ch[i]
        let y0 = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2 = x1; x1 = x0
        y2 = y1; y1 = y0
        ch[i] = y0
    }
}

func hp(_ ch: inout [Double], _ f: Double, _ q: Double = 0.707) {
    let w = 2 * .pi * f / SR, c = cos(w), s = sin(w), al = s / (2 * q)
    let a0 = 1 + al
    biquad(&ch, (1 + c) / 2 / a0, -(1 + c) / a0, (1 + c) / 2 / a0, -2 * c / a0, (1 - al) / a0)
}

func lp(_ ch: inout [Double], _ f: Double, _ q: Double = 0.707) {
    let w = 2 * .pi * f / SR, c = cos(w), s = sin(w), al = s / (2 * q)
    let a0 = 1 + al
    biquad(&ch, (1 - c) / 2 / a0, (1 - c) / a0, (1 - c) / 2 / a0, -2 * c / a0, (1 - al) / a0)
}

func peak(_ ch: inout [Double], _ f: Double, _ gainDB: Double, _ q: Double = 1.0) {
    let A = pow(10, gainDB / 40), w = 2 * .pi * f / SR
    let c = cos(w), s = sin(w), al = s / (2 * q), a0 = 1 + al / A
    biquad(&ch, (1 + al * A) / a0, -2 * c / a0, (1 - al * A) / a0, -2 * c / a0, (1 - al / A) / a0)
}

func paColor(_ ch: inout [Double], amount: Double, top: Double, cut: Double) {
    let dry = ch
    hp(&ch, 150)
    lp(&ch, top); lp(&ch, top); lp(&ch, top * 1.3)
    peak(&ch, 2600, cut, 0.9)
    peak(&ch, 900, 1.2, 0.8)
    for i in 0..<ch.count {
        ch[i] = ch[i] * amount + dry[i] * (1 - amount) * 0.45
    }
}

// MARK: - Reverb

func comb(_ x: [Double], _ d: Int, _ g: Double) -> [Double] {
    var y = x
    if d < y.count {
        for i in d..<y.count { y[i] += y[i - d] * g }
    }
    return y
}

func allpass(_ x: [Double], _ d: Int, _ g: Double) -> [Double] {
    var y = [Double](repeating: 0, count: x.count)
    for i in 0..<x.count {
        let v = i >= d ? x[i - d] : 0
        let yv = i >= d ? y[i - d] : 0
        y[i] = -g * x[i] + v + g * yv
    }
    return y
}

func concourse(_ ch: inout [Double], mix: Double, rt: Double,
               predelay: Double = 0.040, seed: Int, tail: Double) {
    let pd = Int(predelay * SR)
    var src = [Double](repeating: 0, count: pd)
    src.append(contentsOf: ch[0..<(ch.count - pd)])
    lp(&src, tail * 1.27)

    let delays = [1557, 1617, 1491, 1422, 1277, 1356].map { $0 + seed * 23 }
    var wet = [Double](repeating: 0, count: src.count)
    for d in delays {
        let c = comb(src, d, rt)
        for i in 0..<wet.count { wet[i] += c[i] / Double(delays.count) }
    }
    wet = allpass(wet, 225 + seed * 7, 0.55)
    wet = allpass(wet, 556 + seed * 11, 0.50)
    lp(&wet, tail); lp(&wet, tail)

    for i in 0..<ch.count {
        ch[i] = ch[i] * (1 - mix * 0.35) + wet[i] * mix
    }
}

// MARK: - Render

struct Tone {
    var pa = 0.62, mix = 0.24, rt = 0.80, top = 4600.0, cut = -2.0, tail = 2900.0
}

func render(to path: String, dur: Double, tone t: Tone,
            build: (inout [Double], inout [Double]) -> Void) throws {
    let total = Int((dur + 1.8) * SR)
    var L = [Double](repeating: 0, count: total)
    var R = [Double](repeating: 0, count: total)
    build(&L, &R)

    paColor(&L, amount: t.pa, top: t.top, cut: t.cut)
    concourse(&L, mix: t.mix, rt: t.rt, seed: 0, tail: t.tail)
    paColor(&R, amount: t.pa, top: t.top, cut: t.cut)
    concourse(&R, mix: t.mix, rt: t.rt, seed: 1, tail: t.tail)

    var pk = 0.0
    for i in 0..<total { pk = max(pk, max(abs(L[i]), abs(R[i]))) }
    let g = 0.78 / (pk == 0 ? 1 : pk)

    var pcm = [Int16](repeating: 0, count: total * 2)
    for i in 0..<total {
        pcm[i * 2]     = Int16(max(-32767, min(32767, Int(L[i] * g * 32767))))
        pcm[i * 2 + 1] = Int16(max(-32767, min(32767, Int(R[i] * g * 32767))))
    }
    try writeWAV(path: path, pcm: pcm, channels: 2, rate: Int(SR))
}

func writeWAV(path: String, pcm: [Int16], channels: Int, rate: Int) throws {
    var d = Data()
    func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }
    func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }

    let bytes = pcm.count * 2
    d.append(contentsOf: Array("RIFF".utf8)); u32(UInt32(36 + bytes))
    d.append(contentsOf: Array("WAVE".utf8))
    d.append(contentsOf: Array("fmt ".utf8)); u32(16)
    u16(1); u16(UInt16(channels)); u32(UInt32(rate))
    u32(UInt32(rate * channels * 2)); u16(UInt16(channels * 2)); u16(16)
    d.append(contentsOf: Array("data".utf8)); u32(UInt32(bytes))
    pcm.withUnsafeBufferPointer { d.append(contentsOf: UnsafeRawBufferPointer($0)) }
    try d.write(to: URL(fileURLWithPath: path))
}
