import AVFoundation

/// One-shot preview of a notification sound, played when one is picked.
///
/// The whole point is that it mixes. The default `.soloAmbient` category would
/// pause whatever the user is listening to for the two seconds a chime takes,
/// which is a bad trade for a preview, so this uses `.ambient` with
/// `.mixWithOthers`.
///
/// It also never deactivates the session. Deactivating is the call that
/// interrupts and resumes other players, and PiP owns that lifecycle here.
@MainActor
final class NotificationSoundPreview {

    static let shared = NotificationSoundPreview()

    private var player: AVAudioPlayer?

    private init() {}

    func play(_ sound: NotificationSound) {
        // Switching sounds quickly should replace the preview, not layer it.
        player?.stop()
        player = nil

        // .system has no file of ours to play.
        guard let fileName = sound.fileName,
              let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            return
        }

        let session = AVAudioSession.sharedInstance()
        // Leave a session another feature configured alone: PiP sets
        // .playback/.mixWithOthers, which already mixes, and stamping .ambient
        // over it would break PiP audio.
        if !session.categoryOptions.contains(.mixWithOthers) {
            try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        }
        try? session.setActive(true, options: [])

        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.prepareToPlay()
        player.play()
        self.player = player
    }
}
