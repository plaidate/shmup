# shmup — developer guide

This is the architecture guide for the **shmup engine** (`core/`) and the three
games that ship on it (`games/nova`, `games/ravine`, `games/skimmer`). If you
want to play, read [MANUAL.md](MANUAL.md). If you want to build a new game on
the engine, read on.

## Design in one breath

A shmup is *mostly data*. The engine owns the loop, collision, pools, sprites,
HUD, and a small library of reusable enemy **movement** and **fire** behaviours.
A game is a `Content` table: a few tunables, a set of enemy types that each
compose one `Movers.*` + one `Firers.*`, and a `waves` spawn timeline. Two of
the three games are literally nothing but that table plus a four-line
`main.lua`. The third (`skimmer`) is a worked example of building a *different*
kind of game directly on the engine's reusable primitives.

Visual rule, inherited from the OpenTyrian 1-bit port: **solid white shapes on
black**, code-drawn at load so there are zero external assets and nothing turns
to muddy dither. Target is the 400×240 Playdate screen at a fixed 30 fps
timestep.

## Repository layout

```
core/            the engine — pure Lua, no per-game knowledge
games/<g>/       one folder per game: main.lua + content/game + config + pdxinfo
Makefile         stages core/ + games/<g>/ into build/<g>/source, runs pdc
out/             built .pdx (gitignored)
build/           staging + smoke screenshots (gitignored)
```

The Makefile matters because `pdc` wants a single source root. `make <game>`
copies `core/*.lua` and `games/<g>/*` into `build/<g>/source/`, writes a
`smokeflag.lua` (`SMOKE_BUILD = false`), and compiles that to
`out/<Title>.pdx`. `make <game>-smoke` does the same with `SMOKE_BUILD = true`
for the headless autopilot build.

## The engine (`core/`)

Everything hangs off global namespace tables (`Lib`, `Pool`, `Sprites`,
`Stars`, `Terrain`, `Camera`, `Bullets`, `Enemies`, `Movers`, `Firers`,
`Player`, `Waves`, `Shmup`, `Harness`) after the corresponding `import`. This is
the repo convention — globals-as-modules, `import` not `require`, Lua 5.4.

| module | responsibility |
| --- | --- |
| `lib` | `SCREEN_W/H`, math helpers (`clamp`, `approach`, `sign`, `distSq`), circle collision (`circlesHit`), `offscreen`, and the fixed-capacity `Pool` |
| `sprites` | procedural 1-bit sprites drawn once into images; the 4-frame explosion; `Sprites.define(name,w,h,fn)` for game-specific art |
| `stars` | two-layer parallax starfield, scrolls `"down"` (vertical) or `"left"` (horizontal) |
| `terrain` | Scramble-style scrolling cavern (ground + ceiling silhouettes), collision (`Terrain.hits`), and a `groundY` query so ground enemies ride the surface |
| `camera` | horizontal follow-camera over a fixed-width level, clamped to the ends, for Uridium-style back-and-forth scrolling |
| `bullets` | player pool (`pp`) + enemy pool (`ep`), fire helpers (`playerUp/Right/Bomb`), enemy patterns (`eAimed/eSpread/eRing`); bullets may carry gravity (`grav`) |
| `enemies` | the enemy pool + `Enemies.define/spawn`, plus the reusable `Movers.*` and `Firers.*` behaviour factories |
| `player` | ship movement, auto-fire, bombs, lives, invulnerability blink, fuel |
| `waves` | the spawn-timeline driver — reads `content.waves`, spawns on schedule, reports `finished()` |
| `shmup` | the engine proper: state machine (title/play/over/win), collision, explosions, HUD, input; orientation-aware |
| `harness` | smoke-test autopilot + heartbeat + screenshot hook; a no-op in release builds |

### The Pool

`Pool.new(cap)` preallocates `cap` entity tables. `spawn()` returns a cleared
slot (or `nil` when full — spawns silently drop, never allocate). `update(fn)`
runs `fn(e)` over live slots and swap-removes any the callback marked
`e.dead` (order is **not** preserved). `each(fn)` iterates without removing.
This is the no-per-frame-allocation backbone; everything transient (bullets,
enemies, explosions) lives in a Pool.

### The state machine

`Shmup.new(content)` builds the world and enters `TITLE`. `Shmup.update(dt)`
and `Shmup.draw()` dispatch on state:

- **TITLE** → starfield + centred title; `A` starts.
- **PLAY** → step stars, terrain, bullets, enemies, player, waves, then
  `collide()`, explosions, and (if `content.fuel`) drain fuel. Transitions to
  **OVER** when the player is dead, **WIN** when `Waves.finished()` (timeline
  exhausted *and* no enemies left alive).
- **OVER / WIN** → frozen scene + banner; `A` returns to TITLE.

`collide()` runs three passes: player shots vs enemies (and vs terrain for
gravity bombs), enemy bullets vs player, enemy bodies vs player. The player is
only checked while `Player.vulnerable()` (alive and not in the post-hit
invulnerability window), which also prevents multiple hits in one frame.

### The harness

