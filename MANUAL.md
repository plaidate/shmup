# shmup — player's manual

Three little 1-bit shoot-'em-ups on one engine: a vertical wave shooter, a
Scramble-style cave-flyer, and a Uridium-style back-and-forth hull run. Solid
white ships on black space, no dither, no fuss. Each is a separate `.pdx` you
sideload; pick your poison below.

Shared basics: the **d-pad** flies, **A** fires (auto-repeats while held), and
you get **3 lives**. Losing a life recentres you with a brief blink of
invulnerability. Clear the run to win; run out of lives and it's GAME OVER —
press **A** to return to the title from either banner. Score is shown top-left,
lives top-right.

---

## Nova Strike

*Hold the line against wave after wave of descending raiders.*

A classic top-down vertical shooter. Enemies pour in from the top in scripted
waves — sweeping columns, weaving divers, hovering gun platforms — and your job
is to shoot them all before they shoot (or ram) you. Survive the whole
~30-second wave script and the sky clears.

**Controls**

- **D-pad** — fly (all four directions)
- **A** — fire twin forward shots (hold to auto-fire)

**How to play**

Your ship sits near the bottom and fires straight up in two parallel streams.
Enemies enter from the top and move down; some track you and spit bullets.
Weave through the fire, keep the trigger down, and thin each wave as it arrives.
Colliding with an enemy or an enemy bullet costs a life. Clear the timeline
(all waves spawned *and* nothing left alive) to reach **CLEAR!**

**Scoring**

- Grunt — 100
- Darter — 150
- Weaver — 200
- Gunner — 300

**Enemies**

- **Grunt** — a plain drone that flies straight down. Doesn't shoot. 1 hit.
  Arrives in sweeping columns.
- **Darter** — a fast arrowhead that weaves side-to-side as it descends.
  Doesn't shoot, but the wide sine path makes it hard to line up. 1 hit.
- **Weaver** — a tougher grunt (2 hits) on a slower, wider weave that **fires
  aimed shots** at you every couple of seconds.
- **Gunner** — a heavy gun platform (3 hits). Drops to the top of the screen,
  then hovers and drifts while firing a **3-shot spread** downward. The main
  threat; often arrives in pairs on opposite sides.

**Tips**

- Stay mobile horizontally — the twin streams are narrow, so line up kills by
  sliding under targets rather than chasing them.
- Kill gunners first; their spread fills the screen while grunts and darters
  can only hurt you by collision.
- Darters telegraph their arc — pick the side they're weaving toward and let
  them come to your bullets.
- Weavers and gunners take multiple hits; keep firing *through* them rather
  than tapping.
- When two gunners flank you, sit centre-bottom and pick the gaps between the
  two spreads.

---

## Ravine

*Thread a scrolling cavern, shoot the sky, bomb the ground, and don't run dry.*

A horizontal, forced-scroll Scramble-style flyer. The cave scrolls past you at
a fixed pace; you can move anywhere on screen but you can't slow the world down.
Air targets need forward fire, ground targets need bombs, the walls kill on
touch, and a **fuel gauge drains constantly** — so you have to keep bombing the
fuel dumps to stay airborne.

**Controls**

- **D-pad** — fly through the cavern gap
- **A** — fire forward (hold to auto-fire)
- **B** — drop a bomb (arcs down onto the ground)

**How to play**

Fly the black gap between the white ceiling and floor — touching either wall
costs a life. Forward shots handle the air threats (UFOs, rising rockets);
bombs lob downward under gravity to hit ground targets (tanks, fuel dumps).
The **fuel bar** at the top ticks down the whole time; bomb a **fuel dump** to
top it back up. Empty fuel costs a life just like a crash. Reach the end of the
wave run to clear the ravine.

**Scoring**

- Fuel dump — 100 (and refuels you)
- Rocket — 150
- Tank — 200
- UFO — 250

**Enemies & hazards**

- **Cavern walls** — the white ceiling and floor silhouettes. Instant life loss
  on contact; there is no shooting them, only avoiding them.
- **UFO** — an airborne saucer that weaves in on a sine path and **fires aimed
  shots** at you. Kill with forward fire. 1 hit.
- **Rocket** — launches from the ground and **rises** while drifting with the
  scroll. Doesn't shoot, but climbs into your lane. 1 hit; forward fire.
- **Tank** — rides along the ground surface and **lobs aimed shots** upward.
  2 hits, and it sits on the floor — you'll usually need a **bomb** to reach it.
- **Fuel dump** — looks like a tank but doesn't shoot; **bomb it to refuel**
  (+30 fuel) and score 100. Missing these is what eventually strands you.

**Tips**

- Fuel is the real enemy. Prioritise bombing every fuel dump even if it means
  ignoring a UFO — a full gauge buys you time, a kill doesn't.
- Bombs arc *forward and down*, so release them a little before you're over a
  ground target, not directly on top of it.
- Hug the centre of the gap through tight sections; the walls undulate and a
  narrow pinch will clip you if you're riding one edge.
- You keep firing forward while bombing — hold **A** constantly and tap **B**
  as ground targets slide into range.
- Rockets rise into you from below; watch the floor for launches and drift up
  early.

---

## Skimmer

*Skim the hull of a vast dreadnought, weaving girders and picking off defenders
— any direction you like.*

A Uridium-style demo of **bidirectional** scrolling. You pilot a fast skimmer
over a long warship hull; fly left or right and the camera follows, so the
world scrolls whichever way you go. It's about reading the girders and reversing
direction, not just holding right. Reach the far end of the hull to clear it.

**Controls**

- **D-pad** — fly in any direction; **left/right also sets your facing**
- **A** — fire in the direction you're facing (hold to auto-fire)

**How to play**

The top and bottom hull bands are solid; you fly the space between them. Girders
jut down from the ceiling and up from the floor — **crashing into one costs a
life**, so weave through the gaps. Your gun fires whichever way you last moved
horizontally, so to shoot a defender behind you, tap back toward it first. The
position bar at the top shows how far along the hull you are; run all the way to
the right end to reach **HULL CLEARED**.

**Scoring**

- Defender — 200 each

**Enemies & hazards**

- **Girders** — white pillars alternating from ceiling and floor. Static, but a
  crash is a lost life. These are the whole navigation puzzle.
- **Defenders** — arrow-shaped guns anchored along the hull, each **bobbing up
  and down** on its own sine. They don't fire, but ramming one costs you a life
  (and destroys it). Shoot them from range in your facing direction. 1 hit, 200
  points.

**Tips**

- Facing follows your last horizontal input — nudge toward a target before
  firing, or you'll shoot the empty side.
- Use the back-and-forth freedom: overshoot a girder cluster, then reverse to
  clean up defenders you passed.
- Defenders bob predictably — wait for one to drift into your lane rather than
  chasing it into a girder.
- The position bar is your map; if it's crawling you're fighting the walls, not
  the level. Commit to gaps.
- Invulnerability blinks after a crash — use that window to reposition out of a
  tight girder run before it wears off.
