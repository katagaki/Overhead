# Melodies

Notification and departure melodies for Overhead. Everything is synthesised from
scratch, so the only dependencies are Swift and `/usr/bin/afconvert`.

## Building

```
cd Engine
swiftc -O AudioEngine.swift Sequencer.swift Scores.swift main.swift -o render
./render
```

Writes `wav/` (intermediates, gitignored) and `caf/` (ships in the app bundle).
Flags: `--out DIR`, `--voice celesta`, or name filters like `./render minuet`.

## Files

| | |
|---|---|
| `Engine/AudioEngine.swift` | Voices, PA-horn EQ, Schroeder reverb, WAV writer |
| `Engine/Sequencer.swift` | `Score` model, melody/arpeggio/bass layering |
| `Engine/Scores.swift` | The music. Source of truth: edit this to change a tune |
| `Engine/main.swift` | CLI entry point, WAV to CAF conversion |

## House rules for a new melody

These apply to 01-17. The chimes and bells at 18-21 are short signals, not tunes,
and follow neither the four-bar nor the cadence rule. They also use `strikes` and
`bells` rather than `melody`, which routes them to the struck-bell and trembler
voices instead of the electric piano.

- Four bars, and it must cadence onto chord I.
- Minimum tempo 100 BPM.
- Keep melody fundamentals below roughly C6. Higher than that puts the octave
  partials in the ear's most sensitive band and reads as harsh. This is about
  register, not EQ, and cannot be filtered away afterwards.
- Any new voice needs a smooth release. A note that stops while its envelope is
  still open is a click, and a partial switched off rather than faded is a high
  tick on every attack. See `release()` in `AudioEngine.swift`.

## Audio format

CAF is linear PCM (`LEI16`) at 22.05 kHz, roughly 900 KB per piece.

`UNNotificationSound` also accepts MA4/IMA4, mu-law and a-law, but those are
lossy. IMA4 measured ~39 dB SNR against the source, and that quantisation noise
is audible in the long quiet reverb tails. Linear PCM is bit-exact.

22.05 kHz halves the size for no audible cost, since the PA filter already rolls
off around 4.6 kHz. Measured 62-83 dB SNR against the 44.1 kHz source. The
resampling is done by `afconvert`, not by rendering natively at 22.05 kHz: the
tine partials reach 13x the fundamental and would alias past an 11 kHz Nyquist,
so the WAV intermediates stay at 44.1 kHz for the band-limited SRC to decimate.

## Provenance

Numbering groups the set: **01-10 are original compositions** written for this
app, **11-17 are arrangements** of public domain works, each named in a comment
above its score. The arrangements are the traditional *Sakura Sakura* and
*Auld Lang Syne*, Mozart's Sonata K. 545, Pachelbel's *Canon in D*, Beethoven's
*Ode an die Freude*, the Minuet in G (BWV Anh. 114), and Vivaldi's
*La primavera*.

**18-21 are chimes and bells** rather than melodies: struck tones left to ring,
with no arpeggio or bass under them. All four are original.
