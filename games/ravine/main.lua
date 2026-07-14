-- Ravine: entry point. Imports the engine, hands it the game data, calls the
-- cabinet. d-pad flies, A fires forward, B drops bombs on the ground targets.

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

-- The cave-flying bot.
--
-- It steers by Terrain.groundY / Terrain.ceilY -- which is to say, by THE SAME
-- SAMPLED PROFILE THE COLLIDER USES. That is not a convenience, it is the
-- engine's second design rule made executable: when the drawn wall and the hit
-- wall were different curves (as they were, by up to a pixel, before the
-- terrain was rewritten), a bot flying the exact centre of the gap would still
-- occasionally clip a wall it was nowhere near -- and it would do it rarely
-- enough to look like flakiness rather than like a bug.
--
-- Bombing is the other half. Bombs are ballistic and the world is moving, so
-- the bot solves for the drop point rather than flying over the target and
-- hoping: fall time from the ship's altitude down to the target's, then the x
-- at which a bomb launched now meets a target that is itself sliding left.
local function makeBot()
    local cmd = { left = false, right = false, up = false, down = false,
                  fire = false, bomb = false, start = false }

    local HOLD_X <const> = 104     -- station-keeping: room to see what is coming
    local GRAV <const> = 320       -- must match Bullets.playerBomb
    local BOMB_VX <const> = 90
    local BOMB_VY <const> = 30

    -- Where should we be, vertically, and what is actually safe?
    --
    -- These are two different questions and the first version answered only
    -- one. It aimed at the middle of the gap 46 px AHEAD -- correct, since at
    -- 66 px/s the wall you must clear is one you can already see -- but it also
    -- CLAMPED to the gap 46 px ahead, while colliding at its own x. Where the
    -- cavern is narrower here than it is there, "safe" was being measured in
    -- the wrong place, and the ship clipped a wall it had already checked.
    --
    -- So: aim at the gap ahead, but clamp to the TIGHTEST gap anywhere in the
    -- span we currently occupy and are about to.
    local function gap()
        local ahead = math.min(SCREEN_W - 1, Player.x + 46)
        local mid = (Terrain.groundY(ahead) + Terrain.ceilY(ahead)) / 2

        local lo, hi = -1e9, 1e9        -- worst ceiling, worst ground
        for x = Player.x, ahead, 12 do
            lo = math.max(lo, Terrain.ceilY(x))
            hi = math.min(hi, Terrain.groundY(x))
        end
        return mid, lo, hi
    end

    -- Fall time for a bomb dropped now, from
    --   ty = py + BOMB_VY*t + GRAV*t^2/2
    local function fallTime(py, ty)
        local a = GRAV / 2
        local disc = BOMB_VY * BOMB_VY + 4 * a * (ty - py)
        if disc <= 0 then return nil end
        return (-BOMB_VY + math.sqrt(disc)) / (2 * a)
    end

    local function wantBomb()
        local pool = Enemies.pool
        for i = 1, pool.n do
            local e = pool.items[i]
            if not e.dead and (e.type == "dump" or e.type == "tank") then
                local t = fallTime(Player.y + 6, e.y)
                if t then
                    -- The bomb drifts right at BOMB_VX while the target slides
                    -- left with the world at Frame.speed: they close at the sum.
                    local dropX = e.x - (BOMB_VX + Frame.speed) * t
                    if math.abs(Player.x - dropX) < 11 then return true end
                end
            end
        end
        return false
    end

    -- A capsule that is about to drift onto us anyway. This bot used to ignore
    -- power-ups entirely and it showed: it reached the barge on weapon 1, ground
    -- the boss down to single digits over a long fight, and died -- about half
    -- the time, depending on which second of the clock the Simulator seeded
    -- from. A short fight is a safe fight, and the way to shorten it is a bigger
    -- gun.
    --
    -- But collecting must stay OPPORTUNISTIC. The first version of this chased
    -- capsules down, steering x as well as y -- and promptly started dying one
    -- wave short of the boss again, because a bot pursuing a capsule is a bot
    -- not aiming at the UFOs, and the UFOs pile up ahead of it exactly as they
    -- did before. The world here moves at 66 px/s and it moves TOWARD us: we do
    -- not need to fetch anything. We only need to be at the right altitude when
    -- it arrives.
    local function capsuleNear()
        local best, bd
        local pp = Power.pool
        for i = 1, pp.n do
            local p = pp.items[i]
            if not p.dead then
                local dx = p.x - Player.x
                if dx > -20 and dx < 95 and (not bd or dx < bd) then
                    bd, best = dx, p
                end
            end
        end
        return best
    end

    -- Is something we have to shoot bearing down on us? If so, the capsule waits.
    local function ufoClosing()
        local pool = Enemies.pool
        for i = 1, pool.n do
            local e = pool.items[i]
            if not e.dead and e.type == "ufo" then
                local dx = e.x - Player.x
                if dx > 0 and dx < 150 then return true end
            end
        end
        return false
    end

    -- The nearest thing we can actually shoot, while it is still far enough
    -- away that lining up on it is safe. Bullets fly flat along our row, so
    -- "aiming" in the side frame means choosing an altitude. The boss counts:
    -- it is the biggest air target there is.
    local function aimY()
        if Boss.active then return Boss.y end
        local best, bd
        local pool = Enemies.pool
        for i = 1, pool.n do
            local e = pool.items[i]
            if not e.dead and e.type == "ufo" then
                local dx = e.x - Player.x
                if dx > 80 and (not bd or dx < bd) then bd, best = dx, e end
            end
        end
        return best and best.y or nil
    end

    -- PICK AN ALTITUDE. Do not lean away from things.
    --
    -- Three bots died writing this function. Each was reactive: find the threat,
    -- lean the other way. Each failed in its own way, and the ways were
    -- instructive. Leaning away from the CURRENT position of a bullet ignores
    -- that the bullet is moving. Summing the leans from several bullets cancels
    -- to zero when you are caught between two of them, and the bot then flies
    -- perfectly straight into the crossfire. And recomputing the lean every
    -- frame makes the bot slide just far enough that the threat stops
    -- registering, whereupon it steers calmly back into the bullet it has not
    -- yet been hit by.
    --
    -- Every failing seed died the same way, and the death-cause counters said so
    -- in one word: bullet, bullet, bullet, bullet. Not the wall. Not a hull.
    --
    -- So: stop reacting. The gap is one-dimensional and about 150 px tall, which
    -- is nothing -- so sample every altitude in it, score each by how close the
    -- incoming fire will pass to it AT THE MOMENT IT ARRIVES, add the cost of
    -- flying there and a pull toward whatever we would like to shoot, and take
    -- the best. It is a planner rather than a reflex, it costs a couple of
    -- hundred comparisons a frame, and it does not oscillate, because the cost
    -- of moving is part of the thing it is minimising.
    local function bestY(ceil, ground, aim)
        local lo, hi = ceil + 16, ground - 16
        if hi < lo then return (lo + hi) / 2, 0 end

        local ep, pool = Bullets.ep, Enemies.pool
        local best, bestScore, crowd = Player.y, -1e18, 0

        for y = lo, hi, 5 do
            local danger = 0

            for i = 1, ep.n do
                local b = ep.items[i]
                if not b.dead and b.vx < -20 then
                    local t = (b.x - Player.x) / -b.vx
                    if t > 0 and t < 1.7 then
                        local d = math.abs((b.y + b.vy * t) - y)
                        if d < 32 then danger = danger + (32 - d) end
                    end
                end
            end

            for i = 1, pool.n do
                local e = pool.items[i]
                if not e.dead then
                    local dx = e.x - Player.x
                    if dx > -20 and dx < 130 then
                        local d = math.abs(e.y - y)
                        -- a hull is bigger than a bullet and kills just as dead
                        if d < 36 then danger = danger + (36 - d) * 2 end
                    end
                end
            end

            local score = -danger * 4 - math.abs(y - Player.y) * 0.3
            if aim then score = score - math.abs(y - aim) * 0.4 end
            if score > bestScore then bestScore, best = score, y end
        end

        -- how busy is it right here? (for the horizontal give-ground)
        for i = 1, pool.n do
            local e = pool.items[i]
            if not e.dead then
                local dx = e.x - Player.x
                if dx > -14 and dx < 110 and math.abs(e.y - Player.y) < 30 then
                    crowd = crowd + 1
                end
            end
        end

        return best, crowd
    end

    return function()
        local st = Harness.counters.state or 1
        cmd.left, cmd.right, cmd.up, cmd.down = false, false, false, false
        cmd.fire, cmd.bomb, cmd.start = false, false, false

        if st ~= 2 then
            cmd.start = (st == 1)
            return cmd
        end

        local mid, ceil, ground = gap()

        -- What we would LIKE: line the gun up on the nearest air target, or on
        -- a capsule that is drifting onto us anyway (nothing is fetched -- the
        -- world is coming to us at 66 px/s), or failing both, the middle of the
        -- gap ahead.
        local aim = aimY()
        if not aim and not Boss.active and not ufoClosing() then
            local cap = capsuleNear()
            if cap then aim = cap.y end
        end
        aim = aim or mid

        -- What we can SURVIVE, which outranks it.
        local want, crowd = bestY(ceil, ground, aim)

        cmd.up = Player.y > want + 3
        cmd.down = Player.y < want - 3

        -- Give ground when it gets busy. Retreating costs nothing in a frame
        -- where the world comes to you regardless, and it turns a problem you
        -- have half a second to solve into one you have a second to solve.
        local holdX = crowd >= 2 and 72 or HOLD_X
        cmd.left = Player.x > holdX + 6
        cmd.right = Player.x < holdX - 6

        cmd.fire = true
        cmd.bomb = wantBomb()
        return cmd
    end
end

Shmup.run(Content, {
    autopilot = Harness.enabled and makeBot() or nil,
    extra = function(t)
        t.fuel = math.floor(Player.fuel)
        t.bossActive = Boss.active and 1 or 0
        for k, v in pairs(Shmup.causes) do t["d_" .. k] = v end
    end,
})
