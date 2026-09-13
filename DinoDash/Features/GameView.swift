import SwiftUI
import SpriteKit

struct GameView: View {
    @EnvironmentObject private var gameState: GameState
    @State private var scene: GameScene?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                if let scene {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                }
                hud
                jumpButton
            }
            .onAppear {
                guard scene == nil else { return }
                let newScene = GameScene(size: proxy.size)
                newScene.scaleMode = .resizeFill
                newScene.gameState = gameState
                scene = newScene
            }
        }
        .ignoresSafeArea()
    }

    private var jumpButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    scene?.jump()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(Color.bgCard)
                        .frame(width: 84, height: 84)
                        .background(Color.accent, in: Circle())
                }
                .padding(.trailing, 28)
                .padding(.bottom, 24)
            }
        }
    }

    private var hud: some View {
        HStack {
            hudPill(label: "SCORE", value: gameState.score)
            Spacer()
            hudPill(label: "BEST", value: gameState.highScore)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private func hudPill(label: String, value: Int) -> some View {
        Text("\(label) \(value)")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.bgCard.opacity(0.85))
            .clipShape(Capsule())
    }
}
