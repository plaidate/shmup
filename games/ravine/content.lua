-- Ravine: a Scramble-style cave-flyer in the SIDE frame, entirely as data.
-- The world scrolls left at a rate you cannot change; you fly the gap, shoot
-- the air targets (UFOs, rockets) and BOMB the ground targets (tanks, fuel
-- dumps). Fuel drains constantly -- kill the dumps to top up. Original game, no
-- arcade assets.
--
-- Note what is NOT here any more: the old version opened with a constant named
-- TSPEED and the comment "must match terrain scroll so ground units ride it",
-- because the terrain's speed and the ground-movers' speed were two separate
-- numbers a human had to keep equal. Now there is one number -- the frame's --
-- and Movers.groundLeft reads it.

local gfx <const> = playdate.graphics

Content = {
    title = "RAVINE",
    subtitle = "side frame",
    scroll = "side",
    speed = 66,             -- the world's speed. The ONLY place it is stated.
    fuel = true,
    fuelRate = 2.6,
    enemyCap = 64,
    winText = "CAVERN CLEAR",

    terrain = { groundBase = SCREEN_H - 26, groundAmp = 22,
                ceilBase = 34, ceilAmp = 12 },

    music = {
        bpm = 120,
        bass = { 33, 0, 33, 0, 40, 0, 33, 0, 31, 0, 31, 0, 38, 0, 31, 0 },
        lead = { 0, 0, 64, 0, 67, 0, 0, 69, 0, 0, 67, 0, 64, 0, 0, 0 },
        hat  = { 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0 },
    },

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
        Sprites.define("dump", 16, 12, function(w, h)
            gfx.fillRect(1, 2, w - 2, h - 2)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(4, 5, 3, 5)          -- an "F", punched out
            gfx.fillRect(9, 5, 3, 2)
            gfx.setColor(gfx.kColorWhite)
        end)
        Sprites.define("ufo", 16, 9, function(w, h)
            gfx.fillEllipseInRect(0, 3, w, 5)
            gfx.fillEllipseInRect(w / 2 - 3, 0, 6, 5)
        end)
        -- the boss: a gun barge that noses in from the right
        Sprites.define("barge", 62, 74, function(w, h)
            gfx.fillRect(14, 0, w - 14, h)
            gfx.fillTriangle(14, 0, 14, h, 0, h / 2)
            gfx.fillRect(0, h / 2 - 5, 16, 10)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(24, 12, 8, 8)
            gfx.fillRect(24, h - 20, 8, 8)
            gfx.fillRect(38, h / 2 - 6, 12, 12)
            gfx.setColor(gfx.kColorWhite)
        end)
    end,

    enemies = {
        rocket = { sprite = "rocket", hp = 1, r = 5, score = 150,
                   move = Movers.rocketUp(95), fire = Firers.none() },

        tank   = { sprite = "tank", hp = 2, r = 8, score = 200,
                   move = Movers.groundLeft(7), fire = Firers.aimed(2.2, 100),
                   drop = { "gun", 0.3 } },

        dump   = { sprite = "dump", hp = 1, r = 8, score = 100, fuel = 45,
                   move = Movers.groundLeft(8), fire = Firers.none() },

        ufo    = { sprite = "ufo", hp = 1, r = 7, score = 250,
                   move = Movers.leftSine(130, 42, 2.4),
                   fire = Firers.aimed(1.7, 120),
                   drop = { "shield", 0.25 } },
    },

    bosses = {
        -- The barge fires SPREADS, and it is the enemy that caught the bug:
        -- Firers.spread used to hardcode its centre angle at pi/2, so a spread
        -- enemy in a side-scroller fanned its shots politely into the floor. The
        -- centre now comes from Frame.enemyAngle() -- leftward, at you.
        barge = {
            sprite = "barge", hp = 48, r = 28, score = 6000,
            from  = { x = 460, y = 120 },
            enter = { x = 330, y = 120 },
            phases = {
                {
                    above = 0.5,
                    move = function(b, dt)
                        b.y = 120 + math.sin(b.t * 0.9) * 46
                    end,
                    fire = function(b, dt)
                        local d = b.data
                        d.t = (d.t or 0) + dt
                        if d.t >= 1.6 then
                            d.t = 0
                            Bullets.eSpread(b.x - 30, b.y, 3, 0.9, 135)
                        end
                    end,
                },
                {
                    above = 0.0,
                    move = function(b, dt)
                        b.y = 120 + math.sin(b.t * 1.6) * 58
                    end,
                    fire = function(b, dt)
                        local d = b.data
                        d.t = (d.t or 0) + dt
                        if d.t >= 1.3 then
                            d.t = 0
                            Bullets.eSpread(b.x - 30, b.y, 4, 1.2, 145)
                            Bullets.eAimed(b.x - 30, b.y, 165)
                        end
                    end,
                },
            },
        },
    },

    -- Everything spawns just off the right edge. Ground units are snapped to the
    -- terrain by groundLeft, so their y only has to be roughly right.
    waves = {
        { t = 1.5,  type = "ufo",    x = 420, y = 60 },
        { t = 3.0,  type = "dump",   x = 420, y = 200 },
        { t = 4.5,  type = "rocket", x = 420, y = 202 },
        { t = 6.0,  type = "tank",   x = 420, y = 200 },
        { t = 7.5,  type = "ufo",    x = 420, y = 100, n = 3, dy = -28 },
        { t = 10.0, type = "rocket", x = 420, y = 202, n = 2, dx = -70 },
        { t = 12.0, type = "dump",   x = 420, y = 200 },
        { t = 13.5, type = "tank",   x = 420, y = 200, n = 2, dx = -90 },
        { t = 16.0, type = "ufo",    x = 420, y = 70,  n = 4, dy = 22 },
        { t = 19.0, type = "rocket", x = 420, y = 202, n = 3, dx = -55 },
        { t = 21.0, type = "dump",   x = 420, y = 200 },
        { t = 23.0, type = "tank",   x = 420, y = 200, n = 2, dx = -80 },
        { t = 26.0, type = "dump",   x = 420, y = 200 },
        { t = 27.0, type = "ufo",    x = 420, y = 90,  n = 4, dy = 20 },
        { t = 32.0, boss = "barge" },
    },
}
