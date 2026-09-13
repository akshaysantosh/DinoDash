# SpinoDash

A simple endless runner for my son — a spinosaurus auto-runs across the ground, tap anywhere to jump over asteroids (some you must jump, some you must let pass), with a rising difficulty curve, near-miss bonus points, collectible stars, and a background that shifts from day to dusk to deep space the longer you survive. Inspired by the Chrome offline dino game.

<p>
  <img src="screenshots/start.png" width="260" alt="Start screen with best score and Tap to Start button">
  <img src="screenshots/gameplay.png" width="260" alt="Mid-run gameplay — spinosaurus dodging an asteroid, live score and best HUD pills">
</p>

*(Screenshots are from live Simulator gameplay, not mockups.)*

## One-time setup

Same as PriceTrack/Stash/SpotFinder:

1. **Install Xcode** from the Mac App Store, if you haven't already (shared across all your personal apps).
2. **Install XcodeGen** (skip if already installed): `brew install xcodegen`
3. **Generate the Xcode project** (run from this `SpinoDash/` folder):
   ```bash
   xcodegen generate
   ```
   Note: `SpinoDash/App/Info.plist` is **generated** from the `info.properties` block in `project.yml` — edit it there, not in the plist file directly.
4. **Open `SpinoDash.xcodeproj` in Xcode**, select the `SpinoDash` target → *Signing & Capabilities* → pick your Apple ID under *Team*.
5. To run on your iPhone: plug it in (or set up wireless debugging), pick it as the run destination in Xcode's device menu instead of a Simulator, then Build and run (⌘R). The first time, your phone will refuse to open the app until you trust the developer certificate: **Settings → General → VPN & Device Management → [your Apple ID] → Trust**.

No accounts, no backend, no persistence beyond a local high score (`UserDefaults`) — the whole game runs offline. Landscape only, unlike the other three apps, since a side-scrolling runner needs the horizontal room to see obstacles coming.

## How it works

- **Start** — shows your best score (if any) and waits for a tap anywhere to begin.
- **Play** — the spinosaurus auto-runs; tap to jump. Asteroids come in two flavors: ground-level ones you must jump, and elevated ones you must *not* jump into. Speed and spawn frequency ramp up the longer you survive. Clearing a ground asteroid mid-air by a hair scores a near-miss bonus with a spark effect; collectible stars float by for bonus points if you jump into them. The background gradually shifts from cream daylight to dusk to a starry night as your score climbs.
- **Crash** — a screen flash and haptic thump, then your score and (if beaten) a "New High Score!" callout, with a tap anywhere to retry instantly.

## Project structure

`App` (entry point), `Models` (`GameState` — start/playing/game-over phase, score, `UserDefaults`-backed high score), `Game` (SpriteKit layer: `GameScene` driving physics/spawning/scoring/difficulty, `Spinosaurus`/`Asteroid`/`Star` shape-built nodes, `PhysicsCategory`), `Features` (`RootView` switching on game phase, `StartScreenView`, `GameView` wrapping the `SpriteView` with a score/best HUD, `GameOverView`), `DesignSystem` (colors, type, card/button components — copied from Stash unchanged, same look and feel as the other three apps).
