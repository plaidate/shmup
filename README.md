# shmup

> Part of **[plAIdate](https://plaidate.github.io)** — AI-built 1-bit games, ports, and engines for the Playdate. Source: **[github.com/plaidate](https://github.com/plaidate)**.

A **1-bit shoot-'em-up engine** for the [Panic Playdate](https://play.date/),
written in pure Playdate Lua for the 400×240 screen, with three games on top —
one per scroll frame. The visual approach follows the lesson from porting
OpenTyrian to 1-bit: **solid white sprites on black space**, code-drawn, so there
are no external assets and nothing turns to muddy dither.

## The idea

Every other engine in this fleet is about a *representation* — lines, tiles,
voxels, shade. Ask "what is a shmup made of?" and you get a boring answer:
sprites, bullets, a scrolling background. That is because it is the wrong
question. What actually differs between *Xevious*, *Scramble* and *Uridium* is
**what is nailed down and what moves** — the frame of reference. Everything
below it (bullets, pools, collision, waves, bosses, the score) is identical code.

So `core/frame.lua` owns exactly four questions — where world coordinates land on
the screen, how the world advances, where the player may be, and which way is
forward — and a game picks its paradigm with one string:

| game | `scroll` | the frame | lineage |
| --- | --- | --- | --- |
| **Nova Strike** | `"vertical"` | the world scrolls down past a screen-locked ship | *Xevious* |
| **Ravine** | `"side"` | the world scrolls left at a rate you cannot change | *Scramble* |
| **Skimmer** | `"free"` | the level is a fixed-width **place**; the camera chases you | *Uridium* |

Everything else is data. An enemy type composes one movement behaviour and one
fire behaviour; a boss is a list of phases; a level is a spawn timeline. All
three games are a `Content` table plus a `main.lua` that calls `Shmup.run`.

- **Players:** [MANUAL.md](MANUAL.md) — how to play all three, with enemy
  rundowns and tips.
- **Developers:** [DEVGUIDE.md](DEVGUIDE.md) — the architecture, the content
  schema, and how to add a game.
- **Why it is shaped like this:** [DESIGN.md](DESIGN.md) — the thesis and the
  five hard problems.

## Play it

Prebuilt `.pdx` bundles ship in `dist/` and on the [Releases](../../releases)
page — no toolchain needed. Download `Nova.pdx.zip`, `Ravine.pdx.zip` or
`Skimmer.pdx.zip`, then sideload at <https://play.date/account/sideload/> or
unzip into the Playdate Simulator.

D-pad flies, **A** fires, **B** bombs (Ravine). Capsules upgrade your gun over
three rungs, or give you a shield or an extra ship. Every game ends with a boss,
and the boss is the ending. Best scores are saved.

## Engine (`core/`)

| module | owns |
| --- | --- |
| `frame` | **the scroll frame**: the world→screen transform, the advance, the player's bounds, forward, and what counts as offscreen |
| `lib` | math helpers, the fixed-capacity `Pool` (swap-remove, allocation-free) |
| `kit` | the cabinet: HUD text, panels, best-score persistence |
| `shmup` | the engine loop: state machine, collision, the content contract, `Shmup.run` |
| `player` | the ship: movement, the weapon ladder, shield, lives, fuel |
| `bullets` | player/enemy pools, patterns (`aimed`, `spread`, `ring`), ballistic bombs |
| `enemies` | the enemy pool plus the reusable `Movers.*` / `Firers.*` behaviours |
| `waves` | the spawn timeline, keyed on time — or, in the free frame, on place |
| `boss` | the boss state machine: entry, phases, the win condition |
| `power` | capsule drops and the weapon ladder |
| `terrain` | the sampled cavern — **one** profile, drawn and hit |
| `stars` | the parallax field; it asks the frame which way to scroll |
| `fx` / `snd` / `music` | screen shake and hitstop; pooled synth SFX; a 16-step sequencer |
| `sprites` | procedural 1-bit sprites, code-drawn at load |
| `harness` | the smoke-test seam: pcall, counters, autopilot, screenshots |

## Making a game

```lua
Content = {
    scroll   = "side",              -- "vertical" | "side" | "free"
    title    = "MY SHMUP",
    speed    = 66,                  -- the world's speed, stated once
    fuel     = true,
    terrain  = { groundBase = SCREEN_H - 26, ceilBase = 34 },
    enemies  = {
        raider = { sprite = "grunt", hp = 1, r = 6, score = 100,
                   move = Movers.leftSine(130, 42, 2.4),
                   fire = Firers.aimed(1.5, 120),
                   drop = { "gun", 0.3 } },
    },
    bosses   = { barge = { sprite = "barge", hp = 48, score = 6000,
                           from = { x = 460, y = 120 },
                           enter = { x = 330, y = 120 },
                           phases = { ... } } },
    waves    = { { t = 1.5, type = "raider", x = 420, y = 80, n = 4, dy = 30 },
                 { t = 32,  boss = "barge" } },
}
```

Then `Shmup.run(Content)` in `main.lua`. That is the whole game.

## Testing

```sh
make smoke
```

Each game ships an autopilot, and the autopilot **must beat the game, boss and
all** — `tools/smoke.sh` runs all three headless in the Simulator and passes only
on `"wins":1`. A bot that merely survives has quietly stopped testing the second
half of the game.

## Build

Requires the Playdate SDK (`pdc` on `PATH`).

```sh
make nova            # -> out/Nova.pdx
make run-ravine      # build + open in the Simulator
make skimmer-smoke   # instrumented autopilot build
make all             # every game
make smoke           # every bot must win
make dist            # zipped releases in dist/
```

## License

MIT — see [LICENSE](LICENSE). All art is code-drawn; there are no third-party
assets.
