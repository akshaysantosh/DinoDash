import AVFoundation

/// Looping calm background track (`music.caf`, an original synthesised loop — see
/// `Scripts/generate_music.py`). Sound effects are separate and unaffected by the mute toggle.
/// The audio session itself (`.playback`, mixes with other audio) is configured in `DinoDashApp`.
final class MusicPlayer {
    static let shared = MusicPlayer()

    private static let playingVolume: Float = 0.3
    private var player: AVAudioPlayer?

    private init() {}

    func start(muted: Bool) {
        if player == nil {
            guard let url = Bundle.main.url(forResource: "music", withExtension: "caf"),
                  let p = try? AVAudioPlayer(contentsOf: url) else { return }
            p.numberOfLoops = -1
            p.volume = muted ? 0 : MusicPlayer.playingVolume
            p.prepareToPlay()
            player = p
        }
        if player?.isPlaying == false { player?.play() }
        setMuted(muted)
    }

    /// Fades rather than cutting, so toggling doesn't click. The track keeps running while
    /// muted so unmuting picks up mid-loop instead of restarting.
    func setMuted(_ muted: Bool) {
        player?.setVolume(muted ? 0 : MusicPlayer.playingVolume, fadeDuration: 0.4)
    }
}
