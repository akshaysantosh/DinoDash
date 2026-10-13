# DinoDash

A simple endless runner for my son — pick a dino (Ankylosaurus by default, or Brachiosaurus or Stegosaurus) — each runs through its own world (desert, grassland, volcanic) and has its own roar icon, shockwave, haptic and sound, with identical difficulty — then auto-run across the ground, tapping anywhere to jump over asteroids (some you must jump, some you must let pass), with a rising difficulty curve, near-miss bonus points, collectible stars, and a background that shifts from day to dusk to deep space the longer you survive. Inspired by the Chrome offline dino game.

<p>
  <img src="screenshots/start.jpg" width="380" alt="Start screen on a warm paper background, with the Ankylosaurus selected, character picker arrows, a music on/off button and the Tap to Start button">
  <img src="screenshots/gameplay-desert.png" width="380" alt="Desert world — the Ankylosaurus running past an asteroid with dunes, ground pebbles and foot dust">
</p>
<p>
  <img src="screenshots/gameplay-grassland.png" width="380" alt="Grassland world — the long-necked Brachiosaurus running past an asteroid and stars over rolling green hills with grass tufts and floating pollen">
  <img src="screenshots/gameplay-volcanic.png" width="380" alt="Volcanic world — the Stegosaurus running past a lava-edged asteroid and a star, with jagged glowing hills and rising embers">
</p>

*(Screenshots are from live Simulator gameplay, not mockups.)*

## How it works

- **Start** — shows your best score (if any), the currently selected dino with left/right arrows to switch characters, and waits for a tap anywhere to begin.
- **Play** — the dino auto-runs, kicking up little dust puffs as it goes, past rolling parallax hills and a pebble-textured ground; tap anywhere (or the on-screen jump button) to jump, with a whoosh sound effect. Asteroids come in two flavors: ground-level ones you must jump, and elevated ones you must *not* jump into, each trailing small falling embers. Speed and spawn frequency ramp up the longer you survive. Every scoring moment shows a floating "+N" — clearing a ground asteroid mid-air by a hair scores a near-miss bonus with a spark effect, and collectible stars chime when grabbed mid-jump. Every 250 points brings a confetti-and-haptic celebration; every 100 points, the roar button (bottom-left) lights up — tap it to sweep a shockwave across the screen that clears every current asteroid for a bonus, then it greys out until the next 100. A calm, original background loop plays throughout, with a music on/off button on the Start screen and in the HUD (sound effects stay on). A pause button at the top freezes the run and shows your current dino front and center until you tap Resume. The background gradually shifts from cream daylight to dusk to a starry night as your score climbs.
- **Three worlds, three roars** — each dino has its own environment (desert for the Ankylosaurus, grassland for the Brachiosaurus, volcanic for the Stegosaurus) and its own roar: a ground-slam shock ring, a sweeping gust with leaves, or a burst of spike shards, each with its own icon, haptic pattern and sound pitch. Difficulty is identical for every dino — only the look and feel changes.
- **Crash** — a thud, a screen flash, and a haptic thump, then your score and (if beaten) a "New High Score!" callout. Tap anywhere to retry instantly with the same dino, or tap **Change Dino** to head back to the Start screen and pick a different character.
