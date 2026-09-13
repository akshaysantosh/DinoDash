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
    private var gameSpeed: CGFloat = 260
    private var distanceSinceSpawn: CGFloat = 0
    private var nextSpawnDistance: CGFloat = 260
    private var starsLayer: SKNode!

    private let jumpFeedback = UIImpactFeedbackGenerator(style: .light)
    private let crashFeedback = UINotificationFeedbackGenerator()

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

    func startRun() {
        enumerateChildNodes(withName: "obstacle") { node, _ in node.removeFromParent() }
        enumerateChildNodes(withName: "star") { node, _ in node.removeFromParent() }

        elapsed = 0
        lastUpdateTime = 0
        gameSpeed = 260
        distanceSinceSpawn = 0
        nextSpawnDistance = 260
        isOnGround = true
        isPlaying = true

        dino.position = CGPoint(x: size.width * 0.22, y: groundY + 20)
        dino.reset()

        backgroundColor = GameScene.creamColor
        starsLayer.alpha = 0
    }

    func jump() {
        guard isPlaying, isOnGround else { return }
        isOnGround = false
        jumpFeedback.impactOccurred()
        run(.playSoundFileNamed("jump.wav", waitForCompletion: false))
        dino.jump { [weak self] in
            guard let self else { return }
            self.isOnGround = true
            self.dino.landed()
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

        gameSpeed = min(560, 260 + CGFloat(elapsed) * 7)

        let newScore = Int(elapsed * 10)
        if let gameState, newScore > gameState.score {
            gameState.score = newScore
        }

        distanceSinceSpawn += gameSpeed * CGFloat(dt)

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
            spawnSpark(at: CGPoint(x: dino.position.x, y: dino.position.y + 20))
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
