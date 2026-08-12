import Foundation

// Renders every score to WAV and CAF. This is the sole generator for the audio
// in Assets/Melodies.
//
//   swiftc -O AudioEngine.swift Sequencer.swift Scores.swift main.swift -o render
//   ./render                 # writes ../wav and ../caf
//   ./render --out /tmp/x    # elsewhere
//   ./render minuet spring   # only matching names
//   ./render --voice celesta # the original warm platform tone
//
// CAF is linear PCM (LEI16), not IMA4/MA4: the ADPCM codecs are lossy (~39 dB
// SNR), and that quantisation noise is plainly audible in the long quiet reverb
// tails these pieces have. UNNotificationSound accepts linear PCM in a CAF.
//
// The CAF is resampled to 22.05 kHz, which halves the size for no audible cost:
// the PA filter already rolls everything off around 4.6 kHz, so there is nothing
// near the 11 kHz Nyquist to lose. Note this is done here rather than by
// rendering natively at 22.05 kHz. The tine partials reach 13x the fundamental,
// which would alias, so the source stays at 44.1 kHz and afconvert's band-limited
// SRC does the decimation properly.

struct Options {
    var out: String
    var voice: Voice = .electricPiano
    var filters: [String] = []
    var keepWav = false
}

func parseArgs() -> Options {
    let exeDir = URL(fileURLWithPath: CommandLine.arguments[0])
        .deletingLastPathComponent().path
    var opts = Options(out: URL(fileURLWithPath: exeDir).deletingLastPathComponent().path)
    var it = CommandLine.arguments.dropFirst().makeIterator()
    while let a = it.next() {
        switch a {
        case "--out": if let v = it.next() { opts.out = v }
        case "--voice": if let v = it.next() { opts.voice = (v == "celesta") ? .celesta : .electricPiano }
        case "--keep-wav": opts.keepWav = true
        case "--help", "-h":
            print("usage: render [--out DIR] [--voice ep|celesta] [--keep-wav] [nameFilter ...]")
            exit(0)
        default: opts.filters.append(a)
        }
    }
    return opts
}

@discardableResult
func afconvert(_ wav: String, _ caf: String) -> Int32 {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/afconvert")
    p.arguments = ["-f", "caff", "-d", "LEI16@22050", "--src-complexity", "bats", wav, caf]
    do { try p.run() } catch { return -1 }
    p.waitUntilExit()
    return p.terminationStatus
}

let opts = parseArgs()
let fm = FileManager.default
let cafDir = (opts.out as NSString).appendingPathComponent("caf")
try? fm.createDirectory(atPath: cafDir, withIntermediateDirectories: true)

// afconvert needs a file to read, so the 44.1 kHz WAV is written as a scratch
// intermediate and deleted once the CAF exists. Only the CAF is a deliverable.
// --keep-wav puts it alongside caf/ instead, for debugging.
let wavDir = opts.keepWav
    ? (opts.out as NSString).appendingPathComponent("wav")
    : NSTemporaryDirectory().appending("overhead-melodies")
try? fm.createDirectory(atPath: wavDir, withIntermediateDirectories: true)

let tone = Tone()
let start = Date()
var failures = 0

for (name, score) in scores {
    if !opts.filters.isEmpty && !opts.filters.contains(where: { name.contains($0) }) { continue }
    let wav = (wavDir as NSString).appendingPathComponent("\(name).wav")
    let caf = (cafDir as NSString).appendingPathComponent("\(name).caf")
    do {
        try render(to: wav, dur: score.duration, tone: score.reverb ?? tone,
                   build: build(score, voice: opts.voice))
        let status = afconvert(wav, caf)
        if status == 0 {
            if !opts.keepWav { try? fm.removeItem(atPath: wav) }
            print("\(name)  \(String(format: "%.1fs", score.duration))")
        } else {
            print("\(name)  !! afconvert failed (\(status))")
            failures += 1
        }
    } catch {
        print("\(name)  !! \(error)")
        failures += 1
    }
}

print(String(format: "%@ in %.1fs", failures == 0 ? "done" : "\(failures) FAILED",
             Date().timeIntervalSince(start)))
exit(failures == 0 ? 0 : 1)
