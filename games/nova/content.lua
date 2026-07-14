-- Nova Strike: the whole game as data, in the VERTICAL frame. Enemy types
-- compose the engine's Movers.* / Firers.* behaviours; the wave script is an
-- ordered spawn timeline that ends by arming a boss. There is no game logic in
-- this file because there is no game logic in this game -- swap these tables out
-- and you have a different shmup on the same engine.

local gfx <const> = playdate.graphics

Content = {
    title = "NOVA STRIKE",
    subtitle = "vertical frame",
    scroll = "vertical",
    enemyCap = 64,
    winText = "SECTOR CLEAR",

    sprites = function()
        -- the boss: a broad dreadnought, solid white, with black gun ports
        Sprites.define("dread", 108, 52, function(w, h)
            gfx.fillRect(10, 4, w - 20, h - 22)
            gfx.fillTriangle(0, 12, 10, 4, 10, h - 18)
            gfx.fillTriangle(w, 12, w - 10, 4, w - 10, h - 18)
            gfx.fillRect(w / 2 - 22, h - 20, 44, 12)
            gfx.fillTriangle(w / 2 - 30, h - 20, w / 2 + 30, h - 20, w / 2, h)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(24, 12, 10, 8)
            gfx.fillRect(w - 34, 12, 10, 8)
            gfx.fillRect(w / 2 - 4, 8, 8, 10)
            gfx.setColor(gfx.kColorWhite)
        end)
    end,

    music = {
        bpm = 138,
        bass = { 36, 0, 36, 0, 43, 0, 36, 0, 34, 0, 34, 0, 41, 0, 34, 0 },
        lead = { 72, 0, 0, 76, 0, 79, 0, 0, 77, 0, 0, 74, 0, 71, 0, 0 },
        hat  = { 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1 },
    },

    enemies = {
        grunt  = { sprite = "grunt", hp = 1, r = 6, score = 100,
                   move = Movers.straight(80), fire = Firers.none(),
                   drop = { "gun", 0.2 } },

        darter = { sprite = "darter", hp = 1, r = 5, score = 150,
                   move = Movers.sine(120, 55, 3.0), fire = Firers.none() },

        weaver = { sprite = "grunt", hp = 2, r = 6, score = 200,
                   move = Movers.sine(70, 90, 2.2),
                   fire = Firers.aimed(2.2, 120),
                   drop = { "gun", 0.3 } },

        gunner = { sprite = "gunner", hp = 3, r = 9, score = 300,
                   move = Movers.dropHover(56, 55, 44, 1.2),
                   fire = Firers.spread(1.8, 3, 0.7, 120),
                   drop = { "shield", 0.5 } },
    },

    bosses = {
        -- Two phases. The first is a stately sweep you can out-position. The
        -- second -- once it is half dead -- is the one that kills you: it stops
        -- aiming and starts filling the screen.
        dreadnought = {
            sprite = "dread", hp = 70, r = 30, score = 5000,
            from  = { x = 200, y = -40 },
            enter = { x = 200, y = 54 },
            phases = {
                {
                    above = 0.5,
                    move = function(b, dt)
                        b.x = 200 + math.sin(b.t * 0.8) * 110
                    end,
                    fire = function(b, dt)
                        local d = b.data
                        d.t = (d.t or 0) + dt
                        if d.t >= 1.5 then
                            d.t = 0
                            Bullets.eSpread(b.x, b.y + 20, 5, 1.2, 130)
                        end
                    end,
                },
                {
                    above = 0.0,
                    move = function(b, dt)
                        b.x = 200 + math.sin(b.t * 1.5) * 130
                    end,
                    fire = function(b, dt)
                        local d = b.data
                        d.t = (d.t or 0) + dt
                        if d.t >= 1.1 then
                            d.t = 0
                            d.ph = (d.ph or 0) + 0.3
                            Bullets.eRing(b.x, b.y + 10, 10, 105, d.ph)
                            Bullets.eAimed(b.x, b.y + 20, 150)
                        end
                    end,
                },
            },
        },
    },

    waves = {
        { t = 1.0,  type = "grunt",  x = 80,  n = 4, dx = 60 },
        { t = 3.0,  type = "grunt",  x = 340, n = 4, dx = -60 },
        { t = 5.5,  type = "darter", x = 60,  n = 5, dx = 70 },
        { t = 8.0,  type = "gunner", x = 120 },
        { t = 8.0,  type = "gunner", x = 280 },
        { t = 11.0, type = "weaver", x = 100, n = 3, dx = 100 },
        { t = 14.0, type = "darter", x = 340, n = 6, dx = -56 },
        { t = 17.0, type = "gunner", x = 200 },
        { t = 18.0, type = "grunt",  x = 40,  n = 6, dx = 64 },
        { t = 22.0, type = "weaver", x = 80,  n = 4, dx = 80 },
        { t = 26.0, type = "gunner", x = 100 },
        { t = 26.0, type = "gunner", x = 300 },
        { t = 28.0, type = "darter", x = 60,  n = 6, dx = 56 },
        { t = 33.0, boss = "dreadnought" },
    },
}
