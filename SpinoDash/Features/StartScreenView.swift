import SwiftUI

struct StartScreenView: View {
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        ZStack {
            Color.bgPage.ignoresSafeArea()
            VStack(spacing: 18) {
                Text("SpinoDash")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(Color.ink)
                Text("Tap to jump — dodge the asteroids!")
                    .font(AppFont.body())
                    .foregroundStyle(Color.textSecondary)
                if gameState.highScore > 0 {
                    Text("Best: \(gameState.highScore)")
                        .font(AppFont.secondaryDetail())
                        .foregroundStyle(Color.textMuted)
                }
                Button("Tap to Start") { gameState.startGame() }
                    .buttonStyle(.primary)
                    .padding(.horizontal, 40)
            }
            .padding(32)
        }
        .contentShape(Rectangle())
        .onTapGesture { gameState.startGame() }
    }
}
