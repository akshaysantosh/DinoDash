import SwiftUI
import SpriteKit

struct GameView: View {
    @EnvironmentObject private var gameState: GameState
    @State private var scene: GameScene?

    /// A deeper, fierier red than the shared design system's `accent`, so the roar button reads
    /// distinctly from the jump button rather than as a second copy of the same accent color.
    private static let roarActiveColor = Color(hex: "#c23b1e")

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                if let scene {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                }
                hud
                jumpButton
                roarButton
                pauseOverlay
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

    private var roarButton: some View {
        VStack {
            Spacer()
            HStack {
                Button {
                    scene?.roar()
                } label: {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(Color.bgCard)
                        .frame(width: 84, height: 84)
                        .background(
                            gameState.isRoarReady ? GameView.roarActiveColor : Color.textFaint.opacity(0.5),
                            in: Circle()
                        )
                }
                .disabled(!gameState.isRoarReady)
                .padding(.leading, 28)
                .padding(.bottom, 24)
                Spacer()
            }
        }
    }

    private var hud: some View {
        HStack {
            hudPill(label: "SCORE", value: gameState.score)
            Spacer()
            pauseButton
            Spacer()
            hudPill(label: "BEST", value: gameState.highScore)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var pauseButton: some View {
        Button {
            scene?.togglePause()
        } label: {
            Image(systemName: "pause.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.ink)
                .frame(width: 44, height: 44)
                .background(Color.bgCard.opacity(0.85), in: Circle())
        }
    }

    /// A dim scrim with the current dino's own preview art in the foreground — reuses the same
    /// image built for the Start screen's character picker rather than needing separate art.
    private var pauseOverlay: some View {
        Group {
            if gameState.isPaused {
                ZStack {
                    Color.black.opacity(0.55).ignoresSafeArea()
                    VStack(spacing: 14) {
                        Image(gameState.selectedDino.previewImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 190, height: 114)
                        Text("Paused")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundStyle(Color.ink)
                        Button("Resume") { scene?.togglePause() }
                            .buttonStyle(.primary)
                            .padding(.horizontal, 36)
                    }
                    .padding(28)
                    .background(Color.bgPage, in: RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
                    .padding(.horizontal, 70)
                }
                .contentShape(Rectangle())
                .onTapGesture { scene?.togglePause() }
            }
        }
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
