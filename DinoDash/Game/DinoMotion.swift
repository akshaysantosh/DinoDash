import SpriteKit

/// Squash-and-stretch, leg bend and follow-through for any `PlayableDino`, so all characters
/// bounce the same way. It animates a visual-only `rig` (never the node that owns the physics
/// body), so the hitbox stays the same size no matter how squashy the dino looks mid-jump.
///
/// Timeline of one jump, matched to `PlayableDinoJump`'s up/down durations:
/// crouch → stretch on the way up → settle at the apex → stretch again while falling → squash
/// on touchdown → damped wobble back to rest. Legs bend and tuck in the air, then reach for the
/// ground just before landing. Loose parts (plates, tail spikes, a club) lag behind the body and
/// whip back on impact.
final class DinoMotion {
    /// A part that rotates slightly out of step with the body (plates, spikes).
    struct Follower {
        let node: SKNode
        let amplitude: CGFloat
        let delay: TimeInterval
        let baseRotation: CGFloat

        init(_ node: SKNode, amplitude: CGFloat, delay: TimeInterval) {
            self.node = node
            self.amplitude = amplitude
            self.delay = delay
            self.baseRotation = node.zRotation
        }
    }

    /// A part that bobs up and down out of step with the body (a heavy tail club).
    struct Bobber {
        let node: SKNode
        let amplitude: CGFloat
        let baseY: CGFloat

        init(_ node: SKNode, amplitude: CGFloat) {
            self.node = node
            self.amplitude = amplitude
            self.baseY = node.position.y
        }
    }

    private let rig: SKNode
    private let frontLeg: SKNode
    private let backLeg: SKNode
    private let followers: [Follower]
    private let bobbers: [Bobber]

    init(rig: SKNode, frontLeg: SKNode, backLeg: SKNode,
         followers: [Follower] = [], bobbers: [Bobber] = []) {
        self.rig = rig
        self.frontLeg = frontLeg
        self.backLeg = backLeg
        self.followers = followers
        self.bobbers = bobbers
    }

    private static let airKey = "bounce.air"
    private static let landKey = "bounce.land"
    private static let poseKey = "bounce.pose"
    private static let followKey = "bounce.follow"

    func takeoff() {
        clearActions()
        let up = PlayableDinoJump.upDuration
        let down = PlayableDinoJump.downDuration

        let crouch = SKAction.scaleX(to: 1.14, y: 0.82, duration: 0.05)
        crouch.timingMode = .easeOut
        let stretch = SKAction.scaleX(to: 0.9, y: 1.16, duration: 0.12)
        stretch.timingMode = .easeOut
        let settle = SKAction.scaleX(to: 1, y: 1, duration: max(0.05, up - 0.17))
        settle.timingMode = .easeInEaseOut
        let fall = SKAction.scaleX(to: 0.93, y: 1.09, duration: down * 0.6)
        fall.timingMode = .easeIn

        let tiltUp = SKAction.rotate(toAngle: 0.14, duration: up)
        tiltUp.timingMode = .easeOut
        let tiltDown = SKAction.rotate(toAngle: -0.18, duration: down)
        tiltDown.timingMode = .easeIn

        rig.run(.group([
            .sequence([crouch, stretch, settle, fall]),
            .sequence([tiltUp, tiltDown])
        ]), withKey: DinoMotion.airKey)

        // Legs bend and tuck as the dino leaves the ground (front leg forward, back leg back),
        // hang there through the arc, then straighten and reach just before touchdown.
        let reachStart = up + down * 0.55
        for (leg, angle) in [(frontLeg, CGFloat(0.5)), (backLeg, CGFloat(-0.5))] {
            let tuck = SKAction.group([
                .scaleY(to: 0.65, duration: 0.08),
                .rotate(toAngle: angle, duration: 0.08)
            ])
            tuck.timingMode = .easeOut
            let reach = SKAction.group([
                .scaleY(to: 1.05, duration: 0.14),
                .rotate(toAngle: angle * 0.3, duration: 0.14)
            ])
            leg.run(.sequence([tuck, .wait(forDuration: reachStart - 0.08), reach]),
                    withKey: DinoMotion.poseKey)
        }

        for follower in followers {
            let a = follower.amplitude
            let base = follower.baseRotation
            let drag = SKAction.rotate(toAngle: base + a, duration: 0.10)
            drag.timingMode = .easeOut
            let ease = SKAction.rotate(toAngle: base + a * 0.2, duration: up + down - 0.1)
            ease.timingMode = .easeInEaseOut
            follower.node.run(.sequence([.wait(forDuration: follower.delay), drag, ease]),
                              withKey: DinoMotion.followKey)
        }

        for bobber in bobbers {
            let drop = SKAction.moveTo(y: bobber.baseY - bobber.amplitude, duration: 0.10)
            drop.timingMode = .easeOut
            let ease = SKAction.moveTo(y: bobber.baseY - bobber.amplitude * 0.3, duration: up + down - 0.1)
            ease.timingMode = .easeInEaseOut
            bobber.node.run(.sequence([drop, ease]), withKey: DinoMotion.followKey)
        }
    }

