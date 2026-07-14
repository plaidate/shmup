-- Skimmer: a Uridium-style hull-runner in the FREE frame, as data.
--
-- This game is the reason the engine was rewritten. It used to be 244 lines of
-- its own -- its own player, its own bullets, its own enemies, its own
-- collision, its own HUD, its own state machine -- sitting NEXT TO the engine,
-- because the engine was written in screen coordinates and this game needed
-- world coordinates. Once the frame owns the transform, none of that is
-- special: a level with two ends is just a frame whose camera moves, and
-- Skimmer becomes a content table like the other two.
--
-- The level is a PLACE, not a timeline. Its defenders stand at fixed posts and
-- they are still standing there when you fly back past them, because
-- Frame.cull() refuses to delete anything in free mode. And the boss is armed
-- by POSITION, not by the clock: in a frame where the world does not move, time
-- is not a proxy for distance.

local gfx <const> = playdate.graphics

local LEVEL_W <const> = 2400
local HULL_T <const> = 20              -- the hull bands, top and bottom
local HULL_B <const> = SCREEN_H - 20

Level = { girders = {} }               -- read by scene.hits, and by the bot

local function rectHit(cx, cy, r, rx, ry, rw, rh)
    local nx = Lib.clamp(cx, rx, rx + rw)
    local ny = Lib.clamp(cy, ry, ry + rh)
    return Lib.distSq(cx, cy, nx, ny) <= r * r
end

Content = {
    title = "SKIMMER",
    subtitle = "free frame",
    scroll = "free",
    levelW = LEVEL_W,
    top = HULL_T + 8,
    bottom = HULL_B - 8,
    enemyCap = 40,
    winText = "HULL CLEARED",

    music = {
        bpm = 148,
        bass = { 40, 0, 40, 47, 0, 40, 0, 45, 38, 0, 38, 45, 0, 38, 0, 43 },
        lead = { 0, 76, 0, 0, 79, 0, 81, 0, 0, 79, 0, 76, 0, 0, 74, 0 },
        hat  = { 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1 },
    },

    sprites = function()
        Sprites.define("defender", 12, 12, function(w, h)
            gfx.fillTriangle(0, h / 2, w, 1, w, h - 1)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(w - 5, h / 2 - 1, 3, 2)
            gfx.setColor(gfx.kColorWhite)
        end)
        -- the boss: the reactor core, bolted to the far end of the ship
        Sprites.define("core", 70, 96, function(w, h)
            gfx.fillRect(6, 0, w - 12, h)
            gfx.fillRect(0, 14, w, h - 28)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillCircleAtPoint(w / 2, h / 2, 18)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillCircleAtPoint(w / 2, h / 2, 9)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(8, 8, 8, 6)
            gfx.fillRect(w - 16, 8, 8, 6)
            gfx.fillRect(8, h - 14, 8, 6)
            gfx.fillRect(w - 16, h - 14, 8, 6)
            gfx.setColor(gfx.kColorWhite)
        end)
    end,

    -- The static level: the hull you fly over, and the girders you weave.
    scene = {
        build = function()
            local g = Level.girders
            for i = #g, 1, -1 do g[i] = nil end
            local x, top = 300, true
            while x < LEVEL_W - 520 do   -- the boss arena stays clear of girders
                g[#g + 1] = { x = x, w = 22, top = top, h = math.random(34, 82) }
                top = not top
                x = x + math.random(160, 250)
            end
        end,

        hits = function(px, py, r)
            for _, p in ipairs(Level.girders) do
                if math.abs(p.x - px) < 40 then
                    local ry = p.top and HULL_T or (HULL_B - p.h)
                    if rectHit(px, py, r, p.x - p.w / 2, ry, p.w, p.h) then
                        return true
                    end
                end
            end
            return false
        end,

        draw = function()
            -- Hull bands, with panel seams that slide past as the camera moves.
            -- In the free frame the seams are what tell you the ship is moving
            -- at all: the stars are too far away to parallax convincingly on
            -- their own, and a stationary world with no near reference reads as
            -- a stationary world.
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(0, 0, SCREEN_W, HULL_T)
            gfx.fillRect(0, HULL_B, SCREEN_W, SCREEN_H - HULL_B)
            gfx.setColor(gfx.kColorBlack)
            for sx = -(Frame.x % 24), SCREEN_W, 24 do
                gfx.drawLine(sx, 0, sx, HULL_T)
                gfx.drawLine(sx, HULL_B, sx, SCREEN_H)
            end

            gfx.setColor(gfx.kColorWhite)
            for _, p in ipairs(Level.girders) do
                if Frame.visible(p.x, 30) then
                    local sx = Frame.toScreenX(p.x)
                    local y = p.top and HULL_T or (HULL_B - p.h)
                    gfx.fillRect(sx - p.w / 2, y, p.w, p.h)
                end
            end
        end,
    },

    enemies = {
        defender = { sprite = "defender", hp = 1, r = 6, score = 200,
                     move = Movers.station(28, 2.2),
                     fire = Firers.aimedNear(1.8, 130, 230),
                     drop = { "gun", 0.35 } },

        sentry   = { sprite = "defender", hp = 2, r = 6, score = 350,
                     move = Movers.patrol(70, 90),
                     fire = Firers.aimedNear(1.5, 150, 250),
                     drop = { "shield", 0.3 } },
    },

    bosses = {
        -- It does not enter. It is bolted to the end of the ship and has been
        -- there the whole time; you are the one who arrives.
        core = {
            sprite = "core", hp = 60, r = 34, score = 8000,
            from  = { x = 2210, y = 120 },
            enter = { x = 2210, y = 120 },
            phases = {
                {
                    above = 0.5,
                    fire = function(b, dt)
                        local d = b.data
                        d.t = (d.t or 0) + dt
                        if d.t >= 1.5 then
                            d.t = 0
                            d.ph = (d.ph or 0) + 0.4
                            Bullets.eRing(b.x, b.y, 8, 115, d.ph)
                        end
                    end,
                },
                {
                    above = 0.0,
                    move = function(b, dt)
                        b.y = 120 + math.sin(b.t * 1.2) * 40
                    end,
                    fire = function(b, dt)
                        local d = b.data
                        d.t = (d.t or 0) + dt
                        if d.t >= 1.2 then
                            d.t = 0
                            d.ph = (d.ph or 0) + 0.3
                            Bullets.eRing(b.x, b.y, 11, 125, d.ph)
                            Bullets.eAimed(b.x, b.y, 160)
                        end
                    end,
                },
            },
        },
    },

    -- The whole level, placed at t = 0: it is a place, and all of it is there
    -- before you arrive. The boss alone is triggered by WHERE you are.
    waves = {
        { t = 0, type = "defender", x = 420,  y = 90 },
        { t = 0, type = "defender", x = 560,  y = 170 },
        { t = 0, type = "sentry",   x = 700,  y = 120 },
        { t = 0, type = "defender", x = 860,  y = 70 },
        { t = 0, type = "defender", x = 980,  y = 180 },
        { t = 0, type = "sentry",   x = 1140, y = 110 },
        { t = 0, type = "defender", x = 1280, y = 160 },
        { t = 0, type = "defender", x = 1400, y = 80 },
        { t = 0, type = "sentry",   x = 1560, y = 130 },
        { t = 0, type = "defender", x = 1700, y = 100 },
        { t = 0, type = "defender", x = 1820, y = 170 },
        { t = 0, type = "sentry",   x = 1960, y = 120 },
        { at = 1900, boss = "core" },
    },
}
