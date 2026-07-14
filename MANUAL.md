# shmup — player's manual

Three little 1-bit shoot-'em-ups on one engine. They are the same genre seen
from three different **frames of reference** — in Nova Strike the world falls
past you, in Ravine it drags you along, and in Skimmer it does not move at all
and you fly *through* it. Solid white ships on black space, no dither, no fuss.

Each is a separate `.pdx` you sideload. Pick your poison below.

## The basics (all three games)

- **D-pad** — fly.
- **A** — fire. Hold it; the gun auto-repeats. (Which way it fires depends on
  the frame: up in Nova Strike, forward in Ravine, and in Skimmer whichever way
  you last flew.)
- **B** — drop a bomb. Ravine only; there is nothing to bomb in the other two.
- **A** on the title screen starts a run. **A** on the GAME OVER or CLEAR banner
  takes you back to the title.

You get **3 lives**. Losing one gives you a moment of blinking invulnerability
to get out of whatever killed you — and knocks your gun back down a rung, which
is usually the bigger loss. **An extra life at 20,000 points.** Your best score
is saved and shown on the title screen.

**Power-up capsules** drop from certain enemies and drift for a few seconds
before blinking out:

| capsule | effect |
| --- | --- |
| **arrow** | one rung up the weapon ladder |
| **ring** | a shield — it absorbs exactly one hit, then it is gone |
| **cross** | an extra ship |

The **weapon ladder** has three rungs, shown as three pips next to your score.
Rung 1 is a single shot; rung 2 splits it into a twin; rung 3 adds an angled
pair on top of the twin, and fires faster as well. A gun at full rung roughly
doubles your damage — which is exactly what a boss health bar is measured in.
(The three levels here hand out arrows and rings; the cross is what 20,000
points is for.)

Every game ends with a **boss**, and the boss *is* the ending: the level is not
cleared until it comes apart. Its health bar runs along the bottom of the
screen. Bosses change their behaviour once they are about half dead, and the
second half is always worse than the first.

---

## Nova Strike — the vertical frame

*Hold the line while the sky falls on you.*

A classic top-down wave shooter, in the frame *Xevious* invented: the world
scrolls down past a ship that is locked to the screen. Enemies pour in from the
top in scripted waves — sweeping columns, weaving divers, hovering gun platforms
— for about thirty seconds, and then the **Dreadnought** arrives.

**Controls**

- **D-pad** — fly (all four directions)
- **A** — fire straight up (hold to auto-fire)

**How to play**

Sit low, keep the trigger down, and thin each wave as it arrives. Colliding with
an enemy or an enemy bullet costs a life. Kill the Dreadnought to reach **SECTOR
CLEAR**.

**Enemies**

- **Grunt** (100) — a plain drone that flies straight down and does not shoot.
  One hit. Arrives in sweeping columns. Sometimes drops a gun capsule.
- **Darter** (150) — a fast arrowhead that weaves hard as it descends. Does not
  shoot, but the wide sine makes it awkward to line up.
- **Weaver** (200) — a tougher grunt (2 hits) on a slower, wider weave that
  **fires aimed shots** at you every couple of seconds. Drops guns.
- **Gunner** (300) — a heavy gun platform (3 hits). Drops to the top of the
  screen, then hovers and drifts while firing a **3-shot spread** downward. The
  main threat, and the best source of shields — often arriving in pairs on
  opposite sides.
- **Dreadnought** (5,000) — the boss. It sweeps across the top firing a wide
  spread you can out-position; below half health it stops aiming and starts
  filling the screen with **rings**, plus an aimed shot straight at you.

**Tips**

- Stay low. Every pixel of altitude you give up is reaction time you buy back.
- Kill gunners first. Grunts and darters can only hurt you by collision;
  gunners fill the screen.
- The Dreadnought's aimed shot is launched *at an angle*. Do not dodge to where
  the bullet is — dodge out of the row it will be in when it arrives.
- When two gunners flank you, sit centre-bottom and read the gaps between the
  two spreads rather than running for a side.

---

## Ravine — the side frame

*Thread a scrolling cavern, bomb the fuel dumps, and do not run dry.*

A Scramble-style cave-flyer, in the frame where the world scrolls left **at a
rate you cannot change**. You can go anywhere on the screen; you cannot slow the
cavern down. Air targets need forward fire, ground targets need bombs, the walls
kill on touch, and the **fuel gauge drains constantly**.

**Controls**

- **D-pad** — fly the gap
- **A** — fire forward (hold to auto-fire)
- **B** — drop a bomb (it arcs forward and down)

