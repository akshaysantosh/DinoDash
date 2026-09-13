import SwiftUI

struct GameOverView: View {
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        ZStack {
            Color.bgPage.ignoresSafeArea()
            VStack(spacing: 14) {
                Text(gameState.isNewHighScore ? "New High Score!" : "Game Over")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(gameState.isNewHighScore ? Color.accentSuccess : Color.ink)
                Text("\(gameState.score)")
                    .font(.system(size: 54, weight: .heavy))
                    .foregroundStyle(Color.ink)
                Text("Best: \(gameState.highScore)")
                    .font(AppFont.secondaryDetail())
                    .foregroundStyle(Color.textMuted)
                Button("Tap to Retry") { gameState.startGame() }
                    .buttonStyle(.primary)
                    .padding(.horizontal, 40)
                    .padding(.top, 6)
            }
            .padding(32)
        }
        .contentShape(Rectangle())
        .onTapGesture { gameState.startGame() }
    }
}
