# shmup — design

The engine's thesis, the problems it exists to solve, and the reasoning
behind the shapes in `core/`. If you want to *play*, read
[MANUAL.md](MANUAL.md). If you want to *build*, read
[DEVGUIDE.md](DEVGUIDE.md). This file is why.

## The thesis: a shmup is a frame of reference

Every other engine in this fleet is about a **representation**. Phosphor is
about lines. Tiles is about the grid. Voxel is about volume. Dither is about
shade. Lore is about story state. Each one answers "what is the world made
of?", and everything else follows.

Ask that question about a shoot-'em-up and you get a boring answer: sprites,
bullets, a scrolling background. That answer is boring because it is not the
question. Line up the genre's landmarks and the thing that actually differs
between them is not what they are made of — it is **what is nailed down and
what moves**:

| Game | The world | The player | The camera |
|---|---|---|---|
| *Xevious*, *Tyrian* | scrolls past, forever | locked to the screen | fixed |
| *Scramble*, *Defender* | scrolls past at a rate you cannot change | locked to the screen | fixed |
| *Uridium* | is a fixed place with two ends | flies *through* it | chases the player |

Those three rows are the whole genre, and everything below them — bullets,
pools, collision, waves, explosions, the score — is *identical code*. A grunt
that dives at you does not care whether it is diving through a scrolling
starfield or over a stationary dreadnought. Only four things care:

1. where world coordinates land on the screen,
2. how the world advances each frame,
3. where the player is allowed to be,
4. which way is "forward" (so bullets, and the ship, know where to point).

So that is the engine. **`core/frame.lua` owns those four questions and
nothing else owns them.** A frame is a scroll paradigm made into an object;
choosing one is a single string in a game's content table. Everything else in
`core/` is written *once*, against the frame, and works in all three.

```lua
Content = { scroll = "vertical", ... }   -- Nova Strike
Content = { scroll = "side",     ... }   -- Ravine
Content = { scroll = "free",     ... }   -- Skimmer
```

This is what the engine was missing. The previous version advertised three
scroll paradigms and shipped two: `camera.lua` was twenty-two lines, and
Skimmer — the game that was supposed to prove the third — reimplemented the
player, the bullets, the enemies, the collision, the HUD and the state machine
in 244 lines of its own, *beside* the engine rather than on it. An engine
whose third pillar is a copy-paste of the first two is not an engine with
three pillars. Making the frame explicit is what turns the claim into a fact:
Skimmer is now a content table like the others, and the code it used to
duplicate is deleted.

## The five hard problems

### 1. One set of coordinates, three worlds

The temptation is to let each paradigm use whatever coordinates are
convenient: screen coordinates for the scrollers (the world is *only* ever the
screen, after all) and world coordinates for the free camera. That is exactly
how the old engine drifted apart, and it is why Skimmer could not reuse
`Player` or `Bullets`: those modules were written in screen space, and Skimmer
needed world space.

The fix is to make **every entity live in frame coordinates** and to route
every draw through `Frame.toScreen`. In `vertical` and `side` the transform is
the identity, so the scrollers pay nothing for the abstraction — literally
nothing, because the transform is a branch on a local. In `free`, it is a
subtraction of the camera. One rule, three behaviours, zero special cases in
the modules that do not care.

The corollary is that *offscreen* is a frame question too. A bullet in
`vertical` is spent when it leaves the 400×240 box; in `free` it is spent when
it leaves the *camera's* box; and an enemy in `free` must not be culled for
being off-camera at all, because the level is a place that exists whether or
not you are looking at it. `Frame.spent(x, y)` and `Frame.cull(x, y)` are
different questions, and conflating them is how you get a level whose enemies
evaporate the moment you fly away from them.

### 2. The picture and the collision must be the same shape

Ravine's cavern was drawn as a polygon sampled every 16 pixels — a chain of
straight chords — and collided against the exact, continuous sine that
generated it. The two are not the same curve. Between samples the true curve
bows away from the chord, so the wall you *see* is not the wall you *hit*:
near a crest the ship dies in visibly empty black; in a trough it flies
through white pixels.

The error here is under a pixel, which is precisely what makes it instructive.
It is invisible in a screenshot, it will never show up in a counter, and it
will absolutely be *felt* — as the occasional unfair death that the player
cannot explain and you cannot reproduce. The rule the engine now enforces is
blunt: **there is one profile, it is sampled, and both the renderer and the
collider read the same samples.** `Terrain.sample()` fills the sample array;
`Terrain.draw` fills the polygon from it; `Terrain.hits` linearly interpolates
*within* it. If you want a smoother wall, raise the sample rate and both
halves get smoother together. They cannot disagree, because there is no second
source of truth for them to disagree about.

