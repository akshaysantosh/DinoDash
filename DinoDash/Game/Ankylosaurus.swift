import SpriteKit

/// Same hand-tuned bezier-shape technique as Spinosaurus — a low, wide, armored body with
/// rounded back plates (not pointed spikes, to avoid reading as quills) and the defining
/// ankylosaurus feature: a round club at the tail tip, built as its own circle node.
final class Ankylosaurus: SKNode, PlayableDino {
    static let bodyColor = SKColor(red: 0.376, green: 0.290, blue: 0.439, alpha: 1)

    private let bodyShape: SKShapeNode
    private let clubShape: SKShapeNode
    private let legFront: SKShapeNode
    private let legBack: SKShapeNode
    private var isRunning = false

    override init() {
        let bodyPath = UIBezierPath()
        bodyPath.move(to: CGPoint(x: -52, y: -4))
        bodyPath.addCurve(to: CGPoint(x: -30, y: -2),
                           controlPoint1: CGPoint(x: -46, y: -8), controlPoint2: CGPoint(x: -38, y: -8))
        bodyPath.addCurve(to: CGPoint(x: -20, y: 6),
                           controlPoint1: CGPoint(x: -27, y: 2), controlPoint2: CGPoint(x: -24, y: 5))

        // Seven small rounded armor-plate bumps along the back (not pointed spikes).
        bodyPath.addCurve(to: CGPoint(x: -16, y: 13),
                           controlPoint1: CGPoint(x: -18.5, y: 12), controlPoint2: CGPoint(x: -17.5, y: 13))
        bodyPath.addCurve(to: CGPoint(x: -12.5, y: 10),
                           controlPoint1: CGPoint(x: -14.5, y: 13), controlPoint2: CGPoint(x: -14, y: 14))
        bodyPath.addCurve(to: CGPoint(x: -9, y: 15),
                           controlPoint1: CGPoint(x: -11, y: 14), controlPoint2: CGPoint(x: -10.5, y: 15))
        bodyPath.addCurve(to: CGPoint(x: -5.5, y: 11),
                           controlPoint1: CGPoint(x: -7.5, y: 15), controlPoint2: CGPoint(x: -7, y: 15))
        bodyPath.addCurve(to: CGPoint(x: -2, y: 16),
                           controlPoint1: CGPoint(x: -4, y: 15), controlPoint2: CGPoint(x: -3.5, y: 16))
        bodyPath.addCurve(to: CGPoint(x: 1.5, y: 11),
                           controlPoint1: CGPoint(x: -0.5, y: 16), controlPoint2: CGPoint(x: 0, y: 15))
        bodyPath.addCurve(to: CGPoint(x: 5, y: 16),
                           controlPoint1: CGPoint(x: 3, y: 15), controlPoint2: CGPoint(x: 3.5, y: 16))
        bodyPath.addCurve(to: CGPoint(x: 8.5, y: 10),
                           controlPoint1: CGPoint(x: 6.5, y: 16), controlPoint2: CGPoint(x: 7, y: 14))
        bodyPath.addCurve(to: CGPoint(x: 12, y: 15),
                           controlPoint1: CGPoint(x: 10, y: 14), controlPoint2: CGPoint(x: 10.5, y: 15))
        bodyPath.addCurve(to: CGPoint(x: 15.5, y: 8),
                           controlPoint1: CGPoint(x: 13.5, y: 15), controlPoint2: CGPoint(x: 14, y: 12))
        bodyPath.addCurve(to: CGPoint(x: 19, y: 13),
                           controlPoint1: CGPoint(x: 17, y: 12), controlPoint2: CGPoint(x: 17.5, y: 13))
        bodyPath.addCurve(to: CGPoint(x: 22.5, y: 6),
                           controlPoint1: CGPoint(x: 20.5, y: 13), controlPoint2: CGPoint(x: 21, y: 10))
        bodyPath.addCurve(to: CGPoint(x: 26, y: 11),
                           controlPoint1: CGPoint(x: 24, y: 10), controlPoint2: CGPoint(x: 24.5, y: 11))
        bodyPath.addCurve(to: CGPoint(x: 29.5, y: 4),
                           controlPoint1: CGPoint(x: 27.5, y: 11), controlPoint2: CGPoint(x: 28, y: 8))

        bodyPath.addCurve(to: CGPoint(x: 35, y: -3),
                           controlPoint1: CGPoint(x: 31, y: 3), controlPoint2: CGPoint(x: 33, y: 0))
        bodyPath.addCurve(to: CGPoint(x: 45, y: -1),
                           controlPoint1: CGPoint(x: 38, y: 0), controlPoint2: CGPoint(x: 42, y: 1))
        bodyPath.addLine(to: CGPoint(x: 52, y: -5))
        bodyPath.addLine(to: CGPoint(x: 50, y: -10))
        bodyPath.addCurve(to: CGPoint(x: 33, y: -13),
                           controlPoint1: CGPoint(x: 44, y: -11), controlPoint2: CGPoint(x: 39, y: -12))
        bodyPath.addLine(to: CGPoint(x: 28, y: -19))
        bodyPath.addCurve(to: CGPoint(x: -34, y: -16),
                           controlPoint1: CGPoint(x: 4, y: -22), controlPoint2: CGPoint(x: -16, y: -20))
        bodyPath.addCurve(to: CGPoint(x: -52, y: -4),
                           controlPoint1: CGPoint(x: -42, y: -14), controlPoint2: CGPoint(x: -48, y: -10))
        bodyPath.close()

        bodyShape = SKShapeNode(path: bodyPath.cgPath)
        bodyShape.fillColor = Ankylosaurus.bodyColor
        bodyShape.strokeColor = .clear
        bodyShape.zPosition = 2

        clubShape = SKShapeNode(circleOfRadius: 9)
        clubShape.fillColor = Ankylosaurus.bodyColor
        clubShape.strokeColor = .clear
        clubShape.position = CGPoint(x: -50, y: -6)
        clubShape.zPosition = 2

        func legPath() -> CGPath {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: -7, y: 4))
            p.addLine(to: CGPoint(x: 7, y: 4))
            p.addLine(to: CGPoint(x: 8, y: -15))
            p.addLine(to: CGPoint(x: -8, y: -15))
            p.close()
            return p.cgPath
        }

        legBack = SKShapeNode(path: legPath())
        legBack.fillColor = Ankylosaurus.bodyColor
        legBack.strokeColor = .clear
        legBack.position = CGPoint(x: -18, y: -15)
        legBack.zPosition = 1

        legFront = SKShapeNode(path: legPath())
        legFront.fillColor = Ankylosaurus.bodyColor
        legFront.strokeColor = .clear
        legFront.position = CGPoint(x: 26, y: -15)
        legFront.zPosition = 3

        super.init()

        addChild(legBack)
        addChild(legFront)
        addChild(bodyShape)
        addChild(clubShape)

        let body = SKPhysicsBody(rectangleOf: CGSize(width: 58, height: 40), center: CGPoint(x: 0, y: 6))
        body.isDynamic = true
        body.affectedByGravity = false
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
        let forward = SKAction.rotate(toAngle: 0.4, duration: 0.16)
        let back = SKAction.rotate(toAngle: -0.4, duration: 0.16)
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

    func jump(onLanded: @escaping () -> Void) {
        stopRunning()
        run(.sequence([
            .group([.scaleX(to: 0.85, y: 1.2, duration: 0.08)]),
            .scaleX(to: 1, y: 1, duration: 0.15)
        ]))

        let up = SKAction.moveBy(x: 0, y: PlayableDinoJump.height, duration: PlayableDinoJump.upDuration)
        up.timingMode = .easeOut
        let down = SKAction.moveBy(x: 0, y: -PlayableDinoJump.height, duration: PlayableDinoJump.downDuration)
        down.timingMode = .easeIn
        run(.sequence([up, down, .run(onLanded)]))
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
        startRunning()
    }
}
