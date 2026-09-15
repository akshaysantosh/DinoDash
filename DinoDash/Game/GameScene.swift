import SpriteKit
import UIKit

final class GameScene: SKScene, SKPhysicsContactDelegate {
    weak var gameState: GameState?

    private var dino: PlayableDino!
    private var groundY: CGFloat = 0
    private var isPlaying = false
    private var isOnGround = true
    private var elapsed: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var gameSpeed: CGFloat = GameScene.startingSpeed
    private var distanceSinceSpawn: CGFloat = 0
    private var nextSpawnDistance: CGFloat = GameScene.firstSpawnDistance
    private var starsLayer: SKNode!
    private var hillsLayer: SKNode!
    private var hillTiles: [SKShapeNode] = []
    private var hillTileWidth: CGFloat = 0

    private static let milestoneInterval = 250
    private var nextMilestoneScore = GameScene.milestoneInterval

    /// A gentler opening: slower starting speed and a longer gap before the very first obstacle,
    /// so a new player (especially a kid) gets a few seconds to find the jump timing before
    /// anything needs dodging. The long-term ramp rate and cap are unchanged — this only softens
    /// the first several seconds, not the difficulty ceiling.
    private static let startingSpeed: CGFloat = 190
    private static let maxSpeed: CGFloat = 560
    private static let speedRampPerSecond: CGFloat = 7
    private static let firstSpawnDistance: CGFloat = 460

    /// Score needed for the roar's next charge — starts at `roarInterval` and pushes forward by
    /// the same amount each time it's used, so it's always "100 more points away", not a banked
    /// resource that can stack up.
    private var nextRoarScore = GameScene.roarInterval

    private let jumpFeedback = UIImpactFeedbackGenerator(style: .light)
    private let crashFeedback = UINotificationFeedbackGenerator()
    private let roarFeedback = UIImpactFeedbackGenerator(style: .heavy)

    private var hasSetUp = false

    override func didMove(to view: SKView) {
        // SpriteKit can call didMove(to:) more than once for the same scene instance — e.g. when
        // the hosting SKView resizes as the real device's safe area settles shortly after the
        // view appears (doesn't happen in the Simulator's fixed viewport, which is why this
        // wasn't caught earlier). Without this guard, a second call would duplicate the ground
        // body, star layer, and the dino itself — leaving an orphaned copy still on screen while
        // `dino` (and therefore `jump()`) points at a different node than what's visible.
        guard !hasSetUp else { return }
        hasSetUp = true

        backgroundColor = GameScene.creamColor
        physicsWorld.contactDelegate = self

        groundY = size.height * 0.22

        let groundBody = SKPhysicsBody(edgeFrom: CGPoint(x: -size.width, y: groundY),
                                        to: CGPoint(x: size.width * 2, y: groundY))
        groundBody.categoryBitMask = PhysicsCategory.ground
        groundBody.friction = 0
        physicsBody = groundBody

        let groundLine = SKShapeNode(rectOf: CGSize(width: size.width * 3, height: 4))
        groundLine.position = CGPoint(x: size.width / 2, y: groundY)
        groundLine.fillColor = SKColor(red: 0.898, green: 0.886, blue: 0.855, alpha: 1)
        groundLine.strokeColor = .clear
        groundLine.zPosition = 1
        addChild(groundLine)

        starsLayer = SKNode()
        starsLayer.alpha = 0
        starsLayer.zPosition = 0
        addChild(starsLayer)
        scatterBackgroundStars()

        setupHills()

        dino = (gameState?.selectedDino ?? .ankylosaurus).makeNode()
        dino.zPosition = 5
        addChild(dino)

        jumpFeedback.prepare()
        startRun()
    }

