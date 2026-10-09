import SwiftUI

/// Round music on/off button shared by the Start screen and the in-game HUD. Mutes only the
/// background music — jump, roar and other effects keep playing.
struct MusicToggleButton: View {
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        Button {
            gameState.isMusicMuted.toggle()
        } label: {
            ZStack {
                Image(systemName: "music.note")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(gameState.isMusicMuted ? Color.textFaint : Color.ink)
                if gameState.isMusicMuted {
                    Capsule()
                        .fill(Color.accent)
                        .frame(width: 24, height: 2.5)
                        .rotationEffect(.degrees(-45))
                }
            }
            .frame(width: 44, height: 44)
            .background(Color.bgCard.opacity(0.85), in: Circle())
        }
        .accessibilityLabel(gameState.isMusicMuted ? "Turn music on" : "Turn music off")
    }
}
