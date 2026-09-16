import SpriteKit

/// Common interface for any playable dino character node, so `GameScene` can hold
/// whichever one `DinoKind` picked behind a single type.
protocol PlayableDino: SKNode {
    func startRunning()
    func stopRunning()
    /// Runs a self-contained jump arc (a plain position animation, not physics velocity/gravity —
    /// keeps the jump's visual result deterministic regardless of physics-world timing) and calls
    /// `onLanded` once back on the ground.
    func jump(onLanded: @escaping () -> Void)
    func landed()
    func crash()
    func reset()
}

/// Shared jump-arc timing, matched across all `PlayableDino` implementations so every
/// character clears obstacles the same way regardless of its shape.
///
/// Bumped up from the original 130/0.26/0.30 — that arc felt a bit tight against elevated
/// asteroids, so this gives a bit more height and hang time to clear them more comfortably.
enum PlayableDinoJump {
    static let height: CGFloat = 155
    static let upDuration: TimeInterval = 0.30
    static let downDuration: TimeInterval = 0.34
}
