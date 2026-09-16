import SwiftUI

struct GameOverView: View {
    @EnvironmentObject private var gameState: GameState
    @State private var nameInput = ""

    private var headline: String {
        if gameState.isNewHighScore { return "New High Score!" }
        if gameState.qualifiesForLeaderboard { return "Top 3 Score!" }
        return "Game Over"
    }

    private var isCelebrating: Bool {
        gameState.isNewHighScore || gameState.qualifiesForLeaderboard
    }

    var body: some View {
        ZStack {
            Color.bgPage.ignoresSafeArea()
            VStack(spacing: 14) {
                Text(headline)
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(isCelebrating ? Color.accentSuccess : Color.ink)
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
                Button("Change Dino") { gameState.backToStart() }
                    .font(AppFont.secondaryDetail())
                    .foregroundStyle(Color.textSecondary)
                    .underline()
                    .padding(.top, 2)
            }
            .padding(32)
        }
        .contentShape(Rectangle())
        .onTapGesture { gameState.startGame() }
        .alert(
            "You made the leaderboard!",
            isPresented: Binding(
                get: { gameState.qualifiesForLeaderboard },
                set: { isPresented in
                    if !isPresented { gameState.skipLeaderboardEntry() }
                }
            )
        ) {
            TextField("Your name", text: $nameInput)
            Button("Skip") {
                nameInput = ""
                gameState.skipLeaderboardEntry()
            }
            Button("Save") {
                gameState.submitLeaderboardName(nameInput)
                nameInput = ""
            }
        } message: {
            Text("Score of \(gameState.score) — enter a name to show on the leaderboard.")
        }
    }
}
