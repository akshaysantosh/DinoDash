import SpriteKit

final class Asteroid: SKShapeNode {
    /// Ground-level asteroids must be jumped over; elevated ones sit in the jump's flight path,
    /// so the correct move is to *not* jump — the only bit of real decision-making this game
    /// asks for, on top of the single tap-to-jump input.
    let isElevated: Bool

    init(radius: CGFloat, isElevated: Bool) {
        self.isElevated = isElevated
        super.init()

        let path = UIBezierPath()
        let points = 9
        let step = CGFloat.pi * 2 / CGFloat(points)
        for i in 0..<points {
            let angle = CGFloat(i) * step
            let wobble = CGFloat.random(in: 0.75...1.15)
            let r = radius * wobble
            let point = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.close()

        self.path = path.cgPath
        fillColor = SKColor(red: 0.42, green: 0.38, blue: 0.36, alpha: 1)
        strokeColor = SKColor(red: 0.28, green: 0.25, blue: 0.24, alpha: 1)
        lineWidth = 2

        let body = SKPhysicsBody(circleOfRadius: radius * 0.8)
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.asteroid
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = 0
        physicsBody = body

        run(.repeatForever(.rotate(byAngle: CGFloat.random(in: -1...1), duration: 4)))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