The Makefile stages `smokeflag.lua` into every build. When `SMOKE_BUILD` is
false the harness is a pass-through. When true, `Harness.frame(frame, fn)`:
pcall-wraps the update (logging any error to the `err` datastore), writes a
heartbeat of `Harness.counters` to the `smoke` datastore every 90 frames, lets
the game's input read from `Harness.autopilot()`, and — in the simulator —
dumps a PNG via `playdate.simulator.writeToFile` to `Harness.shotPath` at
frame 30 and every 300 frames (both a stable path and a frame-stamped one).
Each game's `main.lua` installs its own autopilot closure (sweep + hold fire +
pulse `A`) and sets `shotPath`. `playdate.display.setRefreshRate(0)` in smoke
builds runs the loop as fast as possible.

## Content schema (vertical / terrain games)

`nova` and `ravine` are pure `Content` tables handed to `Shmup.new`:

```lua
Content = {
    scroll   = "horizontal",   -- or "vertical" (default)
    title    = "MY SHMUP",
    fuel     = true,           -- optional depleting fuel gauge
    enemyCap = 64,             -- optional enemy pool size
    terrain  = { speed = 66, groundBase = SCREEN_H - 26, groundAmp = 22,
                 ceilBase = 34, ceilAmp = 12 },  -- optional cavern
    sprites  = function() Sprites.define("ufo", 16, 9, function(w,h) ... end) end,
    enemies  = {
        raider = { sprite = "grunt", hp = 1, r = 6, score = 100,
                   move = Movers.left(120), fire = Firers.aimed(1.5, 120) },
    },
    waves = { { t = 1.0, type = "raider", x = 420, y = 80, n = 4, dy = 30 } },
}
```

**Movers** (each returns `fn(e, dt)`):
`straight(speed)`, `sine(speed, amp, freq)`, `dropHover(targetY, drop, amp, freq)`
for vertical; `left(speed)`, `leftSine(speed, amp, freq)`,
`groundLeft(speed, yoff)` (snaps to the terrain surface),
`rocketUp(worldSpeed, riseSpeed)` for horizontal.

**Firers** (each returns `fn(e, dt)`):
`none()`, `aimed(interval, speed)` (fires at the player),
`spread(interval, count, arc, speed)`, `ring(interval, count, speed)`.

**Waves** entries `{ t, type, x, y, n, dx, dy }`: at time `t` (seconds), spawn
`n` copies of `type` starting at `(x, y)` and spaced by `(dx, dy)`. Vertical
games default `y` to just above the top; horizontal games pass `x = 420` (just
off the right edge). The timeline is one-shot; when it drains and all enemies
are gone the player **wins**.

## Adding a new game to the collection

1. `mkdir games/<name>`; add it to `GAMES := nova ravine skimmer` in the
   Makefile.
2. Write a `pdxinfo` (name, author, `bundleID=com.sdwfrost.shmup.<name>`,
   version, buildNumber).
3. Add `config.lua` (`Config = { DT = 1/30 }`) — the fixed timestep.
4. Add `content.lua` with your `Content` table (see schema above), plus any
   game-specific sprites in `content.sprites`.
5. Add `main.lua`: `import` the engine modules you need, then
   `import "config"` / `import "content"`, `Shmup.new(Content)`, and a
   `playdate.update` that calls `Harness.frame(frame, ...)` around
   `Shmup.update(Config.DT)` + `Shmup.draw()`. Copy an existing `main.lua`;
   the only per-game part is the autopilot closure and the `shotPath`.
6. `make <name>` to build, `make run-<name>` to try it in the Simulator.

If your game is not a "spawn waves and shoot them" shmup — like `skimmer`,
which is a bidirectional follow-scroll flyer over a fixed-width level — skip
`Shmup`/`Waves` and build directly on `Pool`, `Sprites`, `Lib`, `Camera`, and
`Harness`. `games/skimmer/game.lua` is the reference for that path: it owns its
own state machine, level generation, collision, and draw, but reuses the
pools, the sprite factory, the follow-camera, and the smoke harness.

## Per-game notes

- **nova (Nova Strike)** — the pure vertical shooter. Four enemy types (grunt,
  darter, weaver, gunner) composing the vertical movers/firers over a
  ~30-second wave script. The minimal example: just `content.lua`.
- **ravine** — horizontal forced-scroll Scramble cave-flyer. Adds
  `terrain`, `fuel`, and three custom sprites (rocket, tank, ufo). Ground units
  use `groundLeft` at the same speed as the terrain scroll so they ride the
  surface; `fuel` pickups refill the constantly-draining gauge. Bombs (B) use
  gravity to arc onto ground targets.
- **skimmer** — Uridium-style bidirectional flyer, the "build directly on the
  primitives" example. Self-contained in `game.lua` (`Sk` table): a
  2400-px-wide dreadnought hull, procedurally placed girders you weave, and
  defenders you shoot in your facing direction, all under the follow-`Camera`.

## Building

Requires the Playdate SDK (`pdc` on `PATH`).

```sh
make nova            # -> out/Nova.pdx
make run-ravine      # build + open in the Simulator
make skimmer-smoke   # instrumented autopilot build for headless testing
make all             # every game, release builds
make clean
```

## License

MIT — see [LICENSE](LICENSE). All art is code-drawn; there are no third-party
assets.
