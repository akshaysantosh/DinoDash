import SwiftUI

struct StartScreenView: View {
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        ZStack {
            Color.bgPage.ignoresSafeArea()
            VStack(spacing: 18) {
                Text("DinoDash")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(Color.ink)
                Text("Tap to jump — dodge the asteroids!")
                    .font(AppFont.body())
                    .foregroundStyle(Color.textSecondary)
                characterPicker
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

    private var characterPicker: some View {
        HStack(spacing: 24) {
            chevronButton("chevron.left") { cycleDino(by: -1) }
            VStack(spacing: 4) {
                Image(gameState.selectedDino.previewImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 78)
                Text(gameState.selectedDino.displayName)
                    .font(AppFont.secondaryDetail())
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(width: 160)
            chevronButton("chevron.right") { cycleDino(by: 1) }
        }
    }

    private func chevronButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.ink)
                .frame(width: 40, height: 40)
                .background(Color.bgCard, in: Circle())
        }
    }

    private func cycleDino(by delta: Int) {
        let all = DinoKind.allCases
        guard let index = all.firstIndex(of: gameState.selectedDino) else { return }
        let next = (index + delta + all.count) % all.count
        gameState.selectedDino = all[next]
    }
}
