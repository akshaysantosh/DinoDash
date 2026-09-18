import SpriteKit

final class Star: SKShapeNode {
    override init() {
        super.init()

        let path = UIBezierPath()
        let points = 5
        let outerRadius: CGFloat = 12
        let innerRadius: CGFloat = 5
        var angle = -CGFloat.pi / 2
        let step = CGFloat.pi / CGFloat(points)
        for i in 0..<(points * 2) {
            let r = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            angle += step
        }
        path.close()

        self.path = path.cgPath
        fillColor = SKColor(red: 0.788, green: 0.514, blue: 0.165, alpha: 1)
        strokeColor = .clear

        let body = SKPhysicsBody(circleOfRadius: outerRadius)
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.star
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = 0
        physicsBody = body

        run(.repeatForever(.sequence([.scale(to: 1.15, duration: 0.6), .scale(to: 1.0, duration: 0.6)])))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
