import SwiftUI

struct RootView: View {
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        Group {
            switch gameState.phase {
            case .start:
                StartScreenView()
            case .playing:
                GameView()
            case .gameOver:
                GameOverView()
            }
        }
    }
}
