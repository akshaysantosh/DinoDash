import SwiftUI
import AVFoundation

@main
struct DinoDashApp: App {
    @StateObject private var gameState = GameState()

    init() {
        // SKAction.playSoundFileNamed respects the phone's physical silent switch by default —
        // fine for most apps, but wrong for a game's sound effects. `.playback` makes them play
        // regardless of that switch (the Simulator has no such switch, which is why this only
        // showed up on a real device); `.mixWithOthers` avoids interrupting any music playing.
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(gameState)
                .preferredColorScheme(.light)
                .statusBarHidden()
        }
    }
}