    func land() {
        rig.removeAction(forKey: DinoMotion.airKey)

        let squash = SKAction.group([
            .scaleX(to: 1.24, y: 0.76, duration: 0.05),
            .rotate(toAngle: 0, duration: 0.07)
        ])
        squash.timingMode = .easeOut
        let rebound = SKAction.scaleX(to: 0.93, y: 1.08, duration: 0.09)
        rebound.timingMode = .easeInEaseOut
        let again = SKAction.scaleX(to: 1.03, y: 0.98, duration: 0.08)
        again.timingMode = .easeInEaseOut
        let rest = SKAction.scaleX(to: 1, y: 1, duration: 0.08)
        rest.timingMode = .easeOut
        rig.run(.sequence([squash, rebound, again, rest]), withKey: DinoMotion.landKey)

        // Legs absorb the impact (compress), spring a little long, then settle. Rotation is
        // handed straight back to the run cycle.
        for leg in [frontLeg, backLeg] {
            leg.removeAction(forKey: DinoMotion.poseKey)
            let compress = SKAction.scaleY(to: 0.75, duration: 0.05)
            compress.timingMode = .easeOut
            let spring = SKAction.scaleY(to: 1.1, duration: 0.09)
            spring.timingMode = .easeInEaseOut
            let settle = SKAction.scaleY(to: 1, duration: 0.08)
            settle.timingMode = .easeOut
            leg.run(.sequence([compress, spring, settle]), withKey: DinoMotion.poseKey)
        }

        for follower in followers {
            let a = follower.amplitude
            let base = follower.baseRotation
            let whip = SKAction.rotate(toAngle: base - a * 1.5, duration: 0.07)
            whip.timingMode = .easeOut
            let back = SKAction.rotate(toAngle: base + a * 0.4, duration: 0.09)
            back.timingMode = .easeInEaseOut
            let rest = SKAction.rotate(toAngle: base, duration: 0.10)
            rest.timingMode = .easeOut
            follower.node.run(.sequence([.wait(forDuration: follower.delay), whip, back, rest]),
                              withKey: DinoMotion.followKey)
        }

        for bobber in bobbers {
            let bounce = SKAction.moveTo(y: bobber.baseY + bobber.amplitude * 1.3, duration: 0.07)
            bounce.timingMode = .easeOut
            let dip = SKAction.moveTo(y: bobber.baseY - bobber.amplitude * 0.4, duration: 0.09)
            dip.timingMode = .easeInEaseOut
            let rest = SKAction.moveTo(y: bobber.baseY, duration: 0.10)
            rest.timingMode = .easeOut
            bobber.node.run(.sequence([bounce, dip, rest]), withKey: DinoMotion.followKey)
        }
    }

    /// Snaps everything back to the neutral pose (crash, restart).
    func resetPose() {
        clearActions()
        rig.xScale = 1
        rig.yScale = 1
        rig.zRotation = 0
        frontLeg.yScale = 1
        backLeg.yScale = 1
        followers.forEach { $0.node.zRotation = $0.baseRotation }
        bobbers.forEach { $0.node.position.y = $0.baseY }
    }

    private func clearActions() {
        rig.removeAction(forKey: DinoMotion.airKey)
        rig.removeAction(forKey: DinoMotion.landKey)
        frontLeg.removeAction(forKey: DinoMotion.poseKey)
        backLeg.removeAction(forKey: DinoMotion.poseKey)
        followers.forEach { $0.node.removeAction(forKey: DinoMotion.followKey) }
        bobbers.forEach { $0.node.removeAction(forKey: DinoMotion.followKey) }
    }
}