    private func scatterBackgroundStars() {
        for _ in 0..<24 {
            let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2))
            dot.fillColor = .white
            dot.strokeColor = .clear
            dot.position = CGPoint(x: CGFloat.random(in: 0...size.width),
                                    y: CGFloat.random(in: groundY...size.height))
            starsLayer.addChild(dot)
        }
    }

    private static let hillColor = SKColor(red: 0.80, green: 0.66, blue: 0.55, alpha: 0.5)

    /// Two wide hill silhouettes that scroll slower than the foreground (a fraction of
    /// `gameSpeed`) and recycle from left to right, giving a cheap sense of depth behind the
    /// action without needing more than two nodes ever on screen.
    private func setupHills() {
        hillsLayer = SKNode()
        hillsLayer.zPosition = 0.5
        addChild(hillsLayer)

        hillTileWidth = size.width * 1.15
        for i in 0..<2 {
            let hill = makeHillTile(width: hillTileWidth)
            hill.position = CGPoint(x: hillTileWidth / 2 + CGFloat(i) * hillTileWidth, y: groundY)
            hillsLayer.addChild(hill)
            hillTiles.append(hill)
        }
    }

    private func makeHillTile(width: CGFloat) -> SKShapeNode {
        let h: CGFloat = 46
        let path = UIBezierPath()
        path.move(to: CGPoint(x: -width / 2, y: 0))
        path.addCurve(to: CGPoint(x: -width / 4, y: h * 0.7),
                       controlPoint1: CGPoint(x: -width * 0.42, y: 0),
                       controlPoint2: CGPoint(x: -width * 0.36, y: h * 0.7))
        path.addCurve(to: CGPoint(x: 0, y: h * 0.35),
                       controlPoint1: CGPoint(x: -width * 0.14, y: h * 0.7),
                       controlPoint2: CGPoint(x: -width * 0.06, y: h * 0.35))
        path.addCurve(to: CGPoint(x: width / 4, y: h),
                       controlPoint1: CGPoint(x: width * 0.10, y: h * 0.5),
                       controlPoint2: CGPoint(x: width * 0.18, y: h))
        path.addCurve(to: CGPoint(x: width / 2, y: h * 0.4),
                       controlPoint1: CGPoint(x: width * 0.32, y: h),
                       controlPoint2: CGPoint(x: width * 0.42, y: h * 0.4))
        path.addLine(to: CGPoint(x: width / 2, y: 0))
        path.close()

        let hill = SKShapeNode(path: path.cgPath)
        hill.fillColor = GameScene.hillColor
        hill.strokeColor = .clear
        return hill
    }

    private func updateHills(dt: CGFloat) {
        let parallaxSpeed = gameSpeed * 0.35
        for hill in hillTiles {
            hill.position.x -= parallaxSpeed * dt
        }
        guard let leftmost = hillTiles.min(by: { $0.position.x < $1.position.x }),
              let rightmost = hillTiles.max(by: { $0.position.x < $1.position.x }) else { return }
        if leftmost.position.x < -hillTileWidth / 2 {
            leftmost.position.x = rightmost.position.x + hillTileWidth
        }
    }

    func startRun() {
        enumerateChildNodes(withName: "obstacle") { node, _ in node.removeFromParent() }
        enumerateChildNodes(withName: "star") { node, _ in node.removeFromParent() }

        elapsed = 0
        lastUpdateTime = 0
        gameSpeed = GameScene.startingSpeed
        distanceSinceSpawn = 0
        nextSpawnDistance = GameScene.firstSpawnDistance
        nextRoarScore = GameScene.roarInterval
        nextMilestoneScore = GameScene.milestoneInterval
        isOnGround = true
        isPlaying = true
        gameState?.isRoarReady = false

        enumerateChildNodes(withName: "pebble") { node, _ in node.removeFromParent() }
        for (i, hill) in hillTiles.enumerated() {
            hill.position.x = hillTileWidth / 2 + CGFloat(i) * hillTileWidth
        }

        dino.position = CGPoint(x: size.width * 0.22, y: groundY + 20)
        dino.reset()

        backgroundColor = GameScene.creamColor
        starsLayer.alpha = 0
    }

    /// Toggles SpriteKit's own `isPaused` — since `GameScene` is the root node, this freezes
    /// every action and physics simulation in the whole tree (leg-swing loops, asteroid drift,
    /// ember trails, all of it) with no per-node bookkeeping needed.
    func togglePause() {
        guard isPlaying else { return }
        isPaused.toggle()
        gameState?.isPaused = isPaused
    }

    func jump() {
        guard isPlaying, isOnGround, !isPaused else { return }
        isOnGround = false
        jumpFeedback.impactOccurred()
        run(.playSoundFileNamed("jump.wav", waitForCompletion: false))
        dino.jump { [weak self] in
            guard let self else { return }
            self.isOnGround = true
            self.dino.landed()
        }
    }

    static let roarInterval = 100

    /// Sweeps a shockwave across the screen, destroying every current asteroid (not stars —
    /// those stay a separate jump-for-it bonus). One charge at a time: using it immediately
    /// pushes the next charge another `roarInterval` points out, rather than banking up.
    func roar() {
        guard isPlaying, !isPaused, gameState?.isRoarReady == true else { return }
        gameState?.isRoarReady = false
        nextRoarScore = (gameState?.score ?? 0) + GameScene.roarInterval

        roarFeedback.impactOccurred()
        run(.playSoundFileNamed("roar.wav", waitForCompletion: false))

        let wave = SKShapeNode(circleOfRadius: 4)
        wave.position = dino.position
        wave.fillColor = SKColor(red: 0.76, green: 0.24, blue: 0.13, alpha: 0.35)
        wave.strokeColor = SKColor(red: 0.76, green: 0.24, blue: 0.13, alpha: 0.6)
        wave.lineWidth = 3
        wave.zPosition = 7
        addChild(wave)
        wave.run(.sequence([
            .group([.scale(to: size.width / 2, duration: 0.4), .fadeOut(withDuration: 0.4)]),
            .removeFromParent()
        ]))

        var destroyed = 0
        enumerateChildNodes(withName: "obstacle") { [weak self] node, _ in
            guard let self, node.position.x >= self.dino.position.x - 40 else { return }
            destroyed += 1
            self.spawnSpark(at: node.position)
            node.removeFromParent()
        }
        if destroyed > 0 {
            gameState?.score += destroyed * 10
            spawnScorePopup("+\(destroyed * 10)", at: CGPoint(x: dino.position.x, y: dino.position.y + 40),
                             color: SKColor(red: 0.76, green: 0.24, blue: 0.13, alpha: 1))
        }
    }

    /// Handled natively by SpriteKit rather than a SwiftUI `.onTapGesture` on the hosting
    /// `SpriteView` — that combination is unreliable on real devices (the SwiftUI gesture
    /// recognizer and the SKView's own touch handling can end up competing for the touch).
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        jump()
    }

    override func update(_ currentTime: TimeInterval) {
        guard isPlaying else { return }
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = min(currentTime - lastUpdateTime, 1.0 / 30.0)
        lastUpdateTime = currentTime
        elapsed += dt

        gameSpeed = min(GameScene.maxSpeed, GameScene.startingSpeed + CGFloat(elapsed) * GameScene.speedRampPerSecond)

        let newScore = Int(elapsed * 10)
        if let gameState, newScore > gameState.score {
            gameState.score = newScore
        }

        if let gameState, gameState.isRoarReady == false, gameState.score >= nextRoarScore {
            gameState.isRoarReady = true
        }

        if let gameState, gameState.score >= nextMilestoneScore {
            nextMilestoneScore += GameScene.milestoneInterval
            celebrateMilestone(score: gameState.score)
        }

        distanceSinceSpawn += gameSpeed * CGFloat(dt)
        updateHills(dt: CGFloat(dt))

        if isOnGround, CGFloat.random(in: 0...1) < 0.22 {
            spawnDustPuff()
        }
        if CGFloat.random(in: 0...1) < 0.08 {
            spawnGroundPebble()
        }

        enumerateChildNodes(withName: "obstacle") { [weak self] node, _ in
            guard let self else { return }
            node.position.x -= self.gameSpeed * CGFloat(dt)
            self.checkNearMiss(node)
            if CGFloat.random(in: 0...1) < 0.18 {
                self.spawnAsteroidTrail(at: node.position)
            }
            if node.position.x < -80 { node.removeFromParent() }
        }
        enumerateChildNodes(withName: "star") { [weak self] node, _ in
            guard let self else { return }
            node.position.x -= self.gameSpeed * CGFloat(dt)
            if node.position.x < -80 { node.removeFromParent() }
        }
        enumerateChildNodes(withName: "pebble") { [weak self] node, _ in
            guard let self else { return }
            node.position.x -= self.gameSpeed * CGFloat(dt)
            if node.position.x < -20 { node.removeFromParent() }
        }

        if distanceSinceSpawn >= nextSpawnDistance {
            distanceSinceSpawn = 0
            nextSpawnDistance = CGFloat.random(in: 240...360)
            spawnWave()
        }

        updateBackground(for: newScore)
    }

    private func checkNearMiss(_ node: SKNode) {
        guard let asteroid = node as? Asteroid,
              asteroid.userData?["counted"] == nil,
              !asteroid.isElevated else { return }
        guard node.position.x <= dino.position.x else { return }
        if asteroid.userData == nil { asteroid.userData = [:] }
        asteroid.userData?["counted"] = true
        if !isOnGround {
            gameState?.score += 5
            let point = CGPoint(x: dino.position.x, y: dino.position.y + 20)
            spawnSpark(at: point)
            spawnScorePopup("+5", at: CGPoint(x: point.x, y: point.y + 16))
        }
    }

    private func spawnSpark(at point: CGPoint) {
        let spark = SKShapeNode(circleOfRadius: 4)
        spark.fillColor = SKColor(red: 0.788, green: 0.514, blue: 0.165, alpha: 1)
        spark.strokeColor = .clear
        spark.position = point
        spark.zPosition = 6
        addChild(spark)
        spark.run(.sequence([
            .group([.scale(to: 2.2, duration: 0.3), .fadeOut(withDuration: 0.3), .moveBy(x: 0, y: 18, duration: 0.3)]),
            .removeFromParent()
        ]))
    }

    /// A floating "+N" that rises and fades — used at every scoring moment (near-miss, star,
    /// roar) so it's always visually obvious *why* the score just jumped.
    private func spawnScorePopup(_ text: String, at point: CGPoint,
                                  color: SKColor = SKColor(red: 0.93, green: 0.52, blue: 0.22, alpha: 1)) {
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 20
        label.fontColor = color
        label.position = point
        label.zPosition = 8
        label.verticalAlignmentMode = .center
        addChild(label)
        label.run(.sequence([
            .group([
                .moveBy(x: 0, y: 34, duration: 0.6),
                .scale(to: 1.15, duration: 0.6),
                .sequence([.wait(forDuration: 0.25), .fadeOut(withDuration: 0.35)])
            ]),
            .removeFromParent()
        ]))
    }

    private func spawnDustPuff() {
        let dust = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
        dust.fillColor = SKColor(red: 0.75, green: 0.68, blue: 0.58, alpha: 0.5)
        dust.strokeColor = .clear
        dust.position = CGPoint(x: dino.position.x + CGFloat.random(in: -12...(-2)),
                                 y: groundY + CGFloat.random(in: 0...4))
        dust.zPosition = 1.2
        addChild(dust)
        dust.run(.sequence([
            .group([
                .moveBy(x: CGFloat.random(in: -16...(-6)), y: CGFloat.random(in: 4...10), duration: 0.35),
                .fadeOut(withDuration: 0.35),
                .scale(to: 1.8, duration: 0.35)
            ]),
            .removeFromParent()
        ]))
    }

    private func spawnGroundPebble() {
        let pebble = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3))
        pebble.fillColor = SKColor(red: 0.80, green: 0.78, blue: 0.74, alpha: 0.8)
        pebble.strokeColor = .clear
        pebble.position = CGPoint(x: size.width + 10, y: groundY - CGFloat.random(in: 6...16))
        pebble.zPosition = 1.1
        pebble.name = "pebble"
        addChild(pebble)
    }

    private static let confettiColors: [SKColor] = [
        SKColor(red: 0.93, green: 0.52, blue: 0.22, alpha: 1),
        SKColor(red: 0.788, green: 0.514, blue: 0.165, alpha: 1),
        SKColor(red: 0.478, green: 0.353, blue: 0.541, alpha: 1),
        SKColor(red: 0.376, green: 0.290, blue: 0.439, alpha: 1),
        SKColor(red: 0.76, green: 0.24, blue: 0.13, alpha: 1)
    ]

    /// A brief confetti burst plus a big score callout — fires every `milestoneInterval` points,
    /// giving a more overt "nice!" moment than the gradual background-color shift alone provides.
    private func celebrateMilestone(score: Int) {
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        let label = SKLabelNode(text: "\(score)!")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 42
        label.fontColor = SKColor(red: 0.71, green: 0.33, blue: 0.12, alpha: 1)
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        label.zPosition = 9
        label.alpha = 0
        label.setScale(0.6)
        addChild(label)
        label.run(.sequence([
            .group([.fadeIn(withDuration: 0.15), .scale(to: 1.15, duration: 0.25)]),
            .scale(to: 1.0, duration: 0.15),
            .wait(forDuration: 0.5),
            .group([.fadeOut(withDuration: 0.3), .moveBy(x: 0, y: 20, duration: 0.3)]),
            .removeFromParent()
        ]))

        for _ in 0..<14 {
            let confetti = SKShapeNode(rectOf: CGSize(width: 6, height: 6), cornerRadius: 1.5)
            confetti.fillColor = GameScene.confettiColors.randomElement()!
            confetti.strokeColor = .clear
            confetti.position = CGPoint(x: CGFloat.random(in: size.width * 0.2...size.width * 0.8),
                                         y: size.height * CGFloat.random(in: 0.75...0.95))
            confetti.zPosition = 9
            confetti.zRotation = CGFloat.random(in: 0...(.pi * 2))
            addChild(confetti)
            confetti.run(.sequence([
                .group([
                    .moveBy(x: CGFloat.random(in: -30...30), y: -CGFloat.random(in: 120...220), duration: 0.9),
                    .rotate(byAngle: CGFloat.random(in: -4...4), duration: 0.9),
                    .sequence([.wait(forDuration: 0.5), .fadeOut(withDuration: 0.4)])
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func spawnAsteroidTrail(at point: CGPoint) {
        let ember = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3))
        ember.fillColor = SKColor(red: 0.93, green: 0.52, blue: 0.22, alpha: 1)
        ember.strokeColor = .clear
        ember.alpha = 0.9
        ember.position = CGPoint(x: point.x + CGFloat.random(in: -3...3),
                                  y: point.y + CGFloat.random(in: 4...14))
        ember.zPosition = 3
        addChild(ember)
        ember.run(.sequence([
            .group([
                .fadeOut(withDuration: 0.35),
                .scale(to: 0.4, duration: 0.35),
                .moveBy(x: CGFloat.random(in: 4...9), y: CGFloat.random(in: 6...12), duration: 0.35)
            ]),
            .removeFromParent()
        ]))
    }

    private func spawnWave() {
        let elevated = Int.random(in: 0..<10) < 3
        let asteroid = Asteroid(radius: elevated ? 15 : CGFloat.random(in: 14...22), isElevated: elevated)
        asteroid.name = "obstacle"
        asteroid.position = CGPoint(x: size.width + 40, y: groundY + (elevated ? 78 : 14))
        asteroid.zPosition = 4
        addChild(asteroid)

        if Int.random(in: 0..<3) == 0 {
            let star = Star()
            star.name = "star"
            star.position = CGPoint(x: size.width + (elevated ? 130 : 90), y: groundY + CGFloat.random(in: 55...95))
            star.zPosition = 4
            addChild(star)
        }
    }

    private static let creamColor = SKColor(red: 0.969, green: 0.965, blue: 0.953, alpha: 1)

    private func updateBackground(for score: Int) {
        let t = min(1, CGFloat(score) / 700)
        let cream: (CGFloat, CGFloat, CGFloat) = (0.969, 0.965, 0.953)
        let dusk: (CGFloat, CGFloat, CGFloat) = (0.85, 0.55, 0.45)
        let space: (CGFloat, CGFloat, CGFloat) = (0.08, 0.07, 0.14)

        let from = t < 0.5 ? cream : dusk
        let to = t < 0.5 ? dusk : space
        let localT = t < 0.5 ? t / 0.5 : (t - 0.5) / 0.5

        let r = from.0 + (to.0 - from.0) * localT
        let g = from.1 + (to.1 - from.1) * localT
        let b = from.2 + (to.2 - from.2) * localT
        backgroundColor = SKColor(red: r, green: g, blue: b, alpha: 1)
        starsLayer.alpha = t
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if mask == (PhysicsCategory.spinosaurus | PhysicsCategory.asteroid) {
            crash()
        } else if mask == (PhysicsCategory.spinosaurus | PhysicsCategory.star) {
            let starNode = contact.bodyA.categoryBitMask == PhysicsCategory.star ? contact.bodyA.node : contact.bodyB.node
            if let starNode {
                spawnSpark(at: starNode.position)
                spawnScorePopup("+25", at: CGPoint(x: starNode.position.x, y: starNode.position.y + 16),
                                 color: SKColor(red: 0.788, green: 0.514, blue: 0.165, alpha: 1))
                starNode.removeFromParent()
            }
            run(.playSoundFileNamed("collect.wav", waitForCompletion: false))
            gameState?.score += 25
        }
    }

    private func crash() {
        guard isPlaying else { return }
        isPlaying = false
        crashFeedback.notificationOccurred(.error)
        run(.playSoundFileNamed("crash.wav", waitForCompletion: false))
        dino.crash()

        let flash = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.alpha = 0.6
        flash.zPosition = 10
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(flash)
        flash.run(.sequence([.fadeOut(withDuration: 0.25), .removeFromParent()]))

        run(.sequence([.wait(forDuration: 0.6)])) { [weak self] in
            self?.gameState?.endGame()
        }
    }
}