**How to play**

Fly the black gap between the white ceiling and the white floor; touching either
costs a life. Shoot the air (UFOs, rising rockets); bomb the ground (tanks, fuel
dumps). The **fuel bar** across the top ticks down the whole time and an empty
tank costs a life exactly like a crash — so **bombing the fuel dumps is not
optional**. The dumps are the crates with an "F" punched out of them; each one is
worth 45% of a tank. Kill the **Barge** at the end to reach **CAVERN CLEAR**.

**Enemies and hazards**

- **Cavern walls** — solid white ceiling and floor. Instant life loss on contact.
  You cannot shoot them; you can only fly them.
- **Fuel dump** (100, **+45 fuel**) — an inert ground crate marked "F". Bomb it.
  Missing these is what strands you.
- **Rocket** (150) — launches off the floor and climbs straight up through the
  gap while the world carries it left. Does not shoot; it does not need to.
- **Tank** (200) — rides the ground surface and **lobs aimed shots** upward. Two
  hits, and it is on the floor, so bring a bomb. Drops guns.
- **UFO** (250) — an airborne saucer weaving in on a sine, **firing aimed shots**.
  Forward fire kills it. Best source of shields.
- **Barge** (6,000) — the boss. A gun platform that noses in from the right and
  fires **spreads** while sliding up and down; below half health the spreads
  widen, quicken, and come with an aimed shot.

**Tips**

- Fuel is the real enemy. Bomb every dump even if it means letting a UFO live —
  a full gauge buys time; a kill does not.
- **Bombs are ballistic.** They leave the ship moving forward and fall under
  gravity, and the target is sliding *toward* you meanwhile. Release early; the
  drop point is well short of the thing you are aiming at.
- You can fire and bomb at once. Hold **A** permanently and tap **B**.
- Rockets climb into the exact middle of the gap — which is where you were
  planning to be. Watch the floor for launches and commit high or low early.
- Hug the centre through tight pinches; the walls undulate, and riding an edge
  through a narrowing section is how you clip one.

---

## Skimmer — the free frame

*Skim a two-kilometre dreadnought hull, in either direction, and kill what is
bolted to the far end.*

The *Uridium* frame, and the odd one out. The level is a **place**, not a
timeline: 2,400 pixels of enemy warship that is simply *there*. Fly left or
right and the camera follows you; the defenders you passed are still standing
where you left them, and so is anything you did not finish.

**Controls**

- **D-pad** — fly; **left/right also sets your facing**
- **A** — fire in the direction you are facing (hold to auto-fire)

**How to play**

The top and bottom hull bands are solid; you fly the corridor between them.
**Girders** jut down from the ceiling and up from the floor, alternating — hit
one and it costs a life, so pick your side of the corridor *early*. Shoot the
defenders; they shoot back once you are in range. The **position bar** at the
top is your map: it is the only way to see that a level with two ends has ends.
Fly to the far end and the reactor **Core** wakes up. Kill it to reach **HULL
CLEARED**.

If you die, you come back a little *short* of where you fell rather than at the
start — the ship you already cleared stays cleared.

**Enemies and hazards**

- **Girders** — white pillars from the ceiling and the floor. Static, silent, and
  a crash is a life. They are the whole navigation puzzle.
- **Defender** (200) — an arrowhead gun anchored to the hull, bobbing on its post.
  It **fires aimed shots at you, but only when you are close enough to matter**.
  One hit. Sometimes drops a gun capsule.
- **Sentry** (350) — a tougher defender (2 hits) that **patrols** a stretch of the
  hull rather than holding a post. Drops shields.
- **Core** (8,000) — the boss, and the reason you came. It does not enter: it has
  been bolted to the end of the ship the whole time, and you are the one who
  arrives. It fires slowly rotating **rings**; below half health it starts moving,
  throws more of them, and aims one shot straight at you.

**Tips**

- Facing follows your last horizontal input. To shoot something behind you, tap
  back toward it first — otherwise you will hose the empty side.
- A girder forbids a *band*, it does not command an altitude. Work out which
  half of the corridor is open, then move freely inside it. You still have to
  dodge in there.
- Use the reverse. Overshoot a girder cluster, then come back and clean up the
  defenders you flew past — nothing you left behind has gone anywhere.
- Do not fight the Core at point-blank. Its rings spawn *on top of you* at close
  range; stand off far enough that you can see the whole thing and still have
  room to dodge.
- The position bar is the clock. If it has stopped, you are fighting the hull
  and not the level. Commit to the gaps.
