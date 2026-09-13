import SwiftUI

@main
struct DinoDashApp: App {
    @StateObject private var gameState = GameState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(gameState)
                .preferredColorScheme(.light)
                .statusBarHidden()
        }
    }
}
