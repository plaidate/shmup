# shmup — three 1-bit shoot-'em-ups for Playdate

**Tagline:** Three arcade shmups on one engine — the sky falls, the cave drags, the hull just sits there.

Three tiny shooters for the Panic Playdate, drawn entirely in code: solid white
ships on black space, no dither, no external art. They are deliberately the same
genre seen from three different angles — because what actually separates the
arcade classics is not what they are made of, but **what is nailed down and what
moves**.

**Nova Strike** is the top-down wave shooter: the world falls past you, you hold
the bottom edge, and thirty seconds of raiders end with a Dreadnought that stops
aiming and starts filling the screen. **Ravine** is the Scramble-style
cave-flyer: the cavern drags you left at a rate you cannot change, your fuel
gauge is always draining, and the only way to top it up is to bomb the fuel
dumps on the floor. **Skimmer** is the Uridium-style hull run: 2,400 pixels of
enemy warship that does not move at all, so *you* do — fly it in either
direction, weave the girders, and kill the reactor bolted to the far end.

Every game ends with a boss, and the boss *is* the ending — the level is not
cleared until it comes apart.

## Features

- **Three games, three frames of reference** — vertical waves (Nova Strike),
  forced side-scroll with terrain and fuel (Ravine), and a free camera over a
  fixed level you can fly both ways (Skimmer)
- **A boss at the end of each**, with two phases — and the second half is always
  worse than the first
- **A three-rung weapon ladder**, shields, extra ships, and an extra life at
  20,000 points
- **Real arcade loops** — aimed, spread and ring fire; ballistic bombs you have
  to lead; a fuel economy that will strand you if you get greedy
- **Pure 1-bit** — solid shapes, no dither, no muddy greys; all art code-drawn
- **Locked 30 fps** on the 400×240 screen, with your best score saved
- **No assets, MIT-licensed** — sideload the prebuilt PDX or build it yourself

## Controls

- **D-pad** — fly
- **A** — fire, and hold to auto-fire. Up in Nova Strike, forward in Ravine, and
  in Skimmer whichever way you last flew.
- **B** — drop a bomb (Ravine only — it arcs, so lead your target)
- **A** — start, and return to the title from the GAME OVER and CLEAR banners

Power-up capsules drop from certain enemies: an **arrow** takes your gun up a
rung, a **ring** is a shield that eats one hit, a **cross** is an extra ship.

Full per-game details, enemy rundowns and tips are in
[MANUAL.md](../MANUAL.md).

## Install (no dev tools needed)

1. Download **Nova.pdx.zip**, **Ravine.pdx.zip** and/or **Skimmer.pdx.zip** from
   the Releases page (or the `dist/` folder).
2. Sideload at <https://play.date/account/sideload/> to put it on your Playdate,
   **or** unzip it into the Playdate Simulator.

Each game is independent — grab one or all three.
