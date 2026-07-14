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

    -- Which way to sidestep. The first version of this compared each bullet's
    -- CURRENT x to ours, which is a bot dodging where the bullet is instead of
    -- where it is going: it beat the waves and then died to the boss every run,
    -- because the boss's aimed shots are launched at an angle. So: solve for
    -- when each bullet crosses our row, ask where it will be at that moment,
    -- and lean away from the ones that will land on us.
    local function dodge()
        local shift, nearest = 0, 999

        local ep = Bullets.ep
        for i = 1, ep.n do
            local b = ep.items[i]
            if not b.dead and b.vy > 20 then
                local t = (Player.y - b.y) / b.vy      -- time to our row
                if t > 0 and t < 1.1 then
                    local dx = (b.x + b.vx * t) - Player.x
                    if math.abs(dx) < 24 then
                        shift = shift + (dx >= 0 and -1 or 1)
                        if math.abs(dx) < math.abs(nearest) then nearest = dx end
                    end
                end
            end
        end

        local pool = Enemies.pool
        for i = 1, pool.n do
            local e = pool.items[i]
            if not e.dead then
                local dy = Player.y - e.y
                if dy > -8 and dy < 90 then
                    local dx = e.x - Player.x
                    if math.abs(dx) < 28 then
                        shift = shift + (dx >= 0 and -1 or 1)
                        if math.abs(dx) < math.abs(nearest) then nearest = dx end
                    end
                end
            end
        end

        -- Pinned from both sides: the sum cancels to zero and the naive bot
        -- stands perfectly still in the crossfire. Break the tie by running for
        -- the wider half of the screen.
        if shift == 0 and math.abs(nearest) < 14 then
            return Player.x < 200 and 1 or -1
        end
        return Lib.sign(shift)
    end

    local function targetX()
        if Boss.active then return Boss.x end

        local best, bd
        local pool = Enemies.pool
        for i = 1, pool.n do
            local e = pool.items[i]
            if not e.dead then
                -- prefer whatever is closest to reaching our line
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

    return function()
        local st = Harness.counters.state or 1
        cmd.left, cmd.right, cmd.up, cmd.down = false, false, false, false
        cmd.fire, cmd.start = false, false

        if st ~= 2 then                    -- title: start. over/win: stop dead.
            cmd.start = (st == 1)
            return cmd
        end

        local sh = dodge()
        if sh ~= 0 then
            cmd.left, cmd.right = sh < 0, sh > 0
        else
            local tx = targetX()
            cmd.left = tx < Player.x - 4
            cmd.right = tx > Player.x + 4
        end

        if Player.x < 26 then cmd.left, cmd.right = false, true end
        if Player.x > 374 then cmd.right, cmd.left = false, true end

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
    end,
})
