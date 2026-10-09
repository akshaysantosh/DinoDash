import SpriteKit

/// Built from a handful of hand-wobbled bezier shapes rather than sprite art — same organic,
/// slightly-imperfect-curve spirit as the bikablo app icons, just filled instead of stroked
/// (a filled silhouette reads far better at speed than a thin outline would).
final class Brachiosaurus: SKNode, PlayableDino {
    static let bodyColor = SKColor(red: 0.478, green: 0.353, blue: 0.541, alpha: 1)
    static let nightBodyColor = SKColor(red: 0.82, green: 0.72, blue: 0.86, alpha: 1)

    private let bodyShape: SKShapeNode
    private let legFront: SKShapeNode
    private let legBack: SKShapeNode
    private let rig = SKNode()
    private var motion: DinoMotion!
    private var isRunning = false

    override init() {
        let bodyPath = UIBezierPath()
        bodyPath.move(to: CGPoint(x: -52, y: -2))
        bodyPath.addCurve(to: CGPoint(x: -28, y: -6),
                           controlPoint1: CGPoint(x: -50, y: -8), controlPoint2: CGPoint(x: -40, y: -10))
        bodyPath.addCurve(to: CGPoint(x: -14, y: 8),
                           controlPoint1: CGPoint(x: -24, y: -2), controlPoint2: CGPoint(x: -20, y: 4))
        bodyPath.addLine(to: CGPoint(x: -10, y: 16))
        bodyPath.addLine(to: CGPoint(x: -4, y: 9))
        bodyPath.addLine(to: CGPoint(x: 0, y: 17))
        bodyPath.addLine(to: CGPoint(x: 6, y: 10))
        bodyPath.addCurve(to: CGPoint(x: 18, y: 20),
                           controlPoint1: CGPoint(x: 10, y: 12), controlPoint2: CGPoint(x: 14, y: 15))
        bodyPath.addCurve(to: CGPoint(x: 27, y: 32),
                           controlPoint1: CGPoint(x: 21, y: 25), controlPoint2: CGPoint(x: 23, y: 29))
        bodyPath.addCurve(to: CGPoint(x: 38, y: 28),
                           controlPoint1: CGPoint(x: 31, y: 33), controlPoint2: CGPoint(x: 35, y: 32))
        bodyPath.addLine(to: CGPoint(x: 50, y: 20))
        bodyPath.addLine(to: CGPoint(x: 44, y: 16))
        bodyPath.addLine(to: CGPoint(x: 46, y: 10))
        bodyPath.addLine(to: CGPoint(x: 38, y: 6))
        bodyPath.addCurve(to: CGPoint(x: 22, y: -6),
                           controlPoint1: CGPoint(x: 32, y: 2), controlPoint2: CGPoint(x: 28, y: -2))
        bodyPath.addLine(to: CGPoint(x: 18, y: -16))
        bodyPath.addCurve(to: CGPoint(x: -30, y: -14),
                           controlPoint1: CGPoint(x: 0, y: -20), controlPoint2: CGPoint(x: -14, y: -18))
        bodyPath.addCurve(to: CGPoint(x: -52, y: -2),
                           controlPoint1: CGPoint(x: -38, y: -12), controlPoint2: CGPoint(x: -46, y: -8))
        bodyPath.close()

        bodyShape = SKShapeNode(path: bodyPath.cgPath)
        bodyShape.fillColor = Brachiosaurus.bodyColor
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
        legBack.fillColor = Brachiosaurus.bodyColor
        legBack.strokeColor = .clear
        legBack.position = CGPoint(x: -16, y: -8)
        legBack.zPosition = 1

        legFront = SKShapeNode(path: legPath())
        legFront.fillColor = Brachiosaurus.bodyColor
        legFront.strokeColor = .clear
        legFront.position = CGPoint(x: 22, y: -8)
        legFront.zPosition = 3

        super.init()

        addChild(rig)
        rig.addChild(legBack)
        rig.addChild(legFront)
        rig.addChild(bodyShape)
        motion = DinoMotion(rig: rig, frontLeg: legFront, backLeg: legBack)

        let body = SKPhysicsBody(rectangleOf: CGSize(width: 58, height: 40), center: CGPoint(x: 0, y: 6))
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.player
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

    func jump(onLanded: @escaping () -> Void) {
        // Pause the run cycle without snapping the legs straight — `DinoMotion` bends and tucks
        // them for the jump instead.
        isRunning = false
        legFront.removeAction(forKey: "run")
        legBack.removeAction(forKey: "run")
        motion.takeoff()

        let up = SKAction.moveBy(x: 0, y: PlayableDinoJump.height, duration: PlayableDinoJump.upDuration)
        up.timingMode = .easeOut
        let down = SKAction.moveBy(x: 0, y: -PlayableDinoJump.height, duration: PlayableDinoJump.downDuration)
        down.timingMode = .easeIn
        run(.sequence([up, down, .run(onLanded)]))
    }

    func landed() {
        startRunning()
        motion.land()
    }

    func crash() {
        stopRunning()
        removeAllActions()
        motion.resetPose()
        run(.rotate(byAngle: -1.1, duration: 0.4))
    }

    func reset() {
        removeAllActions()
        zRotation = 0
        xScale = 1
        yScale = 1
        alpha = 1
        motion.resetPose()
        startRunning()
    }

    func setNightMode(_ isNight: Bool) {
        let color = isNight ? Brachiosaurus.nightBodyColor : Brachiosaurus.bodyColor
        bodyShape.fillColor = color
        legFront.fillColor = color
        legBack.fillColor = color
    }
}
