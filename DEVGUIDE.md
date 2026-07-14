# shmup — developer guide

This is the architecture guide for the **shmup engine** (`core/`) and the three
games that ship on it (`games/nova`, `games/ravine`, `games/skimmer`). If you
want to play, read [MANUAL.md](MANUAL.md). If you want the reasoning behind the
shapes — why the engine is built around a *frame of reference* at all — read
[DESIGN.md](DESIGN.md). If you want to build a game on it, read on.

## Design in one breath

A shoot-'em-up is a **frame of reference**: what is nailed down, and what moves.
That is the only thing that differs between *Xevious*, *Scramble* and
*Uridium* — the bullets, the pools, the collision, the waves and the score are
identical code in all three. So `core/frame.lua` owns the four questions that
depend on the paradigm (where world coordinates land on the screen, how the
world advances, where the player may be, and which way is forward), every other
module is written once against the frame, and a game picks its paradigm with a
single string:

```lua
Content = { scroll = "vertical", ... }   -- world scrolls down, player screen-locked
Content = { scroll = "side",     ... }   -- world scrolls left at a fixed rate
Content = { scroll = "free",     ... }   -- the level is a place; the camera chases you
```

Everything else about a game is **data**: enemy types compose one `Movers.*` and
one `Firers.*`, bosses are a list of phases, and a level is a `waves` timeline.
All three games are a `Content` table plus a `main.lua` that imports the engine,
writes an autopilot, and calls `Shmup.run(Content, ...)`.

Visual rule, inherited from the OpenTyrian 1-bit port: **solid white shapes on
solid black**, code-drawn at load. No image files, and no dither — at bullet
size the eye cannot resolve a pattern, it resolves the average, and the average
of a 50% dither is a grey smudge. Target is the 400×240 screen at a fixed 30 fps
timestep.

## Repository layout

```
core/            the engine — pure Lua, no per-game knowledge
games/<g>/       one game: main.lua + content.lua + pdxinfo + launcher art
tools/smoke.sh   the autopilot smoke runner (all three games must WIN)
Makefile         stages core/ + games/<g>/ into build/<g>/source, runs pdc
out/             built .pdx (gitignored)
dist/            zipped release builds
build/           staging + smoke screenshots and logs (gitignored)
```

The Makefile matters because `pdc` wants a single source root. `make <game>`
copies `core/*.lua` and `games/<g>/*` into `build/<g>/source/`, writes a
`smokeflag.lua` (`SMOKE_BUILD = false`), and compiles to `out/<Title>.pdx`.
`make <game>-smoke` does the same with `SMOKE_BUILD = true` and an **absolute**
`SMOKE_SHOT_PATH`, for the headless autopilot build.

## The engine (`core/`)

Everything hangs off global namespace tables after the corresponding `import` —
globals-as-modules, `import` not `require`, Lua 5.4. That is the repo
convention across this fleet.

| module | owns |
| --- | --- |
| `frame` | **the scroll frame**: `toScreenX`, `advance`, `bounds`, `fireDir`, `spent`/`cull`, `progress` |
| `lib` | `SCREEN_W/H`, math (`clamp`, `approach`, `sign`, `lerp`, `distSq`, `circlesHit`), and `Pool` |
| `kit` | the cabinet: `Kit.text/centered/panel`, best-score persistence (`loadBest`/`saveBest`) |
| `shmup` | the engine loop: state machine (title/play/over/win), collision, the content contract, `Shmup.run` |
| `player` | the ship: movement, the weapon ladder, shield, lives, invulnerability, fuel |
| `bullets` | two pools (`pp` player, `ep` enemy), `playerFire`/`playerBomb`, `eAimed`/`eSpread`/`eRing` |
| `enemies` | the enemy pool + the `Movers.*` and `Firers.*` behaviour libraries |
| `waves` | the spawn timeline, including boss entries |
| `boss` | the boss state machine: entry, phases, the health bar, the win condition |
| `power` | capsule drops and the weapon ladder |
| `terrain` | the sampled cavern profile — one source of truth, drawn *and* hit |
| `stars` | the parallax field; it asks the frame which way to scroll |
| `fx` | screen shake and hitstop |
| `sprites` | procedural 1-bit sprites, code-drawn at load |
| `snd` | pooled synth SFX |
| `music` | a clock-driven 16-step sequencer |
| `harness` | pcall, counters, the autopilot seam, screenshots — a no-op in release builds |

### The frame

`Frame.init{ mode, speed, levelW, top, bottom }` is called by `Shmup.new` from
the content table. After that:

