-- Nova Strike: entry point. Imports the engine, hands it the game data, and
-- calls the cabinet. The only game-specific code here is the autopilot -- and
-- the autopilot is a smoke test, not a game feature.

import "lib"
import "harness"
import "frame"
import "kit"
import "snd"
import "music"
import "fx"
import "sprites"
import "stars"
import "terrain"
import "bullets"
import "enemies"
import "power"
import "boss"
import "player"
import "waves"
import "shmup"
import "content"

-- The bot must BEAT the game, boss included. A bot that merely survives will
-- survive forever and tell you nothing; this one has to reach SECTOR CLEAR or
-- the smoke run fails.
--
-- It plays the vertical frame the way the frame wants to be played: hold the
-- bottom edge, keep the gun under whatever is closest to reaching you, and
-- sidestep anything on a collision line. Everything it reads -- the bullet
-- pool, the enemy pool, the boss -- is exactly what a player can see.
local function makeBot()
    local cmd = { left = false, right = false, up = false, down = false,
                  fire = false, bomb = false, start = false }

    -- What we would LIKE to be under: the boss, or whatever is closest to
    -- reaching our line, or -- if the sky is clear -- a capsule to collect.
    local function targetX()
        if Boss.active then return Boss.x end

        local best, bd
        local pool = Enemies.pool
        for i = 1, pool.n do
            local e = pool.items[i]
            if not e.dead then
                local d = math.abs(e.x - Player.x)
                    + math.max(0, Player.y - e.y) * 0.35
                if not bd or d < bd then bd, best = d, e end
            end
        end
        if best then return best.x end

        local pp = Power.pool          -- nothing left to kill: go collect
        for i = 1, pp.n do
            if not pp.items[i].dead then return pp.items[i].x end
        end
        return 200
    end

    -- PICK A COLUMN. Do not lean away from things.
    --
    -- This bot used to sidestep reactively: find the incoming bullets, lean the
    -- other way. That works until it doesn't, and the way it stops working is
    -- ugly -- a lean summed over several bullets cancels to zero exactly when
    -- you are caught between two of them, and a lean recomputed every frame
    -- slides you just far enough that the threat stops registering, at which
    -- point you steer calmly back into it.
    --
    -- It hid, too. Seeded from the clock, this bot won often enough to look
    -- fine; the moment the smoke runs were given FIXED seeds it turned out to
    -- lose two of the first four. That is the whole argument for seeding.
    --
    -- The screen is 400 px wide and the ship can be at any of them, so: score
    -- every column by how close the incoming fire will pass to it AT THE MOMENT
    -- IT ARRIVES, add the cost of flying there and a pull toward what we want to
    -- shoot, and take the best. A planner, not a reflex -- and it cannot
    -- oscillate, because the cost of moving is part of what it minimises.
    -- One more thing Ravine's version could take for granted and this one cannot.
    -- Ravine's gap is 150 px tall, so every candidate altitude is a short hop and
    -- the trip is free. This screen is 400 px wide, and a column that is safe
    -- when the bullets arrive is worthless if crossing to it means walking
    -- through the stream on the way. Searching the whole screen made the bot
    -- strictly WORSE -- it kept electing to be somewhere lovely and dying en
    -- route. So it only considers columns it can actually reach in the time it
    -- has: about half a second of travel, either side.
    local function bestX()
        local ep, pool = Bullets.ep, Enemies.pool
        local aim = targetX()
        local best, bestScore = Player.x, -1e18

        local lo = math.max(26, Player.x - 84)
        local hi = math.min(374, Player.x + 84)

        for x = lo, hi, 6 do
            local danger = 0

            for i = 1, ep.n do
                local b = ep.items[i]
                if not b.dead and b.vy > 20 then
                    local t = (Player.y - b.y) / b.vy         -- time to our row
                    if t > 0 and t < 1.6 then
                        local d = math.abs((b.x + b.vx * t) - x)
                        if d < 30 then danger = danger + (30 - d) end
                    end
                end
            end

            for i = 1, pool.n do
                local e = pool.items[i]
                if not e.dead then
                    local dy = Player.y - e.y
                    if dy > -10 and dy < 110 then
                        local d = math.abs(e.x - x)
                        -- a hull is bigger than a bullet and kills just as dead
                        if d < 34 then danger = danger + (34 - d) * 2 end
                    end
                end
            end

            -- Survival outranks aim -- but only just, and getting the ratio
            -- wrong is fatal in both directions. Weight aim too high and the bot
            -- parks under the boss, which is exactly where the boss's rings are
            -- densest. Weight it too low and the bot stops lining up on anything
            -- at all: it scored 1550 and died with the boss on 49 HP, having
            -- spent the whole level gracefully dodging enemies it never shot.
            -- A bot that will not commit to a firing line does not run out of
            -- luck, it runs out of level.
            local score = -danger * 5 - math.abs(x - Player.x) * 0.3
                - math.abs(x - aim) * 0.4
            if score > bestScore then bestScore, best = score, x end
        end

        return best
    end

    return function()
        local st = Harness.counters.state or 1
        cmd.left, cmd.right, cmd.up, cmd.down = false, false, false, false
        cmd.fire, cmd.start = false, false

        if st ~= 2 then                    -- title: start. over/win: stop dead.
            cmd.start = (st == 1)
            return cmd
        end

        local want = bestX()
        cmd.left = want < Player.x - 4
        cmd.right = want > Player.x + 4

        -- Sit as low as the frame allows: every pixel of altitude the bot gives
        -- up is reaction time it buys back.
        cmd.up = Player.y > 218
        cmd.down = Player.y < 210
        cmd.fire = true
        return cmd
    end
end

Shmup.run(Content, {
    autopilot = Harness.enabled and makeBot() or nil,
    extra = function(t)
        t.bossActive = Boss.active and 1 or 0
        for k, v in pairs(Shmup.causes) do t["d_" .. k] = v end
    end,
})
