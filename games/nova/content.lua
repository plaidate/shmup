-- Nova Strike: the whole game as data. Enemy types compose the engine's
-- Movers.* / Firers.* behaviours; the wave script is an ordered spawn
-- timeline. Swap these tables out to make a different shmup on the same engine.

Content = {
    title = "NOVA STRIKE",
    enemyCap = 64,

    enemies = {
        grunt  = { sprite = "grunt",  hp = 1, r = 6, score = 100,
                   move = Movers.straight(80),              fire = Firers.none() },
        darter = { sprite = "darter", hp = 1, r = 5, score = 150,
                   move = Movers.sine(120, 55, 3.0),        fire = Firers.none() },
        weaver = { sprite = "grunt",  hp = 2, r = 6, score = 200,
                   move = Movers.sine(70, 90, 2.2),         fire = Firers.aimed(2.2, 120) },
        gunner = { sprite = "gunner", hp = 3, r = 9, score = 300,
                   move = Movers.dropHover(56, 55, 44, 1.2),
                   fire = Firers.spread(1.8, 3, 0.7, 120) },
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
    },
}