- **`Frame.toScreenX(x)`** — the world→screen transform. Identity in `vertical`
  and `side` (so the scrollers pay a branch on a local, and nothing else); a
  subtraction of the camera in `free`. Every draw call in `core/` routes through
  it. Entities always live in **frame coordinates**.
- **`Frame.advance(dt, playerX)`** — runs *first* in the update, before anything
  asks where the world is. Scrollers accumulate `Frame.scroll`; `free` clamps
  the camera `Frame.x` to keep the player centred within `levelW`.
- **`Frame.bounds()`** — `minX, maxX, minY, maxY` for the player. In `free` the
  x-range is the whole level; in the scrollers it is the screen.
- **`Frame.fireDir(facing)`** — `(0,-1)` vertical, `(1,0)` side, and the
  player's facing in `free` (where `Frame.flips()` is true and the ship sprite
  mirrors). `Frame.enemyAngle()` is the same question for *them*: down in a
  vertical game, left in a horizontal one.
- **`Frame.spent(x, y)` vs `Frame.cull(x, y)`** — two questions that are easy to
  conflate and expensive to conflate. A bullet is *spent* when it leaves the
  visible box; an enemy is *culled* when it stops existing. In `free`, `cull` is
  **always false**, because the level is a place: its defenders are still
  standing there when you fly back. Cull on camera in free mode and the level
  quietly empties out behind the player.
- **`Frame.visible(x, margin)`** — worth drawing (and, at a wider margin, worth
  *thinking*: a defender parked 1500px away does not run its behaviour).
- **`Frame.progress()`** — camera against level in `free`, `Waves.progress()`
  otherwise.

### The Pool

`Pool.new(cap)` preallocates `cap` entity tables. `spawn()` clears a slot and
returns it (or `nil` when full — spawns silently drop, never allocate).
`update(fn)` runs `fn(e)` over live slots and swap-removes anything the callback
marked `e.dead`; order is **not** preserved. `each(fn)` iterates every live
slot; **`eachLive(fn)` skips the ones killed earlier this frame, and is what you
draw with.**

The slot's `data` sub-table — scratch space for movement behaviours — is cleared
**in place** and handed back. After the first pass through the pool, spawning
allocates nothing, forever.

### The state machine

`Shmup.new(content)` builds the world and enters `TITLE`. `Shmup.update(dt)` and
`Shmup.draw()` dispatch on state:

- **TITLE** → starfield, title, subtitle, best score; `A` starts.
- **PLAY** → `Frame.advance`, then stars, terrain, scene, bullets, enemies,
  power-ups, boss, player, waves, `collide()`, explosions, and (if
  `content.fuel`) the fuel drain.
- **OVER / WIN** → the frozen scene plus a banner; `A` returns to TITLE. Both
  transitions call `Kit.saveBest(score)` and `Music.stop()`.

`collide()` runs player shots (and gravity bombs) against the terrain, the boss
and the enemy pool; then power-up collection; then — only while
`Player.vulnerable()` — the terrain, the scene, enemy bullets, enemy bodies and
the boss hull against the player. `hurtPlayer` is the single place that knows
whether a hit was survivable: a shield eats it, otherwise it costs a life.

**The win condition belongs to the boss.** If a level has one,
`Boss.defeated` is the ending — full stop. Only a boss-less level falls back to
`Waves.finished()` (timeline drained *and* nothing left alive). A level that
declares victory the instant its last scripted grunt drifts off the bottom ends
by accident, and the player reads an accident as a bug.

### The cabinet

`Shmup.run(Content, { autopilot = fn, extra = fn })` owns everything a game used
to copy-paste: the refresh rate (`0` in smoke builds, `30` otherwise), the
random seed, `Shmup.new`, the harness wiring, the system-menu "restart" item,
and `playdate.update` itself (with `Harness.frame` around a `tick` that times
update and draw into the `updMs`/`drwMs` counters). A `main.lua` is imports, an
autopilot closure, and one call.

Best scores persist to the **`best`** datastore key, written only when a run
actually beats the stored best.

## Building a game on it

A game is a folder with four things: `pdxinfo`, `launcher/` art, `content.lua`
and `main.lua`.

### The content table

