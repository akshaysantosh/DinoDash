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
enum PlayableDinoJump {
    static let height: CGFloat = 130
    static let upDuration: TimeInterval = 0.26
    static let downDuration: TimeInterval = 0.30
}