### 3. Pools that actually pool

A fixed-capacity pool with swap-remove exists to make spawning free. The old
`Enemies.spawn` ended with `e.data = {}` — a fresh table for every enemy that
ever spawns, which is the allocation the pool was built to avoid, reintroduced
one line below the pool that avoids it. A bullet-hell frame with forty spawns
is forty tables for the collector to find later, and the pause it eventually
takes will land in the middle of a boss.

`Pool:spawn` now clears the slot's `data` sub-table **in place** and hands the
same table back. After the first pass through the pool, spawning allocates
nothing, forever. This is the general shape of the lesson: a pool is only as
good as its coldest field, and the way to check is not to read the pool — it
is to read every `spawn` call site looking for a `{}`.

### 4. A boss is not a big enemy

It is tempting to model the boss as an enemy with a lot of hit points, and for
about ten minutes that works. Then you want it to enter from off-screen
without being culled, to be immune while entering, to change its fire pattern
when it is hurt, to hold the wave timeline open until it dies, and to be the
thing that *ends the level*. None of that is "an enemy with more HP"; all of
it is a small state machine with its own phase list.

`core/boss.lua` is that state machine, and the wave timeline gains one entry
type (`{ t = 40, boss = "dreadnought" }`) that arms it. The rule that keeps it
honest is that **the boss owns the win condition**: a level with a boss is
cleared when the boss dies, not when the spawn script runs out. Without that
rule you get the old engine's ending, where the level "wins" the instant the
last scripted enemy happens to leave the screen — an anticlimax the player
reads as a bug.

### 5. The autopilot has to be able to win

Every game in this fleet ships a bot that plays it, because that bot is the
smoke test — it is the only thing that runs the whole game on every build. The
discipline that keeps the bot useful is that **it must reach the ending**. A
bot that merely survives will happily survive forever, and a bot that farms
(the Lore engine's autopilot once ground 57 kills off a boss's endlessly
respawning summons without ever touching the boss) looks exactly like a bot
that is working.

So each game's autopilot here is written against its *frame*: the vertical bot
dodges by column and leads its shots; the side bot flies the gap by *sampling
the same terrain profile the collider uses* (a bot that read the true sine
instead would fly into walls, which is a rather emphatic way of proving
problem 2); and the free bot navigates a level with two ends, which means it
has somewhere to *get to* and can therefore fail by being slow. All three beat
their game, boss included, and the build fails if they stop.

## What is in `core/`

| Module | Owns |
|---|---|
| `frame.lua` | **the scroll frame**: transform, advance, bounds, forward, progress |
| `lib.lua` | math helpers, `Pool` (swap-remove, allocation-free) |
| `kit.lua` | the cabinet: `Shmup.run`, HUD text, panels, best-score persistence |
| `shmup.lua` | the engine loop: state machine, collision, the content contract |
| `player.lua` | the ship: movement, weapon levels, shield, lives, invulnerability |
| `bullets.lua` | two pools, player patterns, enemy patterns (aimed/spread/ring) |
| `enemies.lua` | the enemy pool + the `Movers.*` / `Firers.*` behaviour libraries |
| `waves.lua` | the spawn timeline, including boss entries |
| `boss.lua` | the boss state machine: entry, phases, the win condition |
| `power.lua` | drops and the weapon ladder |
| `terrain.lua` | the sampled cavern profile — one source of truth, drawn and hit |
| `stars.lua` | the parallax field (frame-aware: it scrolls whichever way the frame does) |
| `fx.lua` | screen shake, hit flash, freeze frames |
| `sprites.lua` | procedural 1-bit sprites, code-drawn at load |
| `snd.lua` | synth SFX |
| `music.lua` | the clock-driven step sequencer |
| `harness.lua` | pcall, counters, autopilot seam, screenshots |

## The visual rule

Inherited from the 1-bit OpenTyrian port and non-negotiable: **solid white
shapes on solid black**, code-drawn at load, no image files. At this contrast,
on this screen, a dithered sprite the size of a bullet is a grey smudge — the
eye cannot resolve the pattern, so it resolves the average, and the average of
a 50% dither is exactly the thing you most need your bullets *not* to be.
Dither is for the Dither engine's big soft shapes. A shmup is small fast
shapes, and small fast shapes must be solid.
