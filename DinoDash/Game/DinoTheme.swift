import SpriteKit
import SwiftUI

/// Everything that makes one dino's world and roar *look and feel* different. Deliberately
/// cosmetic only — speeds, spawn distances, hitboxes, scoring and the roar interval all live in
/// `GameScene` and are shared, so every dino plays at exactly the same difficulty.
struct DinoTheme {
    struct RGB {
        let r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat
        init(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) {
            self.r = r; self.g = g; self.b = b; self.a = a
        }
        var skColor: SKColor { SKColor(red: r, green: g, blue: b, alpha: a) }
        var color: Color { Color(red: r, green: g, blue: b, opacity: a) }
        func mixed(with other: RGB, _ t: CGFloat) -> RGB {
            RGB(r + (other.r - r) * t, g + (other.g - g) * t, b + (other.b - b) * t, a + (other.a - a) * t)
        }
    }

    enum HillStyle { case dunes, rolling, volcanic }
    enum GroundDecor { case pebbles, grassTufts, lavaRocks }
    enum Ambient { case none, pollen, embers }
    enum RoarWave { case groundSlam, gust, spikeBurst }
    enum RoarHaptic { case heavy, rolling, rigid }

    // World
    let skyDay: RGB
    let skyDusk: RGB
    let skySpace: RGB
    let nightSky: RGB
    let groundLine: RGB
    let hill: RGB
    let dust: RGB
    let pebble: RGB
    let menuBackdrop: RGB
    let hillStyle: HillStyle
    let groundDecor: GroundDecor
    let ambient: Ambient

    // Asteroids (the dark-sky pair is used once the sky has gone dark, as before)
    let asteroidFill: RGB
    let asteroidStroke: RGB
    let asteroidNightFill: RGB
    let asteroidNightStroke: RGB

    // Roar
    let roarSymbol: String
    let roarColor: RGB
    let roarWave: RoarWave
    let roarHaptic: RoarHaptic
    /// Playback rate for `roar.wav` — shifts pitch and length so each dino sounds different
    /// without needing separate audio files.
    let roarSoundRate: Float

    /// Today's look, unchanged.
    static let desert = DinoTheme(
        skyDay: RGB(0.969, 0.965, 0.953),
        skyDusk: RGB(0.85, 0.55, 0.45),
        skySpace: RGB(0.08, 0.07, 0.14),
        nightSky: RGB(0.08, 0.07, 0.14),
        groundLine: RGB(0.898, 0.886, 0.855),
        hill: RGB(0.80, 0.66, 0.55, 0.5),
        dust: RGB(0.75, 0.68, 0.58, 0.5),
        pebble: RGB(0.80, 0.78, 0.74, 0.8),
        menuBackdrop: RGB(0.973, 0.965, 0.945),
        hillStyle: .dunes,
        groundDecor: .pebbles,
        ambient: .none,
        asteroidFill: RGB(0.42, 0.38, 0.36),
        asteroidStroke: RGB(0.28, 0.25, 0.24),
        asteroidNightFill: RGB(0.82, 0.76, 0.68),
        asteroidNightStroke: RGB(0.55, 0.48, 0.42),
        roarSymbol: "shield.lefthalf.filled",
        roarColor: RGB(0.76, 0.24, 0.13),
        roarWave: .groundSlam,
        roarHaptic: .heavy,
        roarSoundRate: 0.8
    )

    static let grassland = DinoTheme(
        skyDay: RGB(0.88, 0.95, 0.97),
        skyDusk: RGB(0.96, 0.74, 0.52),
        skySpace: RGB(0.06, 0.10, 0.17),
        nightSky: RGB(0.06, 0.10, 0.17),
        groundLine: RGB(0.55, 0.72, 0.45),
        hill: RGB(0.45, 0.68, 0.42, 0.5),
        dust: RGB(0.58, 0.72, 0.48, 0.5),
        pebble: RGB(0.38, 0.62, 0.32, 0.9),
        menuBackdrop: RGB(0.90, 0.95, 0.87),
        hillStyle: .rolling,
        groundDecor: .grassTufts,
        ambient: .pollen,
        asteroidFill: RGB(0.42, 0.38, 0.36),
        asteroidStroke: RGB(0.28, 0.25, 0.24),
        asteroidNightFill: RGB(0.82, 0.78, 0.70),
        asteroidNightStroke: RGB(0.52, 0.55, 0.42),
        roarSymbol: "wind",
        roarColor: RGB(0.22, 0.52, 0.28),
        roarWave: .gust,
        roarHaptic: .rolling,
        roarSoundRate: 1.25
    )

    static let volcanic = DinoTheme(
        skyDay: RGB(0.80, 0.73, 0.69),
        skyDusk: RGB(0.72, 0.34, 0.22),
        skySpace: RGB(0.11, 0.05, 0.07),
        nightSky: RGB(0.11, 0.05, 0.07),
        groundLine: RGB(0.30, 0.25, 0.25),
        hill: RGB(0.30, 0.24, 0.24, 0.5),
        dust: RGB(0.42, 0.37, 0.37, 0.5),
        pebble: RGB(0.25, 0.20, 0.20, 0.9),
        menuBackdrop: RGB(0.93, 0.88, 0.85),
        hillStyle: .volcanic,
        groundDecor: .lavaRocks,
        ambient: .embers,
        asteroidFill: RGB(0.20, 0.16, 0.16),
        asteroidStroke: RGB(0.95, 0.45, 0.15),
        asteroidNightFill: RGB(0.90, 0.62, 0.45),
        asteroidNightStroke: RGB(0.98, 0.45, 0.15),
        roarSymbol: "flame.fill",
        roarColor: RGB(0.86, 0.33, 0.10),
        roarWave: .spikeBurst,
        roarHaptic: .rigid,
        roarSoundRate: 1.0
    )
}

extension DinoKind {
    var theme: DinoTheme {
        switch self {
        case .ankylosaurus: return .desert
        case .brachiosaurus: return .grassland
        case .stegosaurus: return .volcanic
        }
    }
}
