import SpriteKit

/// Same low, wide armored-body silhouette and leg rig as Ankylosaurus, but with the two features
/// that actually read as "Stegosaurus": tall alternating plates along the spine (instead of small
/// rounded armor bumps) and a pair of tail spikes — the thagomizer — instead of a tail club.
final class Stegosaurus: SKNode, PlayableDino {
    static let bodyColor = SKColor(red: 0.376, green: 0.290, blue: 0.439, alpha: 1)
    static let nightBodyColor = SKColor(red: 0.80, green: 0.70, blue: 0.85, alpha: 1)

    private let bodyShape: SKShapeNode
    private let plateShapes: [SKShapeNode]
    private let spikeShapes: [SKShapeNode]
    private let legFront: SKShapeNode
    private let legBack: SKShapeNode
    private let rig = SKNode()
    private var motion: DinoMotion!
    private var isRunning = false

    override init() {
        // Same head/neck/jaw/front-leg/belly silhouette as Ankylosaurus (right-facing head, tail
        // to the left) but with a plain smooth back — the plates sit on top of it as their own
        // shapes rather than being baked into the body outline.
        let bodyPath = UIBezierPath()
        bodyPath.move(to: CGPoint(x: -52, y: -4))
        bodyPath.addCurve(to: CGPoint(x: -30, y: -2),
                           controlPoint1: CGPoint(x: -46, y: -8), controlPoint2: CGPoint(x: -38, y: -8))
        bodyPath.addCurve(to: CGPoint(x: -18, y: 7),
                           controlPoint1: CGPoint(x: -26, y: 2), controlPoint2: CGPoint(x: -22, y: 6))
        bodyPath.addCurve(to: CGPoint(x: 5, y: 12),
                           controlPoint1: CGPoint(x: -10, y: 10), controlPoint2: CGPoint(x: -3, y: 12))
        bodyPath.addCurve(to: CGPoint(x: 29.5, y: 4),
                           controlPoint1: CGPoint(x: 14, y: 12), controlPoint2: CGPoint(x: 23, y: 9))
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
        bodyShape.fillColor = Stegosaurus.bodyColor
        bodyShape.strokeColor = .clear
        bodyShape.zPosition = 2

        // Five alternating-height kite-shaped plates along the spine, each its own node so the
        // silhouette reads as plates sitting on the back rather than a serrated body outline.
        func platePath(width: CGFloat, height: CGFloat) -> CGPath {
            let p = UIBezierPath()
            let halfW = width / 2
            p.move(to: CGPoint(x: -halfW, y: 0))
            p.addCurve(to: CGPoint(x: 0, y: height),
                       controlPoint1: CGPoint(x: -halfW, y: height * 0.55),
                       controlPoint2: CGPoint(x: -halfW * 0.35, y: height * 0.95))
            p.addCurve(to: CGPoint(x: halfW, y: 0),
                       controlPoint1: CGPoint(x: halfW * 0.35, y: height * 0.95),
                       controlPoint2: CGPoint(x: halfW, y: height * 0.55))
            p.close()
            return p.cgPath
        }

        let plateSpecs: [(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, rotation: CGFloat)] = [
            (-17, 3, 13, 20, -0.08),
            (-6, 9, 15, 27, 0.05),
            (5, 11, 14, 24, -0.04),
            (16, 10, 15, 28, 0.06),
            (21, 8, 12, 20, -0.04)
        ]
        plateShapes = plateSpecs.map { spec in
            let plate = SKShapeNode(path: platePath(width: spec.width, height: spec.height))
            plate.fillColor = Stegosaurus.bodyColor
            plate.strokeColor = .clear
            plate.position = CGPoint(x: spec.x, y: spec.y)
            plate.zRotation = spec.rotation
            plate.zPosition = 1.5
            return plate
        }

        // The thagomizer: two long spikes fanning out from the tail tip, instead of Ankylosaurus's
        // round club.
        func spikePath(length: CGFloat, baseWidth: CGFloat) -> CGPath {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: 0, y: -baseWidth / 2))
            p.addLine(to: CGPoint(x: -length, y: 0))
            p.addLine(to: CGPoint(x: 0, y: baseWidth / 2))
            p.close()
            return p.cgPath
        }

        let spikeSpecs: [(rotation: CGFloat, length: CGFloat)] = [
            (0.55, 26),
            (-0.45, 24)
        ]
        spikeShapes = spikeSpecs.map { spec in
            let spike = SKShapeNode(path: spikePath(length: spec.length, baseWidth: 10))
            spike.fillColor = Stegosaurus.bodyColor
            spike.strokeColor = .clear
            spike.position = CGPoint(x: -50, y: -5)
            spike.zRotation = spec.rotation
            spike.zPosition = 1.5
            return spike
        }

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
        legBack.fillColor = Stegosaurus.bodyColor
        legBack.strokeColor = .clear
        legBack.position = CGPoint(x: -18, y: -15)
        legBack.zPosition = 1

        legFront = SKShapeNode(path: legPath())
        legFront.fillColor = Stegosaurus.bodyColor
        legFront.strokeColor = .clear
        legFront.position = CGPoint(x: 26, y: -15)
        legFront.zPosition = 3

        super.init()

        addChild(rig)
        rig.addChild(legBack)
        rig.addChild(legFront)
        rig.addChild(bodyShape)
        spikeShapes.forEach { rig.addChild($0) }
        plateShapes.forEach { rig.addChild($0) }

        // Plates ripple one after another along the spine and the tail spikes whip a little
        // harder — the loose parts lag the body and flick back on landing.
        let plateFollowers = plateShapes.enumerated().map { index, plate in
            DinoMotion.Follower(plate, amplitude: 0.14, delay: Double(index) * 0.018)
        }
        let spikeFollowers = spikeShapes.enumerated().map { index, spike in
            DinoMotion.Follower(spike, amplitude: 0.2, delay: Double(index) * 0.03)
        }
        motion = DinoMotion(rig: rig, frontLeg: legFront, backLeg: legBack,
                            followers: plateFollowers + spikeFollowers)

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
        let color = isNight ? Stegosaurus.nightBodyColor : Stegosaurus.bodyColor
        bodyShape.fillColor = color
        legFront.fillColor = color
        legBack.fillColor = color
        plateShapes.forEach { $0.fillColor = color }
        spikeShapes.forEach { $0.fillColor = color }
    }
}
