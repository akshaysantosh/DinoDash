import SpriteKit

/// Common interface for any playable dino character node, so `GameScene` can hold
/// whichever one `DinoKind` picked behind a single type.
protocol PlayableDino: SKNode {
    func startRunning()
    func stopRunning()
    func jump()
    func landed()
    func crash()
    func reset()
}
