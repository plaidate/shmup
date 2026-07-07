# shmup — three 1-bit shoot-'em-ups for Playdate

**Tagline:** Three crisp 1-bit shmups on one engine: waves, caves, and a hull run.

Three tiny arcade shooters for the Panic Playdate, built on one shared engine
and drawn entirely in code — solid white ships on black space, no dither, no
external art. **Nova Strike** is a classic top-down wave shooter; **Ravine** is
a Scramble-style cave-flyer where you shoot the sky, bomb the ground, and fight
a draining fuel gauge; **Skimmer** is a Uridium-style hull run with
back-and-forth scrolling that follows wherever you fly.

Each game is a self-contained `.pdx` at a locked 30 fps on the 400×240 screen.
They're small, fast, and pick-up-and-play — d-pad to fly, A to fire, and (in
Ravine) B to bomb. Under the hood every enemy is just a movement pattern plus a
fire pattern and every level is a spawn timeline, which is why three quite
different games share the same tidy core.

## Features

- **Three games, three scroll styles** — vertical waves (Nova Strike),
  horizontal forced-scroll cave (Ravine), bidirectional follow-scroll (Skimmer)
- **Pure 1-bit** — solid shapes, no dither, no muddy grays; all art code-drawn
- **Real arcade loops** — aimed/spread/ring enemy fire, gravity bombs, a
  depleting fuel economy, weaving girders and a follow-camera
- **Instant to learn** — d-pad + A (+ B for bombs), 3 lives, clear the run to win
- **Locked 30 fps** on the 400×240 Playdate screen
- **No assets, MIT-licensed** — build it yourself or sideload the prebuilt PDX

## Controls

- **D-pad** — fly
- **A** — fire (hold to auto-fire; direction is upward, forward, or your facing
  depending on the game)
- **B** — drop a bomb (Ravine only)
- **A** — start / return to title from the GAME OVER and CLEAR banners

Full per-game details, enemy rundowns, and tips are in
[MANUAL.md](../MANUAL.md).

## Install (no dev tools needed)

1. Download **Nova.pdx.zip**, **Ravine.pdx.zip**, and/or **Skimmer.pdx.zip**
   from the Releases page (or the `dist/` folder).
2. Sideload at <https://play.date/account/sideload/> to put it on your Playdate,
   **or** unzip it into the Playdate Simulator.

Each game is independent — grab one or all three.