```lua
Content = {
    scroll   = "side",              -- "vertical" | "side" | "free"
    title    = "MY SHMUP",
    subtitle = "side frame",
    winText  = "CAVERN CLEAR",

    speed    = 66,                  -- world speed, px/s        (side)
    levelW   = 2400,                -- level extent             (free)
    top, bottom,                    -- the player's vertical box (optional)
    enemyCap = 64,

    fuel     = true,                -- a depleting gauge
    fuelRate = 2.6,                 -- %/s (default 3.4)

    terrain  = { groundBase = SCREEN_H - 26, groundAmp = 22,
                 ceilBase = 34, ceilAmp = 12 },   -- optional cavern (side)

    scene    = { build = fn, update = fn(dt), draw = fn,
                 hits = fn(x, y, r) },            -- optional static level (free)

    sprites  = function() Sprites.define("ufo", 16, 9, function(w, h) ... end) end,
    music    = { bpm = 120, bass = {...}, lead = {...}, hat = {...} },  -- 16 steps each

    enemies  = { name = { sprite, hp, r, score, fuel, drop, move, fire } },
    bosses   = { name = { sprite, hp, r, score, from, enter, phases } },
    waves    = { { t, type, x, y, n, dx, dy }, { t, boss = "name" } },
}
```

**Enemies.** `move` and `fire` are `fn(e, dt)` closures; `e.data` is the
behaviour's scratch space (reused, never reallocated). `drop = "gun"` always
drops a capsule; `drop = { "shield", 0.3 }` drops one 30% of the time. `fuel = 45`
tops the gauge up by 45 when the thing dies.

- **Movers** — vertical: `straight(speed)`, `sine(speed, amp, freq)`,
  `dropHover(targetY, dropSpeed, driftAmp, driftFreq)`. Side: `left(speed)`,
  `leftSine(speed, amp, freq)`, `groundLeft(yoff)` (rides the terrain surface —
  it takes **no** speed argument, because it reads `Frame.speed`), and
  `rocketUp(riseSpeed)`. Free: `station(amp, freq)` (a defender bobbing on its
  post) and `patrol(speed, range)`.
