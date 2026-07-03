# shmup

A generic **1-bit shoot-'em-up engine** for the [Panic Playdate](https://play.date/),
written in pure Playdate Lua and targeted at the 400×240 screen. The visual
approach follows the lesson from porting OpenTyrian to 1-bit: **solid white
sprites on black space**, code-drawn so there are no external assets and nothing
turns to muddy dither.

The engine supports **three scroll paradigms**, and ships a demo of each:

| game | style | shows |
| --- | --- | --- |
| `nova` (Nova Strike) | vertical shooter | classic top-down waves |
| `ravine` | horizontal forced-scroll cave-flyer | Scramble-style terrain + fuel + bombs |
| `skimmer` | bidirectional follow-scroll | Uridium-style **back-and-forth** scrolling |

Games are almost entirely *data* — enemy types compose a small library of
movement/fire behaviours, and waves are a spawn timeline.

## Engine (`core/`)

| module | responsibility |
| --- | --- |
| `lib` | math helpers, the fixed-capacity `Pool` (swap-remove), circle collision |
| `sprites` | procedural 1-bit sprites (ships, bullets, explosions), drawn once |
| `stars` | parallax starfield, scrolling down (vertical) or left (horizontal) |
| `terrain` | a scrolling Scramble-style cavern with collision (horizontal games) |
| `camera` | a horizontal follow-camera over a fixed-width level (Uridium-style) |
| `bullets` | player/enemy bullet pools + patterns (`aimed`, `spread`, `ring`), bombs |
| `enemies` | enemy pool + reusable `Movers.*` and `Firers.*` behaviours |
| `player` | ship movement, auto-fire, bombs, lives, invulnerability, fuel |
| `waves` | the spawn-timeline driver |
| `shmup` | the engine: state machine (title/play/over/win), collision, HUD |
| `harness` | smoke-test autopilot + screenshot hook (no-op in release builds) |

## Making a game

Provide a `content` table and hand it to `Shmup.new`:

```lua
Content = {
    scroll = "horizontal",         -- or "vertical" (default)
    title = "MY SHMUP",
    fuel = true,                    -- optional depleting fuel gauge
    terrain = { speed = 66 },       -- optional scrolling cavern
    enemies = {
        raider = { sprite = "grunt", hp = 1, r = 6, score = 100,
                   move = Movers.left(120), fire = Firers.aimed(1.5, 120) },
    },
    waves = { { t = 1.0, type = "raider", x = 420, y = 80, n = 4, dy = 30 } },
}
Shmup.new(Content)
```

Then in `playdate.update()` call `Shmup.update(dt)` and `Shmup.draw()`. The
follow-camera game (`skimmer`) shows how to build a world-space game directly on
the reusable primitives (`Pool`, `Sprites`, `Lib`, `Camera`).

Controls: d-pad moves, **A** fires, **B** bombs (horizontal games).

## Build

Requires the Playdate SDK (`pdc` on `PATH`).

```sh
make nova            # -> out/Nova.pdx
make run-ravine      # build + open in the Simulator
make skimmer-smoke   # instrumented autopilot build for headless testing
make all             # every game
```

## License

MIT — see [LICENSE](LICENSE).
