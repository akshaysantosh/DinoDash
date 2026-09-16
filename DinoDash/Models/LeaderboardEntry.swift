import Foundation

/// One entry on the top-3 leaderboard.
struct LeaderboardEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let score: Int

    init(name: String, score: Int) {
        self.id = UUID()
        self.name = name
        self.score = score
    }
}

/// A leaderboard rank (0-based) — only the top 3 are ever kept, so this is exhaustive.
enum Medal: Int, CaseIterable {
    case gold = 0
    case silver = 1
    case bronze = 2
}
