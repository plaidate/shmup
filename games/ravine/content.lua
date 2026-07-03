-- Ravine: a horizontal Scramble-style cave-flyer, entirely as data on the
-- shmup engine. Scroll right through a cavern; forward-fire the air targets
-- (UFOs, rockets) and BOMB the ground targets (tanks, fuel dumps). Fuel drains
-- constantly — bomb the fuel dumps to top up. Original game, no arcade assets.

local gfx <const> = playdate.graphics
local TSPEED <const> = 66 -- must match terrain scroll so ground units ride it

Content = {
    title = "RAVINE",
    scroll = "horizontal",
    fuel = true,
    enemyCap = 64,

    terrain = { speed = TSPEED, groundBase = SCREEN_H - 26, groundAmp = 22,
                ceilBase = 34, ceilAmp = 12 },

    -- game-specific 1-bit sprites (added after the core set)
    sprites = function()
        Sprites.define("rocket", 8, 15, function(w, h)
            gfx.fillTriangle(w / 2, 0, 0, 5, w, 5)
            gfx.fillRect(w / 2 - 2, 4, 4, h - 6)
            gfx.fillRect(0, h - 3, 2, 3)
            gfx.fillRect(w - 2, h - 3, 2, 3)
        end)
        Sprites.define("tank", 16, 10, function(w, h)
            gfx.fillRect(0, h - 3, w, 3)
            gfx.fillRect(2, 3, w - 4, 4)
            gfx.fillRect(w / 2 - 1, 0, 3, 4)
        end)
        Sprites.define("ufo", 16, 9, function(w, h)
            gfx.fillEllipseInRect(0, 3, w, 5)
            gfx.fillEllipseInRect(w / 2 - 3, 0, 6, 5)
        end)
    end,

    enemies = {
        rocket = { sprite = "rocket", hp = 1, r = 5, score = 150,
                   move = Movers.rocketUp(TSPEED, 95), fire = Firers.none() },
        tank   = { sprite = "tank", hp = 2, r = 8, score = 200,
                   move = Movers.groundLeft(TSPEED, 7), fire = Firers.aimed(2.2, 100) },
        fuel   = { sprite = "tank", hp = 1, r = 8, score = 100, fuel = 30,
                   move = Movers.groundLeft(TSPEED, 7), fire = Firers.none() },
        ufo    = { sprite = "ufo", hp = 1, r = 7, score = 250,
                   move = Movers.leftSine(130, 42, 2.4), fire = Firers.aimed(1.7, 120) },
    },

    -- all spawn just off the right edge; ground units are snapped to the
    -- terrain by groundLeft, so their y just needs to be near the ground
    waves = {
        { t = 1.5,  type = "ufo",    x = 420, y = 60 },
        { t = 3.0,  type = "fuel",   x = 420, y = 200 },
        { t = 4.5,  type = "rocket", x = 420, y = 202 },
        { t = 6.0,  type = "tank",   x = 420, y = 200 },
        { t = 7.5,  type = "ufo",    x = 420, y = 100, n = 3, dy = -28 },
        { t = 10.0, type = "rocket", x = 420, y = 202, n = 2, dx = -70 },
        { t = 12.0, type = "fuel",   x = 420, y = 200 },
        { t = 13.5, type = "tank",   x = 420, y = 200, n = 2, dx = -90 },
        { t = 16.0, type = "ufo",    x = 420, y = 70,  n = 4, dy = 22 },
        { t = 19.0, type = "rocket", x = 420, y = 202, n = 3, dx = -55 },
        { t = 21.5, type = "fuel",   x = 420, y = 200 },
        { t = 23.0, type = "tank",   x = 420, y = 200, n = 2, dx = -80 },
        { t = 26.5, type = "ufo",    x = 420, y = 90,  n = 5, dy = 20 },
    },
}