- **Firers** — `none()`, `aimed(interval, speed)`, `spread(interval, count, arc,
  speed, center)` (the centre defaults to `Frame.enemyAngle()`, so a spread
  enemy fires *at the player's side of the world*, whichever frame it is in),
  `ring(interval, count, speed)`, and `aimedNear(interval, speed, range)` —
  which only fires when the player is within reach, so a free-frame defender
  does not spend the whole level shooting at nobody.

**Bosses.** A boss is a small state machine, not an enemy with a lot of HP. It
enters from `from` to `enter` (immune on the way in, and never culled, because
it is not in the pool), then picks a phase by remaining HP fraction — the first
entry whose `above` the fraction still exceeds:

```lua
dreadnought = {
    sprite = "dread", hp = 70, r = 30, score = 5000,
    from  = { x = 200, y = -40 },
    enter = { x = 200, y = 54 },
    phases = {
        { above = 0.5, move = fn(b, dt), fire = fn(b, dt) },   -- the opening
        { above = 0.0, move = fn(b, dt), fire = fn(b, dt) },   -- the desperate one
    },
}
```

`b.data` is the boss's scratch table (cleared on every arm); `b.t` is time in
the current state. It draws its own health bar, and when its HP reaches zero it
spends 1.6 seconds coming apart before setting `Boss.defeated` — the one moment
in the game when nothing is trying to kill you.

**Waves.** An ordered list, walked in order:

```lua
{ t = 5.5,   type = "darter", x = 60, n = 5, dx = 70 }   -- n copies, spaced by (dx, dy)
{ t = 33,    boss = "dreadnought" }                      -- arm the boss at a TIME
{ at = 1900, boss = "core" }                             -- ...or at a PLACE
```

`t` is seconds since the level started; `at` is a player x. Both exist because
the frame decides which one means anything. In a scroller the world comes to you
at a fixed rate, so a time *is* a distance. In the free frame the world does not
move at all — you can hover, or fly backwards — so a clock indexes nothing, and
the only honest trigger is where the player actually is.

### The main.lua

```lua
import "lib"     import "harness"  import "frame"   import "kit"
import "snd"     import "music"    import "fx"      import "sprites"
import "stars"   import "terrain"  import "bullets" import "enemies"
import "power"   import "boss"     import "player"  import "waves"
import "shmup"   import "content"

Shmup.run(Content, {
    autopilot = Harness.enabled and makeBot() or nil,
    extra = function(t) t.bossActive = Boss.active and 1 or 0 end,
})
```

The only game-specific code in a `main.lua` is the autopilot — and the autopilot
is a smoke test, not a game feature.

### Adding a game to the collection

1. `mkdir games/<name>`; add it to `GAMES := nova ravine skimmer` in the Makefile.
2. Write a `pdxinfo` (name, author, `bundleID=com.sdwfrost.shmup.<name>`,
   version, buildNumber, `imagePath=launcher`) and drop launcher art in
   `games/<name>/launcher/`.
3. Write `content.lua` (schema above) and `main.lua` (copy one).
4. Write the bot. It has to **win**.
5. `make <name>` to build, `make run-<name>` to play it, `tools/smoke.sh <name>`
   to prove it.

## Testing

```sh
make smoke                 # all three, headless; PASS only if each bot WON
tools/smoke.sh nova 120    # one game, with a timeout in seconds
```

`tools/smoke.sh` builds the instrumented variant, launches it in the Playdate
Simulator, polls the game's datastore, and reports. The bar is deliberately
high: **a run is green only when the bot reached the win screen** (`"wins":1` in
the heartbeat). A bot that survives without winning is a bot that has quietly
stopped testing the second half of the game — including every boss in the repo.

The harness (`core/harness.lua`, active only when `SMOKE_BUILD`) pcall-wraps the
update and logs any error to the `err` datastore key; writes `Harness.counters`
(state, wins, deaths, score, best, lives, enemies, weapon, bossHp, progress,
`updMs`, `drwMs`, plus whatever the game's `extra` hook adds) to the `smoke` key
every 90 frames; feeds `Harness.autopilot()` into the game's input; and, in the
simulator, dumps PNGs to `SMOKE_SHOT_PATH` at frame 30 and every 300 frames.
Results land in `results/<game>.json` and screenshots in `build/<game>-shot*.png`.

Each bot is written against its **frame**, which is the point:

- **nova** holds the bottom edge, keeps the gun under whatever is closest to
  reaching it, and dodges by solving for where each bullet *will be* when it
  crosses the player's row (the first version compared current positions and
  died to the boss's angled shots every run).
- **ravine** flies the gap by sampling `Terrain.groundY`/`ceilY` — the same
  profile the collider reads — and solves the ballistic drop point for its bombs
  against a target that is itself sliding left.
- **skimmer** is the only one that can fail by being **slow**, because the free
  frame's level has a far end to reach. It treats a girder as a forbidden *band*
  rather than a commanded altitude, so it can still dodge inside the corridor
  during the boss fight.

## What was wrong (the rewrite's bug list)

Kept here because each one is a category, not an incident.

- **The picture and the collision were different shapes.** Ravine's cavern was
  drawn as a polygon sampled every 16px and collided against the exact
  continuous sine that generated it. Between samples the true curve bows away
  from the chord, so the wall you *saw* was not the wall you *hit* — sub-pixel,
  invisible in a screenshot, absent from every counter, and felt as an unfair
  death nobody could reproduce. Now `Terrain.sample()` fills one profile and
  both `draw` and `hits` read it.
- **The pool was a table factory.** `Enemies.spawn` ended with `e.data = {}` —
  a fresh table per spawn, which is exactly the allocation the pool exists to
  avoid, reintroduced one line below the pool that avoids it. `Pool:spawn` now
  clears `data` in place.
- **`Firers.spread` hardcoded its centre at `pi/2`**, so spread enemies in a
  horizontal game fanned their shots politely into the floor. The centre now
  comes from `Frame.enemyAngle()`.
- **`Movers.groundLeft` took a speed that had to secretly equal the terrain's**,
  kept in sync by a comment in the content file. Comments do not keep numbers in
  sync; it now reads `Frame.speed`.
- **Dead entities were drawn for one frame after being killed** — collision marks
  `e.dead` mid-frame and compaction happens on the next update, so a corpse was
  drawn on top of its own explosion. Hence `Pool:eachLive`.
- **The boss rendered as a white rectangle for the entire fight.** The enemy hit
  flash fills the silhouette solid, which reads as damage for two frames; a boss
  under sustained fire takes a hit eight times a second, so the flash never let
  go. Removed — damage is legible from the health bar and the impact sound.
- **Nova's smoke screenshots went nowhere for its entire life**, because the path
  was a string hand-typed into each game's `main.lua` and one of the three had a
  stray repo prefix. The Makefile now writes an absolute `SMOKE_SHOT_PATH`, so
  no human types it at all.

## Build

Requires the Playdate SDK (`pdc` on `PATH`).

```sh
make nova            # -> out/Nova.pdx
make run-ravine      # build + open in the Simulator
make skimmer-smoke   # instrumented autopilot build
make all             # every game, release builds
make smoke           # every game's bot must beat its game
make dist            # release builds, zipped into dist/
make clean
```

## License

MIT — see [LICENSE](LICENSE). All art is code-drawn; there are no third-party
assets.
