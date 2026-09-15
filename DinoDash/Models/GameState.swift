import Foundation

/// Shared between the SwiftUI shell (start/HUD/game-over screens) and the SpriteKit scene,
/// which writes `score` live during play and calls `endGame` on collision.
final class GameState: ObservableObject {
    enum Phase {
        case start
        case playing
        case gameOver
    }

    @Published var phase: Phase = .start
    @Published var score: Int = 0
    @Published var isNewHighScore = false
    /// Whether the roar power-move is currently charged. `GameScene` flips this on every 100
    /// points survived and off again the moment it's used — a single charge, no banking.
    @Published var isRoarReady = false
    @Published var isPaused = false
    @Published var selectedDino: DinoKind {
        didSet { UserDefaults.standard.set(selectedDino.rawValue, forKey: selectedDinoKey) }
    }

    private let highScoreKey = "dinodash.highScore"
    private let selectedDinoKey = "dinodash.selectedDino"

    var highScore: Int {
        get { UserDefaults.standard.integer(forKey: highScoreKey) }
        set { UserDefaults.standard.set(newValue, forKey: highScoreKey) }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: selectedDinoKey), let kind = DinoKind(rawValue: raw) {
            selectedDino = kind
        } else {
            selectedDino = .ankylosaurus
        }
    }

    func startGame() {
        score = 0
        isNewHighScore = false
        isRoarReady = false
        isPaused = false
        phase = .playing
    }

    func endGame() {
        if score > highScore {
            highScore = score
            isNewHighScore = true
        } else {
            isNewHighScore = false
        }
        phase = .gameOver
    }

    func backToStart() {
        phase = .start
    }
}
