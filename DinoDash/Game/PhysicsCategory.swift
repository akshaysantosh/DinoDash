import Foundation

enum PhysicsCategory {
    static let player: UInt32 = 0x1 << 0
    static let asteroid: UInt32 = 0x1 << 1
    static let star: UInt32 = 0x1 << 2
    static let ground: UInt32 = 0x1 << 3
}
