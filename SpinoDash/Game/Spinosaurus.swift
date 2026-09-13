import SpriteKit

/// Built from a handful of hand-wobbled bezier shapes rather than sprite art — same organic,
/// slightly-imperfect-curve spirit as the bikablo app icons, just filled instead of stroked
/// (a filled silhouette reads far better at speed than a thin outline would).
final class Spinosaurus: SKNode {
    static let bodyColor = SKColor(red: 0.478, green: 0.353, blue: 0.541, alpha: 1)

    private let bodyShape: SKShapeNode
    private let legFront: SKShapeNode
    private let legBack: SKShapeNode
    private var isRunning = false

    override init() {
        let bodyPath = UIBezierPath()
        bodyPath.move(to: CGPoint(x: -34, y: -8))
        bodyPath.addCurve(to: CGPoint(x: -22, y: 16),
                           controlPoint1: CGPoint(x: -35, y: 2), controlPoint2: CGPoint(x: -30, y: 12))
        let spikeXs: [CGFloat] = [-22, -12, -2, 8, 18]
        for i in 0..<(spikeXs.count - 1) {
            let midX = (spikeXs[i] + spikeXs[i + 1]) / 2
            bodyPath.addLine(to: CGPoint(x: spikeXs[i], y: 32))
            bodyPath.addLine(to: CGPoint(x: midX, y: 20))
            bodyPath.addLine(to: CGPoint(x: spikeXs[i + 1], y: 32))
        }
        bodyPath.addCurve(to: CGPoint(x: 32, y: 4),
                           controlPoint1: CGPoint(x: 24, y: 24), controlPoint2: CGPoint(x: 30, y: 12))
        bodyPath.addLine(to: CGPoint(x: 46, y: 0))
        bodyPath.addLine(to: CGPoint(x: 41, y: -8))
        bodyPath.addCurve(to: CGPoint(x: 18, y: -16),
                           controlPoint1: CGPoint(x: 33, y: -12), controlPoint2: CGPoint(x: 26, y: -16))
        bodyPath.addCurve(to: CGPoint(x: -34, y: -8),
                           controlPoint1: CGPoint(x: -2, y: -20), controlPoint2: CGPoint(x: -22, y: -19))
        bodyPath.close()

        bodyShape = SKShapeNode(path: bodyPath.cgPath)
        bodyShape.fillColor = Spinosaurus.bodyColor
        bodyShape.strokeColor = .clear
        bodyShape.zPosition = 2

        func legPath() -> CGPath {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: -5, y: 4))
            p.addLine(to: CGPoint(x: 5, y: 4))
            p.addLine(to: CGPoint(x: 6, y: -18))
            p.addLine(to: CGPoint(x: -6, y: -18))
            p.close()
            return p.cgPath
        }

        legBack = SKShapeNode(path: legPath())
        legBack.fillColor = Spinosaurus.bodyColor
        legBack.strokeColor = .clear
        legBack.position = CGPoint(x: -14, y: -8)
        legBack.zPosition = 1

        legFront = SKShapeNode(path: legPath())
        legFront.fillColor = Spinosaurus.bodyColor
        legFront.strokeColor = .clear
        legFront.position = CGPoint(x: 12, y: -8)
        legFront.zPosition = 3

        super.init()

        addChild(legBack)
        addChild(legFront)
        addChild(bodyShape)

        let body = SKPhysicsBody(rectangleOf: CGSize(width: 58, height: 40), center: CGPoint(x: 0, y: 6))
        body.isDynamic = true
        body.affectedByGravity = true
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.spinosaurus
        body.contactTestBitMask = PhysicsCategory.asteroid | PhysicsCategory.star
        body.collisionBitMask = PhysicsCategory.ground
        self.physicsBody = body
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func startRunning() {
        guard !isRunning else { return }
        isRunning = true
        let forward = SKAction.rotate(toAngle: 0.45, duration: 0.14)
        let back = SKAction.rotate(toAngle: -0.45, duration: 0.14)
        legFront.run(.repeatForever(.sequence([forward, back])), withKey: "run")
        legBack.run(.repeatForever(.sequence([back, forward])), withKey: "run")
    }

    func stopRunning() {
        isRunning = false
        legFront.removeAction(forKey: "run")
        legBack.removeAction(forKey: "run")
        legFront.run(.rotate(toAngle: 0, duration: 0.08))
        legBack.run(.rotate(toAngle: 0, duration: 0.08))
    }

    func jump() {
        stopRunning()
        physicsBody?.velocity = CGVector(dx: 0, dy: 480)
        run(.sequence([
            .group([.scaleX(to: 0.85, y: 1.2, duration: 0.08)]),
            .scaleX(to: 1, y: 1, duration: 0.15)
        ]))
    }

    func landed() {
        startRunning()
        run(.sequence([
            .scaleX(to: 1.2, y: 0.8, duration: 0.06),
            .scaleX(to: 1, y: 1, duration: 0.12)
        ]))
    }

    func crash() {
        stopRunning()
        removeAllActions()
        run(.rotate(byAngle: -1.1, duration: 0.4))
    }

    func reset() {
        removeAllActions()
        zRotation = 0
        xScale = 1
        yScale = 1
        alpha = 1
        physicsBody?.velocity = .zero
        startRunning()
    }
}
