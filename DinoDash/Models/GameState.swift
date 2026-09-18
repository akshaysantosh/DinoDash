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
    /// Manual override for the sky — forces the night sky (stars + moon) on regardless of score,
    /// instead of the normal day-to-dusk-to-space progression `GameScene` ramps with survival
    /// time. Sticks across sessions like `selectedDino`, since it's a look preference, not
    /// per-run state.
    @Published var isNightMode: Bool {
        didSet { UserDefaults.standard.set(isNightMode, forKey: nightModeKey) }
    }

    /// Top 3 scores, sorted descending — persisted as `leaderboard`.
    @Published private(set) var leaderboard: [LeaderboardEntry] = []
    /// True while a just-finished run's score qualifies for the top 3 but hasn't been named yet
    /// (drives the name-entry prompt on GameOverView) — the run's score is only actually
    /// inserted into `leaderboard` once a name is given (or discarded via `skipLeaderboardEntry`).
    @Published var qualifiesForLeaderboard = false

    private let selectedDinoKey = "dinodash.selectedDino"
    private let leaderboardKey = "dinodash.leaderboard"
    private let nightModeKey = "dinodash.isNightMode"

    var highScore: Int { leaderboard.first?.score ?? 0 }

    init() {
        if let raw = UserDefaults.standard.string(forKey: selectedDinoKey), let kind = DinoKind(rawValue: raw) {
            selectedDino = kind
        } else {
            selectedDino = .ankylosaurus
        }
        isNightMode = UserDefaults.standard.bool(forKey: nightModeKey)
        if let data = UserDefaults.standard.data(forKey: leaderboardKey),
           let decoded = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) {
            leaderboard = decoded
        }
    }

    func startGame() {
        score = 0
        isNewHighScore = false
        isRoarReady = false
        isPaused = false
        qualifiesForLeaderboard = false
        phase = .playing
    }

    func endGame() {
        isNewHighScore = score > highScore && score > 0
        // Qualifies if there's an open slot, or this run beats the current 3rd place — a tie
        // doesn't displace an existing entry, so ties don't churn the board on every replay.
        qualifiesForLeaderboard = score > 0
            && (leaderboard.count < 3 || score > (leaderboard.last?.score ?? 0))
        phase = .gameOver
    }

    /// Records the just-finished run under `name`, re-sorts, and keeps only the top 3.
    func submitLeaderboardName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = trimmed.isEmpty ? "You" : String(trimmed.prefix(16))
        leaderboard.append(LeaderboardEntry(name: displayName, score: score))
        leaderboard.sort { $0.score > $1.score }
        leaderboard = Array(leaderboard.prefix(3))
        persistLeaderboard()
        qualifiesForLeaderboard = false
    }

    /// Discards the pending qualifying score without adding it to the leaderboard.
    func skipLeaderboardEntry() {
        qualifiesForLeaderboard = false
    }

    private func persistLeaderboard() {
        guard let data = try? JSONEncoder().encode(leaderboard) else { return }
        UserDefaults.standard.set(data, forKey: leaderboardKey)
    }

    func backToStart() {
        phase = .start
    }
}
